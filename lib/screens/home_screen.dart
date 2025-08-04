import 'dart:async'; // Import for StreamSubscription
import 'package:WhereIsMyMetro/background_handler.dart';
import 'package:WhereIsMyMetro/services/metro_data_service.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
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
  Station? _selectedStartingStation;
  Station? _selectedEndingStation;
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
  appBar: AppBar(
    title: const Text('Delhi Metro Navigator'),
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  ),
  body: Padding(
    padding: const EdgeInsets.all(20.0),
    child: FutureBuilder<List<Station>>(
      future: _stationsFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<Station>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading stations: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No station data available.'),
          );
        } else {
          final List<Station> stations = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 30),
                const Text(
                  "From",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: DropdownSearch<Station>(
                    dropdownBuilder: (context, selectedItem) => Text(
                      selectedItem != null ? selectedItem.name : 'Select',
                      style: const TextStyle(fontSize: 15),
                    ),
                    itemAsString: (s) => s.name,
                    selectedItem: _selectedStartingStation,
                    items: (f, cs) => stations,
                    compareFn: (s1, s2) => s1.name == s2.name,
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      fit: FlexFit.loose,
                    ),
                    onChanged: (value) {
                      _selectedStartingStation = value;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "To",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: DropdownSearch<Station>(
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration.collapsed(hintText: ''),
                    ),
                    dropdownBuilder: (context, selectedItem) => Text(
                      selectedItem != null ? selectedItem.name : 'Select',
                      style: const TextStyle(fontSize: 15),
                    ),
                    items: (f, cs) => stations,
                    itemAsString: (s) => s.name,
                    compareFn: (s1, s2) => s1.name == s2.name,
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      fit: FlexFit.loose,
                    ),
                    onChanged: (value) {
                      _selectedEndingStation = value;
                    },
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_selectedStartingStation != null &&
                            _selectedEndingStation != null &&
                            _selectedEndingStation != _selectedStartingStation)
                        ? () async {
                            print('Starting Station: $_selectedStartingStation');
                            print('Ending Station: $_selectedEndingStation');

                            await initBackgroundGeolocation(
                              _selectedEndingStation!.latitude,
                              _selectedEndingStation!.longitude,
                            );

                            final List<String> intermediateStations =
                                await findIntermediateStations(
                              _selectedStartingStation!.name,
                              _selectedEndingStation!.name,
                            );
                            print(intermediateStations);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Alarm tracking started. You’ll be alerted within 1 km of ${_selectedEndingStation!.name}.',
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blueAccent,
                      disabledBackgroundColor: Colors.grey.shade300,
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('Plan Journey'),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: _nearestStation != null
                      ? Text(
                          "📍 Nearest Station: ${_nearestStation!.name}",
                          style: const TextStyle(fontSize: 16),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text("Finding nearest station..."),
                          ],
                        ),
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
