import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/trip_location.dart';
import '../view_models/trip_location_view_model.dart';

class TripLocationScreen extends ConsumerStatefulWidget {
  const TripLocationScreen({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<TripLocationScreen> createState() => _TripLocationScreenState();
}

class _TripLocationScreenState extends ConsumerState<TripLocationScreen> {
  AppleMapController? _controller;
  String? _mapError;

  Future<void> _center(TripLocation location) async {
    try {
      await _controller?.moveCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location.latitude, location.longitude),
          12,
        ),
      );
    } on Exception {
      if (mounted) {
        setState(
          () => _mapError =
              'Unable to center the map. You can still save the selected coordinates.',
        );
      }
    }
  }

  Future<void> _save() async {
    final saved = await ref
        .read(tripLocationViewModelProvider(widget.tripId).notifier)
        .save();
    if (mounted && saved) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = tripLocationViewModelProvider(widget.tripId);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    ref.listen(provider, (previous, next) {
      if (next.location != null && previous?.location != next.location) {
        _center(next.location!);
      }
    });
    final location = state.location;
    final supported = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    return PopScope<void>(
      canPop: !state.isSaving,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Trip Location'),
          trailing: state.isSaving
              ? const CupertinoActivityIndicator()
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: state.isBusy || location == null ? null : _save,
                  child: const Text('Save'),
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: supported
                    ? AppleMap(
                        initialCameraPosition: CameraPosition(
                          target: location == null
                              ? const LatLng(20, 0)
                              : LatLng(location.latitude, location.longitude),
                          zoom: location == null ? 1 : 12,
                        ),
                        onMapCreated: (controller) {
                          _controller = controller;
                          final selected = ref.read(provider).location;
                          if (selected != null) _center(selected);
                        },
                        onTap: (point) => viewModel.selectLocation(
                          TripLocation(
                            latitude: point.latitude,
                            longitude: point.longitude,
                          ),
                        ),
                        annotations: {
                          if (location != null)
                            Annotation(
                              annotationId: AnnotationId('trip-location'),
                              position: LatLng(
                                location.latitude,
                                location.longitude,
                              ),
                              infoWindow: const InfoWindow(
                                title: 'Trip location',
                              ),
                            ),
                        },
                      )
                    : const Center(
                        child: Text('Apple Maps is available on iOS.'),
                      ),
              ),
              Flexible(
                flex: 0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Tap the map to place a pin, or use your current location. Save to keep it with this trip.',
                          textAlign: TextAlign.center,
                        ),
                        if (location != null)
                          Semantics(
                            liveRegion: true,
                            child: Text(location.label),
                          ),
                        if (state.error != null || _mapError != null)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              state.error ?? _mapError!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: CupertinoColors.systemRed.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                          ),
                        CupertinoButton(
                          onPressed: !supported || state.isBusy
                              ? null
                              : viewModel.useCurrentLocation,
                          child: state.isLocating
                              ? Semantics(
                                  label: 'Finding your location',
                                  liveRegion: true,
                                  child: const CupertinoActivityIndicator(),
                                )
                              : const Text('Use Current Location'),
                        ),
                        if (state.showSettings)
                          CupertinoButton(
                            onPressed: state.isBusy
                                ? null
                                : viewModel.openSettings,
                            child: const Text('Open Settings'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
