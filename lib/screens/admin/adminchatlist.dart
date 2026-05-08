import 'package:flutter/material.dart';
import 'package:peereess/model/adminchatlistmodel.dart';
import 'package:peereess/provider/adminchatlistprovider.dart';
import 'package:peereess/screens/admin/adminchat.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AdminChatListProvider>().fetchAllChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminChatListProvider>();
    final chatList = provider.chatList;
    final isLoading = provider.isLoading;

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
              /// HEADER
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 12, right: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: Color(0xff9D6E2D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "All Chats",
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              /// SEARCH
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    onChanged: (value) => provider.searchChats(value),
                    decoration: InputDecoration(
                      hintText: "Search chats",
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(Icons.search_outlined, size: 19),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 233, 226, 226),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),

              /// CHAT LIST
              Expanded(
                child: chatList.isEmpty
                    ? isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : const Center(child: Text("No active chats"))
                    : RefreshIndicator(
                        onRefresh: () async {
                          await context
                              .read<AdminChatListProvider>()
                              .fetchAllChats();
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: chatList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final AdminChatListModel chat = chatList[index];

                            final t = chat.lastMessageAt;
                            final formattedTime =
                                "${t.day}/${t.month} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

                            return Material(
                              elevation: 2,
                              borderRadius: BorderRadius.circular(8),
                              color: const Color.fromARGB(255, 233, 226, 226),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  // ✅ markChatAsRead removed from here —
                                  // AdminChatScreen handles it in initState
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminChatScreen(
                                        productId: chat.productId,
                                        productTitle: chat.productTitle,
                                        userId: chat.userId,
                                        imageUrl: chat.productImageUrl,
                                        firstVariantPrice:
                                            chat.firstVariantPrice,
                                        userName: chat.userName,
                                      ),
                                    ),
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
                                        backgroundImage:
                                            chat.productImageUrl != null
                                                ? NetworkImage(
                                                    chat.productImageUrl!,
                                                  )
                                                : null,
                                        backgroundColor: Colors.grey.shade300,
                                        child: chat.productImageUrl == null
                                            ? const Icon(Icons.store, size: 20)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    "${chat.userName} · ${chat.productTitle}",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  formattedTime,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              chat.lastMessage,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (chat.unreadCount > 0)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            chat.unreadCount.toString(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
