import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Clean, Fluid In-App Toast Notification
/// - Slides in smoothly from the left upon appearance
/// - Can be swiped down to dismiss immediately
/// - Auto-dismisses with a smooth exit slide animation if not swiped
/// - Floats with 100px bottom clearance to never collide with the FloatingNavBar
/// - 0% grey, 0% outline, 0% gradient, 0 emojis
/// - Pure solid emerald green (#10B981) or translucent liquid glass
class AppToast {
  static OverlayEntry? _currentEntry;
  static _ToastAnimationState? _currentState;

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2000),
    bool isSuccess = true,
  }) {
    // Strip emojis
    final cleanMessage = _stripEmojis(message).trim();
    if (cleanMessage.isEmpty) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay == null) return;

    // Clean up previous toast if still visible
    _dismissCurrent();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: cleanMessage,
        isSuccess: isSuccess,
        duration: duration,
        onDismissed: () {
          if (_currentEntry == entry) {
            _currentEntry = null;
            _currentState = null;
          }
          entry.remove();
        },
        onStateCreated: (state) {
          _currentState = state;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void _dismissCurrent() {
    try {
      _currentState?.dismiss();
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
    _currentState = null;
  }

  static String _stripEmojis(String text) {
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F1E0}-\u{1F1FF}]',
      unicode: true,
    );
    return text.replaceAll(emojiRegex, '').replaceAll('  ', ' ');
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final Duration duration;
  final VoidCallback onDismissed;
  final ValueChanged<_ToastAnimationState> onStateCreated;

  const _ToastWidget({
    required this.message,
    required this.isSuccess,
    required this.duration,
    required this.onDismissed,
    required this.onStateCreated,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

abstract class _ToastAnimationState {
  void dismiss();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin
    implements _ToastAnimationState {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  double _dragOffsetY = 0.0;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    // Initial entrance: slide in from left and fade in
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward().then((_) {
      if (mounted && !_isExiting) {
        _autoDismissTimer = Timer(widget.duration, _startAutoExit);
      }
    });
  }

  void _startAutoExit() {
    if (!mounted || _isExiting) return;
    _isExiting = true;
    _controller.duration = const Duration(milliseconds: 280);

    // Exit animation: smoothly slide down and fade out
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 1.2),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInCubic,
    ));

    _controller.forward(from: 0.0).then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dismiss() {
    _autoDismissTimer?.cancel();
    if (mounted && !_isExiting) {
      _isExiting = true;
      widget.onDismissed();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isExiting) return;
    if (details.delta.dy > 0 || _dragOffsetY > 0) {
      setState(() {
        _dragOffsetY = (_dragOffsetY + details.delta.dy).clamp(0.0, 200.0);
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isExiting) return;
    if (_dragOffsetY > 35 || details.velocity.pixelsPerSecond.dy > 200) {
      _autoDismissTimer?.cancel();
      _isExiting = true;
      _controller.duration = const Duration(milliseconds: 180);

      _slideAnimation = Tween<Offset>(
        begin: Offset(0.0, _dragOffsetY / 60.0),
        end: const Offset(0.0, 1.5),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ));

      _fadeAnimation = Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ));

      _controller.forward(from: 0.0).then((_) {
        if (mounted) widget.onDismissed();
      });
    } else {
      setState(() {
        _dragOffsetY = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100, // 100px bottom clearance to comfortably float above FloatingNavBar
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _dragOffsetY),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: child,
                  ),
                ),
              );
            },
            child: widget.isSuccess
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981), // Solid Emerald Green (0% grey, 0% outline, 0% gradient)
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14), // Pure translucent liquid glass (0% grey, 0% outline)
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.30),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
