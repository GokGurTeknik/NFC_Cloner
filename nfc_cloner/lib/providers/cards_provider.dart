import 'package:flutter/material.dart';
import '../models/nfc_card.dart';
import '../services/storage_service.dart';

class CardsProvider extends ChangeNotifier {
  final _storage = StorageService();
  List<NfcCard> _cards = [];
  bool _loading = false;

  List<NfcCard> get cards => List.unmodifiable(_cards);
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _cards = await _storage.loadCards();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(NfcCard card) async {
    _cards.add(card);
    notifyListeners();
    await _storage.addCard(card);
  }

  Future<void> delete(String id) async {
    _cards.removeWhere((c) => c.id == id);
    notifyListeners();
    await _storage.deleteCard(id);
  }

  Future<void> rename(String id, String newName) async {
    final idx = _cards.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    _cards[idx].name = newName;
    notifyListeners();
    await _storage.updateCard(_cards[idx]);
  }
}
