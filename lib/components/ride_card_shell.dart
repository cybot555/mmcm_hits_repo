import 'package:flutter/material.dart';

/// Shared surface for Hitcher and Driver ride cards to keep spacing,
/// shadow, and rounded corners consistent.
class RideCardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const RideCardShell({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: padding ?? const EdgeInsets.all(18),
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class RideCardStyles {
  static const title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const subtitle = TextStyle(
    fontSize: 13,
    color: Color(0xFF6B7280),
  );

  static const meta = TextStyle(
    fontSize: 14,
    color: Color(0xFF1F2937),
    fontWeight: FontWeight.w500,
  );

  static const chipStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class RideStatusChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color? textColor;

  const RideStatusChip({
    super.key,
    required this.label,
    required this.background,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: RideCardStyles.chipStyle.copyWith(
          color: textColor ?? Colors.white,
        ),
      ),
    );
  }
}

String formatRideDate(DateTime? dateTime) {
  if (dateTime == null) return 'Scheduling soon';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final local = dateTime.toLocal();
  final month = months[local.month - 1];
  final hourValue = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$month ${local.day} • $hourValue:$minute $period';
}

extension RideCardColorX on Color {
  Color darken([double amount = .08]) {
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

class RideInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const RideInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: RideCardStyles.subtitle,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: RideCardStyles.meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String buildVehicleLabel(String brand, String plate) {
  final trimmedBrand = brand.trim();
  final trimmedPlate = plate.trim();
  final parts = <String>[
    if (trimmedBrand.isNotEmpty) trimmedBrand,
    if (trimmedPlate.isNotEmpty) trimmedPlate,
  ];
  if (parts.isEmpty) return 'Vehicle details pending';
  return parts.join(' • ');
}

class RideMessageNote extends StatelessWidget {
  final String message;

  const RideMessageNote({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 16,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
