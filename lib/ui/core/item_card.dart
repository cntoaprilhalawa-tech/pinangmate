import 'package:flutter/material.dart';

import '../../data/models/item.dart';
import '../../data/models/open_hours.dart';
import 'formatters.dart';

class ItemPhoto extends StatelessWidget {
  const ItemPhoto({
    super.key,
    required this.foto,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final String? foto;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: width,
      height: height,
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.photo_outlined, color: cs.onSurfaceVariant),
    );
    final url = foto;
    final Widget content = (url != null && url.startsWith('http'))
        ? Image.network(
            url,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => placeholder,
          )
        : placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: content,
    );
  }
}

class OpenBadge extends StatelessWidget {
  const OpenBadge({super.key, required this.jamBuka, required this.jamTutup});

  final String? jamBuka;
  final String? jamTutup;

  @override
  Widget build(BuildContext context) {
    final open = isOpenNow(jamBuka, jamTutup);
    if (open == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final okColor = dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
    return Text(
      open ? 'Buka' : 'Tutup',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: open ? okColor : cs.error,
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, required this.onTap});

  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ItemPhoto(foto: item.foto, width: 72, height: 72),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRupiah(item.harga),
                      style: text.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.ratingCount > 0)
                          Icon(Icons.star_rounded,
                              size: 16, color: cs.secondary),
                        if (item.ratingCount > 0) const SizedBox(width: 2),
                        Text(
                          formatRating(item.ratingAvg, item.ratingCount),
                          style: text.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        OpenBadge(
                          jamBuka: item.jamBuka,
                          jamTutup: item.jamTutup,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}