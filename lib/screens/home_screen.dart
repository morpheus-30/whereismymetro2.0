import 'dart:async'; // Import for StreamSubscription
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:myapp/services/location_service.dart'; // Assuming this handles permissions
import 'package:myapp/services/metro_data_service.dart';
import 'package:dropdown_search/dropdown_search.dart';

// Assuming you have a Station class like this from your services
// class Station {
//   final String name;
//   final double latitude;
//   final double longitude;
//   Station({required this.name, required this.latitude, required this.longitude});
// }

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedStartingStation;
  String? _selectedEndingStation;
  Station? _nearestStation;

  // For managing the location stream
  final Location location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  Future<List<Station>>? _stationsFuture;
  final MetroDataService _metroDataService = MetroDataService();

  @override
  void initState() {
    super.initState();
    // Load station list once
    _stationsFuture = _metroDataService.loadStations();
    // Start listening for location changes
    _listenForLocationChanges();
  }

  /// Subscribes to the location stream and updates the nearest station on new data.
  void _listenForLocationChanges() async {
    // Ensure location services are enabled and permissions are granted
    // You might have this logic in your location_service.dart
    final serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      // Handle service not enabled
      return;
    }

    final permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      // Handle permissions denied
      return;
    }

    // Listen to location changes
    _locationSubscription = location.onLocationChanged.listen((
      LocationData currentLocation,
    ) async {
      print(
        'New Location: Lat: ${currentLocation.latitude}, Long: ${currentLocation.longitude}',
      );

      // Find the nearest station with the new coordinates
      final Map<String, dynamic> result = await _metroDataService
          .getNearestStation(
            currentLocation.latitude ?? 0,
            currentLocation.longitude ?? 0,
          );

      // Update the state only if the widget is still in the tree
      if (mounted) {
        setState(() {
          _nearestStation = result['station'];
          print('New Nearest Station: ${_nearestStation?.name}');
        });
      }
    });
  }

  @override
  void dispose() {
    // IMPORTANT: Cancel the subscription to avoid memory leaks
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Delhi Metro Navigator')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<List<Station>>(
          future: _stationsFuture,
          builder: (
            BuildContext context,
            AsyncSnapshot<List<Station>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error loading stations: ${snapshot.error}'),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No station data available.'));
            } else {
              final List<Station> stations = snapshot.data!;
              final List<String> stationNames =
                  stations.map((s) => s.name).toList();

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    DropdownSearch<String>(
                      items: (f, cs) => stationNames, // Corrected items list
                      popupProps: PopupProps.menu(
                        showSearchBox: true, // Good for long lists
                        fit: FlexFit.loose,
                      ),
                      onChanged: (value) {
                        _selectedStartingStation = value;
                      },
                    ),
                    SizedBox(height: 20),
                    DropdownSearch<String>(
                      items: (f, cs) => stationNames, // Corrected items list
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        fit: FlexFit.loose,
                      ),
                      onChanged: (value) {
                        _selectedEndingStation = value;
                      },
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed:
                          (_selectedStartingStation != null &&
                                  _selectedEndingStation != null)
                              ? () {
                                print(
                                  'Starting Station: $_selectedStartingStation',
                                );
                                print(
                                  'Ending Station: $_selectedEndingStation',
                                );
                              }
                              : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 12.0,
                        ),
                        child: Text('Plan Journey'),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Display the nearest station, which updates automatically
                    if (_nearestStation != null)
                      Text(
                        "📍 Nearest Station: ${_nearestStation!.name}",
                        style: TextStyle(fontSize: 16),
                      )
                    else
                      // Show a placeholder while waiting for the first location update
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text("Finding nearest station..."),
                        ],
                      ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
