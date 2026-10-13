import 'package:flutter/material.dart';

class AppConstants {
  // Use your computer's local Wi-Fi IP so physical Android/iOS devices can reach Next.js!
  static const String defaultBaseUrl = "http://192.168.1.154:3000";
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
}

class AppColors {
  static const Color primary = Color(0xFFFF003C); // Official EMapandan Red
  static const Color background = Color(0xFF090D1A); // Deep Executive Dark
  static const Color surface = Color(0xFF111827); // Dark Slate Card
  static const Color surfaceElevated = Color(0xFF1E293B);
  static const Color border = Color(0xFF1F293D);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);
}
