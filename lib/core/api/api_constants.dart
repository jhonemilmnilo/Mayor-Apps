import 'package:flutter/material.dart';

class AppConstants {
  // Use your computer's local Wi-Fi IP so physical Android/iOS devices can reach Next.js!
  static const String defaultBaseUrl = "https://emapandan.vercel.app";
  static const String appKey = "agno-mobile-secret-2024";

  // Supabase Realtime Configuration
  static const String supabaseUrl = "https://kszhmyfpfcqbyezrgtvl.supabase.co";
  static const String supabaseAnonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtzemhteWZwZmNxYnllenJndHZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA4ODM4MjMsImV4cCI6MjEwNjQ1OTgyM30.MAaNM76X_xVKziYMllLzd3UBC5SjVNz1yp7bAD5FLOA";

  // Endpoints
  static const String loginEndpoint = "/api/mobile/auth/login";
  static const String dashboardEndpoint = "/api/mobile/mayor/dashboard";
  static const String barangaysEndpoint = "/api/mobile/mayor/barangays";
  static const String settingsEndpoint = "/api/mobile/public/settings";
  static const String paymentsEndpoint = "/api/mobile/mayor/payments";
  static const String requestsEndpoint = "/api/mobile/mayor/requests";
  static const String residentsEndpoint = "/api/mobile/mayor/residents";
  static const String reportsEndpoint = "/api/mobile/mayor/reports";
  static const String projectsEndpoint = "/api/mobile/mayor/projects";
  static const String announcementsEndpoint = "/api/mobile/mayor/announcements";
  static const String newsEndpoint = "/api/mobile/mayor/news";
  static const String eventsEndpoint = "/api/mobile/mayor/events";
  static const String hotlinesEndpoint = "/api/mobile/mayor/hotlines";
  static const String kainanEndpoint = "/api/mobile/mayor/kainan";
  static const String tuluyanEndpoint = "/api/mobile/mayor/tuluyan";
  static const String tourismEndpoint = "/api/mobile/mayor/tourism";
  static const String artaEndpoint = "/api/mobile/mayor/arta";
}

class AppColors {
  static const Color primary = Color(0xFFFF003C); // Official EMapandan Red

  // Dark Palette (Default)
  static const Color background = Color(0xFF090D1A); // Deep Executive Dark
  static const Color surface = Color(0xFF111827); // Dark Slate Card
  static const Color surfaceElevated = Color(0xFF1E293B);
  static const Color border = Color(0xFF1F293D);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);

  // Light Palette (Executive Light)
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Colors.white; // Pure White Card
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9); // Slate 100
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500

  // Shared Accents
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Dynamic Theme Helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getBackground(BuildContext context) =>
      isDark(context) ? background : lightBackground;

  static Color getSurface(BuildContext context) =>
      isDark(context) ? surface : lightSurface;

  static Color getSurfaceElevated(BuildContext context) =>
      isDark(context) ? surfaceElevated : lightSurfaceElevated;

  static Color getBorder(BuildContext context) =>
      isDark(context) ? border : lightBorder;

  static Color getTextPrimary(BuildContext context) =>
      isDark(context) ? textPrimary : lightTextPrimary;

  static Color getTextSecondary(BuildContext context) =>
      isDark(context) ? textSecondary : lightTextSecondary;

  static List<BoxShadow> getCardShadow(BuildContext context) {
    if (isDark(context)) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.02),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];
    }
  }
}
