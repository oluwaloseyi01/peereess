import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/model/supportchat_model.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/supportchat_provider.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class SupportChatScreen extends StatefulWidget {
  final String supportId;
  final String userId;
  final String userName;
  final String role; // admin | user | seller

  const SupportChatScreen({
    super.key,
    required this.supportId,
    required this.userId,
    required this.userName,
    required this.role,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isDisposed = false;
  bool _humanRequested = false;

  // ✅ Fallback poll timer — catches AI reply if realtime misses it
  Timer? _aiPollTimer;

  late VoidCallback _chatListener;
  late SupportChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();

    _chatProvider = context.read<SupportChatProvider>();

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

      // 1️⃣ Open chat — sets up realtime subscription + triggers AI greeting
      await _chatProvider.openChat(
        supportId: widget.supportId,
        userId: widget.userId,
        userName: widget.userName,
        isAdmin: widget.role == 'admin',
      );

      if (_isDisposed) return;

      await _chatProvider.markMessagesAsReadForSupport(
        widget.supportId,
        isAdmin: widget.role == 'admin',
      );

      _scrollToBottom();

      // 2️⃣ For users: poll once after 4s and once after 8s to catch the
      //    AI greeting/reply in case the realtime event was missed.
      //    These are no-ops if realtime already delivered the message.
      if (widget.role != 'admin') {
        _aiPollTimer = Timer(const Duration(seconds: 4), () async {
          if (_isDisposed) return;
          await _chatProvider.fetchMessages(
            supportId: widget.supportId,
            userId: widget.userId,
          );
          _scrollToBottom();

          // Second poll at 8s for slower Gemini responses
          _aiPollTimer = Timer(const Duration(seconds: 4), () async {
            if (_isDisposed) return;
            await _chatProvider.fetchMessages(
              supportId: widget.supportId,
              userId: widget.userId,
            );
            _scrollToBottom();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _aiPollTimer?.cancel();
    _chatProvider.removeListener(_chatListener);
    _chatProvider.closeChat(isAdmin: widget.role == 'admin');
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Add this helper at the top of _SupportChatScreenState:
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(date.year, date.month, date.day);

    if (msgDay == today) return 'Today';
    if (msgDay == yesterday) return 'Yesterday';

    // e.g. "Mon, 12 Jun 2025"
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _sendMessage({File? imageFile}) async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty && imageFile == null) return;

    final senderId = widget.role == 'admin' ? 'admin' : widget.userId;

    _messageCtrl.clear();
    setState(() => _selectedImage = null);
    _scrollToBottom();

    await context.read<SupportChatProvider>().sendMessage(
          supportId: widget.supportId,
          userId: widget.userId,
          senderId: senderId,
          senderName: widget.userName,
          role: widget.role,
          message: text,
          imageFile: imageFile,
          isFromUser: widget.role != 'admin',
        );

    if (_isDisposed) return;

    _messageCtrl.clear();
    setState(() => _selectedImage = null);
    _scrollToBottom();

    // 3️⃣ After user sends, poll for AI reply at 4s and 8s as fallback
    if (widget.role != 'admin') {
      _aiPollTimer?.cancel();
      _aiPollTimer = Timer(const Duration(seconds: 4), () async {
        if (_isDisposed) return;
        await _chatProvider.fetchMessages(
          supportId: widget.supportId,
          userId: widget.userId,
        );
        _scrollToBottom();

        _aiPollTimer = Timer(const Duration(seconds: 4), () async {
          if (_isDisposed) return;
          await _chatProvider.fetchMessages(
            supportId: widget.supportId,
            userId: widget.userId,
          );
          _scrollToBottom();
        });
      });
    }
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
      if (!fromCamera) {
        final LostDataResponse response = await _picker.retrieveLostData();
        if (response.file != null && mounted) {
          setState(() => _selectedImage = File(response.file!.path));
          return;
        }
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null && mounted) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
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

  Future<void> _onRequestHumanAgent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Talk to an agent?',
          style: TextStyle(fontFamily: 'poppins', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This will connect you with a customer support agent',
          style: TextStyle(fontFamily: 'poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff9D6E2D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Connect Me',
              style: TextStyle(color: Colors.white, fontFamily: 'poppins'),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && !_isDisposed) {
      await context.read<SupportChatProvider>().requestHumanAgent(
            supportId: widget.supportId,
            userId: widget.userId,
            userName: widget.userName,
          );
      if (!_isDisposed) setState(() => _humanRequested = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<SupportChatProvider>();
    final List<SupportChatModel> messages = chatProvider.messages;
    final isAdmin = widget.role == 'admin';
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
        child: Center(child: LogoLoadingIndicator()),
      );
    }

    final bool isOtherTyping = chatProvider.getIsOtherTyping(isAdmin: isAdmin);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(5),
          child: Container(color: Colors.grey, height: 0.5),
        ),
        title: Row(
          children: [
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
            10.getWidthWhiteSpacing,
            Expanded(
              child: Row(
                children: [
                  Text(
                    isAdmin ? widget.userName : 'Support Center',
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  10.getWidthWhiteSpacing,
                  Container(
                    height: 8,
                    width: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
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
            /// ── Messages ──────────────────────────────────────────────
            Expanded(
              child: Builder(
                builder: (context) {
                  // Build a flat list of items: either a date-header String or a SupportChatModel
                  final List<dynamic> items = [];
                  String? lastDateKey;

                  for (final msg in messages) {
                    final msgDay = DateTime(
                      msg.createdAt.year,
                      msg.createdAt.month,
                      msg.createdAt.day,
                    );
                    final dateKey = msgDay.toIso8601String();

                    if (dateKey != lastDateKey) {
                      items.add(msgDay); // date header
                      lastDateKey = dateKey;
                    }
                    items.add(msg);
                  }

                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      // ── Date header ──────────────────────────────────────
                      if (item is DateTime) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatDateHeader(item),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                fontFamily: 'poppins',
                              ),
                            ),
                          ),
                        );
                      }

                      // ── Message bubble ────────────────────────────────────
                      final msg = item as SupportChatModel;
                      final formattedTime =
                          '${msg.createdAt.hour.toString().padLeft(2, '0')}:'
                          '${msg.createdAt.minute.toString().padLeft(2, '0')}';

                      final isFromCurrentUser = (isAdmin && !msg.isFromUser) ||
                          (!isAdmin && msg.isFromUser);

                      return Align(
                        alignment: isFromCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isFromCurrentUser
                                ? Colors.brown[200]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (msg.imageFileId != null)
                                GestureDetector(
                                  onTap: () => _openFullImage(msg.imageFileId!),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: msg.imageFileId!,
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
                                Text(
                                  msg.message,
                                  style: const TextStyle(fontSize: 14),
                                ),
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
                                  const SizedBox(width: 4),
                                  if (isFromCurrentUser)
                                    Icon(
                                      msg.isRead ? Icons.done_all : Icons.done,
                                      size: 14,
                                      color: msg.isRead
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            /// ── Typing bubble ──────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isOtherTyping
                  ? Align(
                      key: const ValueKey('bubble'),
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          bottom: 6,
                          top: 2,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _TypingDot(delay: 0),
                              SizedBox(width: 4),
                              _TypingDot(delay: 180),
                              SizedBox(width: 4),
                              _TypingDot(delay: 360),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-bubble')),
            ),

            /// ── Selected image preview ─────────────────────────────────
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

            /// ── Input bar ─────────────────────────────────────────────
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
                          onChanged: (value) {
                            context.read<SupportChatProvider>().onTypingChanged(
                                  value,
                                );
                          },
                          onSubmitted: (_) {
                            if (_messageCtrl.text.trim().isNotEmpty &&
                                _selectedImage == null) {
                              _sendMessage();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Type a message',
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

// ─────────────────────────────────────────────
// ANIMATED TYPING DOT
// ─────────────────────────────────────────────
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey[600],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
