import 'package:flutter/material.dart';

import '../../data/models/player_card.dart';
import '../../data/models/user_model.dart';

/// FIFA-style player card. Visually mirrors the look of a Ultimate Team
/// card: tier-colored vertical gradient, big overall number, position
/// chip, photo, name, and a 3x2 grid of stat values with the playstyle
/// icon overlay on the boosted attribute.
///
/// Renders nothing (zero-size) if the user isn't premium — the card is
/// a premium-only perk.
class FifaCardWidget extends StatelessWidget {
  final UserModel user;
  /// 1.0 = base size. Use 0.6 for inline previews, 1.0 for the full
  /// "open the card" screen.
  final double scale;
  final VoidCallback? onTap;

  const FifaCardWidget({
    super.key,
    required this.user,
    this.scale = 1.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!user.isPremium) return const SizedBox.shrink();
    final tier = user.cardTier;
    final overall = user.overall;
    final w = 240.0 * scale;
    final h = 360.0 * scale;
    final stats = user.stats;
    final name = (user.name ?? 'JOGADOR').toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            // Tier gradient card body
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18 * scale),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tier.primary,
                    tier.accent,
                    tier.primary,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: tier.accent.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            // Sheen overlay (top-left lighter)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18 * scale),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Inner border
            Positioned.fill(
              child: Container(
                margin: EdgeInsets.all(6 * scale),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14 * scale),
                  border: Border.all(
                    color: tier.accent.withValues(alpha: 0.6),
                    width: 1.4,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(14 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top row: overall + tier label
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$overall',
                            style: TextStyle(
                              color: tier.textOnTier,
                              fontSize: 44 * scale,
                              fontWeight: FontWeight.w900,
                              height: 0.95,
                              letterSpacing: -1,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 2 * scale),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * scale,
                              vertical: 2 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: tier.accent.withValues(alpha: 0.8),
                              borderRadius:
                                  BorderRadius.circular(4 * scale),
                            ),
                            child: Text(
                              tier.label.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10 * scale,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            user.username != null
                                ? '@${user.username}'
                                : 'JOGADOR',
                            style: TextStyle(
                              color: tier.textOnTier.withValues(alpha: 0.8),
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Profile photo
                      CircleAvatar(
                        radius: 36 * scale,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        backgroundColor:
                            tier.accent.withValues(alpha: 0.4),
                        child: user.photoUrl == null
                            ? Text(
                                name.isNotEmpty ? name[0] : '?',
                                style: TextStyle(
                                  fontSize: 28 * scale,
                                  color: tier.textOnTier,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                  SizedBox(height: 10 * scale),
                  // Name banner
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4 * scale),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: tier.accent.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                        bottom: BorderSide(
                          color: tier.accent.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                    ),
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tier.textOnTier,
                        fontWeight: FontWeight.w900,
                        fontSize: 14 * scale,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  SizedBox(height: 10 * scale),
                  // Stats grid 3x2
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4 * scale,
                      crossAxisSpacing: 8 * scale,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.6,
                      children: [
                        for (final key in StatKeys.all)
                          _StatCell(
                            shortLabel: statShortLabel(key),
                            value: stats[key] ?? 50,
                            tier: tier,
                            scale: scale,
                            playstyleIcon: _playstyleForStat(key),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the matching playstyle icon for a given stat key (or null
  /// if no playstyle boosts that stat).
  IconData? _playstyleForStat(String statKey) {
    for (final ps in PlaystyleKeys.all) {
      if (playstyleStatKey(ps) == statKey) return playstyleIcon(ps);
    }
    return null;
  }
}

class _StatCell extends StatelessWidget {
  final String shortLabel;
  final int value;
  final CardTier tier;
  final double scale;
  final IconData? playstyleIcon;

  const _StatCell({
    required this.shortLabel,
    required this.value,
    required this.tier,
    required this.scale,
    this.playstyleIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: tier.textOnTier,
                fontWeight: FontWeight.bold,
                fontSize: 18 * scale,
                height: 1.0,
              ),
            ),
            Text(
              shortLabel,
              style: TextStyle(
                color: tier.textOnTier.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
                fontSize: 10 * scale,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        if (playstyleIcon != null)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: EdgeInsets.all(2 * scale),
              decoration: BoxDecoration(
                color: tier.accent.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: Icon(
                playstyleIcon,
                color: Colors.white,
                size: 9 * scale,
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact coins balance pill — used in profile / app bar.
class CoinsBalanceChip extends StatelessWidget {
  final int coins;
  final VoidCallback? onTap;
  const CoinsBalanceChip({super.key, required this.coins, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.amber.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on_rounded,
                color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              '$coins',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
