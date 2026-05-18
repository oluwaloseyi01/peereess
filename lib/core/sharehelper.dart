import 'package:share_plus/share_plus.dart';

class ShareHelper {
  /// Share a product page link to any app (WhatsApp, Telegram, Instagram, etc.)
  static Future<void> shareProduct({
    required String productId,
    required String title,
    required String description,
  }) async {
    final String shortDesc = description.length > 100
        ? '${description.substring(0, 100)}...'
        : description;

    final String text = '''🛍️ Check out *$title* on Peereess!

$shortDesc

👇 Tap to view and order:
https://peereess.com/product/$productId''';

    await Share.share(
      text,
      subject: title,
    );
  }
}
