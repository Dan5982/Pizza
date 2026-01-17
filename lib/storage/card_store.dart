import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/card_model.dart';

class CardStore extends ChangeNotifier {
  static const _storageKey = 'repertoiretrainer.cards';

  final List<CardModel> _cards = [];

  List<CardModel> get cards => List.unmodifiable(_cards);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return;
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    _cards
      ..clear()
      ..addAll(decoded
          .map((entry) => CardModel.fromJson(entry as Map<String, dynamic>)));
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_cards.map((card) => card.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> addCard(String title, String pgnText) async {
    _cards.insert(0, CardModel.newCard(title: title, pgnText: pgnText));
    notifyListeners();
    await save();
  }

  Future<void> updateCard(CardModel updated) async {
    final index = _cards.indexWhere((card) => card.id == updated.id);
    if (index == -1) return;
    _cards[index] = updated;
    notifyListeners();
    await save();
  }

  Future<void> deleteCard(String id) async {
    _cards.removeWhere((card) => card.id == id);
    notifyListeners();
    await save();
  }
}
