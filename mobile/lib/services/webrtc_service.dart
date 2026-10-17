import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';

typedef SignalCallback = void Function(String event, dynamic data);

class WebRtcService {
  WebRtcService();

  WebSocketChannel? _channel;
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  SignalCallback? onEvent;

  String? _myUserId;
  String? _partnerId;
  bool _isOfferer = false;
  bool _connected = false;

  final List<RTCIceCandidate> _pendingCandidates = [];

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  bool get connected => _connected;

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
        'urls': 'turns:global.relay.metered.ca:443?transport=tcp',
        'username': '32d974cc6eb5071979c7d59c',
        'credential': 'OAThjOf+iRmKGB9U',
      },
    ],
  };

  Future<void> connect({
    required String myUserId,
    required String partnerId,
    required String topic,
  }) async {
    _myUserId = myUserId;
    _partnerId = partnerId;

    final mediaConstraints = {
      'audio': {'mandatory': {'echoCancellation': true, 'noiseSuppression': true}, 'optional': []},
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

    final token = ApiClient.instance.token;
    if (token == null) throw StateError('Not authenticated');
    
    final base = ApiClient.instance.baseUrl;
    final wsBase = base.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://').replaceFirst('/api/v1', '');
    final url = '$wsBase/api/v1/ws/signal?token=$token';
    
    dev.log('WS connect → $url');
    _channel = WebSocketChannel.connect(Uri.parse(url));
    await _channel!.ready;

    _channel!.stream.listen(
      _onWsMessage,
      onDone: () => _emit('wsClosed', null),
      onError: (e) => _emit('error', e.toString()),
    );

    _pc = await createPeerConnection(_iceServers);

    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    _remoteStream = await createLocalMediaStream('remote');
    _pc!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        // Force audio track to be enabled
        for (final track in _remoteStream!.getAudioTracks()) {
          track.enabled = true;
        }
        _emit('remoteStream', _remoteStream);
      }
    };

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
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _connected = false;
        _emit('disconnected', true);
      }
    };

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
      }
    } catch (e) {
      dev.log('WS message error: $e');
    }
  }

  void _send(Map<String, dynamic> msg) {
    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (e) {
      dev.log('WS send failed: $e');
    }
  }

  void toggleMic(bool on) {
    for (final t in _localStream?.getAudioTracks() ?? []) {
      t.enabled = on;
    }
  }

  void toggleCamera(bool on) {
    for (final t in _localStream?.getVideoTracks() ?? []) {
      t.enabled = on;
    }
  }

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

  Future<void> hangup() async {
    try {
      _send({'type': 'hangup', 'to': _partnerId});
    } catch (_) {}
    await dispose();
  }

  Future<void> dispose() async {
    _connected = false;
    try { await _pc?.close(); } catch (_) {}
    _pc = null;

    try {
      for (final t in _localStream?.getTracks() ?? []) {
        await t.stop();
      }
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;

    try { await _remoteStream?.dispose(); } catch (_) {}
    _remoteStream = null;

    try { await _channel?.sink.close(); } catch (_) {}
    _channel = null;
  }

  void _emit(String event, dynamic data) {
    onEvent?.call(event, data);
  }
}
