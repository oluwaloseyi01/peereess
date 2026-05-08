import 'package:flutter/material.dart';
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
import 'package:peereess/screens/product_details.dart';
import 'package:peereess/screens/profile.dart';
import 'package:peereess/screens/pushnotification.dart';
import 'package:peereess/screens/recomendscreen.dart';
import 'package:peereess/screens/refund.dart';
import 'package:peereess/screens/save.dart';
import 'package:peereess/screens/searchscreen.dart';
import 'package:peereess/screens/selectpayment.dart';
import 'package:peereess/screens/signup.dart';
import 'package:peereess/screens/signupaddress.dart';
import 'package:peereess/screens/supportchatscreen.dart';
import 'package:peereess/screens/verifyemail.dart';
import 'package:peereess/screens/voucher.dart';
import 'package:peereess/screens/whatyoulikescreen.dart';
import 'package:peereess/screens/widgets/emailverifiedsplash.dart';
import 'package:peereess/sellers/sellerhome.dart';

class AppRouter {
  Map<String, WidgetBuilder> route = {
    "/home": (BuildContext context) => const Home(),
    "/adminhome": (BuildContext context) => const Adminhome(),
    "/sellerhome": (BuildContext context) => const Sellerhome(),

    "/signup": (BuildContext context) => const Signup(),
    "/login": (BuildContext context) => const Login(),
    "/onboarding": (BuildContext context) => const Onboarding(),
    "/accountSettings": (BuildContext context) => const Profile(),
    "/searchscreen": (BuildContext context) => const Searchscreen(),
    "/save": (BuildContext context) => const Save(),
    "/filter": (BuildContext context) => const Filter(),
    "/cart": (_) => const Cart(),
    "/notificationscreen": (_) => const Notificationscreen(),

    "/addaddress": (BuildContext context) => const AddAddress(),
    "/addressbook": (BuildContext context) => const Addressbook(),
    "/personalinformation": (BuildContext context) =>
        const Personalinformation(),

    "/voucher": (BuildContext context) => const Voucher(),

    "/deleteaccount": (BuildContext context) => const Deleteaccount(),
    "/refund": (BuildContext context) => const Refund(),
    "/changePasswordScreen": (BuildContext context) =>
        const ChangePasswordScreen(),
    "/help": (BuildContext context) => const Help(),
    "/signupaddress": (BuildContext context) => const Signupaddress(),
    "/whatyoulikescreen": (BuildContext context) => const Whatyoulikescreen(),
    "/recomendscreen": (BuildContext context) => const Recomendscreen(),
    "/emailverifysplash": (BuildContext context) => const EmailVerifiedSplash(),
    "/pushnotification": (BuildContext context) => const Pushnotification(),

    // Inside the route map, after paymentOnDeliverySuccess:
    "/paymentResultPage": (context) {
      final map = ModalRoute.of(context)!.settings.arguments as Map;
      return PaymentResultPage(
        isSuccess: map["isSuccess"] as bool,
        message: map["message"] as String,
        reference: map["reference"] as String?,
      );
    },

    "/paymentloading": (context) {
      final map = ModalRoute.of(context)!.settings.arguments as Map;
      return Paymentloading(paymentFuture: map["paymentFuture"]);
    },

    "/paymentOnDeliverySuccess": (context) {
      final map = ModalRoute.of(context)!.settings.arguments as Map;
      return PaymentOnDeliverySuccess(orderId: map["orderId"]);
    },

    "/verifyemail": (BuildContext context) => const Verifyemail(),

    "/pickup": (BuildContext context) => const Pickup(),

    "/orderHistoryDetail": (BuildContext context) {
      final map = ModalRoute.of(context)!.settings.arguments as Map;
      return OrderHistoryDetail(order: map["order"]);
    },

    "/categoryscreen": (BuildContext context) {
      final map = ModalRoute.of(context)!.settings.arguments as Map;
      return Categoryscreen(
        categoryType: map["type"],
        allProducts: map["allProducts"],
      );
    },

    "/collection": (BuildContext context) {
      final map = ModalRoute.of(context)!.settings.arguments as Map;
      return Collection(
        selectedProduct: map["selectedProduct"],
        allProducts: map["allProducts"],
      );
    },

    "/productDetails": (BuildContext context) {
      final map = ModalRoute.of(context)!.settings.arguments as Map;
      return ProductDetails(product: map["product"]);
    },

    "/orderPage": (BuildContext context) {
      final map = ModalRoute.of(context)!.settings.arguments as Map;
      return OrderPage(
        cartItems: map["cartItems"],
        totalPrice: map["totalPrice"],
        deliveryAddress: map["deliveryAddress"],
        deliveryPhoneNumber: map["deliveryPhoneNumber"],
        deliveryFee: map["deliveryFee"],
        deliveryDays: map["deliveryDays"],
        receiverFullName: map["receiverFullName"],
      );
    },

    "/selectPayment": (BuildContext context) {
      final map = ModalRoute.of(context)!.settings.arguments as Map;
      return Selectpayment(
        cartItems: map["cartItems"],
        totalPrice: map["totalPrice"],
        deliveryFee: map["deliveryFee"],
        deliveryAddress: map["deliveryAddress"],
        deliveryPhoneNumber: map["deliveryPhoneNumber"],
        deliveryDays: map["deliveryDays"],
        receiverFullName: map["receiverFullName"],
        selectedPickup: map["selectedPickup"],
        deliveryIncludedInCart: map["deliveryIncludedInCart"],
        selectedDelivery: map["selectedDelivery"],
      );
    },

    "/forgotPassword": (BuildContext context) => const ForgotPasswordPage(),

    "/chat": (BuildContext context) {
      final map = ModalRoute.of(context)!.settings.arguments as Map;
      return ChatScreen(
        productId: map["productId"],
        userId: map["userId"],
        imageUrl: map["imageUrl"],
        firstVariantPrice: map["firstVariantPrice"],
        productTitle: map["productTitle"],
      );
    },

    "/supportChat": (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      return SupportChatScreen(
        supportId: args["supportId"],
        userId: args["userId"],
        userName: args["userName"],
        role: args["role"],
      );
    },
  };
}
