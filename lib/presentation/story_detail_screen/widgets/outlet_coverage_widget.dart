import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';

class OutletCoverageWidget extends StatelessWidget {
  final List<Map<String, String>> outlets;
  final int outletCount;
  final VoidCallback? onClose;

  const OutletCoverageWidget({
    super.key,
    required this.outlets,
    required this.outletCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(31),
            blurRadius: 24,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outlet Coverage',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$outletCount outlets covered this story',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.mutedText,
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
          // AI disclaimer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppTheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lean estimates are AI-generated approximations. Tap an outlet to read their article.',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppTheme.secondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Lean spectrum bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _LeanSpectrumBar(outlets: outlets),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppTheme.outlineLight),
          // Outlet list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              itemCount: outlets.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppTheme.outlineVariantLight,
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, i) {
                final outlet = outlets[i];
                return _OutletRow(outlet: outlet);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LeanSpectrumBar extends StatelessWidget {
  final List<Map<String, String>> outlets;

  const _LeanSpectrumBar({required this.outlets});

  @override
  Widget build(BuildContext context) {
    final leanOrder = [
      'Left',
      'Center-Left',
      'Center',
      'Center-Right',
      'Right',
    ];
    final counts = <String, int>{};
    for (final o in outlets) {
      final lean = o['lean'] ?? 'Center';
      counts[lean] = (counts[lean] ?? 0) + 1;
    }
    final total = outlets.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Political lean distribution',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedText,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: leanOrder.map((lean) {
              final count = counts[lean] ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Expanded(
                flex: count,
                child: Container(height: 8, color: AppTheme.leanColor(lean)),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: leanOrder.where((l) => (counts[l] ?? 0) > 0).map((lean) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.leanColor(lean),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${AppTheme.leanShort(lean)} (${counts[lean]})',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _OutletRow extends StatelessWidget {
  final Map<String, String> outlet;

  const _OutletRow({required this.outlet});

  Future<void> _openArticle(BuildContext context) async {
    final url = outlet['articleUrl'];
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        // Try to open the real article directly. We intentionally do NOT
        // gate this on canLaunchUrl() — on Android 11+ that check silently
        // returns false unless the app declares <queries> for https intents
        // (now added to AndroidManifest.xml), which was causing every tap
        // to fall through to the Google search fallback below even though
        // the outlet had a perfectly valid articleUrl.
        try {
          final opened = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (opened) return;
        } catch (_) {
          // fall through to search fallback
        }
      }
    }
    // Fallback: only reached if there's genuinely no usable article URL,
    // or the device has no browser capable of opening it.
    final name = outlet['name'] ?? '';
    final searchUrl = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent('$name news')}',
    );
    await launchUrl(searchUrl, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lean = outlet['lean'] ?? 'Center';
    final leanColor = AppTheme.leanColor(lean);
    return InkWell(
      onTap: () => _openArticle(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outlet icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: leanColor.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: leanColor.withAlpha(51)),
              ),
              child: Center(
                child: Text(
                  (outlet['name'] ?? 'X').substring(0, 1).toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: leanColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          outlet['name'] ?? '',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      LeanBadgeWidget(lean: lean),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    outlet['framing'] ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.bodyText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 12,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Read article',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppTheme.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}
