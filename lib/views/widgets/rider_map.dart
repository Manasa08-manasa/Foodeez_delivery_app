import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class RiderMap extends StatefulWidget {
  final String? partnerId;
  final List<Map<String, dynamic>> activeRiders;
  final void Function(double latitude, double longitude)? onLocationChanged;

  const RiderMap({super.key, this.partnerId, this.activeRiders = const [], this.onLocationChanged});

  @override
  State<RiderMap> createState() => _RiderMapState();
}

class _RiderMapState extends State<RiderMap> {
  GoogleMapController? _mapController;

  LatLng _currentLocation = const LatLng(17.4126, 78.4482);

  final Set<Marker> _markers = {};
  BitmapDescriptor? _currentPartnerIcon;
  final Map<String, BitmapDescriptor> _activeRiderIcons = {};

  Future<void> _syncMarkers() async {
    final markers = <Marker>{};
    final positions = <LatLng>[];

    if (_currentLocation != const LatLng(17.4126, 78.4482) || widget.activeRiders.isNotEmpty) {
      positions.add(_currentLocation);
      markers.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: _currentLocation,
          icon: _currentPartnerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: widget.partnerId != null && widget.partnerId!.isNotEmpty ? 'You' : 'Your Location'),
        ),
      );
    }

    for (final rider in widget.activeRiders) {
      final lat = _parseDouble(rider['latitude'] ?? rider['lat'] ?? rider['partnerLatitude'] ?? rider['partner_latitude']);
      final lng = _parseDouble(rider['longitude'] ?? rider['lng'] ?? rider['partnerLongitude'] ?? rider['partner_longitude']);
      if (lat == null || lng == null) continue;

      final riderName = rider['partnerName']?.toString() ??
          rider['partner_name']?.toString() ??
          rider['riderName']?.toString() ??
          rider['rider_name']?.toString() ??
          rider['fullName']?.toString() ??
          rider['full_name']?.toString() ??
          rider['name']?.toString() ??
          'Rider';
      final initials = _initialsForName(riderName);
      final riderId = rider['partnerId']?.toString() ??
          rider['id']?.toString() ??
          rider['partner_id']?.toString() ??
          rider['rider_id']?.toString() ??
          'rider-${positions.length + 1}';
      final icon = await _getRiderIcon(riderId, initials, riderName);
      final position = LatLng(lat, lng);
      positions.add(position);
      markers.add(
        Marker(
          markerId: MarkerId(riderId),
          position: position,
          icon: icon,
          infoWindow: InfoWindow(
            title: riderName,
            snippet: 'Active rider',
          ),
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

  Future<BitmapDescriptor> _createMarkerIcon(Color backgroundColor, {IconData? icon, String? label, String? subLabel}) async {
    const size = Size(120, 120);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = backgroundColor;
    canvas.drawCircle(const Offset(60, 60), 54, paint);

    if (icon != null) {
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 50,
          color: Colors.white,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
      );
    } else if (label != null && label.isNotEmpty) {
      final primaryPainter = TextPainter(textDirection: TextDirection.ltr);
      primaryPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      primaryPainter.layout(maxWidth: 90);
      final primaryOffset = Offset((size.width - primaryPainter.width) / 2, 24);
      primaryPainter.paint(canvas, primaryOffset);

      if (subLabel != null && subLabel.isNotEmpty) {
        final secondaryPainter = TextPainter(textDirection: TextDirection.ltr, maxLines: 2, ellipsis: '...');
        secondaryPainter.text = TextSpan(
          text: subLabel,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        );
        secondaryPainter.layout(maxWidth: 100);
        final secondaryOffset = Offset((size.width - secondaryPainter.width) / 2, primaryOffset.dy + primaryPainter.height + 6);
        secondaryPainter.paint(canvas, secondaryOffset);
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  String _initialsForName(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Future<BitmapDescriptor> _getRiderIcon(String riderId, String initials, String riderName) async {
    if (_activeRiderIcons.containsKey(riderId)) {
      return _activeRiderIcons[riderId]!;
    }
    final marker = await _createMarkerIcon(
      const Color(0xFF10B981),
      label: initials,
      subLabel: _shortNameForMarker(riderName),
    );
    _activeRiderIcons[riderId] = marker;
    return marker;
  }

  String _shortNameForMarker(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    const maxLength = 12;
    if (trimmed.length <= maxLength) return trimmed;
    return '${trimmed.substring(0, maxLength)}...';
  }

  Future<void> _initMarkerIcons() async {
    _currentPartnerIcon = await _createMarkerIcon(const Color(0xFF3B82F6), icon: Icons.person);
    if (mounted) {
      await _syncMarkers();
    }
  }

  @override
  void initState() {
    super.initState();
    _initMarkerIcons();
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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();

    _currentLocation = LatLng(position.latitude, position.longitude);
    widget.onLocationChanged?.call(position.latitude, position.longitude);

    _syncMarkers();

    if (mounted) {
      setState(() {});
    }

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLocation,
          zoom: 16.5,
        ),
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
      myLocationEnabled: true,
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
              CameraPosition(
                target: _currentLocation,
                zoom: 16.5,
              ),
            ),
          );
        }
      },
    );
  }
}