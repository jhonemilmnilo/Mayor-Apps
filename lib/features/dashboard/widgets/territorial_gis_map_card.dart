import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../models/dashboard_model.dart';
import 'mapandan_boundary.dart';

class TerritorialGisMapCard extends StatefulWidget {
  final List<MapPlaceItem> places;

  const TerritorialGisMapCard({
    super.key,
    required this.places,
  });

  @override
  State<TerritorialGisMapCard> createState() => _TerritorialGisMapCardState();
}

class _TerritorialGisMapCardState extends State<TerritorialGisMapCard> {
  // Center of Mapandan, Pangasinan
  static final LatLng _mapandanCenter = LatLng(16.0260, 120.4505);

  late final MapController _mapController;
  MapPlaceItem? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  // 100% Exact match to Web Map (components/maps/MapandanMap.tsx)
  _CategoryConfig _getCategoryConfig(String category) {
    switch (category) {
      case "MUNICIPAL_FACILITY":
        return _CategoryConfig(
          pinColor: const Color(0xFF2563EB),
          icon: LucideIcons.building2,
          label: "Municipal Facility",
        );
      case "PUBLIC_MARKET":
        return _CategoryConfig(
          pinColor: const Color(0xFFD97706),
          icon: LucideIcons.shoppingBag,
          label: "Public Market",
        );
      case "HEALTH_CENTER":
        return _CategoryConfig(
          pinColor: const Color(0xFF059669),
          icon: LucideIcons.heartPulse,
          label: "Rural Health Unit / Clinic",
        );
      case "POLICE_STATION":
        return _CategoryConfig(
          pinColor: const Color(0xFF4F46E5),
          icon: LucideIcons.shieldAlert,
          label: "PNP / Police Station",
        );
      case "FIRE_STATION":
        return _CategoryConfig(
          pinColor: const Color(0xFFDC2626),
          icon: LucideIcons.flame,
          label: "BFP / Fire Station",
        );
      case "RESCUE_MDRRMO":
        return _CategoryConfig(
          pinColor: const Color(0xFFEA580C),
          icon: LucideIcons.siren, // Ambulance/Emergency Siren
          label: "Rescue / MDRRMO",
        );
      case "CEMETERY":
        return _CategoryConfig(
          pinColor: const Color(0xFF9333EA),
          icon: LucideIcons.cross,
          label: "Cemetery / Memorial",
        );
      case "OTHER":
      default:
        return _CategoryConfig(
          pinColor: const Color(0xFFE11D48),
          icon: LucideIcons.mapPin,
          label: "Landmark",
        );
    }
  }

  void _showPlaceDetailsModal(MapPlaceItem place, _CategoryConfig config) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: config.pinColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: config.pinColor.withValues(alpha: 0.5),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(config.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: config.pinColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: config.pinColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            config.label.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: config.pinColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          place.name,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (place.description != null && place.description!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  place.description!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFCBD5E1),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.compass, size: 16, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 8),
                    Text(
                      "Lat: ${place.latitude.toStringAsFixed(6)} | Lng: ${place.longitude.toStringAsFixed(6)}",
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: AppColors.getCardShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header matching web: TERRITORIAL LANDMARKS & GIS MAP
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF38BDF8)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TERRITORIAL LANDMARKS & GIS MAP",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.getTextPrimary(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        "Geographic registry of municipal facilities and verified landmarks",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.getTextSecondary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Interactive Map Container
          SizedBox(
            height: 380,
            width: double.infinity,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mapandanCenter,
                    initialZoom: 14.2,
                    minZoom: 11.0,
                    maxZoom: 18.5,
                  ),
                  children: [
                    // 1. Pure Esri High-Resolution Satellite Imagery Layer
                    TileLayer(
                      urlTemplate:
                          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.emapandan.mayor_apps',
                      maxZoom: 19,
                    ),

                    // 2. Mapandan Territorial Boundary (Glowing Cyan Outer Halo Line)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: kMapandanBoundaryCoords,
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                          strokeWidth: 6.0,
                        ),
                      ],
                    ),

                    // 3. Mapandan Territorial Boundary (Polygon Fill Tint & Crisp Border)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: kMapandanBoundaryCoords,
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.05),
                          borderColor: const Color(0xFF0284C7),
                          borderStrokeWidth: 2.2,
                        ),
                      ],
                    ),

                    // 4. Landmark Markers (100% Matched to Web Icons & Colors)
                    MarkerLayer(
                      markers: widget.places.map((place) {
                        final config = _getCategoryConfig(place.category);
                        final isSelected = _selectedPlace?.id == place.id;

                        return Marker(
                          point: LatLng(place.latitude, place.longitude),
                          width: 160,
                          height: 75,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPlace = place;
                              });
                              _mapController.move(
                                LatLng(place.latitude, place.longitude),
                                16.5,
                              );
                              _showPlaceDetailsModal(place, config);
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Glowing Circular Disc Badge (Matching Web)
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: config.pinColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: config.pinColor.withValues(alpha: isSelected ? 0.9 : 0.65),
                                        blurRadius: isSelected ? 18 : 12,
                                        spreadRadius: isSelected ? 3 : 1,
                                      ),
                                      const BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    config.icon,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                // Underneath Dark Capsule Label Pill (Matching Web)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xEB020617),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? Colors.white70 : Colors.white24,
                                      width: 1,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black87,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    place.name.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.4,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Floating Re-center Button (Bottom-Right)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _mapController.move(_mapandanCenter, 14.2);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xEE0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.crosshair, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryConfig {
  final Color pinColor;
  final IconData icon;
  final String label;

  _CategoryConfig({
    required this.pinColor,
    required this.icon,
    required this.label,
  });
}
