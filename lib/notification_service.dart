// ================= FILE 11: notification_service.dart =================
import 'package:flutter/material.dart';

class NotificationService {
  // इन-ऐप स्नैकबार या बैनर अलर्ट दिखाने के लिए यूटिलिटी
  static void showAppAlert(BuildContext context, String title, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                  Text(message, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade800 : const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isError ? Colors.red : const Color(0xFFF59E0B), width: 1),
        ),
      ),
    );
  }
}
