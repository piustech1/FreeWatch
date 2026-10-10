import 'dart:ui';
import 'package:flutter/material.dart';

/// Clean In-App Toast Notification
/// - Floats with 100px clearance above screen bottom to completely avoid colliding with FloatingNavBar
/// - 0% grey background, 0% gradient, 0% outline, 0 emojis
/// - Pure solid green (#10B981) for success/action feedback or pure translucent liquid glass
class AppToast {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 1800),
    bool isSuccess = true,
  }) {
    // Strip any emoji characters that might be passed in strings
    final cleanMessage = _stripEmojis(message).trim();

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: isSuccess
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
                  cleanMessage,
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
                      cleanMessage,
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
    );
  }

  static String _stripEmojis(String text) {
    // Regex matching unicode emoji ranges
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F1E0}-\u{1F1FF}]',
      unicode: true,
    );
    return text.replaceAll(emojiRegex, '').replaceAll('  ', ' ');
  }
}
