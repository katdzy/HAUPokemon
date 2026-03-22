import 'package:flutter/material.dart';
import 'api_service.dart';
import 'app_text_styles.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List users = [];
  bool isLoading = true;

  final TextEditingController _playerNameCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _playerNameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────
  void _fetchUsers() async {
    setState(() => isLoading = true);
    final result = await ApiService.getUsers();
    setState(() {
      users = result;
      isLoading = false;
    });
  }

  // ── Add ────────────────────────────────────────────────────────────────────
  Future<void> _addUser() async {
    final playerName = _playerNameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (playerName.isEmpty || username.isEmpty || password.isEmpty) return;

    final success =
        await ApiService.createUser(playerName, username, password);
    if (!mounted) return;
    if (success) {
      _clearControllers();
      _fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Player added successfully'),
            backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to create player'),
            backgroundColor: Colors.red),
      );
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  Future<void> _updateUser(int id) async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) return;

    final success = await ApiService.updateUser(id, username);
    if (!mounted) return;
    if (success) {
      _clearControllers();
      _fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Player updated'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update player'),
            backgroundColor: Colors.red),
      );
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _deleteUser(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete player "$name"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await ApiService.deleteUser(id);
    if (!mounted) return;
    if (success) {
      _fetchUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to delete player'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _clearControllers() {
    _playerNameCtrl.clear();
    _usernameCtrl.clear();
    _passwordCtrl.clear();
  }

  // ── Dialog ─────────────────────────────────────────────────────────────────
  void _showDialog({int? id, String? currentPlayerName, String? currentUsername}) {
    if (currentPlayerName != null) _playerNameCtrl.text = currentPlayerName;
    if (currentUsername != null) _usernameCtrl.text = currentUsername;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          id == null ? 'Add Player' : 'Edit Player',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Player Name – only shown when adding
              if (id == null)
                TextField(
                  controller: _playerNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name / Player Name',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                ),
              if (id == null) const SizedBox(height: 12),
              TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              if (id == null) const SizedBox(height: 12),
              if (id == null)
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearControllers();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (id == null) {
                _addUser();
              } else {
                _updateUser(id);
              }
            },
            child: Text(id == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Players'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Player'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(
                  child: Text('No players found.',
                      style: TextStyle(fontSize: AppTextStyles.scale(context, 16), color: Colors.grey)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final id = user['userid'] ??
                        user['player_id'] ??
                        user['id'] ??
                        0;
                    final playerName = user['player_name'] ??
                        user['name'] ??
                        '';
                    final username = user['username'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          (playerName.isNotEmpty
                                  ? playerName[0]
                                  : username.isNotEmpty
                                      ? username[0]
                                      : '?')
                              .toUpperCase(),
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        playerName.isNotEmpty ? playerName : username,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('@$username'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueGrey),
                            tooltip: 'Edit',
                            onPressed: () => _showDialog(
                              id: id is int ? id : int.tryParse(id.toString()) ?? 0,
                              currentPlayerName: playerName,
                              currentUsername: username,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            tooltip: 'Delete',
                            onPressed: () => _deleteUser(
                              id is int ? id : int.tryParse(id.toString()) ?? 0,
                              playerName.isNotEmpty ? playerName : username,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}