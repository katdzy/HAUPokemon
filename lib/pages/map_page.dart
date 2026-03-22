// map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/monster_model.dart';
import '../api_service.dart';
import '../app_text_styles.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late Future<List<Monster>> _monstersFuture;
  late Future<Set<int>> _caughtIdsFuture;

  @override
  void initState() {
    super.initState();
    _monstersFuture = ApiService.getMonsters();
    _caughtIdsFuture = ApiService.getCaughtMonsterIds();
  }

  void _showMonsterDetails(Monster m) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (m.pictureUrl != null && m.pictureUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    m.pictureUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.catching_pokemon,
                      size: 80,
                      color: Colors.red,
                    ),
                  ),
                )
              else
                const Icon(Icons.catching_pokemon, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                m.monsterName,
                style: TextStyle(fontSize: AppTextStyles.scale(context, 22), fontWeight: FontWeight.bold),
              ),
              Text(
                m.monsterType,
                style: TextStyle(fontSize: AppTextStyles.scale(context, 16), color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Latitude:'),
                  Text(m.spawnLatitude.toStringAsFixed(6)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Longitude:'),
                  Text(m.spawnLongitude.toStringAsFixed(6)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Spawn Radius:'),
                  Text('${m.spawnRadiusMeters.toStringAsFixed(1)} m'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monster Map")),
      body: FutureBuilder(
        future: Future.wait([
          _monstersFuture,
          _caughtIdsFuture,
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allMonsters = (snapshot.data?[0] as List<Monster>?) ?? [];
          final caughtIds = (snapshot.data?[1] as Set<int>?) ?? {};

          // Overwrite the rendering list with only UNCAUGHT monsters
          final monsters = allMonsters.where((m) => !caughtIds.contains(m.monsterId)).toList();

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
                        child: GestureDetector(
                          onTap: () => _showMonsterDetails(m),
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
