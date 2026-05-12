import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/provider/notificationprovider.dart';
import 'package:peereess/provider/product_provider.dart';
import 'package:peereess/provider/spinservice.dart';
import 'package:peereess/screens/companyscreen.dart/spin.dart';

import 'package:provider/provider.dart';

import 'package:peereess/core/app_color.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/cart_provider.dart';
import 'package:peereess/provider/chatlistprovider.dart';
import 'package:peereess/provider/home_provider.dart';
import 'package:peereess/provider/tabbar_provider.dart';

import 'package:peereess/screens/cart.dart';
import 'package:peereess/screens/chat.dart';
import 'package:peereess/screens/explore.dart';
import 'package:peereess/screens/homecontent.dart';
import 'package:peereess/screens/profile.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final ValueNotifier<int> _homeRefreshNotifier = ValueNotifier(0);

  bool _initialized = false;
  bool _spinModalShown = false;
  bool _spinListenerAdded = false;

  late final List<AnimationController> _shakeControllers;
  late final List<Animation<double>> _shakeAnimations;

  late final Homecontent _homeContent;

  // ✅ Save reference so dispose() never calls context.read
  SpinService? _spinService;

  int _previousIndex = 0;

  void _onTabTapped(int index, HomeProvider homeProvider) {
    if (index == 0 && homeProvider.currentIndex == 0) {
      _shakeControllers[0].forward(from: 0);
      _homeRefreshNotifier.value++;
      return;
    }

    if (index != _previousIndex) {
      _shakeControllers[index].forward(from: 0);
      _previousIndex = index;
    }
    homeProvider.changeIndex(index);
  }

  @override
  void initState() {
    super.initState();

    _homeContent = Homecontent(refreshNotifier: _homeRefreshNotifier);

    _shakeControllers = List.generate(
      5,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );

    _shakeAnimations = _shakeControllers.map((controller) {
      return TweenSequence([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 6.0, end: -3.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -3.0, end: 3.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 1),
      ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _initialized) return;
      _initialized = true;

      final auth = context.read<AuthProvider>();

      if (auth.isLoggedIn && auth.currentUserData == null) {
        await auth.fetchUserData();
      }

      if (!mounted) return;

      final currentUserId = auth.userId ?? '';
      if (currentUserId.isEmpty) return;

      final notificationProvider = context.read<NotificationProvider>();
      notificationProvider.fetchNotifications(userId: currentUserId);
      notificationProvider.subscribeToNotifications(userId: currentUserId);

      context.read<ChatListProvider>().init(currentUserId);

      context.read<ProductProvider>().loadUserLikes(currentUserId);

      // ✅ Save reference before using
      final spin = context.read<SpinService>();
      _spinService = spin;

      spin.fetchSpinConfig().then((_) {
        if (!mounted) return;
        spin.subscribeRealtime();

        if (spin.spinEnabled && !_spinModalShown) {
          _spinModalShown = true;
          _showSpinModal();
        }
      });

      spin.addListener(_onSpinChanged);
      _spinListenerAdded = true;
    });
  }

  @override
  void dispose() {
    for (final c in _shakeControllers) {
      c.dispose();
    }
    _homeRefreshNotifier.dispose();

    // ✅ Use saved reference — never call context.read() in dispose()
    if (_spinListenerAdded && _spinService != null) {
      _spinService!.removeListener(_onSpinChanged);
    }

    super.dispose();
  }

  void _onSpinChanged() {
    if (!mounted) return;
    // ✅ Use saved reference instead of context.read
    final spin = _spinService;
    if (spin == null) return;
    if (spin.spinEnabled && !_spinModalShown) {
      _spinModalShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSpinModal();
      });
    }
  }

  void _showSpinModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const _SpinModal(),
    );
  }

  Widget _buildShakeIcon(int index, Widget child) {
    return AnimatedBuilder(
      animation: _shakeAnimations[index],
      builder: (_, c) => Transform.translate(
        offset: Offset(_shakeAnimations[index].value, 0),
        child: c,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.userId ?? '';

    return Scaffold(
      body: IndexedStack(
        index: homeProvider.currentIndex,
        children: [
          _homeContent,
          const Explore(),
          const Cart(),
          Chat(userId: currentUserId),
          const Profile(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: homeProvider.currentIndex,
        backgroundColor: Colors.white,
        onTap: (index) => _onTabTapped(index, homeProvider),
        iconSize: 20,
        selectedItemColor: const Color(0xff9D6E2D),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(
            icon: _buildShakeIcon(
              0,
              Icon(
                homeProvider.currentIndex == 0
                    ? IconsaxPlusBold.home_1
                    : IconsaxPlusLinear.home_1,
              ),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _buildShakeIcon(
              1,
              Icon(
                homeProvider.currentIndex == 1
                    ? IconsaxPlusBold.category_2
                    : IconsaxPlusLinear.category_2,
              ),
            ),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            label: 'Cart',
            icon: _buildShakeIcon(
              2,
              Consumer<CartProvider>(
                builder: (_, cartProvider, __) {
                  final count = cartProvider.cartItems.length;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        homeProvider.currentIndex == 2
                            ? IconsaxPlusBold.shopping_cart
                            : IconsaxPlusLinear.shopping_cart,
                      ),
                      if (count > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          BottomNavigationBarItem(
            label: 'Message',
            icon: _buildShakeIcon(
              3,
              Consumer<ChatListProvider>(
                builder: (_, chatListProvider, __) {
                  final unread = chatListProvider.totalUnreadCount;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        homeProvider.currentIndex == 3
                            ? IconsaxPlusBold.message
                            : IconsaxPlusLinear.message,
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          BottomNavigationBarItem(
            icon: _buildShakeIcon(
              4,
              Icon(
                homeProvider.currentIndex == 4
                    ? IconsaxPlusBold.profile
                    : IconsaxPlusLinear.profile,
              ),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Spin modal ───────────────────────────────────────────────────────────────
class _SpinModal extends StatelessWidget {
  const _SpinModal();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 217, 194, 162),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.brown.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.brown.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF7B3F00),
                  ),
                ),
              ),
            ),
          ),
          const Expanded(child: SpinToWinPage(showAppBar: false)),
        ],
      ),
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.pink,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
