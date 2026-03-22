import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/monster_model.dart';
import 'models/player_ranking_model.dart';

class ApiService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ─── AUTH ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await _db
          .from('playerstbl')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (response != null) {
        return {
          'status': 'success',
          'user': {
            'userid': response['player_id'],
            'player_id': response['player_id'],
            'player_name': response['player_name'],
            'username': response['username'],
          }
        };
      } else {
        return {'status': 'error', 'message': 'Invalid username or password'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ─── PLAYERS (USERS) ───────────────────────────────────────────────────────

  static Future<List> getUsers() async {
    try {
      final response = await _db
          .from('playerstbl')
          .select()
          .order('player_id', ascending: true);
      return (response as List)
          .map((e) => {
                'userid': e['player_id'],
                'player_id': e['player_id'],
                'player_name': e['player_name'],
                'username': e['username'],
              })
          .toList();
    } catch (e) {
      debugPrint('getUsers error: $e');
      return [];
    }
  }

  static Future<bool> createUser(
      String playerName, String username, String password) async {
    try {
      await _db.from('playerstbl').insert({
        'player_name': playerName,
        'username': username,
        'password': password,
      });
      return true;
    } catch (e) {
      debugPrint('createUser error: $e');
      return false;
    }
  }

  static Future<bool> updateUser(int id, String username) async {
    try {
      await _db
          .from('playerstbl')
          .update({'username': username})
          .eq('player_id', id);
      return true;
    } catch (e) {
      debugPrint('updateUser error: $e');
      return false;
    }
  }

  static Future<bool> deleteUser(int id) async {
    try {
      await _db.from('playerstbl').delete().eq('player_id', id);
      return true;
    } catch (e) {
      debugPrint('deleteUser error: $e');
      return false;
    }
  }

  // ─── MONSTERS ─────────────────────────────────────────────────────────────

  static Future<List<Monster>> getMonsters() async {
    try {
      final response = await _db.from('monsterstbl').select();
      return (response as List).map((e) => Monster.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getMonsters error: $e');
      return [];
    }
  }

  static Future<bool> createMonster(Monster monster) async {
    try {
      final data = monster.toJson()..remove('monster_id');
      await _db.from('monsterstbl').insert(data);
      return true;
    } catch (e) {
      debugPrint('createMonster error: $e');
      return false;
    }
  }

  static Future<bool> updateMonster(Monster monster) async {
    try {
      final data = monster.toJson()..remove('monster_id');
      await _db
          .from('monsterstbl')
          .update(data)
          .eq('monster_id', monster.monsterId);
      return true;
    } catch (e) {
      debugPrint('updateMonster error: $e');
      return false;
    }
  }

  static Future<bool> deleteMonster(int monsterId) async {
    try {
      await _db
          .from('monsterstbl')
          .delete()
          .eq('monster_id', monsterId);
      return true;
    } catch (e) {
      debugPrint('deleteMonster error: $e');
      return false;
    }
  }

  // ─── IMAGE UPLOAD (Supabase Storage) ──────────────────────────────────────

  static Future<String?> uploadMonsterImage(File imageFile) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last.split('\\').last}';
      await _db.storage.from('monster-images').upload(fileName, imageFile);
      final publicUrl =
          _db.storage.from('monster-images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('uploadMonsterImage error: $e');
      return null;
    }
  }

  // ─── CATCH MONSTERS ───────────────────────────────────────────────────────

  static Future<bool> catchMonster({
    required int playerId,
    required int monsterId,
    required int locationId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _db.from('monster_catchestbl').insert({
        'player_id': playerId,
        'monster_id': monsterId,
        'location_id': locationId,
        'latitude': latitude,
        'longitude': longitude,
      });
      return true;
    } catch (e) {
      debugPrint('catchMonster error: $e');
      return false;
    }
  }

  static Future<List> getCaughtMonsters(int playerId) async {
    try {
      final response = await _db
          .from('monster_catchestbl')
          .select()
          .eq('player_id', playerId);
      return response as List;
    } catch (e) {
      debugPrint('getCaughtMonsters error: $e');
      return [];
    }
  }

  static Future<Set<int>> getCaughtMonsterIds() async {
    try {
      final response = await _db.from('monster_catchestbl').select('monster_id');
      return (response as List).map((e) => (e['monster_id'] as num).toInt()).toSet();
    } catch (e) {
      debugPrint('getCaughtMonsterIds error: $e');
      return {};
    }
  }

  // ─── TOP HUNTERS (LEADERBOARD) ────────────────────────────────────────────

  static Future<List<PlayerRanking>> getTopHunters() async {
    try {
      // Fetch all catches with player info via foreign key join
      final response = await _db
          .from('monster_catchestbl')
          .select('player_id, playerstbl(player_name)');

      // Aggregate catch counts per player in Dart
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

      return sorted.take(10).map((e) => PlayerRanking.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getTopHunters error: $e');
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