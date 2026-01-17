import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'storage/card_store.dart';
import 'views/library_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = CardStore();
  await store.load();
  runApp(RepertoireTrainerApp(store: store));
}

class RepertoireTrainerApp extends StatelessWidget {
  final CardStore store;

  const RepertoireTrainerApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: MaterialApp(
        title: 'RepertoireTrainer',
        theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
        home: const LibraryScreen(),
      ),
    );
  }
}
