import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

/// CookMyFridge PayPal Integration
///
/// How it works:
/// 1. App calls PayPal REST API to create an order / subscription
/// 2. PayPal returns an approval URL
/// 3. We open that URL in the browser (user logs into PayPal and pays)
/// 4. PayPal redirects back to your return URL
/// 5. App captures the payment and upgrades the user to Pro
///
/// Setup: Create a PayPal Developer account at developer.paypal.com
///        Get your Client ID and Secret from the sandbox/live app

class PayPalService {
  // ── Configuration ─────────────────────────────────────────────────────────
  // Replace with your real PayPal credentials from developer.paypal.com
  static const _clientId = 'YOUR_PAYPAL_CLIENT_ID';
  static const _secret   = 'YOUR_PAYPAL_SECRET';

  // Use sandbox for testing, switch to live for production
  static const _isSandbox = true;
  static String get _baseUrl => _isSandbox
      ? 'https://api-m.sandbox.paypal.com'
      : 'https://api-m.paypal.com';

  // Your app's deep link — set this up in AndroidManifest.xml / Info.plist
  static const _returnUrl = 'cookmyfridge://paypal/success';
  static const _cancelUrl = 'cookmyfridge://paypal/cancel';

  // Pricing
  static const double proMonthlyPrice = 2.99;
  static const double proYearlyPrice  = 24.99; // ~$2.08/month
  static const String currency        = 'USD';

  // ── Get Access Token ──────────────────────────────────────────────────────
  static Future<String?> _getAccessToken() async {
    final credentials = base64Encode(utf8.encode('$_clientId:$_secret'));
    final response = await http.post(
      Uri.parse('$_baseUrl/v1/oauth2/token'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    }
    debugPrint('PayPal token error: ${response.body}');
    return null;
  }

  // ── Create Monthly Subscription ───────────────────────────────────────────
  /// Creates a PayPal subscription plan and returns the approval URL.
  /// The user is sent to PayPal to approve, then redirected back.
  static Future<String?> createSubscription({bool yearly = false}) async {
    final token = await _getAccessToken();
    if (token == null) return null;

    final price = yearly ? proYearlyPrice : proMonthlyPrice;
    final interval = yearly ? 'YEAR' : 'MONTH';

    // Step 1: Create a billing plan
    final planResponse = await http.post(
      Uri.parse('$_baseUrl/v1/billing/plans'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: jsonEncode({
        'product_id': await _getOrCreateProduct(token),
        'name': 'CookMyFridge Pro ${yearly ? 'Annual' : 'Monthly'}',
        'description': 'Unlimited AI recipes, nutrition tracking & more',
        'billing_cycles': [
          {
            'frequency': {'interval_unit': interval, 'interval_count': 1},
            'tenure_type': 'REGULAR',
            'sequence': 1,
            'total_cycles': 0,
            'pricing_scheme': {
              'fixed_price': {'value': price.toStringAsFixed(2), 'currency_code': currency}
            }
          }
        ],
        'payment_preferences': {
          'auto_bill_outstanding': true,
          'setup_fee_failure_action': 'CONTINUE',
          'payment_failure_threshold': 3,
        }
      }),
    );

    if (planResponse.statusCode != 201) {
      debugPrint('Plan creation failed: ${planResponse.body}');
      return null;
    }

    final planId = jsonDecode(planResponse.body)['id'];

    // Step 2: Create a subscription from the plan
    final subResponse = await http.post(
      Uri.parse('$_baseUrl/v1/billing/subscriptions'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'plan_id': planId,
        'subscriber': {
          'email_address': AuthService.currentUser?.email ?? '',
        },
        'application_context': {
          'return_url': _returnUrl,
          'cancel_url': _cancelUrl,
          'brand_name': 'CookMyFridge',
          'user_action': 'SUBSCRIBE_NOW',
        }
      }),
    );

    if (subResponse.statusCode == 201) {
      final data = jsonDecode(subResponse.body);
      final links = data['links'] as List;
      final approveLink = links.firstWhere((l) => l['rel'] == 'approve', orElse: () => null);
      return approveLink?['href'];
    }

    debugPrint('Subscription error: ${subResponse.body}');
    return null;
  }

  // ── One-time Payment (e.g. recipe pack) ───────────────────────────────────
  static Future<String?> createOneTimePayment({
    required String description,
    required double amount,
  }) async {
    final token = await _getAccessToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse('$_baseUrl/v2/checkout/orders'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'intent': 'CAPTURE',
        'purchase_units': [{
          'description': description,
          'amount': {'currency_code': currency, 'value': amount.toStringAsFixed(2)},
        }],
        'application_context': {
          'return_url': _returnUrl,
          'cancel_url': _cancelUrl,
          'brand_name': 'CookMyFridge',
          'user_action': 'PAY_NOW',
        }
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final links = data['links'] as List;
      final approveLink = links.firstWhere((l) => l['rel'] == 'approve', orElse: () => null);
      return approveLink?['href'];
    }

    debugPrint('Order error: ${response.body}');
    return null;
  }

  // ── Launch PayPal in browser ───────────────────────────────────────────────
  static Future<bool> launchPayPal(String approvalUrl) async {
    final uri = Uri.parse(approvalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  // ── Activate Pro after successful payment ─────────────────────────────────
  static Future<void> activatePro({bool yearly = false}) async {
    if (!AuthService.isLoggedIn) return;
    await FirebaseFirestore.instance.collection('users').doc(AuthService.userId).update({
      'plan': 'pro',
      'proActivatedAt': FieldValue.serverTimestamp(),
      'proType': yearly ? 'annual' : 'monthly',
      'proExpiresAt': Timestamp.fromDate(
        DateTime.now().add(yearly ? const Duration(days: 365) : const Duration(days: 30))
      ),
    });
    debugPrint('Pro activated for ${AuthService.userId}');
  }

  // ── Helper: get or create PayPal product ─────────────────────────────────
  static Future<String> _getOrCreateProduct(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/v1/catalogs/products'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': 'CookMyFridge Pro',
        'description': 'AI-powered recipe app premium subscription',
        'type': 'SERVICE',
        'category': 'SOFTWARE',
      }),
    );
    return jsonDecode(response.body)['id'] ?? 'PROD-COOKMYFRIDGE';
  }
}
