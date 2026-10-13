import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/metric_cards_grid.dart';
import '../widgets/territorial_gis_map_card.dart';
import '../widgets/collections_ledger_card.dart';
import '../widgets/daily_request_card.dart';
import '../widgets/demographic_census_card.dart';
import '../widgets/civic_reports_card.dart';
import '../widgets/projects_infrastructure_card.dart';
import '../widgets/recent_announcements_card.dart';
import '../widgets/latest_news_card.dart';
import '../widgets/barangay_search_modal.dart';

class MayorDashboardScreen extends ConsumerWidget {
  const MayorDashboardScreen({super.key});

  void _openBarangaySelector(
    BuildContext context,
    WidgetRef ref,
    List<String> barangays,
    String selectedBarangay,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BarangaySearchModal(
          barangays: barangays,
          selectedBarangay: selectedBarangay,
          onSelect: (chosenBarangay) {
            ref.read(selectedBarangayProvider.notifier).state = chosenBarangay;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep active Supabase Realtime subscription alive for the lifetime of this screen
    ref.watch(residentRealtimeSubscriptionProvider);

    final dashboardAsync = ref.watch(mayorDashboardProvider);
    final selectedBarangay = ref.watch(selectedBarangayProvider);
    final settingsAsync = ref.watch(publicSettingsProvider);

    final logoUrl = settingsAsync.value?["siteLogo"] ?? kDefaultLogoUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        toolbarHeight: 52,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Image.network(
                    logoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.network(
                      kDefaultLogoUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900),
                children: const [
                  TextSpan(text: "E", style: TextStyle(color: Colors.white)),
                  TextSpan(text: "Mapandan", style: TextStyle(color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: AppColors.textSecondary, size: 18),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.red, size: 40),
                const SizedBox(height: 12),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () => ref.refresh(mayorDashboardProvider),
                  child: const Text("Retry", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final currentScopeLabel = selectedBarangay.isEmpty
              ? "All Barangays (Municipality Wide)"
              : "Brgy. $selectedBarangay";

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.refresh(mayorDashboardProvider),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Compact Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "EXECUTIVE OVERVIEW",
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          "Honorable Mayor",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Compact Searchable Barangay Selector
                InkWell(
                  onTap: () => _openBarangaySelector(
                    context,
                    ref,
                    data.barangays,
                    selectedBarangay,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "JURISDICTION",
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              currentScopeLabel,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Ultra Compact 4 Metric Cards (Residents, Jobs, Incidents, LGU Projects)
                MetricCardsGrid(counts: data.counts),
                const SizedBox(height: 14),

                // Territorial Landmarks & GIS Satellite Map
                TerritorialGisMapCard(places: data.mapPlaces),
                const SizedBox(height: 14),

                // 1. Collections Ledger Card (100% Web Parity)
                CollectionsLedgerCard(
                  revenue: data.revenue,
                  payments: data.payments,
                ),
                const SizedBox(height: 14),

                // 2. Daily Service Requests Card (100% Web Parity)
                DailyRequestCard(
                  transactions: data.transactions,
                  recentTransactions: data.recentTransactions,
                ),
                const SizedBox(height: 14),

                // 3. Demographic Census & Population Growth Card
                DemographicCensusCard(demographics: data.demographics),
                const SizedBox(height: 14),

                // 4. Civic Incident Reports & Public Safety Card
                CivicReportsCard(reports: data.recentReports),
                const SizedBox(height: 14),

                // 5. LGU Projects & Infrastructure Card
                ProjectsInfrastructureCard(
                  projects: data.activeProjects,
                ),
                const SizedBox(height: 14),

                // 6. Recent Announcements Card (100% Web Parity)
                RecentAnnouncementsCard(
                  announcements: data.announcements,
                ),
                const SizedBox(height: 14),

                // 7. Latest News Card (100% Web Parity)
                LatestNewsCard(
                  news: data.news,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
