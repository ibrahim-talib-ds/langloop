import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'rating_screen.dart';

class VideoRoomScreen extends StatefulWidget {
  const VideoRoomScreen({
    super.key,
    required this.matchId,
    required this.partnerId,
    required this.partnerName,
    required this.topic,
  });

  final String matchId;
  final String partnerId;
  final String partnerName;
  final String topic;

  @override
  State<VideoRoomScreen> createState() => _VideoRoomScreenState();
}

class _VideoRoomScreenState extends State<VideoRoomScreen> {
  final int appID = 1052798588; 
  final String appSign = "252667blc0b1be5fdl35ldbac95d9922c950ac0"; 

  @override
  Widget build(BuildContext context) {
    final me = AuthService.instance.user;
    final myId = me?['id'].toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ZegoUIKitPrebuiltCall(
          appID: appID,
          appSign: appSign,
          userID: myId,
          userName: me?['full_name'] ?? 'User',
          callID: widget.matchId, // Both users use the MatchID as the room!
          config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
        ),
      ),
    );
  }
}
