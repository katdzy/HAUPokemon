// map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/monster_model.dart';
import '../services/api_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late Future<List<Monster>> _monstersFuture;

  @override
  void initState() {
    super.initState();
    _monstersFuture = ApiService.getMonsters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monster Map")),
      body: FutureBuilder<List<Monster>>(
        future: _monstersFuture,
        builder: (context, snapshot) {
          final monsters = snapshot.data ?? [];

          return FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(15.144985, 120.588702),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.example.haumonsters",
              ),
              CircleLayer(
                circles: monsters
                    .map(
                      (m) => CircleMarker(
                        point: LatLng(m.spawnLatitude, m.spawnLongitude),
                        radius: m.spawnRadiusMeters,
                        useRadiusInMeter: true,
                        color: Colors.red.withOpacity(0.2),
                        borderStrokeWidth: 2,
                        borderColor: Colors.red,
                      ),
                    )
                    .toList(),
              ),
              MarkerLayer(
                markers: monsters
                    .map(
                      (m) => Marker(
                        point: LatLng(m.spawnLatitude, m.spawnLongitude),
                        width: 50,
                        height: 50,
                        child: Tooltip(
                          message: m.monsterName,
                          child: const Icon(
                            Icons.location_pin,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
