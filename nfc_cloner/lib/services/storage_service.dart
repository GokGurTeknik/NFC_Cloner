import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nfc_card.dart';

class StorageService {
  static const _cardsKey = 'saved_nfc_cards';

  Future<List<NfcCard>> loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_cardsKey);
    if (jsonStr == null) return [];
    final List<dynamic> list = jsonDecode(jsonStr);
    return list.map((j) => NfcCard.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> _save(List<NfcCard> cards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cardsKey, jsonEncode(cards.map((c) => c.toJson()).toList()));
  }

  Future<void> addCard(NfcCard card) async {
    final cards = await loadCards();
    cards.add(card);
    await _save(cards);
  }

  Future<void> deleteCard(String id) async {
    final cards = await loadCards();
    cards.removeWhere((c) => c.id == id);
    await _save(cards);
  }

  Future<void> updateCard(NfcCard card) async {
    final cards = await loadCards();
    final idx = cards.indexWhere((c) => c.id == card.id);
    if (idx != -1) {
      cards[idx] = card;
      await _save(cards);
    }
  }
}
