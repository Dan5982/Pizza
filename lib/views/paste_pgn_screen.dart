import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pgn_service.dart';
import '../storage/card_store.dart';

class PastePGNScreen extends StatefulWidget {
  const PastePGNScreen({super.key});

  @override
  State<PastePGNScreen> createState() => _PastePGNScreenState();
}

class _PastePGNScreenState extends State<PastePGNScreen> {
  final _titleController = TextEditingController();
  final _pgnController = TextEditingController();
  final _pgnService = PGNService();

  List<String> _assetFiles = [];
  String? _selectedAsset;

  @override
  void initState() {
    super.initState();
    _loadAssetList();
  }

  Future<void> _loadAssetList() async {
    final assets = await _pgnService.listAssetPGNs();
    setState(() {
      _assetFiles = assets;
    });
  }

  Future<void> _loadSelectedAsset(String assetPath) async {
    final content = await _pgnService.loadAssetPGN(assetPath);
    setState(() {
      _selectedAsset = assetPath;
      _pgnController.text = content;
      _titleController.text = _titleController.text.isEmpty
          ? assetPath.split('/').last.replaceAll('.pgn', '')
          : _titleController.text;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pgnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<CardStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paste PGN'),
        actions: [
          TextButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              final pgn = _pgnController.text.trim();
              if (title.isEmpty || pgn.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a title and PGN text.')),
                );
                return;
              }
              await store.addCard(title, pgn);
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_assetFiles.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              value: _selectedAsset,
              decoration: const InputDecoration(
                labelText: 'Load PGN from assets',
                border: OutlineInputBorder(),
              ),
              items: _assetFiles
                  .map(
                    (asset) => DropdownMenuItem(
                      value: asset,
                      child: Text(asset.split('/').last),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _loadSelectedAsset(value);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _pgnController,
            decoration: const InputDecoration(
              labelText: 'PGN',
              border: OutlineInputBorder(),
            ),
            maxLines: 12,
          ),
        ],
      ),
    );
  }
}
