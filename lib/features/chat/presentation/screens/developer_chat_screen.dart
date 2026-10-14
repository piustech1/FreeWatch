import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/avatar_item.dart';
import '../../../../shared/widgets/free_watch_top_app_bar.dart';
import '../../../auth/presentation/providers/user_avatar_provider.dart';
import '../../../home/providers/home_providers.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../domain/models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_wallpaper_painter.dart';
import '../../../../core/services/support_chat_notification_service.dart';

class DeveloperChatScreen extends ConsumerStatefulWidget {
  const DeveloperChatScreen({super.key});

  @override
  ConsumerState<DeveloperChatScreen> createState() => _DeveloperChatScreenState();
}

class _DeveloperChatScreenState extends ConsumerState<DeveloperChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  ChatMessage? _replyingTo;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    SupportChatNotificationService.isChatScreenVisible = true;
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
    });
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    SupportChatNotificationService.isChatScreenVisible = false;
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _setReply(ChatMessage message) {
    HapticFeedback.lightImpact();
    setState(() {
      _replyingTo = message;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final reply = _replyingTo;
    _textController.clear();
    setState(() {
      _replyingTo = null;
    });

    HapticFeedback.selectionClick();
    await ref.read(chatProvider.notifier).sendMessage(
          text: text,
          replyTo: reply,
        );

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom(animated: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final userAvatar = ref.watch(userAvatarProvider);
    final userProfile = ref.watch(userProfileProvider);

    // Scroll to bottom when new messages arrive
    ref.listen(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        Future.delayed(const Duration(milliseconds: 150), () {
          _scrollToBottom(animated: true);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Signature Persistent Top App Bar ──────────────────────
            FreeWatchTopAppBar(
              onSearchTap: () => navigateToBottomNavTab(context, ref, 1),
              onNotificationTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              onProfileTap: () => navigateToBottomNavTab(context, ref, 4),
            ),

            // ── iOS Liquid Frosted Glass Admin Subheader ──────────────
            _buildAdminGlassHeader(context),

            // ── Chat Body with Wallpaper Background ───────────────────
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(
                      painter: ChatWallpaperPainter(),
                    ),
                  ),
                  Column(
                    children: [
                      // Chat messages list
                      Expanded(
                        child: chatState.isLoading && chatState.messages.isEmpty
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                itemCount: chatState.messages.length,
                                itemBuilder: (context, index) {
                                  final msg = chatState.messages[index];
                                  final showDateHeader = index == 0 ||
                                      _isDifferentDay(
                                        msg.timestamp,
                                        chatState.messages[index - 1].timestamp,
                                      );

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (showDateHeader) _buildDateHeader(msg.timestamp),
                                      _buildSwipeableMessage(
                                        message: msg,
                                        userAvatar: userAvatar,
                                        userName: userProfile.name,
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),

                      // Active Reply Banner (when replying to a message)
                      if (_replyingTo != null) _buildReplyPreviewBanner(_replyingTo!),

                      // Floating Liquid Glass Input Dock
                      _buildInputBar(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── iOS Liquid Frosted Glass Admin Subheader ────────────────────────────────
  Widget _buildAdminGlassHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // iOS Frosted Glass Back Button (borderless)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Admin Avatar with glowing emerald online status badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withOpacity(0.30),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/admin_avatar.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF142E21),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.support_agent_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676).withOpacity(0.95),
                              blurRadius: 7,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Admin Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF38BDF8),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E676).withOpacity(0.9),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Active now • Developer Support',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Info Action Button (borderless)
                GestureDetector(
                  onTap: () => _showSupportInfo(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFCBD5E1),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Swipe-To-Reply Wrapper ──────────────────────────────────────────────────
  Widget _buildSwipeableMessage({
    required ChatMessage message,
    required AvatarItem userAvatar,
    required String userName,
  }) {
    final isUser = message.isFromUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Dismissible(
        key: ValueKey(message.id),
        direction: isUser ? DismissDirection.endToStart : DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          _setReply(message);
          return false; // Do not dismiss bubble from tree
        },
        background: _buildSwipeActionBackground(isUser),
        child: GestureDetector(
          onLongPress: () => _setReply(message),
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Admin Avatar (Left)
              if (!isUser) ...[
                _buildAdminSmallAvatar(),
                const SizedBox(width: 8),
              ],

              // Message Bubble with potential Quote Preview
              Flexible(
                child: _buildBubbleContent(message, isUser),
              ),

              // User Avatar (Right)
              if (isUser) ...[
                const SizedBox(width: 8),
                _buildUserSmallAvatar(userAvatar, userName),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeActionBackground(bool isUser) {
    return Container(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF00E676).withOpacity(0.18),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.reply_rounded,
          color: Color(0xFF00E676),
          size: 18,
        ),
      ),
    );
  }

  // ── Message Bubble Content (Liquid Frosted Glass) ───────────────────────────
  Widget _buildBubbleContent(ChatMessage message, bool isUser) {
    final timeStr = DateFormat('h:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(message.timestamp),
    );

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: Radius.circular(isUser ? 20 : 4),
        bottomRight: Radius.circular(isUser ? 4 : 20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 290),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            gradient: isUser
                ? const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.09),
                      Colors.white.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: isUser
                    ? const Color(0xFF059669).withOpacity(0.35)
                    : Colors.black.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Quoted message if this was a reply
              if (message.replyToText != null && message.replyToText!.isNotEmpty)
                _buildQuotedReplyBox(
                  senderName: message.replyToSender ?? 'Message',
                  text: message.replyToText!,
                  isUser: isUser,
                ),

              // Message Body
              SelectableText(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 5),

              // Timestamp & Status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white.withOpacity(0.80)
                          : const Color(0xFFCBD5E1).withOpacity(0.75),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (isUser) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all_rounded,
                      color: Colors.white.withOpacity(0.95),
                      size: 14,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quoted Box Inside Bubble ────────────────────────────────────────────────
  Widget _buildQuotedReplyBox({
    required String senderName,
    required String text,
    required bool isUser,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.black.withOpacity(0.22)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isUser ? const Color(0xFF34D399) : const Color(0xFF00E676),
            width: 3.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            style: TextStyle(
              color: isUser ? const Color(0xFFA7F3D0) : const Color(0xFF00E676),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── Admin Small Avatar ──────────────────────────────────────────────────────
  Widget _buildAdminSmallAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withOpacity(0.25),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/admin_avatar.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF142E21),
            alignment: Alignment.center,
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 16),
          ),
        ),
      ),
    );
  }

  // ── User Small Avatar ───────────────────────────────────────────────────────
  Widget _buildUserSmallAvatar(AvatarItem userAvatar, String userName) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: userAvatar.assetPath.endsWith('.svg')
            ? SvgPicture.asset(userAvatar.assetPath, fit: BoxFit.cover)
            : Image.asset(
                userAvatar.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF059669),
                  alignment: Alignment.center,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ── Reply Preview Banner (Above Input Field) ───────────────────────────────
  Widget _buildReplyPreviewBanner(ChatMessage replyingTo) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
          ),
          child: Row(
            children: [
              Container(
                width: 3.5,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.reply_rounded, color: Color(0xFF00E676), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Replying to ${replyingTo.senderName}',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      replyingTo.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
                onPressed: _cancelReply,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Floating Liquid Glass Input Dock ────────────────────────────────────────
  Widget _buildInputBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Text Input Box with borderless iOS frosted glass capsule
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ask developer anything...',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Glowing Circular Send Button
              GestureDetector(
                onTap: _hasText ? _sendMessage : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _hasText
                        ? const LinearGradient(
                            colors: [Color(0xFF00E676), Color(0xFF00B050)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.12),
                              Colors.white.withOpacity(0.06),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    boxShadow: _hasText
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E676).withOpacity(0.55),
                              blurRadius: 14,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : const [],
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: _hasText ? Colors.black : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Frosted Glass Date Header Widget ────────────────────────────────────────
  Widget _buildDateHeader(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    String formatted;

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      formatted = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      formatted = 'Yesterday';
    } else {
      formatted = DateFormat('MMM d, yyyy').format(date);
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              formatted,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isDifferentDay(int t1, int t2) {
    final d1 = DateTime.fromMillisecondsSinceEpoch(t1);
    final d2 = DateTime.fromMillisecondsSinceEpoch(t2);
    return d1.year != d2.year || d1.month != d2.month || d1.day != d2.day;
  }

  void _showSupportInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0D0F18).withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFF00E676), size: 22),
              SizedBox(width: 8),
              Text(
                'FreeWatch Developer Support',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Your direct line to the FreeWatch engineering team! Ask questions about movie availability, VJ requests, bug reports, or upcoming features. All messages are encrypted and synced directly.',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
