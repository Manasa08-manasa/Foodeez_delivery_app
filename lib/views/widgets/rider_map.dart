import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class RiderMap extends StatefulWidget {
  final String? partnerId;
  final List<Map<String, dynamic>> activeRiders;
  final void Function(double latitude, double longitude)? onLocationChanged;

  const RiderMap({
    super.key,
    this.partnerId,
    this.activeRiders = const [],
    this.onLocationChanged,
  });

  @override
  State<RiderMap> createState() => _RiderMapState();
}

class _RiderMapState extends State<RiderMap> {
  static const _bikeAsset = 'assets/images/rider-bike-marker.png';

  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(17.4126, 78.4482);

  final Set<Marker> _markers = {};
  BitmapDescriptor? _bikeIcon;
  BitmapDescriptor? _youIcon;

  Future<void> _syncMarkers() async {
    final markers = <Marker>{};
    final positions = <LatLng>[];
    final bike = _bikeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    final you = _youIcon ?? bike;

    if (_currentLocation != const LatLng(17.4126, 78.4482) || widget.activeRiders.isNotEmpty) {
      positions.add(_currentLocation);
      markers.add(
        Marker(
          markerId: const MarkerId('you'),
          position: _currentLocation,
          icon: you,
          zIndexInt: 2,
        ),
      );
    }

    for (final rider in widget.activeRiders) {
      final lat = _parseDouble(rider['latitude'] ?? rider['lat'] ?? rider['partnerLatitude'] ?? rider['partner_latitude']);
      final lng = _parseDouble(rider['longitude'] ?? rider['lng'] ?? rider['partnerLongitude'] ?? rider['partner_longitude']);
      if (lat == null || lng == null) continue;

      final riderId = rider['partnerId']?.toString() ??
          rider['id']?.toString() ??
          rider['partner_id']?.toString() ??
          rider['rider_id']?.toString() ??
          'rider-${positions.length + 1}';

      if (widget.partnerId != null && widget.partnerId!.isNotEmpty && riderId == widget.partnerId) {
        continue;
      }

      final position = LatLng(lat, lng);
      positions.add(position);
      markers.add(
        Marker(
          markerId: MarkerId(riderId),
          position: position,
          icon: bike,
          zIndexInt: 1,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers
          ..clear()
          ..addAll(markers);
      });
    }

    if (_mapController != null && positions.isNotEmpty) {
      _fitToMarkers(positions);
    }
  }

  Future<void> _fitToMarkers(List<LatLng> positions) async {
    if (positions.isEmpty) return;

    final latitudes = positions.map((p) => p.latitude).toList();
    final longitudes = positions.map((p) => p.longitude).toList();
    final bounds = LatLngBounds(
      southwest: LatLng(latitudes.reduce((a, b) => a < b ? a : b), longitudes.reduce((a, b) => a < b ? a : b)),
      northeast: LatLng(latitudes.reduce((a, b) => a > b ? a : b), longitudes.reduce((a, b) => a > b ? a : b)),
    );

    await _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 70),
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Future<void> _loadBikeIcon() async {
    // Transparent PNG bike silhouette only (no white square / text).
    _bikeIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(84, 72)),
      _bikeAsset,
    );
    _youIcon = _bikeIcon;
    if (mounted) await _syncMarkers();
  }

  @override
  void initState() {
    super.initState();
    _loadBikeIcon();
    _getCurrentLocation();
  }

  @override
  void didUpdateWidget(covariant RiderMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeRiders != widget.activeRiders || oldWidget.partnerId != widget.partnerId) {
      _syncMarkers();
    }
  }

  Future<void> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    _currentLocation = LatLng(position.latitude, position.longitude);
    widget.onLocationChanged?.call(position.latitude, position.longitude);

    await _syncMarkers();
    if (mounted) setState(() {});

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentLocation, zoom: 16.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentLocation,
        zoom: 16.5,
      ),
      markers: _markers,
      myLocationEnabled: false,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: false,
      indoorViewEnabled: false,
      buildingsEnabled: false,
      trafficEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        if (_markers.isNotEmpty) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentLocation, zoom: 16.5),
            ),
          );
        }
      },
    );
  }
}
