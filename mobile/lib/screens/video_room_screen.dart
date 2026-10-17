import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../services/auth_service.dart';

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
  final String appSign = "252667b1c0b1be5fd1351dbac95d9922c950ac0460e07caef0dd7d191cf5c177";

  // Zego only allows letters, numbers, and underscores in IDs.
  // This strips out the hyphens from your UUIDs.
  String _sanitize(String raw) => raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');

  @override
  Widget build(BuildContext context) {
    final me = AuthService.instance.user;
    final myId = _sanitize(me?['id'].toString() ?? '');
    final roomId = _sanitize(widget.matchId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ZegoUIKitPrebuiltCall(
          appID: appID,
          appSign: appSign,
          userID: myId,
          userName: me?['full_name'] ?? 'User',
          callID: roomId,
          config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
        ),
      ),
    );
  }
}
