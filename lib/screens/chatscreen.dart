import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/chatlistprovider.dart';
import 'package:peereess/provider/product_provider.dart';
import 'package:peereess/screens/widgets/addtocart_widget.dart';
import 'package:peereess/screens/widgets/inappcamera.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';
import 'package:peereess/provider/chatprovider.dart';
import 'package:peereess/model/chatmodel.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final String productId;
  final String productTitle;
  final String userId;
  final String? imageUrl;
  final double? firstVariantPrice;
  final String role;
  final String? buyerId;
  final String? buyerName;

  const ChatScreen({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.userId,
    this.imageUrl,
    this.firstVariantPrice,
    this.role = 'user',
    this.buyerId,
    this.buyerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();

  late ChatProvider _chatProvider;
  late ChatListProvider _chatListProvider;
  late AuthProvider _authProvider;

  File? _selectedImage;
  bool _isDisposed = false;
  bool _isDeleting = false;
  final formatter = NumberFormat("#,##0", "en_US");

  late VoidCallback _chatListener;

  bool get _isAdmin => widget.role == 'admin';

  String get _conversationUserId =>
      _isAdmin ? (widget.buyerId ?? widget.userId) : widget.userId;

  String get _receiverId => _isAdmin ? (widget.buyerId ?? '') : 'admin';

  @override
  void initState() {
    super.initState();

    _chatProvider = context.read<ChatProvider>();
    _chatListProvider = context.read<ChatListProvider>();
    _authProvider = context.read<AuthProvider>();

    int lastMessageCount = 0;

    _chatListener = () {
      if (_isDisposed) return;
      final count = _chatProvider.messages.length;
      if (count != lastMessageCount) {
        lastMessageCount = count;
        _scrollToBottom();
      }
    };

    _chatProvider.addListener(_chatListener);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isDisposed) return;

      _chatProvider.setChatOpen(
        productId: widget.productId,
        userId: _conversationUserId,
        viewerId: _isAdmin ? widget.userId : null,
      );
      _chatListProvider.setChatOpen(
        productId: widget.productId,
        userId: _conversationUserId,
        viewerId: _isAdmin ? widget.userId : null,
      );

      if (_chatProvider.messages.isEmpty) {
        await _chatProvider.fetchMessages(
          productId: widget.productId,
          userId: _conversationUserId,
          viewerId: _isAdmin ? widget.userId : null,
        );
      }

      if (_isDisposed) return;

      _chatListProvider.markChatAsRead(
        productId: widget.productId,
        userId: widget.userId,
      );
      await _chatProvider.markMessagesAsRead(
        productId: widget.productId,
        userId: widget.userId,
        isAdmin: _isAdmin,
      );

      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _chatProvider.removeListener(_chatListener);
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    _chatListProvider.setChatClosed();
    super.dispose();
  }

  Future<void> _deleteChat() async {
    if (_isDisposed) return;
    setState(() => _isDeleting = true);
    await _chatListProvider.deleteChat(widget.productId, widget.userId);
    if (!_isDisposed && mounted) {
      setState(() => _isDeleting = false);
      Navigator.pop(context);
    }
  }

  Future<void> _sendMessage({File? imageFile}) async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty && imageFile == null) return;

    _messageCtrl.clear();
    setState(() => _selectedImage = null);

    final String senderName;
    if (_isAdmin) {
      senderName = 'Admin';
    } else {
      final name = _authProvider.currentUserData?.fullName?.trim() ??
          _authProvider.fullNameController.text.trim();
      senderName = name.isNotEmpty ? name : 'Customer';
    }

    await _chatProvider.sendMessage(
      senderId: widget.userId,
      receiverId: _receiverId,
      productId: widget.productId,
      productTitle: widget.productTitle,
      message: text,
      imageFile: imageFile,
      firstVariantPrice: widget.firstVariantPrice,
      senderRole: widget.role,
      senderName: senderName,
      chatListProvider: _chatListProvider,
    );

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    try {
      if (fromCamera) {
        final File? photo = await Navigator.push<File>(
          context,
          MaterialPageRoute(builder: (_) => const InAppCamera()),
        );
        if (photo != null && mounted) {
          setState(() => _selectedImage = photo);
        }
        return;
      }

      if (Platform.isAndroid) {
        final LostDataResponse response = await _picker.retrieveLostData();
        if (response.file != null && mounted) {
          setState(() => _selectedImage = File(response.file!.path));
          return;
        }
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null && mounted) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  void _openFullImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SizedBox.expand(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => const Center(
                    child: LogoLoadingIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  dynamic _getProduct() {
    try {
      return context.read<ProductProvider>().products.firstWhere(
            (p) => p.productId == widget.productId,
          );
    } catch (_) {
      return null;
    }
  }

  void _onProductTap() {
    final product = _getProduct();
    if (product == null) return;
    Navigator.pushNamed(
      context,
      "/productDetails",
      arguments: {"product": product},
    );
  }

  void _onCartTap() {
    final product = _getProduct();
    if (product == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: AddtocartWidget(
              product: product,
              isOrderNow: true,
              parentContext: context,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final List<ChatModel> messages = chatProvider.messages;
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
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 218, 192, 155),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(5),
          child: Container(color: Colors.grey, height: 0.5),
        ),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: Color(0xff9D6E2D),
                  ),
                ),
              ),
            ),
            10.getWidthWhiteSpacing,
            Flexible(
              child: GestureDetector(
                onTap: _isAdmin ? null : _onProductTap,
                child: Row(
                  children: [
                    if (widget.imageUrl != null)
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrl!,
                          height: 40,
                          width: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 40,
                            width: 40,
                            color: Colors.grey[200],
                          ),
                          errorWidget: (context, url, error) =>
                              const CircleAvatar(
                            radius: 25,
                            child: Icon(Icons.store),
                          ),
                        ),
                      )
                    else
                      const CircleAvatar(
                        radius: 25,
                        child: Icon(Icons.store),
                      ),
                    10.getWidthWhiteSpacing,
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isAdmin && widget.buyerName != null)
                            Text(
                              widget.buyerName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            widget.productTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: _isAdmin ? 11 : 14,
                              fontWeight:
                                  _isAdmin ? FontWeight.w400 : FontWeight.bold,
                              color: _isAdmin ? Colors.brown.shade600 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (!_isAdmin)
              GestureDetector(
                onTap: _onCartTap,
                child: Icon(
                  IconsaxPlusLinear.shop,
                  size: 22,
                  color: Color(0xff9D6E2D),
                ),
              ),
            10.getWidthWhiteSpacing,
            GestureDetector(
              onTap: () {
                showCustomMenu(
                  context: context,
                  onDelete: _deleteChat,
                  productId: widget.productId,
                  userId: widget.userId,
                  isAdmin: _isAdmin,
                  onViewProduct: _onProductTap,
                );
              },
              child: Icon(
                Icons.more_vert,
                size: 22,
                color: Color(0xff9D6E2D),
              ),
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];

                      if (msg.productId != widget.productId) {
                        return const SizedBox.shrink();
                      }

                      final t = msg.createdAt;
                      final formattedTime =
                          "${t.hour.toString().padLeft(2, '0')}:"
                          "${t.minute.toString().padLeft(2, '0')}";

                      final bool isMyMessage =
                          _isAdmin ? msg.role == 'admin' : msg.isMe;

                      final alignment = isMyMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft;
                      final bgColor =
                          isMyMessage ? Colors.brown[200] : Colors.grey[300];

                      return Align(
                        alignment: alignment,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isAdmin)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    msg.role == 'admin'
                                        ? 'You'
                                        : (msg.fullName.isNotEmpty
                                            ? msg.fullName
                                            : 'Customer'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.brown.shade700,
                                    ),
                                  ),
                                ),
                              if (msg.uploadImage != null)
                                GestureDetector(
                                  onTap: () => _openFullImage(msg.uploadImage!),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: msg.uploadImage!,
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 200,
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: LogoLoadingIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        width: 200,
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Text(msg.message),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formattedTime,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  if (isMyMessage) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      msg.isRead ? Icons.done_all : Icons.done,
                                      size: 14,
                                      color: msg.isRead
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black54,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SafeArea(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      border:
                          Border(top: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Row(
                      children: [
                        5.getWidthWhiteSpacing,
                        GestureDetector(
                          onTap: () => _pickImage(fromCamera: false),
                          child: const Icon(
                            IconsaxPlusLinear.image,
                            color: Color(0xff9D6E2D),
                          ),
                        ),
                        5.getWidthWhiteSpacing,
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: TextField(
                              controller: _messageCtrl,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) {
                                if (_messageCtrl.text.trim().isNotEmpty ||
                                    _selectedImage != null) {
                                  _sendMessage(imageFile: _selectedImage);
                                }
                              },
                              decoration: InputDecoration(
                                hintText: _isAdmin
                                    ? "Reply to customer..."
                                    : "Type a message",
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontFamily: 'poppins',
                                  fontStyle: FontStyle.italic,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: () => _pickImage(fromCamera: true),
                                  child: const Icon(
                                    IconsaxPlusLinear.camera,
                                    color: Color(0xff9D6E2D),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 10,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                        5.getWidthWhiteSpacing,
                        InkWell(
                          onTap: () => _sendMessage(imageFile: _selectedImage),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xff9D6E2D),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Delete loading overlay ──────────────────────────────────
          if (_isDeleting)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: LogoLoadingIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

void showCustomMenu({
  required BuildContext context,
  required Future<void> Function() onDelete,
  required String productId,
  required String userId,
  required bool isAdmin,
  required VoidCallback onViewProduct,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black26,
    builder: (context) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
          Positioned(
            top: 60,
            right: 10,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 150,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 233, 226, 226),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Delete Message
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 15,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete Messages',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Divider(
                      height: 1,
                      thickness: 0.8,
                      color: Colors.grey.shade400,
                    ),

                    /// View Product
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (!isAdmin) onViewProduct();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.remove_red_eye_outlined,
                              size: 15,
                              color: Color(0xff9D6E2D),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'View Product',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
