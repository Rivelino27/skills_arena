import 'package:flutter/material.dart';

import '../../data/models/player_card.dart';
import '../../data/models/user_model.dart';

/// Shield-shaped FIFA-style player card with strong 3D depth: stacked
/// drop shadows, inner gloss highlight, beveled border, and gilded
/// playstyle badges floated on the right.
///
/// `overall` defaults to the average of stats but is forced ≥ 50 so a
/// freshly promoted user starts at 50 (per design) and tops at 99.
/// `activePlaystyles` is the result of the community-voting aggregation
/// — only voted-in playstyles render as gold badges; unvoted ones are
/// dimmed/locked.
class FifaCardWidget extends StatelessWidget {
  final UserModel user;
  final double scale;
  final VoidCallback? onTap;
  final Set<String>? activePlaystyles;

  const FifaCardWidget({
    super.key,
    required this.user,
    this.scale = 1.0,
    this.onTap,
    this.activePlaystyles,
  });

  @override
  Widget build(BuildContext context) {
    if (!user.isPremium) return const SizedBox.shrink();
    final tier = user.cardTier;
    // Floor de 50 (rookie) + máximo 99 (lendário).
    final overall = user.overall.clamp(50, 99);
    final cardW = 240.0 * scale;
    final cardH = 360.0 * scale;
    // Total width inclui a coluna de playstyles na lateral direita.
    final extra = 56.0 * scale;
    final stats = user.stats;
    final name = (user.name ?? 'JOGADOR').toUpperCase();
    final active = activePlaystyles ?? const <String>{};

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardW + extra,
        height: cardH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Shield-shaped card with stacked 3D shadows ──
            Positioned(
              left: 0,
              top: 0,
              child: _ShieldCard(
                width: cardW,
                height: cardH,
                tier: tier,
                scale: scale,
                overall: overall,
                name: name,
                user: user,
                stats: stats,
              ),
            ),
            // ── Stacked gilded playstyle badges (right rail) ──
            Positioned(
              right: 0,
              top: 24 * scale,
              child: Column(
                children: [
                  for (var i = 0; i < PlaystyleKeys.all.length; i++)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 12 * scale),
                      child: _PlaystyleBadge3D(
                        playstyleKey: PlaystyleKeys.all[i],
                        tier: tier,
                        scale: scale,
                        active: active.contains(PlaystyleKeys.all[i]),
                        // Offset levemente cada badge pra parecer empilhado
                        // saindo do escudo (efeito 3D).
                        nudgeX: (i.isEven ? -2 : 2) * scale,
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
}

// ─── Shield card body ────────────────────────────────────────────────

class _ShieldCard extends StatelessWidget {
  final double width;
  final double height;
  final CardTier tier;
  final double scale;
  final int overall;
  final String name;
  final UserModel user;
  final Map<String, int> stats;

  const _ShieldCard({
    required this.width,
    required this.height,
    required this.tier,
    required this.scale,
    required this.overall,
    required this.name,
    required this.user,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Stacked depth shadows (3-4 layers for the 3D look) ──
        for (final l in const [
          (12.0, 22.0, 0.22),
          (8.0, 14.0, 0.30),
          (4.0, 8.0, 0.35),
        ])
          Positioned(
            left: 0,
            top: l.$1 * scale,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: l.$3),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20 * scale),
                  bottom: Radius.circular(width / 2),
                ),
              ),
            ),
          ),
        // ── Shield silhouette: rounded top, pointed bottom ──
        ClipPath(
          clipper: _ShieldClipper(),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                // Base tier gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        tier.primary,
                        tier.accent,
                        tier.primary,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
                // Top gloss (diagonal highlight)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.center,
                        colors: [
                          Colors.white.withValues(alpha: 0.32),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Inner bevel border
                Padding(
                  padding: EdgeInsets.all(5 * scale),
                  child: ClipPath(
                    clipper: _ShieldClipper(),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: tier.accent.withValues(alpha: 0.55),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                // Content
                _ShieldContent(
                  tier: tier,
                  scale: scale,
                  overall: overall,
                  name: name,
                  user: user,
                  stats: stats,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShieldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // Rounded-top rectangle with a tapered bottom point — a stylized
    // football-club shield. Approximate measurements derived from the
    // overall size so it scales cleanly.
    final w = size.width;
    final h = size.height;
    const topR = 22.0;
    final shoulderY = h * 0.72;
    final pointY = h;
    final waistX = w * 0.5;

    final p = Path()
      ..moveTo(topR, 0)
      ..lineTo(w - topR, 0)
      ..quadraticBezierTo(w, 0, w, topR)
      ..lineTo(w, shoulderY)
      ..quadraticBezierTo(w * 0.85, h * 0.92, waistX, pointY)
      ..quadraticBezierTo(w * 0.15, h * 0.92, 0, shoulderY)
      ..lineTo(0, topR)
      ..quadraticBezierTo(0, 0, topR, 0)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ShieldContent extends StatelessWidget {
  final CardTier tier;
  final double scale;
  final int overall;
  final String name;
  final UserModel user;
  final Map<String, int> stats;

  const _ShieldContent({
    required this.tier,
    required this.scale,
    required this.overall,
    required this.name,
    required this.user,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          18 * scale, 16 * scale, 18 * scale, 36 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Overall + tier label + photo
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      // 3D text shadow under the overall number
                      Positioned(
                        left: 1.5 * scale,
                        top: 1.5 * scale,
                        child: Text(
                          '$overall',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.35),
                            fontSize: 48 * scale,
                            fontWeight: FontWeight.w900,
                            height: 0.95,
                          ),
                        ),
                      ),
                      Text(
                        '$overall',
                        style: TextStyle(
                          color: tier.textOnTier,
                          fontSize: 48 * scale,
                          fontWeight: FontWeight.w900,
                          height: 0.95,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2 * scale),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8 * scale, vertical: 2 * scale),
                    decoration: BoxDecoration(
                      color: tier.accent.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4 * scale),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 3,
                            offset: Offset(0, 1 * scale)),
                      ],
                    ),
                    child: Text(
                      tier.label.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10 * scale,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                  if (user.username != null) ...[
                    SizedBox(height: 4 * scale),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        color: tier.textOnTier.withValues(alpha: 0.8),
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              const Spacer(),
              // Photo with thick border + drop shadow (3D pop)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 8,
                        offset: Offset(0, 3 * scale)),
                  ],
                ),
                child: CircleAvatar(
                  radius: 36 * scale,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  backgroundColor: tier.accent.withValues(alpha: 0.4),
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
              ),
            ],
          ),
          SizedBox(height: 10 * scale),
          // Name banner with embossed border
          Container(
            padding: EdgeInsets.symmetric(vertical: 5 * scale),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: tier.accent.withValues(alpha: 0.7), width: 1.4),
                bottom: BorderSide(
                    color: tier.accent.withValues(alpha: 0.7), width: 1.4),
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
                shadows: [
                  Shadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      offset: Offset(0, 1 * scale)),
                ],
              ),
            ),
          ),
          SizedBox(height: 10 * scale),
          // Stats 3x2 grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 4 * scale,
              crossAxisSpacing: 8 * scale,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: [
                for (final key in StatKeys.all)
                  _StatCell3D(
                    shortLabel: statShortLabel(key),
                    value: stats[key] ?? 50,
                    tier: tier,
                    scale: scale,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell3D extends StatelessWidget {
  final String shortLabel;
  final int value;
  final CardTier tier;
  final double scale;

  const _StatCell3D({
    required this.shortLabel,
    required this.value,
    required this.tier,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 3D shadow on the number
        Stack(
          children: [
            Positioned(
              left: 1 * scale,
              top: 1 * scale,
              child: Text(
                '$value',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.4),
                  fontWeight: FontWeight.bold,
                  fontSize: 20 * scale,
                  height: 1.0,
                ),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: tier.textOnTier,
                fontWeight: FontWeight.bold,
                fontSize: 20 * scale,
                height: 1.0,
              ),
            ),
          ],
        ),
        SizedBox(height: 2 * scale),
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
    );
  }
}

