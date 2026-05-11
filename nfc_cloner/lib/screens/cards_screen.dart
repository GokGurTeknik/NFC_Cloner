import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/nfc_card.dart';
import '../providers/cards_provider.dart';
import 'card_detail_screen.dart';
import 'read_screen.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kartlarım')),
      body: Consumer<CardsProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator(color: kPrimary));
          }
          if (provider.cards.isEmpty) {
            return _emptyState(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _cardTile(context, provider.cards[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReadScreen()),
        ),
        backgroundColor: kPrimary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.nfc),
        label: const Text('Yeni Kart'),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.credit_card_off, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Henüz kayıtlı kart yok',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReadScreen()),
            ),
            icon: const Icon(Icons.nfc),
            label: const Text('İlk Kartı Oku'),
          ),
        ],
      ),
    );
  }

  Widget _cardTile(BuildContext context, NfcCard card) {
    return Dismissible(
      key: Key(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withAlpha(80)),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: kCard,
            title: const Text('Kartı sil?'),
            content: Text('"${card.name}" silinecek.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('Sil'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<CardsProvider>().delete(card.id);
      },
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _techColor(card.tech).withAlpha(30),
            ),
            child: Icon(Icons.credit_card, color: _techColor(card.tech), size: 22),
          ),
          title: Text(
            card.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                card.uid,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  _badge(card.tech.displayName, _techColor(card.tech)),
                  if (card.tech.canEmulate) ...[
                    const SizedBox(width: 6),
                    _badge('Emüle edilebilir', kPrimary),
                  ],
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white38),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10)),
    );
  }

  Color _techColor(CardTech tech) {
    switch (tech) {
      case CardTech.mifareClassic:
        return Colors.blueAccent;
      case CardTech.mifareUltralight:
        return Colors.purpleAccent;
      case CardTech.isoDep:
        return kPrimary;
      default:
        return Colors.grey;
    }
  }
}
