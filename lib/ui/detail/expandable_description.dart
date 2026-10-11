import 'package:flutter/material.dart';

class ExpandableDescription extends StatelessWidget {
  const ExpandableDescription({
    super.key,
    required this.judul,
    required this.text,
    this.maxBaris = 4,
  });

  final String judul;
  final String text;
  final int maxBaris;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    return LayoutBuilder(
      builder: (context, c) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: maxBaris,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: c.maxWidth);
        final terpotong = tp.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: style,
              maxLines: maxBaris,
              overflow: TextOverflow.ellipsis,
            ),
            if (terpotong)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 40),
                ),
                onPressed: () => _buka(context),
                child: const Text('Lihat lengkap'),
              ),
          ],
        );
      },
    );
  }

  void _buka(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Text(
              judul,
              style: Theme.of(ctx)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(text, style: Theme.of(ctx).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}