import 'package:flutter/material.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/notificationprovider.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/appwrite.dart';

class Notificationscreen extends StatefulWidget {
  const Notificationscreen({super.key});

  @override
  State<Notificationscreen> createState() => _NotificationscreenState();
}

class _NotificationscreenState extends State<Notificationscreen>
    with SingleTickerProviderStateMixin {
  String? userId;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _gradientTop = Color.fromARGB(255, 217, 194, 162);
  static const _brown = Color(0xff9D6E2D);
  static const _brownDeep = Color(0xFF6B4A1B);

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      try {
        final account = Account(AppwriteConfig.client);
        final user = await account.get();
        userId = user.$id;
        await notificationProvider.fetchNotifications(userId: userId!);
        notificationProvider.subscribeToNotifications(userId: userId!);
        _fadeCtrl.forward();
      } catch (e) {
        debugPrint("Error fetching current user: $e");
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    final notificationProvider = context.watch<NotificationProvider>();
    final isEmpty = notificationProvider.notifications.isEmpty;

    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 217, 194, 162),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                // Back button
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

                // Center title
                Expanded(
                  child: Center(
                    child: const Text(
                      "Notifications",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Right side
                if (!isEmpty)
                  GestureDetector(
                    onTap: () async {
                      if (userId == null) return;

                      await context
                          .read<NotificationProvider>()
                          .clearAllNotifications(userId: userId!);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "Clear all",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 60), // 👈 balance when button no show
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.75),
              boxShadow: [
                BoxShadow(
                  color: _brown.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: _brown,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _brownDeep,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "No notifications right now",
            style: TextStyle(fontSize: 12.5, color: Colors.brown.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(dynamic notification, int index) {
    final timeAgo = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(notification.createdAt);
    final isRead = notification.isRead;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.08 * (index + 1)),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _fadeCtrl,
            curve: Interval(
              (index * 0.06).clamp(0.0, 0.8),
              1.0,
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isRead
                ? Colors.white.withOpacity(0.65)
                : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead ? Colors.brown.shade100 : _brown.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isRead
                    ? Colors.black.withOpacity(0.04)
                    : _brown.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isRead
                          ? [Colors.grey.shade200, Colors.grey.shade300]
                          : [_gradientTop, _brown],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    notification.orderId != null &&
                            notification.orderId!.isNotEmpty
                        ? Icons.shopping_bag_outlined
                        : Icons.notifications_outlined,
                    size: 19,
                    color: isRead ? Colors.grey.shade500 : Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight:
                                    isRead ? FontWeight.w500 : FontWeight.w700,
                                color: const Color(0xFF2C1A0E),
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Colors.brown.shade600,
                        ),
                      ),
                      if (notification.orderId != null &&
                          notification.orderId!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _gradientTop.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Order ID: ${notification.orderId}",
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: _brownDeep,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.brown.shade300,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isConnected) {
      return Container(
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
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
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
        child: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: LogoLoadingIndicator());
            }

            if (provider.notifications.isEmpty) {
              // ✅ Wrap empty state in scrollable so pull-to-refresh works
              return RefreshIndicator(
                color: _brown,
                onRefresh: () =>
                    provider.fetchNotifications(userId: userId ?? ''),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [SliverFillRemaining(child: _buildEmptyState())],
                ),
              );
            }

            // ✅ Pull-to-refresh + tap card to mark as read
            return RefreshIndicator(
              color: _brown,
              onRefresh: () =>
                  provider.fetchNotifications(userId: userId ?? ''),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                itemCount: provider.notifications.length,
                itemBuilder: (_, index) {
                  final notification = provider.notifications[index];
                  return GestureDetector(
                    onTap: () {
                      if (!notification.isRead && userId != null) {
                        provider.markAsRead(notification.id, userId!);
                      }
                    },
                    child: _buildNotificationCard(notification, index),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
