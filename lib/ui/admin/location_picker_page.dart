import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/nominatim_service.dart';
import 'location_picker_view_model.dart';

const _pusatTanjungpinang = LatLng(0.92, 104.45);

class LocationPickerPage extends StatelessWidget {
  const LocationPickerPage({super.key, this.initial});

  final LatLng? initial;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => LocationPickerViewModel(
        c.read<NominatimService>(),
        initial: initial,
      ),
      child: _PickerBody(initial: initial),
    );
  }
}

class _PickerBody extends StatefulWidget {
  const _PickerBody({required this.initial});

  final LatLng? initial;

  @override
  State<_PickerBody> createState() => _PickerBodyState();
}

class _PickerBodyState extends State<_PickerBody> {
  final _map = MapController();
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    _map.dispose();
    super.dispose();
  }

  void _cari() {
    FocusScope.of(context).unfocus();
    context.read<LocationPickerViewModel>().search(_query.text);
  }

  void _pilih(GeoResult r) {
    context.read<LocationPickerViewModel>().pilihHasil(r);
    _map.move(LatLng(r.lat, r.lng), 17);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LocationPickerViewModel>();
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final pin = vm.pin;

    return Scaffold(
      appBar: AppBar(title: const Text('Pilih lokasi')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: widget.initial ?? _pusatTanjungpinang,
              initialZoom: widget.initial == null ? 13 : 16,
              onTap: (tapPosition, point) =>
                  context.read<LocationPickerViewModel>().setPin(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pinangmate.pinangmate',
              ),
              if (pin != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pin,
                      width: 48,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: Icon(Icons.location_on, size: 48, color: cs.error),
                    ),
                  ],
                ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(
                      Uri.parse('https://openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Column(
              children: [
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(28),
                  color: cs.surface,
                  child: TextField(
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _cari(),
                    decoration: InputDecoration(
                      hintText: 'Cari tempat, lalu tekan cari',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Cari',
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _cari,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (vm.searching)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: LinearProgressIndicator(),
                  ),
                if (vm.message != null)
                  Card(
                    margin: const EdgeInsets.only(top: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(vm.message!),
                    ),
                  ),
                if (vm.results.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(top: 4),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: vm.results.length,
                        separatorBuilder: (context, i) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final r = vm.results[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined),
                            title: Text(
                              r.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _pilih(r),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 6,
              color: cs.surface,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pin == null
                            ? 'Ketuk peta untuk menaruh pin'
                            : '${pin.latitude.toStringAsFixed(6)}, ${pin.longitude.toStringAsFixed(6)}',
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (vm.alamat != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          vm.alamat!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: pin == null
                              ? null
                              : () => context.pop(vm.hasil()),
                          child: const Text('Gunakan lokasi ini'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}