import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:peereess/databases/config/sessionmanagement.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:appwrite/appwrite.dart';

class DeepLinkService {
  static final AppLinks _appLinks = AppLinks();

  static void init() {
    _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    }, onError: (e) {
      debugPrint('❌ Deep link stream error: $e');
    });

    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleLink(uri);
    });
  }

  static void _handleLink(Uri uri) {
    debugPrint('🔗 Deep link received: $uri');
    final segments = uri.pathSegments;

    if (segments.length >= 2 && segments[0] == 'product') {
      _navigateToProduct(segments[1]);
    }
  }

  static void _navigateToProduct(String productId) async {
    final context = SessionManager.navigatorKey.currentContext;

    if (context == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToProduct(productId);
      return;
    }

    // Step 1: clear entire stack, show loading screen as only route
    SessionManager.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/deepLinkLoading'),
        builder: (_) => const _DeepLinkLoadingScreen(),
      ),
      (route) => false, // remove everything underneath
    );

    try {
      final product = await _fetchProductById(productId);

      if (product == null) {
        debugPrint('❌ Deep link: product $productId not found');
        // Go home, nothing else in stack
        SessionManager.navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const _GoHome()),
          (route) => false,
        );
        return;
      }

      // Step 2: push /home first, then product page on top
      // So back from product → home
      SessionManager.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
      SessionManager.navigatorKey.currentState?.pushNamed(
        '/productDetails',
        arguments: {'product': product},
      );
    } catch (e) {
      debugPrint('❌ Deep link navigation error: $e');
      SessionManager.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    }
  }

  static Future<ProductModel?> _fetchProductById(String productId) async {
    try {
      final db = Databases(AppwriteConfig.client);
      final doc = await db.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.product,
        documentId: productId,
      );
      return ProductModel.fromMap(doc.data);
    } catch (e) {
      debugPrint('❌ fetchProductById error: $e');
      return null;
    }
  }
}

class _DeepLinkLoadingScreen extends StatelessWidget {
  const _DeepLinkLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: LogoLoadingIndicator(size: 100),
      ),
    );
  }
}

// Fallback widget just in case
class _GoHome extends StatelessWidget {
  const _GoHome();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    });
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: LogoLoadingIndicator(size: 100)),
    );
  }
}
