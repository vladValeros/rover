import 'package:flutter/material.dart';

/// A reusable expandable card that wraps a single ML feature.
///
/// Every ML feature card in the settings screen uses this as its shell.
/// The card shows:
///   - An icon + title + description in the header
///   - A status badge ("Active" / "Off")
///   - An enable/disable toggle
///   - An animated body that appears only when [isEnabled] is true
///
/// Usage:
/// ```dart
/// MlFeatureCard(
///   icon: Icons.camera_alt_outlined,
///   title: 'Object Detection',
///   description: 'Detect and label objects in the live stream',
///   isEnabled: settings.mode != ObjectDetectionMode.off,
///   onToggle: (enabled) { ... },
///   body: ObjectDetectionBody(settings: settings, cubit: cubit),
/// )
/// ```
class MlFeatureCard extends StatelessWidget {
  const MlFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isEnabled,
    required this.onToggle,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;

  /// The settings body shown when the feature is enabled.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Status accent bar ────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 3,
            color: isEnabled ? colorScheme.primary : Colors.transparent,
          ),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                // Feature icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isEnabled
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),

                // Title + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title, style: textTheme.titleSmall),
                          const SizedBox(width: 8),
                          _StatusBadge(isEnabled: isEnabled),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Enable toggle
                Switch(value: isEnabled, onChanged: onToggle),
              ],
            ),
          ),

          // ── Settings body (shown when enabled) ───────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isEnabled
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.outlineVariant,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: body,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Small pill badge showing "Active" or "Off".
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isEnabled});

  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isEnabled
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isEnabled ? 'Active' : 'Off',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isEnabled
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
