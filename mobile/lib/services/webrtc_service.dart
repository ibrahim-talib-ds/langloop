import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'api_client.dart';

typedef SignalCallback = void Function(String event, dynamic data);

class WebRtcService {
  WebRtcService();

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  SignalCallback? onEvent;

  String? _myUserId;
  String? _partnerId;
  bool _isOfferer = false;
  bool _connected = false;

  final List<RTCIceCandidate> _pendingCandidates = [];
  Timer? _pollTimer;
  bool _isPolling = false;

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

    _pc = await createPeerConnection(_iceServers);

    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    _remoteStream = await createLocalMediaStream('remote');
    _pc!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _emit('remoteStream', _remoteStream);
      }
    };

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      _sendSignal('ice', {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
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
    
    // Start polling BEFORE sending offer
    _startPolling();

    if (_isOfferer) {
      // Wait a moment to ensure the other side is polling
      await Future.delayed(const Duration(milliseconds: 500));
      await _createAndSendOffer();
    }
  }

  void _startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_isPolling) return;
      try {
        final res = await ApiClient.instance.get('/signal-poll/receive');
        final list = res['data'] is List ? res['data'] as List : [];
        for (final msg in list) {
          await _handleSignal(msg as Map<String, dynamic>);
        }
      } catch (_) {}
    });
  }

  Future<void> _handleSignal(Map<String, dynamic> data) async {
    final type = data['type'];
    if (_pc == null) return;

    try {
      if (type == 'offer') {
        await _pc!.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['sdpType']),
        );
        final answer = await _pc!.createAnswer();
        await _pc!.setLocalDescription(answer);
        _sendSignal('answer', {
          'sdp': answer.sdp,
          'sdpType': answer.type,
        });
        
        // Apply any queued candidates
        for (final c in _pendingCandidates) {
          await _pc!.addCandidate(c);
        }
        _pendingCandidates.clear();
        
      } else if (type == 'answer') {
        await _pc!.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['sdpType']),
        );
        for (final c in _pendingCandidates) {
          await _pc!.addCandidate(c);
        }
        _pendingCandidates.clear();
        
      } else if (type == 'ice') {
        final c = data['candidate'];
        if (c == null) return;
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
      }
    } catch (e) {
      dev.log('Signal handle error: $e');
    }
  }

  Future<void> _createAndSendOffer() async {
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    _sendSignal('offer', {
      'sdp': offer.sdp,
      'sdpType': offer.type,
    });
  }

  void _sendSignal(String type, Map<String, dynamic> payload) {
    if (_partnerId == null) return;
    ApiClient.instance.post('/signal-poll/send', body: {
      'type': type,
      'to': _partnerId!,
      ...payload,
    });
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
    await dispose();
  }

  Future<void> dispose() async {
    _connected = false;
    _isPolling = false;
    _pollTimer?.cancel();
    _pollTimer = null;

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
  }

  void _emit(String event, dynamic data) {
    onEvent?.call(event, data);
  }
}
