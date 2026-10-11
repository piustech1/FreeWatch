import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/avatar_item.dart';
import '../../../auth/presentation/providers/user_avatar_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../domain/models/chat_message.dart';
import '../providers/chat_provider.dart';

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
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Chat messages list
            Expanded(
              child: chatState.isLoading && chatState.messages.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
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

            // Bottom Input Bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── Top App Bar ─────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0D0F18).withOpacity(0.95),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Admin Avatar with glowing online status badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.6),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/admin_avatar.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFF1E2230),
                      child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0D0F18), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.8),
                        blurRadius: 6,
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
                    SizedBox(width: 4),
                    Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF38BDF8),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Online • FreeWatch Developer Support',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Developer Info',
          icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8), size: 22),
          onPressed: () => _showSupportInfo(context),
        ),
        const SizedBox(width: 6),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: Colors.white.withOpacity(0.06),
          height: 1,
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
          color: const Color(0xFF8B5CF6).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.reply_rounded,
          color: Color(0xFFA78BFA),
          size: 18,
        ),
      ),
    );
  }

  // ── Message Bubble Content ──────────────────────────────────────────────────
  Widget _buildBubbleContent(ChatMessage message, bool isUser) {
    final timeStr = DateFormat('h:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(message.timestamp),
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 290),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isUser ? null : const Color(0xFF1E2230),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border: Border.all(
          color: isUser
              ? Colors.white.withOpacity(0.18)
              : Colors.white.withOpacity(0.08),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isUser
                ? const Color(0xFF7C3AED).withOpacity(0.25)
                : Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
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

          const SizedBox(height: 4),

          // Timestamp & Status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  color: isUser ? Colors.white.withOpacity(0.7) : const Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.done_all_rounded,
                  color: Colors.white.withOpacity(0.85),
                  size: 13,
                ),
              ],
            ],
          ),
        ],
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
            ? Colors.black.withOpacity(0.2)
            : const Color(0xFF131722).withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isUser ? Colors.white.withOpacity(0.9) : const Color(0xFF8B5CF6),
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
              color: isUser ? const Color(0xFFF3E8FF) : const Color(0xFFA78BFA),
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
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5), width: 1.2),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/admin_avatar.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFF1E2230),
            child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 16),
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5), width: 1.2),
      ),
      child: ClipOval(
        child: userAvatar.assetPath.endsWith('.svg')
            ? SvgPicture.asset(userAvatar.assetPath, fit: BoxFit.cover)
            : Image.asset(
                userAvatar.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF6D28D9),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161925),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.reply_rounded, color: Color(0xFFA78BFA), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${replyingTo.senderName}',
                  style: const TextStyle(
                    color: Color(0xFFA78BFA),
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
    );
  }

  // ── Bottom Input Bar ────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F18),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Text Input Box
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D2B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.8,
                ),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask developer anything...',
                  hintStyle: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send Button
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
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [
                          Color(0xFF2A2E3D),
                          Color(0xFF1E2230),
                        ],
                      ),
                boxShadow: _hasText
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : const [],
              ),
              child: Icon(
                Icons.send_rounded,
                color: _hasText ? Colors.white : const Color(0xFF64748B),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Date Header Widget ──────────────────────────────────────────────────────
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2230).withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.8),
        ),
        child: Text(
          formatted,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF131722),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.8),
          ),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFF8B5CF6), size: 22),
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
              child: const Text('Got it', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
