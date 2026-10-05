import 'package:flutter/material.dart';

import '../../data/models/item.dart';
import '../core/formatters.dart';
import '../core/item_card.dart';

class PopularCard extends StatelessWidget {
  const PopularCard({super.key, required this.item, required this.onTap});

  static const double width = 150;

  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ItemPhoto(foto: item.foto, width: width, height: 96, radius: 0),
              Padding(
                padding: const EdgeInsets.all(10),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.ratingCount > 0) ...[
                          Icon(Icons.star_rounded,
                              size: 16, color: cs.secondary),
                          const SizedBox(width: 2),
                        ],
                        Flexible(
                          child: Text(
                            formatRating(item.ratingAvg, item.ratingCount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 6),
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