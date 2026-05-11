import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/nfc_card.dart';
import '../providers/cards_provider.dart';
import '../services/nfc_service.dart';
import 'card_detail_screen.dart';

enum _State { idle, scanning, result, error }

class ReadScreen extends StatefulWidget {
  const ReadScreen({super.key});

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen>
    with SingleTickerProviderStateMixin {
  final _nfcService = NfcService();
  _State _state = _State.idle;
  NfcCard? _scannedCard;
  String _errorMsg = '';
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    if (_state == _State.scanning) _nfcService.stopSession();
    super.dispose();
  }

  Future<void> _startScan() async {
    final available = await _nfcService.isAvailable();
    if (!available) {
      setState(() {
        _state = _State.error;
        _errorMsg = 'Bu cihazda NFC desteklenmiyor veya kapalı.';
      });
      return;
    }

    setState(() => _state = _State.scanning);
    _pulseCtrl.repeat(reverse: true);

    await _nfcService.startSession(
      onDiscovered: (card) {
        _pulseCtrl.stop();
        setState(() {
          _scannedCard = card;
          _state = _State.result;
        });
      },
      onError: (err) {
        _pulseCtrl.stop();
        setState(() {
          _state = _State.error;
          _errorMsg = err;
        });
      },
    );
  }

  void _stopScan() {
    _pulseCtrl.stop();
    _nfcService.stopSession();
    setState(() => _state = _State.idle);
  }

  Future<void> _saveCard() async {
    if (_scannedCard == null) return;
    final name = await _showNameDialog(_scannedCard!.name);
    if (name == null) return;

    _scannedCard!.name = name;
    if (!mounted) return;
    await context.read<CardsProvider>().add(_scannedCard!);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CardDetailScreen(card: _scannedCard!),
      ),
    );
  }

  Future<String?> _showNameDialog(String initial) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Karta isim ver'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Kart adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? initial : ctrl.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kart Oku')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_state) {
            _State.idle => _idleBody(),
            _State.scanning => _scanningBody(),
            _State.result => _resultBody(),
            _State.error => _errorBody(),
          },
        ),
      ),
    );
  }

  Widget _idleBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.nfc, size: 80, color: kPrimary),
        const SizedBox(height: 24),
        Text(
          'NFC kartını okumak için\nbaşlat butonuna bas',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: _startScan,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Okumayı Başlat'),
        ),
      ],
    );
  }

  Widget _scanningBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Transform.scale(
            scale: _pulse.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimary.withAlpha(20),
                    border: Border.all(color: kPrimary.withAlpha(80), width: 2),
                  ),
                ),
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimary.withAlpha(35),
                    border: Border.all(color: kPrimary.withAlpha(120), width: 2),
                  ),
                ),
                const Icon(Icons.nfc, size: 64, color: kPrimary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Kartı telefona yaklaştır',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'NFC okuyucu aktif',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: kPrimary),
        ),
        const SizedBox(height: 40),
        OutlinedButton.icon(
          onPressed: _stopScan,
          icon: const Icon(Icons.stop),
          label: const Text('Durdur'),
        ),
      ],
    );
  }

  Widget _resultBody() {
    final card = _scannedCard!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 60, color: kPrimary),
        const SizedBox(height: 16),
        Text(
          'Kart Okundu!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 24),
        _infoTile('UID', card.uid),
        const SizedBox(height: 8),
        _infoTile('Tür', card.tech.displayName),
        const SizedBox(height: 8),
        _emulationBadge(card),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _saveCard,
          icon: const Icon(Icons.save),
          label: const Text('Kaydet'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => setState(() => _state = _State.idle),
          icon: const Icon(Icons.refresh),
          label: const Text('Yeniden Oku'),
        ),
      ],
    );
  }

  Widget _errorBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(
          _errorMsg,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => setState(() => _state = _State.idle),
          icon: const Icon(Icons.replay),
          label: const Text('Tekrar Dene'),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emulationBadge(NfcCard card) {
    final canEmulate = card.tech.canEmulate;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: canEmulate ? kPrimary.withAlpha(20) : Colors.orange.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: canEmulate ? kPrimary.withAlpha(80) : Colors.orange.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Icon(
            canEmulate ? Icons.check_circle_outline : Icons.warning_amber,
            color: canEmulate ? kPrimary : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              card.tech.emulationNote,
              style: TextStyle(
                color: canEmulate ? kPrimary : Colors.orange.shade300,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
