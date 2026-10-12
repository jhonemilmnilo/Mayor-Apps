import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/dashboard_model.dart';

final selectedBarangayProvider = StateProvider<String>((ref) => "");

// Realtime Counter State for Residents (Starts with null until dashboard loads)
final realtimeResidentCountProvider = StateProvider<int?>((ref) => null);

// Signal to trigger subtle UI pulse animation on live update
final residentPulseTriggerProvider = StateProvider<int>((ref) => 0);

final mayorDashboardProvider = FutureProvider.autoDispose<MayorDashboardData>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final barangay = ref.watch(selectedBarangayProvider);

  final queryParams = <String, dynamic>{
    if (barangay.isNotEmpty) "barangay": barangay,
  };

  final response = await apiClient.dio.get(
    AppConstants.dashboardEndpoint,
    queryParameters: queryParams,
  );

  if (response.data["success"] == true) {
    final data = MayorDashboardData.fromJson(response.data["data"]);
    // Initialize realtime resident count with the API result
    ref.read(realtimeResidentCountProvider.notifier).state = data.counts.residents;
    return data;
  } else {
    throw Exception(response.data["error"] ?? "Failed to load dashboard data");
  }
});

// Realtime Stream Subscription Controller for Resident Table
final residentRealtimeSubscriptionProvider = Provider.autoDispose((ref) {
  final selectedBarangay = ref.watch(selectedBarangayProvider);
  final client = Supabase.instance.client;

  final channel = client
      .channel('public:Resident:changes')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'Resident',
        callback: (payload) {
          debugPrint("[REALTIME_RESIDENT_EVENT] ${payload.eventType}");

          final record = payload.newRecord;
          final oldRecord = payload.oldRecord;

          final newStatus = record['registrationStatus'];
          final oldStatus = oldRecord['registrationStatus'];
          final residentBarangay = (record['barangay'] ?? oldRecord['barangay'])?.toString() ?? "";

          // Check if event applies to currently selected barangay filter
          final matchesBarangay = selectedBarangay.isEmpty ||
              residentBarangay.toLowerCase() == selectedBarangay.toLowerCase();

          if (!matchesBarangay) return;

          final currentCount = ref.read(realtimeResidentCountProvider);
          if (currentCount == null) return;

          // 1. Newly approved resident: INSERT with APPROVED or UPDATE from PENDING to APPROVED
          if (payload.eventType == PostgresChangeEvent.insert) {
            if (newStatus == "APPROVED") {
              ref.read(realtimeResidentCountProvider.notifier).state = currentCount + 1;
              ref.read(residentPulseTriggerProvider.notifier).state++;
            }
          } else if (payload.eventType == PostgresChangeEvent.update) {
            if (oldStatus != "APPROVED" && newStatus == "APPROVED") {
              ref.read(realtimeResidentCountProvider.notifier).state = currentCount + 1;
              ref.read(residentPulseTriggerProvider.notifier).state++;
            } else if (oldStatus == "APPROVED" && (newStatus == "REJECTED" || newStatus == "DEACTIVATED")) {
              ref.read(realtimeResidentCountProvider.notifier).state = (currentCount - 1).clamp(0, 9999999);
              ref.read(residentPulseTriggerProvider.notifier).state++;
            }
          } else if (payload.eventType == PostgresChangeEvent.delete) {
            if (oldStatus == "APPROVED") {
              ref.read(realtimeResidentCountProvider.notifier).state = (currentCount - 1).clamp(0, 9999999);
              ref.read(residentPulseTriggerProvider.notifier).state++;
            }
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    debugPrint("[REALTIME_RESIDENT_UNSUBSCRIBE]");
    client.removeChannel(channel);
  });

  return channel;
});
