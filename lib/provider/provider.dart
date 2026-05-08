import 'package:flutter/material.dart';
import 'package:peereess/provider/cloudinaryservice.dart';
import 'package:peereess/provider/ledgerprovider.dart';
import 'package:peereess/provider/paystack.dart';
import 'package:peereess/provider/peereesscompanyprovider.dart';
import 'package:peereess/provider/productedit.dart';
import 'package:peereess/provider/productview.dart';

import 'package:peereess/provider/refundservice.dart';
import 'package:peereess/provider/spinservice.dart';
import 'package:peereess/provider/themeprovider.dart';
import 'package:peereess/provider/withdrawservice.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/provider/adminchatlistprovider.dart';
import 'package:peereess/provider/adminchatprovider.dart';
import 'package:peereess/provider/adminprovider.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/cart_provider.dart';
import 'package:peereess/provider/chatlistprovider.dart';
import 'package:peereess/provider/chatprovider.dart';
import 'package:peereess/provider/deliveryfee_provider.dart';
import 'package:peereess/provider/filter_provider.dart';
import 'package:peereess/provider/home_provider.dart';
import 'package:peereess/provider/notificationprovider.dart';

import 'package:peereess/provider/picturechat_provider.dart';
import 'package:peereess/provider/product_provider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/provider/searchprovider.dart';
import 'package:peereess/provider/sellerorder_provider.dart';
import 'package:peereess/provider/supportchat_provider.dart';
import 'package:peereess/provider/tabbar_provider.dart';

class AppProvider {
  List<SingleChildWidget> providers = [
    ChangeNotifierProvider(create: (_) => AuthProvider()),

    ChangeNotifierProvider(
      create: (_) => ChatProvider(client: AppwriteConfig.client),
    ),

    ChangeNotifierProvider(create: (_) => HomeProvider()),
    ChangeNotifierProvider(create: (_) => ProductProvider()),
    ChangeNotifierProvider(create: (_) => ProductUploadProvider()),
    ChangeNotifierProvider(create: (_) => CartProvider()),
    ChangeNotifierProvider(create: (_) => DeliveryFeeProvider()),
    ChangeNotifierProvider(create: (_) => PeereessProvider()),
    ChangeNotifierProvider(create: (_) => RefundProvider()),
    ChangeNotifierProvider(create: (_) => PaystackWebProvider()),
    ChangeNotifierProvider(create: (_) => SpinService()),
    ChangeNotifierProvider(create: (_) => SpinService()),
    // In your MultiProvider list, add:
    ChangeNotifierProvider(create: (_) => UserProductViewProvider()),

    // ChatListProvider depends on AuthProvider for currentUserId
    ChangeNotifierProxyProvider<AuthProvider, ChatListProvider>(
      create: (_) =>
          ChatListProvider(client: AppwriteConfig.client, currentUserId: ''),
      update: (_, authProvider, chatListProvider) {
        final provider = chatListProvider!;
        final userId = authProvider.userId ?? '';

        // Initialize only once when user logs in
        if (userId.isNotEmpty && provider.currentUserId != userId) {
          provider.init(userId); // fetch chats + subscribe to Realtime
        }

        return provider;
      },
    ),

    ChangeNotifierProvider(create: (_) => ProductFilterProvider()),
    ChangeNotifierProvider(create: (_) => PictureSearchProvider()),
    ChangeNotifierProvider(create: (_) => SearchProvider()),
    ChangeNotifierProvider(create: (_) => TabbarProvider()),
    ChangeNotifierProvider(create: (_) => SellerOrderProvider()),
    ChangeNotifierProvider(create: (_) => AdminProvider()),
    ChangeNotifierProvider(create: (_) => SupportChatProvider()),
    ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ChangeNotifierProvider(create: (_) => LedgerProvider()),
    ChangeNotifierProvider(create: (_) => WithdrawService()),

    // ProductEditProvider - created without initial data
    // Call provider.initialize(productId, productData) before using
    ChangeNotifierProvider(create: (_) => ProductEditProvider()),

    ChangeNotifierProvider(
      create: (_) => AdminChatListProvider(client: AppwriteConfig.client),
    ),
    ChangeNotifierProvider(
      create: (_) => AdminChatProvider(client: AppwriteConfig.client),
    ),
    // ChangeNotifierProvider(create: (_) => ThemeProvider()),
  ];
}
