import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:torch_light/torch_light.dart';
import '../api_service.dart';
import '../models/monster_model.dart';

class CatchMonsterPage extends StatefulWidget {
  final int playerId;
  const CatchMonsterPage({super.key, required this.playerId});

  @override
  State<CatchMonsterPage> createState() => _CatchMonsterPageState();
}

class _CatchMonsterPageState extends State<CatchMonsterPage>
    with TickerProviderStateMixin {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  bool _isDetecting = false;
  String _statusMessage = 'Tap "Catch Monsters" to scan for nearby monsters.';
  Monster? _detectedMonster;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Animation for the radar pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Location permission ────────────────────────────────────────────────────
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location services are disabled. Please enable them.')));
      }
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions denied')));
        }
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permissions permanently denied.')));
      }
      return false;
    }
    return true;
  }

  // ── Main detect + catch flow ───────────────────────────────────────────────
  Future<void> _catchMonsters() async {
    double? inputLat = double.tryParse(_latController.text);
    double? inputLng = double.tryParse(_lngController.text);

    if (inputLat == null || inputLng == null) {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;

      setState(() {
        _isDetecting = true;
        _detectedMonster = null;
        _statusMessage = 'Fetching your current location...';
      });
      _pulseController.repeat(reverse: true);

      try {
        final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        inputLat = position.latitude;
        inputLng = position.longitude;
        
        setState(() {
          _latController.text = inputLat!.toString();
          _lngController.text = inputLng!.toString();
        });
      } catch (e) {
        setState(() {
          _statusMessage = 'Error getting location: $e';
          _isDetecting = false;
        });
        _pulseController.stop();
        _pulseController.reset();
        return;
      }
    } else {
      setState(() {
        _isDetecting = true;
        _detectedMonster = null;
        _statusMessage = 'Scanning at entered coordinates...';
      });
      _pulseController.repeat(reverse: true);
    }

    try {
      final monsters = await ApiService.getMonsters();
      Monster? nearbyMonster;
      double closestDistance = double.infinity;

      for (var monster in monsters) {
        double distance = Geolocator.distanceBetween(
          inputLat!,
          inputLng!,
          monster.spawnLatitude,
          monster.spawnLongitude,
        );
        
        bool isExactMatch = (inputLat == monster.spawnLatitude && inputLng == monster.spawnLongitude);
        
        if (isExactMatch || distance <= monster.spawnRadiusMeters) {
          if (distance < closestDistance) {
            closestDistance = distance;
            nearbyMonster = monster;
          }
        }
      }

      if (nearbyMonster != null) {
        setState(() {
          _detectedMonster = nearbyMonster;
          _statusMessage =
              '⚠️ Monster detected!\n${nearbyMonster!.monsterName} (${nearbyMonster.monsterType})\n${closestDistance.toStringAsFixed(1)} m away';
        });
        await _catchSequence(nearbyMonster, inputLat!, inputLng!);
      } else {
        setState(() {
          _statusMessage = 'No monsters nearby.\nKeep exploring!';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      _pulseController.stop();
      _pulseController.reset();
      setState(() => _isDetecting = false);
    }
  }

  // ── Catch sequence: alarm + torch + API log ────────────────────────────────
  Future<void> _catchSequence(Monster monster, double lat, double lng) async {
    // Sound alarm
    try {
      await _audioPlayer.play(AssetSource('sounds/monster_alarm.wav'));
    } catch (e) {
      debugPrint('Could not play audio: $e');
    }

    // Flash torch for 5 seconds
    try {
      final isTorchAvailable = await TorchLight.isTorchAvailable();
      if (isTorchAvailable) {
        await TorchLight.enableTorch();
        Timer(const Duration(seconds: 5), () async {
          try {
            await TorchLight.disableTorch();
          } catch (_) {}
        });
      }
    } catch (e) {
      debugPrint('Could not enable torch: $e');
    }

    // Log to API
    try {
      final success = await ApiService.catchMonster(
        playerId: widget.playerId,
        monsterId: monster.monsterId,
        locationId: 1,
        latitude: lat,
        longitude: lng,
      );

      if (!mounted) return;
      if (success) {
        _showCaughtDialog(monster);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Detected ${monster.monsterName} but failed to record catch.')),
        );
      }
    } catch (e) {
      debugPrint('Could not log catch to API: $e');
    }
  }

  // ── Caught dialog ──────────────────────────────────────────────────────────
  void _showCaughtDialog(Monster monster) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.catching_pokemon, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Monster Caught!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (monster.pictureUrl != null &&
                monster.pictureUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  monster.pictureUrl!,
                  height: 120,
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
            const SizedBox(height: 12),
            Text(
              monster.monsterName,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              monster.monsterType,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool monsterFound = _detectedMonster != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catch Monsters'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isDetecting ? null : _catchMonsters,
            tooltip: 'Scan again',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── GPS coordinates ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Latitude',
                      hintText: 'e.g. 37.77',
                      prefixIcon: const Icon(Icons.gps_fixed),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Longitude',
                      hintText: 'e.g. -122.41',
                      prefixIcon: const Icon(Icons.gps_fixed),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Radar animation ──────────────────────────────────────────────
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isDetecting ? _pulseAnimation.value : 1.0,
                    child: child,
                  );
                },
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: monsterFound
                        ? Colors.red.withAlpha(30)
                        : colorScheme.primaryContainer.withAlpha(120),
                    border: Border.all(
                      color: monsterFound
                          ? Colors.red
                          : colorScheme.primary,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    monsterFound
                        ? Icons.catching_pokemon
                        : Icons.radar,
                    size: 80,
                    color: monsterFound
                        ? Colors.red
                        : colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Catch Monsters button ────────────────────────────────────────
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isDetecting ? null : _catchMonsters,
                icon: _isDetecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.catching_pokemon, size: 28),
                label: Text(
                  _isDetecting ? 'Scanning...' : 'Catch Monsters',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      monsterFound ? Colors.red : colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Status card ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: monsterFound
                    ? Colors.red.withAlpha(20)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: monsterFound
                    ? Border.all(color: Colors.red, width: 1.5)
                    : null,
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: monsterFound ? Colors.red[800] : null,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Info note ────────────────────────────────────────────────────
            const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'When a monster is detected, your phone will sound an alarm and flash the torch for 5 seconds.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

