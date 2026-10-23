import 'package:flutter/material.dart';
import '../../../../design_system/app_colors.dart';
import '../../../../design_system/app_text_styles.dart';
import '../../../../design_system/components/app_button.dart';
import '../../../../services/location_service.dart';

class PickupLocationCard extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? placeName;
  final String? formattedAddress;
  final double? distanceKm;
  final bool isLoading;
  final String? errorMessage;
  final bool isReceiverMode;
  final VoidCallback? onFetchLocation;

  const PickupLocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.formattedAddress,
    this.distanceKm,
    this.isLoading = false,
    this.errorMessage,
    this.isReceiverMode = false,
    this.onFetchLocation,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (latitude == null || longitude == null) {
      return _buildEmptyState();
    }

    return _buildMapCard(context, latitude!, longitude!);
  }

  Widget _buildMapCard(BuildContext context, double lat, double lng) {
    final locationService = LocationService();
    final addressText = formattedAddress ??
        (placeName != null && placeName!.isNotEmpty
            ? placeName!
            : 'Captured Device Location');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.outlineVariant,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Muted Vector Map Preview Canvas (130dp height)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(15.0),
            ),
            child: SizedBox(
              height: 130.0,
              width: double.infinity,
              child: Stack(
                children: [
                  // Vector Map Canvas with subtle roads, parcels, and parks
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MutedMapPainter(
                        lat: lat,
                        lng: lng,
                      ),
                    ),
                  ),

                  // Subtle gradient overlay for contrast
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Centered Surplus Location Pin
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft Ripple
                        Container(
                          width: 44.0,
                          height: 44.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        // Pin Icon Container
                        Container(
                          width: 32.0,
                          height: 32.0,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6.0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 18.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // GPS Badge
                  Positioned(
                    top: 10.0,
                    right: 10.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: AppColors.outlineVariant,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.0,
                            height: 6.0,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            'GPS Active',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Location Info & Actions
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        color: AppColors.primary,
                        size: 18.0,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addressText,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2.0),
                          Row(
                            children: [
                              Text(
                                '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (distanceKm != null) ...[
                                const SizedBox(width: 8.0),
                                Text(
                                  '• ${distanceKm!.toStringAsFixed(1)} km away',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                const Divider(height: 1.0, color: AppColors.outlineVariant),
                const SizedBox(height: 10.0),

                // 3. Actions Row
                if (isReceiverMode)
                  SecondaryButton(
                    text: 'Open in Maps',
                    icon: const Icon(
                      Icons.directions_outlined,
                      size: 18,
                    ),
                    onPressed: () => locationService.openMapDirections(lat, lng),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Open in Maps
                      InkWell(
                        onTap: () => locationService.openMapDirections(lat, lng),
                        borderRadius: BorderRadius.circular(8.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 6.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.map_outlined,
                                size: 16.0,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                'Open in Maps',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Update Button
                      if (onFetchLocation != null)
                        SecondaryButton(
                          text: 'Update location',
                          isFullWidth: false,
                          onPressed: onFetchLocation!,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: errorMessage != null
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.outlineVariant,
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: errorMessage != null
                  ? AppColors.errorContainer
                  : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              errorMessage != null
                  ? Icons.location_off_outlined
                  : Icons.add_location_alt_outlined,
              color: errorMessage != null
                  ? AppColors.error
                  : AppColors.primary,
              size: 24.0,
            ),
          ),
          const SizedBox(height: 10.0),
          Text(
            errorMessage != null
                ? "Couldn't get your location"
                : 'Add a pickup location',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: errorMessage != null
                  ? AppColors.error
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            errorMessage ??
                'Receivers will use this location to collect the surplus food.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14.0),
          SecondaryButton(
            text: errorMessage != null ? 'Try again' : 'Use current location',
            isFullWidth: false,
            onPressed: onFetchLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.outlineVariant,
          width: 1.0,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24.0,
              height: 24.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              'Getting your current location...',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter that creates a clean, muted, vector map canvas with roads, blocks, and parks.
class _MutedMapPainter extends CustomPainter {
  final double lat;
  final double lng;

  _MutedMapPainter({required this.lat, required this.lng});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base Land Background
    final bgPaint = Paint()..color = const Color(0xFFF3F1EB);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Green Space / Park Area
    final parkPaint = Paint()
      ..color = const Color(0xFFE4EFE3)
      ..style = PaintingStyle.fill;

    final parkPath = Path()
      ..moveTo(size.width * 0.65, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.35,
        size.width * 0.65,
        0,
      );
    canvas.drawPath(parkPath, parkPaint);

    // 3. Subtle City Blocks / Parcels
    final blockPaint = Paint()
      ..color = const Color(0xFFE8E5DD)
      ..style = PaintingStyle.fill;

    // Block 1
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, 12, size.width * 0.35, size.height * 0.32),
        const Radius.circular(4),
      ),
      blockPaint,
    );

    // Block 2
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, size.height * 0.52, size.width * 0.4, size.height * 0.38),
        const Radius.circular(4),
      ),
      blockPaint,
    );

    // Block 3
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.58,
          size.height * 0.54,
          size.width * 0.36,
          size.height * 0.36,
        ),
        const Radius.circular(4),
      ),
      blockPaint,
    );

    // 4. Secondary Road Network
    final secondaryRoadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFDCD8CF)
      ..strokeWidth = 7.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Diagonal Secondary Street
    final street1 = Path()
      ..moveTo(0, size.height * 0.46)
      ..lineTo(size.width, size.height * 0.46);
    canvas.drawPath(street1, roadBorderPaint);
    canvas.drawPath(street1, secondaryRoadPaint);

    // Vertical Secondary Street
    final street2 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.5, size.height);
    canvas.drawPath(street2, roadBorderPaint);
    canvas.drawPath(street2, secondaryRoadPaint);

    // 5. Primary Highway / Avenue
    final mainRoadPaint = Paint()
      ..color = const Color(0xFFFAF9F5)
      ..strokeWidth = 9.0
      ..style = PaintingStyle.stroke;

    final mainRoadBorder = Paint()
      ..color = const Color(0xFFD3CEC3)
      ..strokeWidth = 11.0
      ..style = PaintingStyle.stroke;

    final avenue = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.75,
        size.width,
        size.height * 0.2,
      );
    canvas.drawPath(avenue, mainRoadBorder);
    canvas.drawPath(avenue, mainRoadPaint);
  }

  @override
  bool shouldRepaint(covariant _MutedMapPainter oldDelegate) {
    return oldDelegate.lat != lat || oldDelegate.lng != lng;
  }
}
