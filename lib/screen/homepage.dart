import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late GoogleMapController mapController;
  late DatabaseReference _carsRef;
  Set<Marker> _markers = Set<Marker>();

  @override
  void initState() {
    super.initState();
    _carsRef = FirebaseDatabase.instance.reference().child('cars');

    // Simulate locations for 3 cars and periodically update them
    for (int i = 0; i < 3; i++) {
      final lat = 22.7196 + 0.01 * (i + 1); // Different starting latitudes
      final lng = 75.8577 - 0.01 * (i + 1); // Different starting longitudes
      final carLocation = LatLng(lat, lng);

      _carsRef.child('car$i').set({
        'lat': lat,
        'lng': lng,
      });

      _markers.add(Marker(
        markerId: MarkerId('car$i'),
        position: carLocation,
      ));
    }

    // Periodically update car locations (every 10 seconds)
    Timer.periodic(Duration(seconds: 10), (timer) {
      _updateCarLocations();
    });
  }

  void _updateCarLocations() {
    // Update car locations and push to Firebase Realtime Database
    _markers.forEach((marker) {
      final newLat = marker.position.latitude +
          0.001 * (1 - 2 * (0.5 - Random().nextDouble()));
      final newLng = marker.position.longitude +
          0.001 * (1 - 2 * (0.5 - Random().nextDouble()));
      final newLocation = LatLng(newLat, newLng);

      _carsRef.child(marker.markerId.value).set({
        'lat': newLocation.latitude,
        'lng': newLocation.longitude,
      });

      setState(() {
        _markers.remove(marker);
        _markers.add(Marker(
          markerId: marker.markerId,
          position: newLocation,
        ));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Google Maps Example"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                setState(() {
                  mapController = controller;
                });
              },
              markers: _markers,
              initialCameraPosition: CameraPosition(
                target: LatLng(22.7196, 75.8577), // Initial map location
                zoom: 12.0, // Zoom level
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your action here, e.g., move the camera to a new location.
          _updateCarLocations();
        },
        child: Icon(Icons.location_searching),
      ),
    );
  }
}
