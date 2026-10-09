import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

final _pesoFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

String peso(num amount) => _pesoFormat.format(amount);

/// A product's photo tile. Shows the real photo the staff picked from their
/// device when [imageBytes] is set; otherwise falls back to a colored tile +
/// icon (used for the seed catalog, which ships without real photos).
class ProductThumb extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Uint8List? imageBytes;
  final String? imageUrl; // Cloudinary URL
  final double size;
  final Availability? availability;

  const ProductThumb({
    super.key,
    required this.icon,
    required this.color,
    this.imageBytes,
    this.imageUrl,
    this.size = 64,
    this.availability,
  });

  // Cloudinary resizes and compresses on the fly, so lists stay fast.
  String _cdn(String url) => url.contains('/upload/')
      ? url.replaceFirst('/upload/', '/upload/w_${(size * 2).round()},c_fill,q_auto,f_auto/')
      : url;

  Widget _fallback() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.85), color.withOpacity(0.55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      );

  Widget _photo() {
    if (imageBytes != null) {
      return Image.memory(imageBytes!, width: size, height: size, fit: BoxFit.cover);
    }
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        _cdn(url),
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null ? child : _fallback(),
        errorBuilder: (context, error, stack) => _fallback(),
      );
    }
    return _fallback();
  }

  @override
  Widget build(BuildContext context) {
    final soldOut = availability == Availability.soldOut;
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(size * 0.22), child: _photo()),
        if (soldOut)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(size * 0.22),
              ),
              alignment: Alignment.center,
              child: Text(
                'SOLD OUT',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.11),
              ),
            ),
          ),
      ],
    );
  }
}

/// A selectable pill — used for category filters, size/variant options,
/// modular add-on choices, and the staff customization-level picker.
///
/// Flutter's [ChipThemeData] can't reliably give selected vs. unselected
/// chips different label colors under Material 3 (`labelStyle` governs both
/// states; `secondaryLabelStyle` is effectively unused), so instead of
/// leaning on the theme, every instance sets its own colors explicitly:
/// selected = solid red background with white text, unselected = beige
/// background with red text — always readable, never ambiguous.
class AppChoiceChip extends StatelessWidget {
  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const AppChoiceChip({super.key, required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? Colors.white : AppColors.ribbonRed;
    return ChoiceChip(
      label: DefaultTextStyle.merge(
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        child: label,
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: AppColors.creamDark,
      selectedColor: AppColors.ribbonRed,
      surfaceTintColor: Colors.transparent,
      checkmarkColor: Colors.white,
      pressElevation: 0,
      labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

Color orderStatusColor(OrderStatus s) {
  switch (s) {
    case OrderStatus.received:
      return AppColors.warning;
    case OrderStatus.baking:
      return const Color(0xFF3A6FB0);
    case OrderStatus.ready:
      return AppColors.gold;
    case OrderStatus.completed:
      return AppColors.success;
    case OrderStatus.cancelled:
      return AppColors.danger;
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.creamDark, shape: BoxShape.circle),
              child: Icon(icon, size: 44, color: AppColors.ribbonRed),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(message))]),
      backgroundColor: AppColors.success,
    ),
  );
}

void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [const Icon(Icons.error, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(message))]),
      backgroundColor: AppColors.danger,
    ),
  );
}