import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/monster_model.dart';
import '../models/player_ranking_model.dart';

// This is the services/api_service.dart used by add/edit/delete/map monster pages.
// It delegates to the same Supabase client as lib/api_service.dart.

class ApiService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ─── ADD MONSTER ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> addMonster({
    required String monsterName,
    required String monsterType,
    required double spawnLatitude,
    required double spawnLongitude,
    required double spawnRadiusMeters,
    String? pictureUrl,
  }) async {
    try {
      await _db.from('monsterstbl').insert({
        'monster_name': monsterName,
        'monster_type': monsterType,
        'spawn_latitude': spawnLatitude,
        'spawn_longitude': spawnLongitude,
        'spawn_radius_meters': spawnRadiusMeters,
        'picture_url': pictureUrl ?? '',
      });
      return {'success': true, 'message': 'Monster added successfully'};
    } catch (e) {
      debugPrint('addMonster error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── GET MONSTERS ─────────────────────────────────────────────────────────
  static Future<List<Monster>> getMonsters() async {
    try {
      final response = await _db.from('monsterstbl').select();
      return (response as List).map((e) => Monster.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getMonsters error: $e');
      return [];
    }
  }

  // ─── UPDATE MONSTER ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateMonster({
    required int monsterId,
    required String monsterName,
    required String monsterType,
    required double spawnLatitude,
    required double spawnLongitude,
    required double spawnRadiusMeters,
    String? pictureUrl,
  }) async {
    try {
      await _db.from('monsterstbl').update({
        'monster_name': monsterName,
        'monster_type': monsterType,
        'spawn_latitude': spawnLatitude,
        'spawn_longitude': spawnLongitude,
        'spawn_radius_meters': spawnRadiusMeters,
        'picture_url': pictureUrl ?? '',
      }).eq('monster_id', monsterId);
      return {'success': true, 'message': 'Monster updated successfully'};
    } catch (e) {
      debugPrint('updateMonster error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── DELETE MONSTER ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> deleteMonster({
    required int monsterId,
  }) async {
    try {
      await _db.from('monsterstbl').delete().eq('monster_id', monsterId);
      return {'success': true, 'message': 'Monster deleted successfully'};
    } catch (e) {
      debugPrint('deleteMonster error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── UPLOAD IMAGE (Supabase Storage) ──────────────────────────────────────
  static Future<String?> uploadMonsterImage(File imageFile) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last.split('\\').last}';
      await _db.storage.from('monster-images').upload(fileName, imageFile);
      return _db.storage.from('monster-images').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('uploadMonsterImage error: $e');
      return null;
    }
  }

  // ─── GET PLAYER RANKINGS ──────────────────────────────────────────────────
  static Future<List<PlayerRanking>> getPlayerRankings() async {
    try {
      final response = await _db
          .from('monster_catchestbl')
          .select('player_id, playerstbl(player_name)');

      final Map<int, Map<String, dynamic>> counts = {};
      for (final row in response as List) {
        final pid = (row['player_id'] as num).toInt();
        if (!counts.containsKey(pid)) {
          final playerData = row['playerstbl'];
          final playerName = (playerData is Map)
              ? (playerData['player_name']?.toString() ?? 'Unknown')
              : 'Unknown';
          counts[pid] = {
            'player_id': pid,
            'player_name': playerName,
            'catch_count': 0,
          };
        }
        counts[pid]!['catch_count'] =
            (counts[pid]!['catch_count'] as int) + 1;
      }

      final sorted = counts.values.toList()
        ..sort((a, b) =>
            (b['catch_count'] as int).compareTo(a['catch_count'] as int));

      return sorted
          .take(10)
          .map((e) => PlayerRanking.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('getPlayerRankings error: $e');
      return [];
    }
  }

  // ─── LOCATIONS ────────────────────────────────────────────────────────────
  static Future<List> getLocations() async {
    try {
      final response = await _db.from('locationstbl').select();
      return response as List;
    } catch (e) {
      debugPrint('getLocations error: $e');
      return [];
    }
  }
}
