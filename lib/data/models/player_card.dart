import 'package:flutter/material.dart';

/// FIFA-style player card system for premium users.
/// Tiers are derived from `followersCount` (server-truth field) so they
/// can't be self-promoted from the client.
enum CardTier { bronze, silver, gold, platinum, diamond }

extension CardTierX on CardTier {
  String get label {
    switch (this) {
      case CardTier.bronze:
        return 'Bronze';
      case CardTier.silver:
        return 'Prata';
      case CardTier.gold:
        return 'Dourado';
      case CardTier.platinum:
        return 'Platina';
      case CardTier.diamond:
        return 'Diamante';
    }
  }

  String get storageKey => name;

  Color get primary {
    switch (this) {
      case CardTier.bronze:
        return const Color(0xFFCD7F32);
      case CardTier.silver:
        return const Color(0xFFBFC1C2);
      case CardTier.gold:
        return const Color(0xFFD4AF37);
      case CardTier.platinum:
        return const Color(0xFF7CC1E4);
      case CardTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  Color get accent {
    switch (this) {
      case CardTier.bronze:
        return const Color(0xFF8B4513);
      case CardTier.silver:
        return const Color(0xFF6E7174);
      case CardTier.gold:
        return const Color(0xFF8B6914);
      case CardTier.platinum:
        return const Color(0xFF1E5F8A);
      case CardTier.diamond:
        return const Color(0xFF3B7DD8);
    }
  }

  Color get textOnTier => this == CardTier.bronze ||
          this == CardTier.platinum
      ? Colors.white
      : Colors.black87;

  /// Stat cap per tier. Bronze caps at ~70, diamond caps at 99.
  /// Used by the edit-stats screen to gate progression.
  int get statCap {
    switch (this) {
      case CardTier.bronze:
        return 70;
      case CardTier.silver:
        return 80;
      case CardTier.gold:
        return 90;
      case CardTier.platinum:
        return 95;
      case CardTier.diamond:
        return 99;
    }
  }
}

/// Derive the tier from a follower count. Mirrors a typical FIFA-Web
/// progression: a few hundred followers gets you into platinum.
CardTier cardTierFromFollowers(int followers) {
  if (followers >= 1000) return CardTier.diamond;
  if (followers >= 200) return CardTier.platinum;
  if (followers >= 50) return CardTier.gold;
  if (followers >= 10) return CardTier.silver;
  return CardTier.bronze;
}

// ─── Stats ───────────────────────────────────────────────────────────────

/// Stat keys stored on the user doc under `stats: { ... }`.
class StatKeys {
  static const speed = 'speed';
  static const dribble = 'dribble';
  static const finishing = 'finishing';
  static const defense = 'defense';
  static const pass = 'pass';
  static const stamina = 'stamina';

  static const all = [speed, dribble, finishing, defense, pass, stamina];
}

String statLabel(String key) {
  switch (key) {
    case StatKeys.speed:
      return 'Velocidade';
    case StatKeys.dribble:
      return 'Drible';
    case StatKeys.finishing:
      return 'Finalização';
    case StatKeys.defense:
      return 'Defesa';
    case StatKeys.pass:
      return 'Passe';
    case StatKeys.stamina:
      return 'Stamina';
    default:
      return key;
  }
}

String statShortLabel(String key) {
  switch (key) {
    case StatKeys.speed:
      return 'VEL';
    case StatKeys.dribble:
      return 'DRI';
    case StatKeys.finishing:
      return 'FIN';
    case StatKeys.defense:
      return 'DEF';
    case StatKeys.pass:
      return 'PAS';
    case StatKeys.stamina:
      return 'STA';
    default:
      return key.toUpperCase();
  }
}

IconData statIcon(String key) {
  switch (key) {
    case StatKeys.speed:
      return Icons.bolt_rounded;
    case StatKeys.dribble:
      return Icons.auto_fix_high_rounded;
    case StatKeys.finishing:
      return Icons.sports_soccer_rounded;
    case StatKeys.defense:
      return Icons.shield_rounded;
    case StatKeys.pass:
      return Icons.swap_horiz_rounded;
    case StatKeys.stamina:
      return Icons.battery_charging_full_rounded;
    default:
      return Icons.star_rounded;
  }
}

/// Default stats handed to a freshly-promoted premium user. All 50 →
/// solid bronze-tier starting point.
Map<String, int> defaultStats() => {for (final k in StatKeys.all) k: 50};

/// Overall = arithmetic mean of all stats, rounded.
int overallRating(Map<String, int> stats) {
  if (stats.isEmpty) return 0;
  final values = StatKeys.all
      .map((k) => stats[k] ?? 0)
      .toList();
  final sum = values.fold<int>(0, (a, b) => a + b);
  return (sum / values.length).round();
}

// ─── Playstyles ──────────────────────────────────────────────────────────

/// Special abilities. All premium users have all four; the visual
/// quality is rendered using the user's current `cardTier`.
class PlaystyleKeys {
  static const rocketSpeed = 'rocket_speed';
  static const defenseShield = 'defense_shield';
  static const dribbleMagic = 'dribble_magic';
  static const staminaBattery = 'stamina_battery';

  static const all = [
    rocketSpeed,
    defenseShield,
    dribbleMagic,
    staminaBattery,
  ];
}

String playstyleLabel(String key) {
  switch (key) {
    case PlaystyleKeys.rocketSpeed:
      return 'Foguete de Velocidade';
    case PlaystyleKeys.defenseShield:
      return 'Escudo de Defesa';
    case PlaystyleKeys.dribbleMagic:
      return 'Cartola e Varinha Mágica';
    case PlaystyleKeys.staminaBattery:
      return 'Bateria de Stamina';
    default:
      return key;
  }
}

IconData playstyleIcon(String key) {
  switch (key) {
    case PlaystyleKeys.rocketSpeed:
      return Icons.rocket_launch_rounded;
    case PlaystyleKeys.defenseShield:
      return Icons.shield_moon_rounded;
    case PlaystyleKeys.dribbleMagic:
      return Icons.auto_awesome_rounded;
    case PlaystyleKeys.staminaBattery:
      return Icons.battery_charging_full_rounded;
    default:
      return Icons.star_rounded;
  }
}

/// Which stat each playstyle boosts (visual only — used to overlay the
/// playstyle icon on the matching stat in the card).
String playstyleStatKey(String key) {
  switch (key) {
    case PlaystyleKeys.rocketSpeed:
      return StatKeys.speed;
    case PlaystyleKeys.defenseShield:
      return StatKeys.defense;
    case PlaystyleKeys.dribbleMagic:
      return StatKeys.dribble;
    case PlaystyleKeys.staminaBattery:
      return StatKeys.stamina;
    default:
      return '';
  }
}
