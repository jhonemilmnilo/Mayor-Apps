import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mayor_apps/core/api/api_constants.dart';

class DashboardSectionItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final GlobalKey key;

  DashboardSectionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.key,
  });
}

class MayorDashboardDrawer extends StatefulWidget {
  final List<DashboardSectionItem> sections;
  final String? activeSectionId;
  final void Function(DashboardSectionItem section) onSectionSelected;
  final VoidCallback onLogout;

  const MayorDashboardDrawer({
    super.key,
    required this.sections,
    required this.activeSectionId,
    required this.onSectionSelected,
    required this.onLogout,
  });

  @override
  State<MayorDashboardDrawer> createState() => _MayorDashboardDrawerState();
}

class _MayorDashboardDrawerState extends State<MayorDashboardDrawer> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _drawerScrollController = ScrollController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveSection();
    });
  }

  @override
  void didUpdateWidget(covariant MayorDashboardDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeSectionId != widget.activeSectionId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveSection();
      });
    }
  }

  void _scrollToActiveSection() {
    if (widget.activeSectionId == null || !_drawerScrollController.hasClients) {
      return;
    }
    final index = widget.sections.indexWhere(
      (s) => s.id == widget.activeSectionId,
    );
    if (index != -1) {
      // Approximate height of each item (padding 20 + content ~38 + separator 4 = ~62px)
      const itemHeight = 62.0;
      final viewportHeight = _drawerScrollController.position.viewportDimension;
      final targetScroll =
          (index * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
      final clampedScroll = targetScroll.clamp(
        0.0,
        _drawerScrollController.position.maxScrollExtent,
      );

      _drawerScrollController.animateTo(
        clampedScroll,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _drawerScrollController.dispose();
    super.dispose();
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.logOut,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Sign Out",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to end your executive session and log out?",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.getTextSecondary(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close drawer
              widget.onLogout();
            },
            child: Text(
              "Logout",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    // Filter sections based on title or subtitle query
    final query = _searchQuery.trim().toLowerCase();
    final filteredSections = query.isEmpty
        ? widget.sections
        : widget.sections.where((item) {
            return item.title.toLowerCase().contains(query) ||
                item.subtitle.toLowerCase().contains(query);
          }).toList();

    return Drawer(
      backgroundColor: AppColors.getBackground(context),
      elevation: 16,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Executive Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.getBorder(context),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.layoutDashboard,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "EXECUTIVE DIRECTORY",
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          "Dashboard Sections",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: "Close",
                    icon: Icon(
                      LucideIcons.x,
                      size: 20,
                      color: AppColors.getTextSecondary(context),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Executive Instant Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: _searchQuery.isNotEmpty
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : AppColors.getBorder(context),
                    width: _searchQuery.isNotEmpty ? 1.4 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.03,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.getTextPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search sections (e.g. Events, ARTA)...",
                    hintStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.getTextSecondary(
                        context,
                      ).withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 14),
                            color: AppColors.getTextSecondary(context),
                            splashRadius: 16,
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${filteredSections.length} matching sections",
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 4),

            // Scrollable List of Sections (Filtered or Full)
            Expanded(
              child: filteredSections.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.getSurface(context),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.getBorder(context),
                                ),
                              ),
                              child: Icon(
                                LucideIcons.searchX,
                                size: 28,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No matching section found",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Try searching for keywords like 'Events', 'ARTA', 'Ledger', or 'Census'",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _drawerScrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: filteredSections.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final section = filteredSections[index];
                        final isSelected = section.id == widget.activeSectionId;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => widget.onSectionSelected(section),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? section.color.withValues(
                                        alpha: isDark ? 0.2 : 0.12,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? section.color.withValues(alpha: 0.45)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: section.color.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Icon(
                                      section.icon,
                                      size: 17,
                                      color: section.color,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          section.title,
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            fontWeight: isSelected
                                                ? FontWeight.w900
                                                : FontWeight.w700,
                                            color: isSelected
                                                ? section.color
                                                : AppColors.getTextPrimary(
                                                    context,
                                                  ),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          section.subtitle,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: AppColors.getTextSecondary(
                                              context,
                                            ),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: section.color,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "ACTIVE",
                                        style: GoogleFonts.inter(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    )
                                  else
                                    Icon(
                                      LucideIcons.chevronRight,
                                      size: 14,
                                      color: AppColors.getTextSecondary(
                                        context,
                                      ).withValues(alpha: 0.5),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Divider
            Divider(height: 1, color: AppColors.getBorder(context)),

            // Sleek Logout Button at the Bottom
            Container(
              padding: const EdgeInsets.all(14),
              color: AppColors.getSurface(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _confirmLogout(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFEF4444,
                          ).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.logOut,
                              size: 17,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Sign Out",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFEF4444),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.shieldCheck,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Office of the Municipal Mayor • EMapandan",
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          color: AppColors.getTextSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}
