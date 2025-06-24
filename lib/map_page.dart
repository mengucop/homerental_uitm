import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'listing_detail_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  final LatLng _uitmArau = const LatLng(6.4431, 100.2743);
  LatLng? _currentPosition;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _currentPosition = _uitmArau;
    _loadMarkers();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _goToCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission permanently denied.')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    LatLng pos = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentPosition = pos;
      _addCurrentLocationMarker(pos);
    });

    _mapController.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
  }

  void _addCurrentLocationMarker(LatLng pos) {
    _markers.removeWhere((m) => m.markerId.value == 'currentLocation');
    _markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: pos,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
  }

  Future<void> _loadMarkers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('listings')
        .where('latitude', isNotEqualTo: null)
        .where('longitude', isNotEqualTo: null)
        .get();

    final List<Marker> listingMarkers = snapshot.docs.map((doc) {
      final data = doc.data();
      final LatLng pos = LatLng(
        data['latitude'] ?? 0.0,
        data['longitude'] ?? 0.0,
      );
      return Marker(
        markerId: MarkerId(doc.id),
        position: pos,
        infoWindow: InfoWindow(
          title: data['title'] ?? 'Listing',
          snippet: "RM${data['price'] ?? 'N/A'}",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ListingDetailPage(
                  title: data['title'] ?? '',
                  description: data['description'] ?? '',
                  price: data['price'].toString(),
                  imageUrl: data['imageUrl'] ?? '',
                  latitude: data['latitude'] ?? 6.4431,
                  longitude: data['longitude'] ?? 100.2743,
                  phone: data['phone'] ?? '',
                  email: data['email'] ?? '',
                ),
              ),
            );
          },
        ),
      );
    }).toList();

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('default'),
          position: _uitmArau,
          infoWindow: const InfoWindow(title: 'UiTM Arau'),
        ),
        ...listingMarkers,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map View")),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _uitmArau,
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location),
              tooltip: 'Go to My Location',
            ),
          ),
        ],
      ),
    );
  }
}
