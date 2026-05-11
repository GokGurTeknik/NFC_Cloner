import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/cards_provider.dart';
import 'read_screen.dart';
import 'cards_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              _header(context),
              const Spacer(),
              _nfcGraphic(),
              const Spacer(),
              _buttons(context),
              const SizedBox(height: 16),
              _warningNote(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.contactless, size: 40, color: kPrimary),
        const SizedBox(height: 12),
        Text(
          'NFC Klonlayıcı',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Kartını oku • Telefonunda sakla • Kullan',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _nfcGraphic() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(200, 0.06),
          _ring(150, 0.10),
          _ring(110, 0.16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kPrimary.withAlpha(40),
              border: Border.all(color: kPrimary.withAlpha(100), width: 2),
            ),
            child: const Icon(Icons.nfc, size: 44, color: kPrimary),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kPrimary.withAlpha((opacity * 255).round()),
        ),
      );

  Widget _buttons(BuildContext context) {
    final count = context.watch<CardsProvider>().cards.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReadScreen()),
          ),
          icon: const Icon(Icons.nfc),
          label: const Text('Kart Oku'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CardsScreen()),
          ),
          icon: const Icon(Icons.credit_card),
          label: Text('Kartlarım ($count)'),
        ),
      ],
    );
  }

  Widget _warningNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '125 kHz kartlar (EM4100, HID Prox) telefon donanımı tarafından desteklenmez. '
              '13.56 MHz MIFARE kartlar okunabilir; emülasyon yalnızca ISO-DEP kartlarda çalışır.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.orange.shade300, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
