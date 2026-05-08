import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/model/chatlist.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/chatlistprovider.dart';
import 'package:peereess/provider/product_provider.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class Chat extends StatefulWidget {
  final String userId;
  final String role;

  const Chat({super.key, required this.userId, this.role = 'user'});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with WidgetsBindingObserver {
  Timer? _refreshTimer;

  bool get _isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() {
      context.read<ChatListProvider>().init(widget.userId, admin: _isAdmin);
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        context.read<ChatListProvider>().fetchChats(
              widget.userId,
              isAdmin: _isAdmin,
            );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        context.read<ChatListProvider>().fetchChats(
              widget.userId,
              isAdmin: _isAdmin,
            );
      }
      _refreshTimer ??= Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) {
          context.read<ChatListProvider>().fetchChats(
                widget.userId,
                isAdmin: _isAdmin,
              );
        }
      });
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatListProvider = context.watch<ChatListProvider>();
    final chatList = chatListProvider.chatList;
    final isLoading = chatListProvider.isLoading;
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isConnected) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(child: LogoLoadingIndicator()),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── PINNED HEADER (never scrolls) ───────────────────
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 0, right: 12),
                child: Row(
                  children: [
                    Text(
                      _isAdmin ? "Customer Messages" : "Messages",
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (!_isAdmin)
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, "/save"),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.fromARGB(255, 236, 216, 191),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.favorite_outline,
                                  size: 18,
                                  color: Color(0xff9D6E2D),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Consumer<ProductProvider>(
                                builder: (context, provider, _) {
                                  final userId = authProvider.userId;
                                  if (userId == null) return const SizedBox();
                                  final hasLikes =
                                      provider.likedProductIds.isNotEmpty;
                                  if (!hasLikes) return const SizedBox();
                                  return Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.pink,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 8,
                                      minHeight: 8,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // ── SCROLLABLE BODY (search bar + chat list scroll under header) ──
              Expanded(
                child: chatList.isEmpty
                    ? isLoading
                        ? const Center(child: LogoLoadingIndicator())
                        : _buildEmptyState()
                    : RefreshIndicator(
                        color: const Color(0xff9D6E2D),
                        backgroundColor: const Color.fromARGB(
                          255,
                          236,
                          216,
                          191,
                        ),
                        onRefresh: () async {
                          await context.read<ChatListProvider>().fetchChats(
                                widget.userId,
                                isAdmin: _isAdmin,
                              );
                        },
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            // ── Search bar (scrolls) ─────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: SizedBox(
                                height: 38,
                                child: TextField(
                                  onChanged: (value) {
                                    chatListProvider.searchChats(value);
                                  },
                                  decoration: InputDecoration(
                                    hintText: _isAdmin
                                        ? "Search by customer or product"
                                        : "Search chats",
                                    hintStyle: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    prefixIcon: const Icon(
                                      IconsaxPlusLinear.search_normal_1,
                                      color: Color(0xff9D6E2D),
                                      size: 19,
                                    ),
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                        255, 233, 226, 226),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // ── Chat items ───────────────────────
                            ...List.generate(chatList.length, (index) {
                              final ChatListModel chat = chatList[index];

                              final t = chat.lastMessageAt;
                              final formattedTime =
                                  "${t.day}/${t.month} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  children: [
                                    Slidable(
                                      key: Key(chat.productId),
                                      endActionPane: ActionPane(
                                        motion: const DrawerMotion(),
                                        extentRatio: 0.25,
                                        children: [
                                          SlidableAction(
                                            onPressed: (_) async {
                                              final confirmed =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  title: const Text(
                                                    "Delete Chat",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF6B4A1B),
                                                    ),
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.delete_outline,
                                                        size: 52,
                                                        color: Colors
                                                            .brown.shade200,
                                                      ),
                                                      const SizedBox(
                                                          height: 12),
                                                      Text(
                                                        "Are you sure you want to delete this chat?",
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors
                                                              .brown.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child: const Text(
                                                        "Cancel",
                                                        style: TextStyle(
                                                          color:
                                                              Color(0xff9D6E2D),
                                                        ),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: const Text(
                                                        "Delete",
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirmed ?? false) {
                                                chatListProvider.deleteChat(
                                                  chat.productId,
                                                  widget.userId,
                                                );
                                              }
                                            },
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            icon: IconsaxPlusLinear.trash,
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        elevation: 2,
                                        borderRadius: BorderRadius.circular(8),
                                        color: const Color.fromARGB(
                                            255, 233, 226, 226),
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              "/chat",
                                              arguments: {
                                                "productId": chat.productId,
                                                "productTitle":
                                                    chat.productTitle,
                                                "userId": widget.userId,
                                                "imageUrl": chat.imageUrl,
                                                "firstVariantPrice":
                                                    chat.firstVariantPrice,
                                                "role": widget.role,
                                                "buyerId": chat.senderId,
                                                "buyerName": chat.senderName,
                                              },
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 22,
                                                  backgroundColor:
                                                      Colors.grey.shade300,
                                                  child: chat.imageUrl != null
                                                      ? ClipOval(
                                                          child:
                                                              CachedNetworkImage(
                                                            imageUrl:
                                                                chat.imageUrl!,
                                                            width: 44,
                                                            height: 44,
                                                            fit: BoxFit.cover,
                                                            placeholder:
                                                                (context,
                                                                        url) =>
                                                                    Container(
                                                              color: Colors.grey
                                                                  .shade300,
                                                            ),
                                                            errorWidget:
                                                                (context, url,
                                                                        error) =>
                                                                    const Icon(
                                                              Icons.store,
                                                              size: 20,
                                                            ),
                                                          ),
                                                        )
                                                      : const Icon(
                                                          Icons.store,
                                                          size: 20,
                                                        ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              _isAdmin &&
                                                                      chat.senderName !=
                                                                          null
                                                                  ? '${chat.senderName} • ${chat.productTitle}'
                                                                  : chat
                                                                      .productTitle,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            formattedTime,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 10,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      if (_isAdmin)
                                                        Text(
                                                          chat.productTitle,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors
                                                                .brown.shade400,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      Text(
                                                        chat.lastMessage,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors
                                                              .grey.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (chat.unreadCount > 0)
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            left: 8),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 7,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(
                                                      chat.unreadCount
                                                          .toString(),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IconsaxPlusLinear.message, size: 40, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No messages yet",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
