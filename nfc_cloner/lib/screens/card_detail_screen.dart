import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../models/nfc_card.dart';
import '../services/hce_service.dart';

class CardDetailScreen extends StatefulWidget {
  final NfcCard card;
  const CardDetailScreen({super.key, required this.card});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  final _hce = HceService();
  bool _emulating = false;

  Future<void> _toggleEmulation() async {
    if (_emulating) {
      await _hce.stopEmulation();
      setState(() => _emulating = false);
    } else {
      try {
        await _hce.startEmulation(
          uid: widget.card.uid,
          historicalBytes: widget.card.rawData['historical_bytes'] as String?,
          hiLayerResponse: widget.card.rawData['hi_layer_response'] as String?,
        );
        setState(() => _emulating = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('HCE emülasyonu başlatıldı'),
              backgroundColor: kPrimary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Emülasyon başlatılamadı: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Panoya kopyalandı'), duration: Duration(seconds: 1)),
    );
  }

  @override
  void dispose() {
    if (_emulating) _hce.stopEmulation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Scaffold(
      appBar: AppBar(
        title: Text(card.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'UID kopyala',
            onPressed: () => _copyToClipboard(card.uid),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(card),
          const SizedBox(height: 12),
          _emulationCard(card),
          const SizedBox(height: 12),
          _rawDataCard(card),
        ],
      ),
    );
  }

  Widget _headerCard(NfcCard card) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimary.withAlpha(25),
              ),
              child: const Icon(Icons.credit_card, size: 40, color: kPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              card.uid,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                color: kPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _techBadge(card.tech),
            const SizedBox(height: 8),
            Text(
              'Kaydedildi: ${_formatDate(card.savedAt)}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _techBadge(CardTech tech) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: kBorder,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tech.displayName,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  Widget _emulationCard(NfcCard card) {
    final canEmulate = card.tech.canEmulate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  canEmulate ? Icons.phone_android : Icons.block,
                  color: canEmulate ? kPrimary : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Emülasyon',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (canEmulate)
                  Switch(
                    value: _emulating,
                    onChanged: (_) => _toggleEmulation(),
                    activeColor: kPrimary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              card.tech.emulationNote,
              style: TextStyle(
                color: canEmulate ? Colors.white60 : Colors.orange.shade300,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (_emulating) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kPrimary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kPrimary.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 10, color: kPrimary),
                    const SizedBox(width: 8),
                    const Text(
                      'Emülasyon aktif — Kartı okutabilirsin',
                      style: TextStyle(color: kPrimary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rawDataCard(NfcCard card) {
    final data = card.rawData;
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.data_object, color: kPrimary),
        title: const Text('Ham Veri', style: TextStyle(color: Colors.white)),
        iconColor: kPrimary,
        collapsedIconColor: Colors.white54,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                for (final entry in data.entries)
                  if (entry.value is Map)
                    _sectionTile(entry.key, entry.value as Map)
                  else
                    _dataTile(entry.key, entry.value.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataTile(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(key,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12, fontFamily: 'monospace')),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _copyToClipboard(value),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTile(String sectionName, Map entries) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        sectionName,
        style: const TextStyle(color: Colors.white54, fontSize: 13),
      ),
      iconColor: Colors.white38,
      collapsedIconColor: Colors.white38,
      children: [
        for (final e in entries.entries)
          _dataTile(e.key.toString(), e.value.toString()),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
