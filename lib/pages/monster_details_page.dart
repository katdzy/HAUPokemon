// monster_details_page.dart – stub for future use
import 'package:flutter/material.dart';
import '../models/monster_model.dart';

class MonsterDetailsPage extends StatelessWidget {
  final Monster monster;

  const MonsterDetailsPage({super.key, required this.monster});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(monster.monsterName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (monster.pictureUrl != null && monster.pictureUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  monster.pictureUrl!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text("Name: ${monster.monsterName}",
                style: const TextStyle(fontSize: 18)),
            Text("Type: ${monster.monsterType}"),
            Text(
                "Latitude: ${monster.spawnLatitude.toStringAsFixed(7)}"),
            Text(
                "Longitude: ${monster.spawnLongitude.toStringAsFixed(7)}"),
            Text(
                "Radius: ${monster.spawnRadiusMeters.toStringAsFixed(2)} meters"),
          ],
        ),
      ),
    );
  }
}
