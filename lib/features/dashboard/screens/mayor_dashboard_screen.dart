import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mayor_apps/core/api/api_constants.dart';
import 'package:mayor_apps/core/theme/theme_provider.dart';
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
import '../widgets/recent_events_card.dart';
import '../widgets/administrative_services_card.dart';
import '../widgets/department_compliance_leaderboard_card.dart';
import '../widgets/statutory_processing_speed_card.dart';
import '../widgets/urgent_attention_card.dart';
import '../widgets/activity_logs_card.dart';
import '../widgets/staff_audit_logs_card.dart';
import '../widgets/barangay_search_modal.dart';
import '../widgets/mayor_dashboard_drawer.dart';

class MayorDashboardScreen extends ConsumerStatefulWidget {
  const MayorDashboardScreen({super.key});

  @override
  ConsumerState<MayorDashboardScreen> createState() => _MayorDashboardScreenState();
}

class _MayorDashboardScreenState extends ConsumerState<MayorDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  String? _activeSectionId;

  // GlobalKeys for each dashboard section
  final GlobalKey _executiveOverviewKey = GlobalKey();
  final GlobalKey _keyMetricsKey = GlobalKey();
  final GlobalKey _gisMapKey = GlobalKey();
  final GlobalKey _adminServicesKey = GlobalKey();
  final GlobalKey _complianceLeaderboardKey = GlobalKey();
  final GlobalKey _processingSpeedKey = GlobalKey();
  final GlobalKey _urgentAttentionKey = GlobalKey();
  final GlobalKey _activityLogsKey = GlobalKey();
  final GlobalKey _staffAuditLogsKey = GlobalKey();
  final GlobalKey _collectionsLedgerKey = GlobalKey();
  final GlobalKey _dailyRequestsKey = GlobalKey();
  final GlobalKey _demographicsKey = GlobalKey();
  final GlobalKey _civicReportsKey = GlobalKey();
  final GlobalKey _projectsKey = GlobalKey();
  final GlobalKey _announcementsKey = GlobalKey();
  final GlobalKey _newsKey = GlobalKey();
  final GlobalKey _eventsKey = GlobalKey();

  late final List<DashboardSectionItem> _sections;

  @override
  void initState() {
    super.initState();
    _sections = [
      DashboardSectionItem(
        id: 'overview',
        title: 'Executive Overview',
        subtitle: 'Jurisdiction & greetings',
        icon: LucideIcons.layoutGrid,
        color: AppColors.primary,
        key: _executiveOverviewKey,
      ),
      DashboardSectionItem(
        id: 'metrics',
        title: 'Key Operational Metrics',
        subtitle: 'Residents, jobs, incidents',
        icon: LucideIcons.barChart2,
        color: const Color(0xFF0EA5E9),
        key: _keyMetricsKey,
      ),
      DashboardSectionItem(
        id: 'gis_map',
        title: 'GIS Satellite & Landmarks',
        subtitle: 'Territorial infrastructure map',
        icon: LucideIcons.mapPin,
        color: const Color(0xFF10B981),
        key: _gisMapKey,
      ),
      DashboardSectionItem(
        id: 'admin_services',
        title: 'Administrative Services',
        subtitle: 'ARTA, dining, accommodations',
        icon: LucideIcons.building2,
        color: const Color(0xFF8B5CF6),
        key: _adminServicesKey,
      ),
      DashboardSectionItem(
        id: 'compliance',
        title: 'ARTA Compliance Board',
        subtitle: 'Department SLA adherence',
        icon: LucideIcons.award,
        color: const Color(0xFFF59E0B),
        key: _complianceLeaderboardKey,
      ),
      DashboardSectionItem(
        id: 'speed',
        title: 'Processing Speed',
        subtitle: 'Working days vs RA 11032',
        icon: LucideIcons.zap,
        color: const Color(0xFF06B6D4),
        key: _processingSpeedKey,
      ),
      DashboardSectionItem(
        id: 'urgent',
        title: 'Urgent Statutory Clock',
        subtitle: 'Overdue escalations & SLA risks',
        icon: LucideIcons.alertTriangle,
        color: const Color(0xFFEF4444),
        key: _urgentAttentionKey,
      ),
      DashboardSectionItem(
        id: 'activity_logs',
        title: 'Resident Activity Stream',
        subtitle: 'Live analytics & citizen queries',
        icon: LucideIcons.activity,
        color: const Color(0xFF10B981),
        key: _activityLogsKey,
      ),
      DashboardSectionItem(
        id: 'staff_logs',
        title: 'Staff Operational Audits',
        subtitle: 'Employee action log trace',
        icon: LucideIcons.shieldCheck,
        color: const Color(0xFF6366F1),
        key: _staffAuditLogsKey,
      ),
      DashboardSectionItem(
        id: 'collections',
        title: 'Collections Ledger',
        subtitle: 'Revenue, cash & e-wallets',
        icon: LucideIcons.receipt,
        color: const Color(0xFF10B981),
        key: _collectionsLedgerKey,
      ),
      DashboardSectionItem(
        id: 'requests',
        title: 'Daily Service Requests',
        subtitle: 'Civil registry & permits',
        icon: LucideIcons.fileCheck2,
        color: const Color(0xFFF59E0B),
        key: _dailyRequestsKey,
      ),
      DashboardSectionItem(
        id: 'demographics',
        title: 'Demographic Census',
        subtitle: 'Population stats & growth',
        icon: LucideIcons.users,
        color: const Color(0xFF3B82F6),
        key: _demographicsKey,
      ),
      DashboardSectionItem(
        id: 'reports',
        title: 'Civic Reports & Incidents',
        subtitle: 'Public grievances & inspection',
        icon: LucideIcons.messageSquareWarning,
        color: const Color(0xFFEF4444),
        key: _civicReportsKey,
      ),
      DashboardSectionItem(
        id: 'projects',
        title: 'LGU Infrastructure Projects',
        subtitle: 'Budget status & milestones',
        icon: LucideIcons.hardHat,
        color: const Color(0xFFF97316),
        key: _projectsKey,
      ),
      DashboardSectionItem(
        id: 'announcements',
        title: 'Announcements Board',
        subtitle: 'Official municipal releases',
        icon: LucideIcons.megaphone,
        color: const Color(0xFFEC4899),
        key: _announcementsKey,
      ),
      DashboardSectionItem(
        id: 'news',
        title: 'Municipal News & Press',
        subtitle: 'Verified local updates',
        icon: LucideIcons.newspaper,
        color: const Color(0xFF0EA5E9),
        key: _newsKey,
      ),
      DashboardSectionItem(
        id: 'events',
        title: 'Calendar of Events',
        subtitle: 'Civic celebrations & hearings',
        icon: LucideIcons.calendar,
        color: const Color(0xFF8B5CF6),
        key: _eventsKey,
      ),
    ];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(DashboardSectionItem section) {
    setState(() {
      _activeSectionId = section.id;
    });

    // Close the drawer smoothly
    Navigator.of(context).pop();

    Future.delayed(const Duration(milliseconds: 220), () {
      final targetContext = section.key.currentContext;
      if (targetContext != null && targetContext.mounted) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
          alignment: 0.04, // Clean breathing room below AppBar
        );
      }
    });
  }

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
  Widget build(BuildContext context) {
    // Keep active Supabase Realtime subscription alive for the lifetime of this screen
    ref.watch(residentRealtimeSubscriptionProvider);

    final dashboardAsync = ref.watch(mayorDashboardProvider);
    final selectedBarangay = ref.watch(selectedBarangayProvider);
    final settingsAsync = ref.watch(publicSettingsProvider);

    final logoUrl = settingsAsync.value?["siteLogo"] ?? kDefaultLogoUrl;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.getBackground(context),
      // Left Sidebar Drawer
      drawer: MayorDashboardDrawer(
        sections: _sections,
        activeSectionId: _activeSectionId,
        onSectionSelected: _scrollToSection,
        onLogout: () => ref.read(authProvider.notifier).logout(),
      ),
      appBar: AppBar(
        titleSpacing: 0,
        toolbarHeight: 52,
        leading: IconButton(
          tooltip: "Sections Menu",
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.getBorder(context), width: 1),
            ),
            child: const Icon(
              LucideIcons.menu,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.getSurface(context),
                border: Border.all(color: AppColors.getBorder(context), width: 1.2),
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
                children: [
                  TextSpan(
                    text: "E",
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const TextSpan(text: "Mapandan", style: TextStyle(color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Light / Dark Mode Toggle
          IconButton(
            tooltip: AppColors.isDark(context) ? "Switch to Light Mode" : "Switch to Dark Mode",
            icon: Icon(
              AppColors.isDark(context) ? LucideIcons.sunMedium : LucideIcons.moon,
              color: AppColors.getTextSecondary(context),
              size: 19,
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          const SizedBox(width: 4),
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
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // 1. Compact Header Row & Overview
                Container(
                  key: _executiveOverviewKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                  color: AppColors.getTextPrimary(context),
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
                            color: AppColors.getSurface(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.getBorder(context)),
                            boxShadow: AppColors.getCardShadow(context),
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
                                      color: AppColors.getTextSecondary(context),
                                    ),
                                  ),
                                  Text(
                                    currentScopeLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                              Icon(LucideIcons.chevronDown, size: 16, color: AppColors.getTextSecondary(context)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Ultra Compact 4 Metric Cards (Residents, Jobs, Incidents, LGU Projects)
                Container(
                  key: _keyMetricsKey,
                  child: MetricCardsGrid(counts: data.counts),
                ),
                const SizedBox(height: 14),

                // 3. Territorial Landmarks & GIS Satellite Map
                Container(
                  key: _gisMapKey,
                  child: TerritorialGisMapCard(places: data.mapPlaces),
                ),
                const SizedBox(height: 14),

                // 4. Administrative Services Card (ARTA, Dining, Tourism, Accommodations)
                Container(
                  key: _adminServicesKey,
                  child: AdministrativeServicesCard(
                    adminServices: data.adminServices,
                    selectedBarangay: selectedBarangay,
                  ),
                ),
                const SizedBox(height: 14),

                // 5. Department Compliance Leaderboard (RA 11032 Anti-Red Tape SLA)
                Container(
                  key: _complianceLeaderboardKey,
                  child: DepartmentComplianceLeaderboardCard(
                    leaderboard: data.departmentLeaderboard,
                  ),
                ),
                const SizedBox(height: 14),

                // 6. Statutory Processing Speed (Average Working Days vs RA 11032 Ceilings)
                Container(
                  key: _processingSpeedKey,
                  child: StatutoryProcessingSpeedCard(
                    processingSpeed: data.processingSpeed,
                  ),
                ),
                const SizedBox(height: 14),

                // 7. Urgent Attention (RA 11032 Statutory Clock Breaches)
                Container(
                  key: _urgentAttentionKey,
                  child: UrgentAttentionCard(
                    overdueRequests: data.overdueRequests,
                  ),
                ),
                const SizedBox(height: 14),

                // 8. Real-Time Activity Logs Card (Resident Analytics Stream)
                Container(
                  key: _activityLogsKey,
                  child: ActivityLogsCard(
                    activityLogs: data.activityLogs,
                    selectedBarangay: selectedBarangay,
                  ),
                ),
                const SizedBox(height: 14),

                // 9. Staff Operational Audit Logs Card (100% Web Parity)
                Container(
                  key: _staffAuditLogsKey,
                  child: StaffAuditLogsCard(
                    staffLogs: data.staffLogs,
                    selectedBarangay: selectedBarangay,
                  ),
                ),
                const SizedBox(height: 14),

                // 10. Collections Ledger Card (100% Web Parity)
                Container(
                  key: _collectionsLedgerKey,
                  child: CollectionsLedgerCard(
                    revenue: data.revenue,
                    payments: data.payments,
                  ),
                ),
                const SizedBox(height: 14),

                // 11. Daily Service Requests Card (100% Web Parity)
                Container(
                  key: _dailyRequestsKey,
                  child: DailyRequestCard(
                    transactions: data.transactions,
                    recentTransactions: data.recentTransactions,
                  ),
                ),
                const SizedBox(height: 14),

                // 12. Demographic Census & Population Growth Card
                Container(
                  key: _demographicsKey,
                  child: DemographicCensusCard(demographics: data.demographics),
                ),
                const SizedBox(height: 14),

                // 13. Civic Incident Reports & Public Safety Card
                Container(
                  key: _civicReportsKey,
                  child: CivicReportsCard(reports: data.recentReports),
                ),
                const SizedBox(height: 14),

                // 14. LGU Projects & Infrastructure Card
                Container(
                  key: _projectsKey,
                  child: ProjectsInfrastructureCard(
                    projects: data.activeProjects,
                  ),
                ),
                const SizedBox(height: 14),

                // 15. Recent Announcements Card (100% Web Parity)
                Container(
                  key: _announcementsKey,
                  child: RecentAnnouncementsCard(
                    announcements: data.announcements,
                  ),
                ),
                const SizedBox(height: 14),

                // 16. Latest News Card (100% Web Parity)
                Container(
                  key: _newsKey,
                  child: LatestNewsCard(
                    news: data.news,
                  ),
                ),
                const SizedBox(height: 14),

                // 17. Recent & Upcoming Events Card (100% Web Parity)
                Container(
                  key: _eventsKey,
                  child: RecentEventsCard(
                    upcomingEvents: data.upcomingEvents,
                    pastEvents: data.pastEvents,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    ),
  );
  }
}
