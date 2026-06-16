import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: state.shoppingItems.isEmpty
          ? const Center(child: Text('Your shopping list is empty.'))
          : ListView.builder(
              itemCount: state.shoppingItems.length,
              itemBuilder: (context, i) {
                return ListTile(
                  title: Text(state.shoppingItems[i]['name'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => state.deleteShoppingItem(i),
                  ),
                );
              },
            ),
    );
  }
}
