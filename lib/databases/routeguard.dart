import 'package:flutter/material.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/screens/addaddress.dart';
import 'package:peereess/screens/addressbook.dart';
import 'package:peereess/screens/admin/adminhome.dart';
import 'package:peereess/screens/cart.dart';
import 'package:peereess/screens/categoryscreen.dart';
import 'package:peereess/screens/changepassword.dart';
import 'package:peereess/screens/chatscreen.dart';
import 'package:peereess/screens/collection.dart';
import 'package:peereess/screens/deleteaccount.dart';
import 'package:peereess/screens/filter.dart';
import 'package:peereess/screens/forgetpassword.dart';
import 'package:peereess/screens/help.dart';
import 'package:peereess/screens/home.dart';
import 'package:peereess/screens/login.dart';
import 'package:peereess/screens/notificationscreen.dart';
import 'package:peereess/screens/onboarding.dart';
import 'package:peereess/screens/orderhistorydetail.dart';
import 'package:peereess/screens/orderpage.dart';
import 'package:peereess/screens/paymentloading.dart';
import 'package:peereess/screens/paymentondeliverysuccess.dart';
import 'package:peereess/screens/paymentresult.dart';
import 'package:peereess/screens/personalinformation.dart';
import 'package:peereess/screens/pickup.dart';
import 'package:peereess/screens/privacypolicy.dart';
import 'package:peereess/screens/product_details.dart';
import 'package:peereess/screens/pushnotification.dart';
import 'package:peereess/screens/recomendscreen.dart';
import 'package:peereess/screens/refund.dart';
import 'package:peereess/screens/save.dart';
import 'package:peereess/screens/searchscreen.dart';
import 'package:peereess/screens/selectpayment.dart';
import 'package:peereess/screens/signup.dart';
import 'package:peereess/screens/signupaddress.dart';
import 'package:peereess/screens/splash.dart';
import 'package:peereess/screens/supportchatscreen.dart';
import 'package:peereess/screens/temsofuse.dart';
import 'package:peereess/screens/verifyemail.dart';
import 'package:peereess/screens/voucher.dart';
import 'package:peereess/screens/whatyoulikescreen.dart';
import 'package:peereess/screens/widgets/emailverifiedsplash.dart';
import 'package:peereess/sellers/sellerhome.dart';
import 'package:provider/provider.dart';

