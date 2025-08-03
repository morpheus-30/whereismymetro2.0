import 'package:location/location.dart';

Future<LocationData?> getCurrentLocation() async {
  Location location = Location();

  bool serviceEnabled;
  PermissionStatus permissionGranted;

  // Check if location services are enabled
  serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return null;
    }
  }

  // Check for permissions
  permissionGranted = await location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await location.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      print('Location permission denied.');
      return null;
    }
  }

  // Get current location
  return await location.getLocation();
}
