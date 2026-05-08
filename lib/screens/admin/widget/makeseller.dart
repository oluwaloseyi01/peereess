import 'dart:async';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/databases/config/appwrite.dart';

class MakeSellerPage extends StatefulWidget {
  const MakeSellerPage({super.key});

  @override
  State<MakeSellerPage> createState() => _MakeSellerPageState();
}

class _MakeSellerPageState extends State<MakeSellerPage> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _lastId;

  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchUsers();

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        fetchUsers(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchUsers({bool loadMore = false}) async {
    if (loadMore && (!_hasMore || _isFetchingMore)) return;

    if (!loadMore) {
      setState(() {
        isLoading = true;
        users.clear();
        _lastId = null;
        _hasMore = true;
      });
    } else {
      setState(() => _isFetchingMore = true);
    }

    try {
      final functions = Functions(AppwriteConfig.client);
      final execution = await functions.createExecution(
        functionId: AppwriteConfig.createUserFunction,
        body: jsonEncode({
          'action': 'getAllUsers',
          'adminSecret': AppwriteConfig.adminPanelSecret,
          'search': searchController.text.trim(),
          if (_lastId != null) 'lastId': _lastId,
        }),
        method: ExecutionMethod.pOST,
      );

      final result = jsonDecode(execution.responseBody) as Map<String, dynamic>;

      if (result['status'] == true) {
        final List<dynamic> data = result['users'] ?? [];
        final newUsers = data.map((e) => Map<String, dynamic>.from(e)).toList();

        setState(() {
          if (loadMore) {
            users.addAll(newUsers);
          } else {
            users = newUsers;
          }
          _hasMore = result['hasMore'] ?? false;
          _lastId = result['lastId'];
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Unauthorized'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching users: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  void filterUsers(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchUsers(); // re-fetches server-side with new search term
    });
  }

  /// Toggle seller/user role — goes through server function
  Future<void> _setRole(String? targetUserId, String role) async {
    if (targetUserId == null || targetUserId.isEmpty) return;

    try {
      final functions = Functions(AppwriteConfig.client);
      final execution = await functions.createExecution(
        functionId: AppwriteConfig.createUserFunction,
        body: jsonEncode({
          'action': 'makeSeller',
          'adminSecret': AppwriteConfig.adminPanelSecret,
          'targetUserId': targetUserId,
          'role': role,
        }),
        method: ExecutionMethod.pOST,
      );

      final result = jsonDecode(execution.responseBody) as Map<String, dynamic>;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Done'),
            backgroundColor:
                result['status'] == true ? Colors.green : Colors.red,
          ),
        );
      }

      if (result['status'] == true) await fetchUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Make a Seller"),
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
      ),
      body: Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // ── Search bar ───────────────────────────────────────────
            TextField(
              controller: searchController,
              onChanged: filterUsers,
              decoration: InputDecoration(
                hintText: "Search users by name...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            10.getHeightWhiteSpacing,

            // ── User list ────────────────────────────────────────────
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                      ? const Center(child: Text("No users found"))
                      : ListView.builder(
                          controller: _scrollCtrl,
                          itemCount: users.length + (_isFetchingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // ── Load more spinner at the bottom ──────────
                            if (index == users.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }

                            final user = users[index];
                            final role = user['role'] ?? 'user';
                            final userId = user['userId'] as String?;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(user['fullName'] ?? "No Name"),
                                subtitle: Text("Role: $role"),
                                trailing: role == 'seller'
                                    ? SizedBox(
                                        width: 120,
                                        height: 36,
                                        child: AppButtons(
                                          text: "Remove Seller",
                                          onPressed: () =>
                                              _setRole(userId, 'user'),
                                        ),
                                      )
                                    : SizedBox(
                                        width: 110,
                                        height: 36,
                                        child: AppButtons(
                                          text: "Make Seller",
                                          onPressed: () =>
                                              _setRole(userId, 'seller'),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