class RouteGuard {
  // ─────────────────────────────────────────────────────────────
  // These routes are ALWAYS allowed — no auth check whatsoever.
  // Splash owns all startup navigation so these must never be
  // intercepted by the logged-in / role guards below.
  // ─────────────────────────────────────────────────────────────
  static const _publicRoutes = {
    '/',
    '/onboarding',
    '/login',
    '/signup',
    '/verifyemail',
    '/emailverifysplash',
    '/forgotPassword',
    '/recomendscreen',
    '/whatyoulikescreen',
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final name = settings.name ?? '/';
    final args = settings.arguments;

    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        // ── PUBLIC: never touch auth state ──────────────────────
        if (_publicRoutes.contains(name)) {
          switch (name) {
            case '/':
              return const Splash();
            case '/onboarding':
              return const Onboarding();
            case '/login':
              return const Login();
            case '/signup':
              return const Signup();
            case '/tems':
              return const TermsofUse();
            case '/privacy&policy':
              return const Privacypolicy();
            case '/verifyemail':
              return const Verifyemail();
            case '/emailverifysplash':
              return const EmailVerifiedSplash();
            case '/forgotPassword':
              return const ForgotPasswordPage();
            case '/recomendscreen':
              return const Recomendscreen();
            case '/whatyoulikescreen':
              return const Whatyoulikescreen();
            default:
              return const Splash();
          }
        }

        // ── AUTH GUARD: everything below requires a session ─────
        final auth = Provider.of<AuthProvider>(context, listen: false);

        // Still initializing
        if (!auth.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in — send to login
        if (!auth.isLoggedIn) {
          return const Login();
        }

        // ── PAYMENT (any logged-in role) ─────────────────────────
        switch (name) {
          case '/paymentloading':
            final map = args as Map;
            return Paymentloading(
              paymentFuture: map['paymentFuture'] as Future<void> Function(),
            );
          case '/paymentOnDeliverySuccess':
            final map = args as Map;
            return PaymentOnDeliverySuccess(orderId: map['orderId'] as String);
          case '/paymentResultPage':
            final map = args as Map;
            return PaymentResultPage(
              isSuccess: map['isSuccess'] as bool,
              message: map['message'] as String,
              reference: map['reference'] as String?,
            );
        }

        // ── ADMIN ────────────────────────────────────────────────
        if (auth.userType == 'admin') {
          switch (name) {
            case '/adminhome':
            case '/admin':
              return const Adminhome();

            case '/chat':
              if (args == null) return const Home();
              final map = args as Map;
              final productId = map['productId'] as String?;
              final userId = map['userId'] as String?;
              if (productId == null ||
                  productId.isEmpty ||
                  userId == null ||
                  userId.isEmpty) {
                return const Home();
              }
              return ChatScreen(
                productId: productId,
                userId: userId,
                productTitle: (map['productTitle'] as String?) ?? '',
                imageUrl: map['imageUrl'] as String?,
                firstVariantPrice: map['firstVariantPrice'] != null
                    ? double.tryParse(map['firstVariantPrice'].toString())
                    : null,
                role: 'admin', // ← ADD
                buyerId: map['buyerId'] as String?, // ← ADD
                buyerName: map['buyerName'] as String?, // ← ADD
              );
            case '/supportChat':
              final map = args as Map;
              return SupportChatScreen(
                supportId: map['supportId'],
                userId: map['userId'],
                userName: map['userName'],
                role: map['role'],
              );
            default:
              return const Adminhome();
          }
        }

        // ── SELLER ───────────────────────────────────────────────
        if (auth.userType == 'seller') {
          switch (name) {
            case '/sellerhome':
            case '/seller':
              return const Sellerhome();
            case '/addaddress':
              return const AddAddress();
            case '/addressbook':
              return const Addressbook();
            case '/supportChat':
              final map = args as Map;
              return SupportChatScreen(
                supportId: map['supportId'],
                userId: map['userId'],
                userName: map['userName'],
                role: map['role'],
              );
            default:
              return const Sellerhome();
          }
        }

        // ── NORMAL USER ──────────────────────────────────────────
        switch (name) {
          case '/home':
            return const Home();
          case '/searchscreen':
            return const Searchscreen();
          case '/save':
            return const Save();
          case '/filter':
            return const Filter();
          case '/cart':
            return const Cart();
          case '/notificationscreen':
            return const Notificationscreen();
          case '/addaddress':
            return const AddAddress();
          case '/addressbook':
            return const Addressbook();
          case '/personalinformation':
            return const Personalinformation();
          case '/voucher':
            return const Voucher();
          case '/deleteaccount':
            return const Deleteaccount();
          case '/changePasswordScreen':
            return const ChangePasswordScreen();
          case '/refund':
            return const Refund();
          case '/help':
            return const Help();
          case '/signupaddress':
            return const Signupaddress();
          case '/pushnotification':
            return const Pushnotification();
          case '/pickup':
            return const Pickup();

          case '/categoryscreen':
            final map = args as Map;
            return Categoryscreen(
              categoryType: map['type'],
              allProducts: map['allProducts'],
            );
          case '/orderHistoryDetail':
            final map = args as Map;
            return OrderHistoryDetail(order: map['order']);
          case '/collection':
            final map = args as Map;
            return Collection(
              selectedProduct: map['selectedProduct'],
              allProducts: map['allProducts'],
            );
          case '/productDetails':
            final map = args as Map;
            return ProductDetails(product: map['product']);
          case '/orderPage':
            final map = args as Map;
            return OrderPage(
              cartItems: map['cartItems'],
              totalPrice: map['totalPrice'],
              deliveryAddress: map['deliveryAddress'],
              deliveryPhoneNumber: map['deliveryPhoneNumber'],
              deliveryFee: map['deliveryFee'],
              deliveryDays: map['deliveryDays'],
              receiverFullName: map['receiverFullName'],
            );
          case '/selectPayment':
            final map = args as Map;
            return Selectpayment(
              cartItems: map['cartItems'],
              totalPrice: map['totalPrice'],
              deliveryFee: map['deliveryFee'],
              deliveryAddress: map['deliveryAddress'],
              deliveryPhoneNumber: map['deliveryPhoneNumber'],
              deliveryDays: map['deliveryDays'],
              receiverFullName: map['receiverFullName'],
              selectedPickup: map['selectedPickup'],
              deliveryIncludedInCart: map['deliveryIncludedInCart'],
              selectedDelivery: map['selectedDelivery'],
            );

          case '/chat':
            // ── Null-safe: args may be null if notification had no data ──
            if (args == null) return const Home();
            final map = args as Map;
            final productId = map['productId'] as String?;
            final userId = map['userId'] as String?;
            if (productId == null ||
                productId.isEmpty ||
                userId == null ||
                userId.isEmpty) {
              return const Home();
            }
            return ChatScreen(
              productId: productId,
              userId: userId,
              productTitle: (map['productTitle'] as String?) ?? '',
              imageUrl: map['imageUrl'] as String?,
              firstVariantPrice: map['firstVariantPrice'] != null
                  ? double.tryParse(map['firstVariantPrice'].toString())
                  : null,
            );

          case '/supportChat':
            final map = args as Map;
            return SupportChatScreen(
              supportId: map['supportId'],
              userId: map['userId'],
              userName: map['userName'],
              role: map['role'],
            );

          default:
            return const Home();
        }
      },
    );
  }
}
