import 'package:appwrite/appwrite.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AppwriteConfig {
  static const String appwriteProjectId = '69383047001867cb050b';
  static const String appwriteProjectName = 'peereess';
  static const String endPoint = "https://nyc.cloud.appwrite.io/v1";
  static const String userCollection = "usercollection";
  static const String product = "product";
  static const String databaseId = "6938319d0016f950f765";
  static const String cart = "cart";
  static const String deliveryfee = "deliveryfee";
  static const String peereess = "peereess";
  static const String chat = "chat";
  static const String order = "order";
  static const String admin = "admin";
  static const String refund = "refund";
  static const String ledger = "ledger";
  static const String typingCollection = "typing";

  static const String createUserFunction = "69452d4c001d39669ee8";
  static const String productFunction = "69511660003cc5877431";
  static const String messagingFunctionId = "6949a0980027f204602a";
  static const String adminPanelSecret = "69511660003cc5877431";

  static const String spinConfigCollection = 'spin';
  static const String spinConfigDocumentId = 'global';
  static const String productViews = 'userproductview';

  static const String supportchat = "supportchat";
  static const String sellerscollection = "sellerscollection";
  static const String notification = "notification";

  static const String bucketId = "693bd3b7001d1f5e9a9e";

  // ✅ Add your FCM Provider ID from Appwrite Console → Messaging → Providers
  static const String fcmProviderId = '69bc18ed0009ca87849e';

  static Functions functions = Functions(client);

  static final Client _client = Client()
    ..setEndpoint(endPoint)
    ..setProject(appwriteProjectId);

  static Client get client => _client;

  static final Account account = Account(_client);
  static final Storage storage = Storage(_client);
  static final Realtime realtime = Realtime(_client);
  static final TablesDB tablesDB = TablesDB(_client);
  static final Messaging messaging = Messaging(_client); // ✅ Added

  static String getFileUrl(String s, {required String fileId}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return "$endPoint/storage/buckets/$bucketId/files/$fileId/view"
        "?project=$appwriteProjectId&t=$timestamp";
  }

  // ✅ Register device FCM token with Appwrite
  static Future<void> registerDevice() async {
    try {
      // Force fresh token to avoid expired tokens
      await FirebaseMessaging.instance.deleteToken();
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken == null) {
        print('⚠️ FCM token is null');
        return;
      }

      print('✅ FCM Token: $fcmToken');

      // Remove any existing targets with old/expired tokens first
      try {
        final user = await account.get();
        for (final target in user.targets) {
          await account.deletePushTarget(targetId: target.$id);
          print('🗑️ Removed old push target: ${target.$id}');
        }
      } catch (e) {
        print('⚠️ Could not clean old targets: $e');
      }

      // Register fresh token
      await account.createPushTarget(
        targetId: ID.unique(),
        identifier: fcmToken,
        providerId: fcmProviderId,
      );

      print('✅ Device registered with Appwrite!');

      // Listen for future token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          final user = await account.get();
          for (final target in user.targets) {
            await account.deletePushTarget(targetId: target.$id);
          }
          await account.createPushTarget(
            targetId: ID.unique(),
            identifier: newToken,
            providerId: fcmProviderId,
          );
          print('✅ Push token refreshed in Appwrite');
        } catch (e) {
          print('⚠️ Failed to refresh push token: $e');
        }
      });
    } on AppwriteException catch (e) {
      print('❌ Appwrite error: ${e.message}');
    } catch (e) {
      print('❌ Error registering device: $e');
    }
  }

// ✅ Unregister device (call on logout) — must be called BEFORE deleteSessions()
  static Future<void> unregisterDevice() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print('⚠️ No FCM token found');
        return;
      }

      final user = await account.get();
      for (final target in user.targets) {
        if (target.identifier == fcmToken) {
          await account.deletePushTarget(targetId: target.$id);
          print('✅ Device unregistered from Appwrite');
          break;
        }
      }
    } on AppwriteException catch (e) {
      print('❌ Unregister error: ${e.message}');
    } catch (e) {
      print('❌ Unregister error: $e');
    }
  }
}
