import 'package:flutter/material.dart';

/// Centralized icon set. Uses Material Symbols Rounded for a modern,
/// consistent look. Never inline `IconData` — always reference from here.
class AppIcons {
  AppIcons._();

  // Nav
  static const home      = Icons.grid_view_rounded;
  static const friends   = Icons.people_alt_rounded;
  static const profile   = Icons.person_rounded;

  // Actions
  static const video     = Icons.videocam_rounded;
  static const mic       = Icons.mic_rounded;
  static const micOff    = Icons.mic_off_rounded;
  static const cameraOff = Icons.videocam_off_rounded;
  static const callEnd   = Icons.call_end_rounded;
  static const report    = Icons.flag_rounded;
  static const logout    = Icons.logout_rounded;
  static const back      = Icons.arrow_back_rounded;
  static const close     = Icons.close_rounded;
  static const send      = Icons.arrow_forward_rounded;

  // Status / badges
  static const streak    = Icons.local_fire_department_rounded;
  static const xp        = Icons.bolt_rounded;
  static const level     = Icons.military_tech_rounded;
  static const trophy    = Icons.emoji_events_rounded;
  static const star      = Icons.star_rounded;
  static const starHalf  = Icons.star_half_rounded;
  static const starEmpty = Icons.star_border_rounded;
  static const check     = Icons.check_rounded;
  static const online    = Icons.circle;
  static const verified  = Icons.verified_rounded;

  // Theme
  static const sun       = Icons.wb_sunny_rounded;
  static const moon      = Icons.dark_mode_rounded;

  // Topics
  static const topicChat = Icons.forum_rounded;
  static const topicJob  = Icons.work_rounded;
  static const topicTrip = Icons.flight_takeoff_rounded;
  static const topicFood = Icons.restaurant_rounded;
  static const topicTech = Icons.memory_rounded;
  static const topicLife = Icons.favorite_rounded;
  static const topicGame = Icons.sports_esports_rounded;
}
