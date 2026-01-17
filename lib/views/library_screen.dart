import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card_model.dart';
import '../storage/card_store.dart';
import 'paste_pgn_screen.dart';
import 'train_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CardStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('RepertoireTrainer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PastePGNScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: store.cards.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final card = store.cards[index];
          return Dismissible(
            key: ValueKey(card.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => store.deleteCard(card.id),
            child: ListTile(
              title: Text(card.title),
              subtitle: Text('Box ${card.box} • ${_statusLabel(card.dueStatus)}'),
              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade600),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TrainScreen(card: card),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _statusLabel(DueStatus status) {
    switch (status) {
      case DueStatus.overdue:
        return 'Overdue';
      case DueStatus.dueSoon:
        return 'Due Soon';
      case DueStatus.notDue:
        return 'Not Due';
    }
  }
}
