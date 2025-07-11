import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bot_card.dart';

class BotGridView extends StatelessWidget {
  final List<DocumentSnapshot> bots;
  final void Function(DocumentSnapshot bot)? onLiveFeed;
  final void Function(DocumentSnapshot bot)? onControl;

  const BotGridView({
    super.key,
    required this.bots,
    this.onLiveFeed,
    this.onControl,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: bots.length,
      itemBuilder: (context, i) {
        final doc = bots[i];
        return BotCard(
          doc: doc,
          index: i,
          isGrid: true,
          onLiveFeed: () =>
              Navigator.pushNamed(context, '/live-feed', arguments: doc),
          onControl: () => onControl?.call(doc),
        );
      },
    );
  }
}
