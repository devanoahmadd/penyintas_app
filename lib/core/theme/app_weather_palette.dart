import 'package:flutter/material.dart';

abstract class AppWeatherPalette {
  // ── LIGHT MODE — Sky & Hills ──────────────────────────────────────────
  static const skyTopClear          = Color(0xFF8DD4F0);
  static const skyBotClear          = Color(0xFFC8EEF8);
  static const hillFarClear         = Color(0xFF7EC87A);
  static const hillNearClear        = Color(0xFF5AB05A);

  static const skyTopCloudy         = Color(0xFF7AAECC);
  static const skyBotCloudy         = Color(0xFFB8D4E0);
  static const hillFarCloudy        = Color(0xFF5E9E6A);
  static const hillNearCloudy       = Color(0xFF4A8A55);

  static const skyTopOvercast       = Color(0xFF4A6878);
  static const skyBotOvercast       = Color(0xFF788C98);
  static const hillFarOvercast      = Color(0xFF344E38);
  static const hillNearOvercast     = Color(0xFF263A28);

  static const skyTopStorm          = Color(0xFF2A3C48);
  static const skyBotStorm          = Color(0xFF445A68);
  static const hillFarStorm         = Color(0xFF1E3028);
  static const hillNearStorm        = Color(0xFF162218);

  static const skyTopOverwhelmed    = Color(0xFFC8D8C8);
  static const skyBotOverwhelmed    = Color(0xFFD8E8D8);
  static const hillFarOverwhelmed   = Color(0xFF506C50);
  static const hillNearOverwhelmed  = Color(0xFF3C5C3C);

  // ── DARK MODE — Sky & Hills (hillNear difix: ΔL* ≥15% vs bgDark #0B1F14) ──
  static const skyTopClearDark          = Color(0xFF0D2236);
  static const skyBotClearDark          = Color(0xFF1A3A52);
  static const hillFarClearDark         = Color(0xFF1A3B22);
  static const hillNearClearDark        = Color(0xFF1E4030);

  static const skyTopCloudyDark         = Color(0xFF0B1D2E);
  static const skyBotCloudyDark         = Color(0xFF162A3E);
  static const hillFarCloudyDark        = Color(0xFF14301C);
  static const hillNearCloudyDark       = Color(0xFF192E22);

  static const skyTopOvercastDark       = Color(0xFF0A1820);
  static const skyBotOvercastDark       = Color(0xFF121E28);
  static const hillFarOvercastDark      = Color(0xFF0E2018);
  static const hillNearOvercastDark     = Color(0xFF0E1E16);

  static const skyTopStormDark          = Color(0xFF060E14);
  static const skyBotStormDark          = Color(0xFF0C1A24);
  static const hillFarStormDark         = Color(0xFF0A1810);
  static const hillNearStormDark        = Color(0xFF0C1810);

  static const skyTopOverwhelmedDark    = Color(0xFF121E18);
  static const skyBotOverwhelmedDark    = Color(0xFF1A2A20);
  static const hillFarOverwhelmedDark   = Color(0xFF1E3828);
  static const hillNearOverwhelmedDark  = Color(0xFF1A2E22);

  // ── HILL BACK — Layer ketiga (paling jauh, light mode) ───────────────
  static const hillBackClear        = Color(0xFFA8D4A0);
  static const hillBackCloudy       = Color(0xFF8ABE8A);
  static const hillBackOvercast     = Color(0xFF4A6450);
  static const hillBackStorm        = Color(0xFF2A3E2E);
  static const hillBackOverwhelmed  = Color(0xFF6A8A6A);

  // ── HILL BACK — Layer ketiga (dark mode) ─────────────────────────────
  static const hillBackClearDark        = Color(0xFF10261A);
  static const hillBackCloudyDark       = Color(0xFF0E2018);
  static const hillBackOvercastDark     = Color(0xFF0C1C14);
  static const hillBackStormDark        = Color(0xFF080E0C);
  static const hillBackOverwhelmedDark  = Color(0xFF142018);

  // ── NIGHT ELEMENTS — Bulan ───────────────────────────────────────────
  static const moonColor = Color(0xFFF0F4FF);
  static const moonGlow  = Color(0xFFA8E6B6);

  // ── NIGHT ELEMENTS — Awan ────────────────────────────────────────────
  static const cloudNightBase   = Color(0xFF4A5A70);
  static const cloudNightBase2  = Color(0xFF404E62);
  static const cloudNightStorm  = Color(0xFF1E2430);
  static const cloudNightStorm2 = Color(0xFF182030);

  // ── NIGHT ELEMENTS — Hujan ───────────────────────────────────────────
  static const rainNightColor = Color(0xFF3A5A70);

  // ── NIGHT ELEMENTS — Kabut (overwhelmed) ─────────────────────────────
  static const fogNightStart = Color(0xFF0E2A24);
  static const fogNightEnd   = Color(0xFF162E28);
}
