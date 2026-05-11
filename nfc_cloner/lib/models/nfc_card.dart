import 'dart:convert';

enum CardTech {
  mifareClassic,
  mifareUltralight,
  isoDep,
  nfcA,
  nfcB,
  nfcF,
  nfcV,
  ndef,
  unknown,
}

extension CardTechExt on CardTech {
  String get displayName {
    switch (this) {
      case CardTech.mifareClassic:
        return 'MIFARE Classic';
      case CardTech.mifareUltralight:
        return 'MIFARE Ultralight';
      case CardTech.isoDep:
        return 'ISO-DEP (14443-4)';
      case CardTech.nfcA:
        return 'NFC-A (ISO 14443-3A)';
      case CardTech.nfcB:
        return 'NFC-B (ISO 14443-3B)';
      case CardTech.nfcF:
        return 'NFC-F (FeliCa)';
      case CardTech.nfcV:
        return 'NFC-V (ISO 15693)';
      case CardTech.ndef:
        return 'NDEF';
      case CardTech.unknown:
        return 'Bilinmiyor';
    }
  }

  bool get canEmulate => this == CardTech.isoDep;

  String get emulationNote {
    switch (this) {
      case CardTech.mifareClassic:
        return 'MIFARE Classic emülasyonu Android HCE tarafından desteklenmez. '
            'Kart verisi kaydedildi ancak telefon bu kart olarak davranamaz.';
      case CardTech.mifareUltralight:
        return 'MIFARE Ultralight emülasyonu standart Android HCE ile desteklenmez.';
      case CardTech.isoDep:
        return 'ISO-DEP kartlar HCE ile emüle edilebilir. '
            'Not: Bazı sistemler UID doğrulaması yaptığından emülasyon çalışmayabilir.';
      case CardTech.nfcA:
        return 'NFC-A kartlar için standart HCE emülasyonu desteklenmez.';
      case CardTech.nfcB:
        return 'NFC-B kartlar için standart HCE emülasyonu desteklenmez.';
      default:
        return 'Bu kart türü için emülasyon desteklenmez.';
    }
  }
}

class NfcCard {
  final String id;
  String name;
  final String uid;
  final CardTech tech;
  final Map<String, dynamic> rawData;
  final DateTime savedAt;

  NfcCard({
    required this.id,
    required this.name,
    required this.uid,
    required this.tech,
    required this.rawData,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'uid': uid,
        'tech': tech.index,
        'rawData': rawData,
        'savedAt': savedAt.toIso8601String(),
      };

  factory NfcCard.fromJson(Map<String, dynamic> json) {
    return NfcCard(
      id: json['id'] as String,
      name: json['name'] as String,
      uid: json['uid'] as String,
      tech: CardTech.values[json['tech'] as int],
      rawData: Map<String, dynamic>.from(json['rawData'] as Map),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());
}
