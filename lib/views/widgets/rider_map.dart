import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class RiderMap extends StatefulWidget {
  const RiderMap({super.key});

  @override
  State<RiderMap> createState() => _RiderMapState();
}

class _RiderMapState extends State<RiderMap> {
  GoogleMapController? _mapController;

  LatLng _currentLocation = const LatLng(17.4126, 78.4482);

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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

    _markers.clear();

    _markers.add(
      Marker(
        markerId: const MarkerId("rider"),
        position: _currentLocation,
        infoWindow: const InfoWindow(title: "Your Location"),
      ),
    );

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