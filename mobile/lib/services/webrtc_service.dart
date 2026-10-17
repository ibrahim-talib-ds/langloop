import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';

/// Event callback so the UI can react.
typedef SignalCallback = void Function(String event, dynamic data);

class WebRtcService {
  WebRtcService();

  WebSocketChannel? _channel;
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  SignalCallback? onEvent;

  String? _partnerId;
  bool _isOfferer = false;
  bool _connected = false;

  final List<RTCIceCandidate> _pendingCandidates = [];

  // ─── Public state ───
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  bool get connected => _connected;
  bool get isOfferer => _isOfferer;

  static const _iceServers = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.relay.metered.ca:80',
          'stun:stun.l.google.com:19302',
        ],
      },
      {
        'urls': 'turn:global.relay.metered.ca:80',
        'username': '32d974cc6eb5071979c7d59c',
        'credential': 'OAThjOf+iRmKGB9U',
      },
      {
        'urls': 'turn:global.relay.metered.ca:443',
        'username': '32d974cc6eb5071979c7d59c',
        'credential': 'OAThjOf+iRmKGB9U',
      },
      {
        'urls': 'turn:global.relay.metered.ca:443?transport=tcp',
        'username': '32d974cc6eb5071979c7d59c',
        'credential': 'OAThjOf+iRmKGB9U',
      },
      {
        'urls': 'turns:global.relay.metered.ca:443?transport=tcp',
        'username': '32d974cc6eb5071979c7d59c',
        'credential': 'OAThjOf+iRmKGB9U',
      },
    ],
  };

  /// Called once when the video room opens.
  Future<void> connect({
    required String myUserId,
    required String partnerId,
    required String topic,
  }) async {
    _partnerId = partnerId;

    // ─── 1) Get local media ───
    final mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '24',
        },
        'facingMode': 'user',
        'optional': [],
      },
    };
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _emit('localStream', _localStream);

    // ─── 2) Open WebSocket ───
    final token = ApiClient.instance.token;
    if (token == null) throw StateError('Not authenticated');
    final wsBase = ApiClient.instance.baseUrl
        .replaceFirst('http', 'ws')
        .replaceFirst('/api/v1', '');
    final url = '$wsBase/api/v1/ws/signal?token=$token';
    dev.log('WS connect → $url');
    _channel = WebSocketChannel.connect(Uri.parse(url));
    await _channel!.ready;

    _channel!.stream.listen(
      _onWsMessage,
      onDone: () {
        _emit('wsClosed', null);
      },
      onError: (e) {
        _emit('error', e.toString());
      },
    );

    // ─── 3) Build peer connection ───
    _pc = await createPeerConnection(_iceServers);

    // Local tracks into peer connection
    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    // Remote stream hook
    _remoteStream = await createLocalMediaStream('remote');
    _pc!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _emit('remoteStream', _remoteStream);
      }
    };

    // ICE candidates → send to peer over WS
    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      _send({
        'type': 'ice',
        'to': _partnerId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _connected = true;
        _emit('connected', true);
      } else if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _connected = false;
        _emit('disconnected', true);
      }
    };

    // ─── 4) Decide who creates the offer ───
    // Lower user id creates the offer so both sides agree deterministically.
    _isOfferer = (myUserId.compareTo(partnerId) < 0);
    if (_isOfferer) {
      await _createAndSendOffer();
    }
  }

  Future<void> _createAndSendOffer() async {
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    _send({
      'type': 'offer',
      'to': _partnerId,
      'sdp': offer.sdp,
      'sdpType': offer.type,
    });
  }

  Future<void> _onWsMessage(dynamic raw) async {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'offer':
          await _pc!.setRemoteDescription(
            RTCSessionDescription(data['sdp'], data['sdpType'] ?? 'offer'),
          );
          final answer = await _pc!.createAnswer();
          await _pc!.setLocalDescription(answer);
          _send({
            'type': 'answer',
            'to': _partnerId,
            'sdp': answer.sdp,
            'sdpType': answer.type,
          });
          break;

        case 'answer':
          await _pc!.setRemoteDescription(
            RTCSessionDescription(data['sdp'], data['sdpType'] ?? 'answer'),
          );
          // Apply any queued ICE candidates
          for (final c in _pendingCandidates) {
            await _pc!.addCandidate(c);
          }
          _pendingCandidates.clear();
          break;

        case 'ice':
          final c = data['candidate'];
          if (c == null) break;
          final candidate = RTCIceCandidate(
            c['candidate'] as String?,
            c['sdpMid'] as String?,
            c['sdpMLineIndex'] as int?,
          );
          if (await _pc!.getRemoteDescription() != null) {
            await _pc!.addCandidate(candidate);
          } else {
            _pendingCandidates.add(candidate);
          }
          break;

        case 'peer-online':
          _emit('peerOnline', true);
          break;

        case 'peer-offline':
          _emit('peerOffline', true);
          break;

        case 'hangup':
          _emit('hangup', true);
          break;
      }
    } catch (e) {
      dev.log('WS msg error: $e');
    }
  }

  void _send(Map<String, dynamic> msg) {
    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (e) {
      dev.log('send failed: $e');
    }
  }

  // ─── Local controls ───
  void toggleMic(bool on) {
    final tracks = _localStream?.getAudioTracks() ?? [];
    for (final t in tracks) {
      t.enabled = on;
    }
  }

  void toggleCamera(bool on) {
    final tracks = _localStream?.getVideoTracks() ?? [];
    for (final t in tracks) {
      t.enabled = on;
    }
  }

  

  /// Send hangup to peer, then close everything.
  Future<void> hangup() async {
    try {
      _send({'type': 'hangup', 'to': _partnerId});
    } catch (_) {}
    await dispose();
  }

  Future<void> dispose() async {
    _connected = false;
    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;

    try {
      for (final t in _localStream?.getTracks() ?? []) {
        await t.stop();
      }
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;

    try {
      await _remoteStream?.dispose();
    } catch (_) {}
    _remoteStream = null;

    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _emit(String event, dynamic data) {
    onEvent?.call(event, data);
  }

  /// Switch between front and back camera (mobile only).
  Future<bool> switchCamera() async {
    try {
      final tracks = _localStream?.getVideoTracks() ?? [];
      if (tracks.isEmpty) return false;
      await Helper.switchCamera(tracks.first);
      return true;
    } catch (_) {
      return false;
    }
  }

}
