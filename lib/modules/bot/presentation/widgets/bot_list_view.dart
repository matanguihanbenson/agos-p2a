import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bot_card.dart';

class BotListView extends StatelessWidget {
  final List<DocumentSnapshot> bots;
  final void Function(DocumentSnapshot bot)? onLiveFeed;
  final void Function(DocumentSnapshot bot)? onControl;

  const BotListView({
    super.key,
    required this.bots,
    this.onLiveFeed,
    this.onControl,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bots.length,
      itemBuilder: (context, i) {
        final doc = bots[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: BotCard(
            doc: doc,
            index: i,
            isGrid: false,
            onLiveFeed: () => onLiveFeed?.call(doc),
            onControl: () => onControl?.call(doc),
          ),
        );
      },
    );
  }
}
