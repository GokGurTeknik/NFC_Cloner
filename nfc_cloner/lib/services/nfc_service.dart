import 'dart:typed_data';
import 'dart:math' as math;
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:uuid/uuid.dart';
import '../models/nfc_card.dart';

class NfcService {
  static const _defaultKeysA = [
    [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
    [0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5],
    [0xD3, 0xF7, 0xD3, 0xF7, 0xD3, 0xF7],
    [0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
    [0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5],
    [0x4D, 0x3A, 0x99, 0xC3, 0x51, 0xDD],
  ];

  // MifareClassic type constants (Android)
  static const _mcTypeClassic = 0;
  static const _mcTypePlus = 1;
  static const _mcTypePro = 2;

  // MifareUltralight type constants (Android)
  static const _muTypeUltralight = 1;
  static const _muTypeUltralightC = 2;

  Future<bool> isAvailable() => NfcManager.instance.isAvailable();

  Future<void> startSession({
    required void Function(NfcCard card) onDiscovered,
    required void Function(String error) onError,
  }) async {
    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final card = await _processTag(tag);
          onDiscovered(card);
        } catch (e) {
          onError('Kart okunurken hata: $e');
        }
      },
    );
  }

  Future<void> stopSession({String? alertMessage}) async {
    await NfcManager.instance.stopSession(alertMessage: alertMessage);
  }

  Future<NfcCard> _processTag(NfcTag tag) async {
    final mifareClassic = MifareClassic.from(tag);
    final mifareUltralight = MifareUltralight.from(tag);
    final isoDep = IsoDep.from(tag);
    final nfcA = NfcA.from(tag);
    final nfcB = NfcB.from(tag);
    final nfcF = NfcF.from(tag);
    final nfcV = NfcV.from(tag);

    String uid = '';
    CardTech tech = CardTech.unknown;
    final rawData = <String, dynamic>{};

    if (mifareClassic != null) {
      tech = CardTech.mifareClassic;
      uid = _toHexColon(mifareClassic.identifier);
      rawData['identifier'] = _toHex(mifareClassic.identifier);
      rawData['type'] = _mcTypeName(mifareClassic.type);
      rawData['size_bytes'] = mifareClassic.size;
      rawData['block_count'] = mifareClassic.blockCount;
      rawData['sector_count'] = mifareClassic.sectorCount;
      final sectors = await _readMifareClassicSectors(mifareClassic);
      if (sectors.isNotEmpty) rawData['sectors'] = sectors;
    } else if (mifareUltralight != null) {
      tech = CardTech.mifareUltralight;
      uid = _toHexColon(mifareUltralight.identifier);
      rawData['identifier'] = _toHex(mifareUltralight.identifier);
      rawData['type'] = _muTypeName(mifareUltralight.type);
      final pages = await _readUltralightPages(mifareUltralight);
      if (pages.isNotEmpty) rawData['pages'] = pages;
    } else if (isoDep != null) {
      tech = CardTech.isoDep;
      uid = _toHexColon(isoDep.identifier);
      rawData['identifier'] = _toHex(isoDep.identifier);
      if (isoDep.historicalBytes != null) {
        rawData['historical_bytes'] = _toHex(isoDep.historicalBytes!);
      }
      if (isoDep.hiLayerResponse != null) {
        rawData['hi_layer_response'] = _toHex(isoDep.hiLayerResponse!);
      }
      rawData['extended_length_apdu'] = isoDep.isExtendedLengthApduSupported;
    } else if (nfcA != null) {
      tech = CardTech.nfcA;
      uid = _toHexColon(nfcA.identifier);
      rawData['identifier'] = _toHex(nfcA.identifier);
      rawData['atqa'] = _toHex(nfcA.atqa);
      rawData['sak'] = nfcA.sak.toRadixString(16).padLeft(2, '0').toUpperCase();
    } else if (nfcB != null) {
      tech = CardTech.nfcB;
      uid = _toHexColon(nfcB.identifier);
      rawData['identifier'] = _toHex(nfcB.identifier);
      rawData['application_data'] = _toHex(nfcB.applicationData);
      rawData['protocol_info'] = _toHex(nfcB.protocolInfo);
    } else if (nfcF != null) {
      tech = CardTech.nfcF;
      uid = _toHexColon(nfcF.identifier);
      rawData['identifier'] = _toHex(nfcF.identifier);
      rawData['system_code'] = _toHex(nfcF.systemCode);
      rawData['manufacturer'] = _toHex(nfcF.manufacturer);
    } else if (nfcV != null) {
      tech = CardTech.nfcV;
      uid = _toHexColon(nfcV.identifier);
      rawData['identifier'] = _toHex(nfcV.identifier);
      rawData['dsf_id'] =
          nfcV.dsfId.toRadixString(16).padLeft(2, '0').toUpperCase();
      rawData['response_flags'] =
          nfcV.responseFlags.toRadixString(16).padLeft(2, '0').toUpperCase();
    }

    final shortUid = uid.replaceAll(':', '');
    final name = 'Kart ${shortUid.substring(0, math.min(8, shortUid.length))}';

    return NfcCard(
      id: const Uuid().v4(),
      name: name,
      uid: uid,
      tech: tech,
      rawData: rawData,
      savedAt: DateTime.now(),
    );
  }

  Future<Map<String, String>> _readMifareClassicSectors(
      MifareClassic mc) async {
    final result = <String, String>{};
    for (int s = 0; s < mc.sectorCount; s++) {
      bool authenticated = false;
      for (final key in _defaultKeysA) {
        try {
          authenticated = await mc.authenticateSectorWithKeyA(
            sectorIndex: s,
            key: Uint8List.fromList(key),
          );
          if (authenticated) break;
        } catch (_) {}
      }
      if (!authenticated) {
        result['sektor_$s'] = 'AUTH_FAILED';
        continue;
      }
      final blockCount = _mcBlockCountInSector(s, mc.sectorCount);
      final firstBlock = _mcFirstBlockInSector(s);
      final blocks = <String>[];
      for (int b = 0; b < blockCount; b++) {
        try {
          final data = await mc.readBlock(blockIndex: firstBlock + b);
          blocks.add(_toHex(data));
        } catch (_) {
          blocks.add('READ_ERR');
        }
      }
      result['sektor_$s'] = blocks.join(' | ');
    }
    return result;
  }

  Future<Map<String, String>> _readUltralightPages(
      MifareUltralight mu) async {
    final result = <String, String>{};
    for (int p = 0; p < 45; p += 4) {
      try {
        final data = await mu.readPages(pageOffset: p);
        for (int i = 0; i < 4 && (p + i) < 45; i++) {
          final start = i * 4;
          final end = start + 4;
          if (end <= data.length) {
            result['sayfa_${p + i}'] = _toHex(data.sublist(start, end));
          }
        }
      } catch (_) {
        break;
      }
    }
    return result;
  }

  // MIFARE Classic 1K: sectors 0-15, 4 blocks each
  // MIFARE Classic 4K: sectors 0-31 have 4 blocks, sectors 32-39 have 16 blocks
  static int _mcBlockCountInSector(int sector, int totalSectors) {
    if (totalSectors <= 16) return 4;
    return sector < 32 ? 4 : 16;
  }

  static int _mcFirstBlockInSector(int sector) {
    if (sector < 32) return sector * 4;
    return 128 + (sector - 32) * 16;
  }

  static String _mcTypeName(int type) {
    switch (type) {
      case _mcTypeClassic:
        return 'Classic';
      case _mcTypePlus:
        return 'Plus';
      case _mcTypePro:
        return 'Pro';
      default:
        return 'Bilinmiyor';
    }
  }

  static String _muTypeName(int type) {
    switch (type) {
      case _muTypeUltralight:
        return 'Ultralight';
      case _muTypeUltralightC:
        return 'Ultralight C';
      default:
        return 'Bilinmiyor';
    }
  }

  static String _toHex(Uint8List bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join();

  static String _toHexColon(Uint8List bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(':');
}