// ─── Playstyle badge with 3D + gilded look ───────────────────────────

class _PlaystyleBadge3D extends StatelessWidget {
  final String playstyleKey;
  final CardTier tier;
  final double scale;
  final bool active;
  final double nudgeX;

  const _PlaystyleBadge3D({
    required this.playstyleKey,
    required this.tier,
    required this.scale,
    required this.active,
    required this.nudgeX,
  });

  @override
  Widget build(BuildContext context) {
    final size = 42.0 * scale;
    // Gold only when voted-active. Inactive = dim tier-accent.
    final gold = active;
    final bg = gold
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE082),
              Color(0xFFFFB300),
              Color(0xFF8B6914),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tier.accent.withValues(alpha: 0.45),
              tier.accent.withValues(alpha: 0.7),
            ],
          );

    return Transform.translate(
      offset: Offset(nudgeX, 0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: gold ? const Color(0xFF8B6914) : tier.accent,
            width: 2,
          ),
          boxShadow: [
            // Drop shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 5,
              offset: Offset(0, 2 * scale),
            ),
            // Inner top highlight (faked via second BoxShadow)
            BoxShadow(
              color: Colors.white.withValues(alpha: gold ? 0.55 : 0.18),
              blurRadius: 3,
              offset: Offset(0, -1 * scale),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Icon(
          playstyleIcon(playstyleKey),
          color: gold ? const Color(0xFF4A3300) : Colors.white,
          size: 22 * scale,
        ),
      ),
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
