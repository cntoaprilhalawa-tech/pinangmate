import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/foto_codec.dart';
import '../../data/models/event_status.dart';
import '../../data/models/item.dart';
import '../../data/models/open_hours.dart';
import 'formatters.dart';
import 'item_labels.dart';

Color okColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);

class ItemPhoto extends StatefulWidget {
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
  State<ItemPhoto> createState() => _ItemPhotoState();
}

class _ItemPhotoState extends State<ItemPhoto> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = decodeFoto(widget.foto);
  }

  @override
  void didUpdateWidget(ItemPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.foto != widget.foto) _bytes = decodeFoto(widget.foto);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: widget.width,
      height: widget.height,
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.photo_outlined, color: cs.onSurfaceVariant),
    );
    final url = widget.foto;
    final Widget content;
    if (_bytes != null) {
      content = Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else if (url != null && url.startsWith('http')) {
      content = Image.network(
        url,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else {
      content = placeholder;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
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
    return Text(
      open ? 'Buka' : 'Tutup',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: open ? okColor(context) : cs.error,
      ),
    );
  }
}

class EventBadge extends StatelessWidget {
  const EventBadge({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final s = eventStatus(item.tanggalMulai, item.tanggalSelesai);
    if (s == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final color = switch (s) {
      EventStatus.berlangsung => okColor(context),
      EventStatus.akanDatang => cs.primary,
      EventStatus.selesai => cs.onSurfaceVariant,
    };
    return Text(
      eventStatusLabel(s),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
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
    final info = item.kategori == Kategori.event
        ? tanggalLabel(item)
        : hargaLabel(item);
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
                    if (info != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        info,
                        style: text.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
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
                        if (item.kategori == Kategori.event)
                          EventBadge(item: item)
                        else
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