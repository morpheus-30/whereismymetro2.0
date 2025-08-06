import 'package:WhereIsMyMetro/services/metro_data_service.dart';
import 'package:flutter/material.dart';

class MetroRouteFinder extends StatefulWidget {
  String? startStation;
  String? endStation;
  final List<String> stationNames; // Pass from CSV

  MetroRouteFinder({
    required this.stationNames,
    required this.startStation,
    required this.endStation,
    super.key,
  });

  @override
  State<MetroRouteFinder> createState() => _MetroRouteFinderState();
}

class _MetroRouteFinderState extends State<MetroRouteFinder> {
  List<String> _route = [];

  void _findRoute() async {
    if (widget.startStation == null || widget.endStation == null) return;

    final path = await findIntermediateStations(
      widget.startStation!,
      widget.endStation!,
    );
    setState(() {
      _route = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Delhi Metro Route")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text("Select Starting Station"),
              value: widget.startStation,
              items:
                  widget.stationNames.map((station) {
                    return DropdownMenuItem(
                      value: station,
                      child: Text(station),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => widget.startStation = val),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text("Select Destination Station"),
              value: widget.endStation,
              items:
                  widget.stationNames.map((station) {
                    return DropdownMenuItem(
                      value: station,
                      child: Text(station),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => widget.endStation = val),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _findRoute,
              child: const Text("Get Route"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  _route.isNotEmpty
                      ? ListView.builder(
                        itemCount: _route.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(child: Text("${index + 1}")),
                            title: Text(_route[index]),
                          );
                        },
                      )
                      : const Text("No route yet."),
            ),
          ],
        ),
      ),
    );
  }
}
