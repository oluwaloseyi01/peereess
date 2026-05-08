import 'package:flutter/material.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/supportchat_provider.dart';
import 'package:peereess/model/supportchat_model.dart';
import 'package:provider/provider.dart';
import 'package:peereess/screens/supportchatscreen.dart';
import 'package:intl/intl.dart';

class AdminSupportChatListScreen extends StatefulWidget {
  const AdminSupportChatListScreen({super.key});

  @override
  State<AdminSupportChatListScreen> createState() =>
      _AdminSupportChatListScreenState();
}

class _AdminSupportChatListScreenState
    extends State<AdminSupportChatListScreen> {
  @override
  void initState() {
    super.initState();

    // Delay fetching until after first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SupportChatProvider>();
      provider.fetchAdminChatList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupportChatProvider>(
      builder: (context, provider, child) {
        final chatList = provider.adminChatList;
        final isLoading = provider.isLoading;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color.fromARGB(255, 217, 194, 162),
            title: Row(
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
                10.getWidthWhiteSpacing,
                const Text(
                  "Customer Service Messages",
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
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
                children: [
                  /// Search
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        onChanged: (value) => provider.searchAdminChats(value),
                        decoration: InputDecoration(
                          hintText: "Search chats",
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_outlined,
                            size: 19,
                          ),
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

                  /// Chat list
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : chatList.isEmpty
                            ? const Center(child: Text("No active chats"))
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: chatList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final SupportChatModel chat = chatList[index];
                                  final formattedTime = DateFormat(
                                    'dd/MM hh:mm a',
                                  ).format(chat.createdAt);

                                  return Material(
                                    elevation: 2,
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color.fromARGB(
                                        255, 233, 226, 226),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        provider.clearUnreadForSupport(
                                          chat.supportId,
                                        );

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SupportChatScreen(
                                              supportId: chat.supportId,
                                              userId: chat.userId,
                                              userName: chat.senderName,
                                              role: "admin",
                                            ),
                                          ),
                                        ).then((_) {});
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            /// Avatar
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor:
                                                  Colors.grey.shade300,
                                              child: chat.senderName.isNotEmpty
                                                  ? Text(
                                                      chat.senderName[0]
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.person,
                                                      size: 20,
                                                    ),
                                            ),
                                            const SizedBox(width: 12),

                                            /// Texts
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          chat.senderName,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
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
                                                    chat.message.isNotEmpty
                                                        ? chat.message
                                                        : "📷 Image",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            /// Unread count badge
                                            if (chat.unreadCount > 0)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 8,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
