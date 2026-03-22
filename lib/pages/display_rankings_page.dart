// display_rankings_page.dart
import 'package:flutter/material.dart';
import '../app_text_styles.dart';
import '../models/player_ranking_model.dart';
import '../api_service.dart';

// NOTE: The dashboard references this as MonsterListPage
class MonsterListPage extends StatefulWidget {
  const MonsterListPage({super.key});

  @override
  State<MonsterListPage> createState() => _MonsterListPageState();
}

class _MonsterListPageState extends State<MonsterListPage> {
  late Future<List<PlayerRanking>> _rankingsFuture;

  @override
  void initState() {
    super.initState();
    _rankingsFuture = ApiService.getTopHunters();
  }

  void _refresh() {
    setState(() {
      _rankingsFuture = ApiService.getTopHunters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<PlayerRanking>>(
        future: _rankingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: AppTextStyles.scale(context, 60), color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final rankings = (snapshot.data ?? []).take(10).toList();

          if (rankings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: AppTextStyles.scale(context, 72), color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No rankings yet.\nBe the first to catch a monster!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: AppTextStyles.scale(context, 16), color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // ── Trophy header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events, size: AppTextStyles.scale(context, 50), color: Colors.amber),
                    const SizedBox(height: 8),
                    Text(
                      'Top Monster Hunters',
                      style: TextStyle(
                          fontSize: AppTextStyles.scale(context, 22), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Top 10 players with the most captures',
                        style: TextStyle(fontSize: AppTextStyles.scale(context, 13))),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Rankings list ──────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: rankings.length,
                  itemBuilder: (context, index) {
                    final rank = rankings[index];
                    final rankNum = index + 1;
                    return _RankingCard(rank: rank, rankNum: rankNum);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Individual Ranking Card ──────────────────────────────────────────────────
class _RankingCard extends StatelessWidget {
  final PlayerRanking rank;
  final int rankNum;

  const _RankingCard({required this.rank, required this.rankNum});

  Color get _medalColor {
    switch (rankNum) {
      case 1:
        return const Color(0xFFFFD700); // gold
      case 2:
        return const Color(0xFFC0C0C0); // silver
      case 3:
        return const Color(0xFFCD7F32); // bronze
      default:
        return Colors.blueGrey.shade300;
    }
  }

  IconData get _medalIcon {
    switch (rankNum) {
      case 1:
      case 2:
      case 3:
        return Icons.emoji_events;
      default:
        return Icons.catching_pokemon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTopThree = rankNum <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isTopThree
            ? _medalColor.withAlpha(30)
            : colorScheme.surfaceContainerHighest,
        border: isTopThree
            ? Border.all(color: _medalColor, width: 1.5)
            : null,
        boxShadow: isTopThree
            ? [
                BoxShadow(
                    color: _medalColor.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]
            : null,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: _medalColor.withAlpha(isTopThree ? 80 : 40),
              child: Icon(_medalIcon, color: _medalColor, size: 22),
            ),
            // Rank number badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _medalColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '$rankNum',
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          rank.playerName,
          style: TextStyle(
            fontWeight:
                isTopThree ? FontWeight.bold : FontWeight.w500,
            fontSize: AppTextStyles.scale(context, isTopThree ? 16 : 15),
          ),
        ),
        subtitle: Text('Player ID: ${rank.playerId}',
            style: TextStyle(fontSize: AppTextStyles.scale(context, 12))),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${rank.catchCount}',
              style: TextStyle(
                fontSize: AppTextStyles.scale(context, 22),
                fontWeight: FontWeight.bold,
                color: isTopThree ? _medalColor : colorScheme.primary,
              ),
            ),
            Text('catches',
                style: TextStyle(fontSize: AppTextStyles.scale(context, 11), color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
