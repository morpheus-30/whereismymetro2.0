import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/services/metro_data_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dropdown_search/dropdown_search.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedStartingStation;
  String? _selectedEndingStation;
  Station? _nearestStation;
  double? userLat;
  double? userlong;

  Future<List<Station>>? _stationsFuture;

  @override
  void initState() {
    super.initState();
    _stationsFuture = _loadStations();
    getNearestStation();
  }

  Future<List<Station>> _loadStations() async {
    final MetroDataService metroDataService = MetroDataService();
    return metroDataService.loadStations();
  }

  Future<void> getNearestStation() async {
    final MetroDataService metroDataService = MetroDataService();
    LocationData? userLocation = await getCurrentLocation();
    if (userLocation != null) {
      print(
        'Latitude: ${userLocation.latitude}, Longitude: ${userLocation.longitude}',
      );
      final Map<String, dynamic> result = await metroDataService
          .getNearestStation(
            userLocation.latitude ?? 0,
            userLocation.longitude ?? 0,
          );
      setState(() {
        _nearestStation = result['station'];
        print('Nearest Station: ${_nearestStation!.name}');
      });
    }
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
              return Center(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center the column vertically
                  children: <Widget>[
                    DropdownSearch<String>(
                      items: (f, cs) => stations.map((s) => s.name).toList(),
                      popupProps: PopupProps.menu(fit: FlexFit.loose),
                      onChanged: (value) {
                        _selectedStartingStation = value;
                      },
                    ),
                    SizedBox(height: 20),
                    DropdownSearch<String>(
                      items: (f, cs) => stations.map((s) => s.name).toList(),
                      popupProps: PopupProps.menu(fit: FlexFit.loose),
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
                                // TODO: Implement journey planning logic
                                print(
                                  'Starting Station: $_selectedStartingStation',
                                );
                                print(
                                  'Ending Station: $_selectedEndingStation',
                                );
                              }
                              : null, // Disable button if stations are not selected
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 12.0,
                        ),
                        child: Text('Plan Journey'),
                      ),
                    ),
                    _nearestStation != null
                        ? Text("Nearest Station: ${_nearestStation!.name}")
                        : SizedBox(),
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
