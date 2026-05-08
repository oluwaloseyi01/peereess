import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/model/adminchatmodel.dart';
import 'package:peereess/provider/adminchatlistprovider.dart';
import 'package:peereess/provider/adminchatprovider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class AdminChatScreen extends StatefulWidget {
  final String productId;
  final String productTitle;
  final String userId;
  final String userName;
  final String? imageUrl;
  final double? firstVariantPrice;

  const AdminChatScreen({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.userId,
    required this.userName,
    this.imageUrl,
    this.firstVariantPrice,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = context.read<AdminChatProvider>();
      final chatListProvider = context.read<AdminChatListProvider>();

      chatProvider.clear();

      await chatProvider.fetchMessages(
        productId: widget.productId,
        userId: widget.userId,
      );

      await chatListProvider.markChatAsRead(
        productId: widget.productId,
        userId: widget.userId,
      );

      if (mounted) setState(() {});
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage({File? imageFile}) {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty && imageFile == null) return;

    context.read<AdminChatProvider>().sendMessage(
          receiverId: widget.userId,
          productId: widget.productId,
          productTitle: widget.productTitle,
          message: text,
          imageFile: imageFile,
        );

    _messageCtrl.clear();
    setState(() => _selectedImage = null);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  /// uploadImage is now a full Cloudinary URL — pass it directly
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
            child: Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<AdminChatProvider>();
    final List<AdminChatModel> messages = chatProvider.messages;

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

            // ── Product / user avatar ──────────────────────────────
            if (widget.imageUrl != null)
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl!,
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(height: 40, width: 40, color: Colors.grey[300]),
                  errorWidget: (context, url, error) =>
                      const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                ),
              )
            else
              const CircleAvatar(radius: 20, child: Icon(Icons.person)),

            10.getWidthWhiteSpacing,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
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
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
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
        child: Column(
          children: [
            /// ── Messages ────────────────────────────────────────────
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

                  final isAdmin = msg.senderId == 'admin';
                  final alignment =
                      isAdmin ? Alignment.centerRight : Alignment.centerLeft;
                  final crossAxis = isAdmin
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start;
                  final bgColor =
                      isAdmin ? Colors.brown[200] : Colors.grey[300];

                  final time = msg.createdAt;
                  final formattedTime =
                      "${time.hour.toString().padLeft(2, '0')}:"
                      "${time.minute.toString().padLeft(2, '0')}";

                  return Align(
                    alignment: alignment,
                    child: Column(
                      crossAxisAlignment: crossAxis,
                      children: [
                        Container(
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
                              // ── Image or text ────────────────────
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
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
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

                              // ── Timestamp + sender + read tick ───
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
                                  const SizedBox(width: 4),
                                  Text(
                                    isAdmin ? 'Admin' : msg.senderName,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  if (isAdmin) ...[
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
                      ],
                    ),
                  );
                },
              ),
            ),

            /// ── Selected image preview ───────────────────────────────
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

            /// ── Input bar ────────────────────────────────────────────
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
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
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: "Type a message",
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
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.grey),
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
    );
  }
}
