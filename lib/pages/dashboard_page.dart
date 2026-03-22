import 'package:flutter/material.dart';
import '../app_text_styles.dart';
import 'add_monster_page.dart';
import 'display_rankings_page.dart';
import 'map_page.dart';
import 'catch_monster_page.dart';
import 'edit_monsters_page.dart';
import 'delete_monster_page.dart';
import '../users_page.dart';

class DashboardPage extends StatelessWidget {
  final Map<String, dynamic>? playerData;
  const DashboardPage({super.key, this.playerData});

  void _open(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monster Control Center'),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text("Monster Admin"),
              accountEmail: const Text("monster@app.local"),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.catching_pokemon, size: 32),
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Manage Players"),
              onTap: () {
                Navigator.pop(context);
                _open(context, UsersPage());
              },
            ),
            ExpansionTile(
              leading: const Icon(Icons.edit_note),
              title: const Text("Manage Monsters"),
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text("Add Monster"),
                  onTap: () {
                    Navigator.pop(context);
                    _open(context, const AddMonsterPage());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text("Edit Monsters"),
                  onTap: () {
                    Navigator.pop(context);
                    _open(context, const EditMonstersPage());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text("Delete Monsters"),
                  onTap: () {
                    Navigator.pop(context);
                    _open(context, const DeleteMonsterPage());
                  },
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text("View Top Monster Hunters"),
              onTap: () {
                Navigator.pop(context);
                _open(context, const MonsterListPage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.catching_pokemon),
              title: const Text("Catch Monsters"),
              onTap: () {
                Navigator.pop(context);
                _open(context, CatchMonsterPage(playerId: (playerData?['userid'] as int?) ?? (playerData?['player_id'] as int?) ?? 1));
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Show Monster Map"),
              onTap: () {
                Navigator.pop(context);
                _open(context, const MapPage());
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Header banner ─────────────────────────────────────────────
            Container(
              width: double.infinity,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Monster Control Center",
                    style: TextStyle(
                      fontSize: AppTextStyles.scale(context, 22),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Manage monster records, catch monsters, and view monster areas.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Dashboard grid ────────────────────────────────────────────
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              children: [
                _DashboardCard(
                  icon: Icons.add_circle,
                  label: "Add Monsters",
                  onTap: () => _open(context, const AddMonsterPage()),
                ),
                _DashboardCard(
                  icon: Icons.catching_pokemon,
                  label: "Catch Monsters",
                  onTap: () => _open(context, CatchMonsterPage(playerId: (playerData?['userid'] as int?) ?? (playerData?['player_id'] as int?) ?? 1)),
                ),
                _DashboardCard(
                  icon: Icons.edit,
                  label: "Edit Monsters",
                  onTap: () => _open(context, const EditMonstersPage()),
                ),
                _DashboardCard(
                  icon: Icons.delete_forever,
                  label: "Delete Monsters",
                  onTap: () => _open(context, const DeleteMonsterPage()),
                ),
                _DashboardCard(
                  icon: Icons.list_alt,
                  label: "View Top Monster Hunters",
                  onTap: () => _open(context, const MonsterListPage()),
                ),
                _DashboardCard(
                  icon: Icons.map,
                  label: "Show Monster Map",
                  onTap: () => _open(context, const MapPage()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Card widget ────────────────────────────────────────────────────
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppTextStyles.scale(context, 42),
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTextStyles.scale(context, 15),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
