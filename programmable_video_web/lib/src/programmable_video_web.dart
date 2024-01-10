import 'dart:async';
import 'dart:html' as html;
import 'dart:html';
import 'dart:js_util' as js_util;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/js_map.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_audio_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_data_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_video_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_video_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/logger.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_audio_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_audio_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_participant.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/room.dart';
import 'package:twilio_programmable_video_web/src/interop/connect.dart';
import 'package:twilio_programmable_video_web/src/listeners/local_participant_event_listener.dart';
import 'package:twilio_programmable_video_web/src/listeners/room_event_listener.dart';

import 'interop/classes/local_audio_track.dart';

class ProgrammableVideoPlugin extends ProgrammableVideoPlatform {
  static Room? _room;
  static RoomEventListener? _roomListener;
  static LocalParticipantEventListener? _localParticipantListener;

  // TODO add listeners for camera and remotedatatrack stream
  static final _roomStreamController = StreamController<BaseRoomEvent>.broadcast();
  static final _cameraStreamController = StreamController<BaseCameraEvent>.broadcast();
  static final _localParticipantController = StreamController<BaseLocalParticipantEvent>.broadcast();
  static final _remoteParticipantController = StreamController<BaseRemoteParticipantEvent>.broadcast();
  static final _remoteDataTrackController = StreamController<BaseRemoteDataTrackEvent>.broadcast();
  static final _loggingStreamController = StreamController<String>.broadcast();

  static var _nativeDebug = false;
  static var _sdkDebugSetup = false;
  static final _registeredRemoteParticipantViewFactories = [];

  //Variables to support screen share
  static html.MediaStreamTrack? shareTrack;
  static html.VideoElement? _screenShareVideoElement;
  static Widget? _screenShareWidget;
  static var _shareTrackSid = '';

  // Camera variables
  static html.MediaStream? cameraMediaStream;
  static html.MediaStreamTrack? cameraTrack;
  static html.VideoElement? _cameraVideoElement;
  static LocalVideoTrack? _cameraLocalTrack;

  // Microphone variables
  static html.MediaStream? microphoneMediaStream;
  static html.MediaStreamTrack? microphoneTrack;
  static LocalAudioTrack? _microphoneLocalTrack;

  static String speakerDeviceId = 'default';

  static void debug(String msg) {
    if (_nativeDebug) _loggingStreamController.add(msg);
  }

  static void registerWith(Registrar registrar) {
    ProgrammableVideoPlatform.instance = ProgrammableVideoPlugin();
    _createLocalViewFactory();
  }

/* RMC 20221124 - THEIRS 
  static void _createLocalViewFactory() {
    ui.platformViewRegistry.registerViewFactory('local-video-track-html', (int viewId) {
      final room = _room;
      if (room != null) {
        final localVideoTrackElement = room.localParticipant.videoTracks.values().next().value.track.attach()..style.objectFit = 'cover';
        debug('Created local video track view for:  ${room.localParticipant.sid}');
        return localVideoTrackElement;
      } else {
        // TODO: review behaviour in scenario where `_room` is `null`.
        return DivElement();
      }
    });
  }
  */

  static void _createLocalViewFactory({bool isScreenShare = false}) {
    final htmlTag = !isScreenShare ? 'local-video-track-html' : 'local-screen-share-track-html';
    ui.platformViewRegistry.registerViewFactory(htmlTag, (int viewId) {
      final room = _room;
      if (room != null) {
        debug('Creating local video track view for:  ${room.localParticipant.sid}');
        if (!isScreenShare) {
          _cameraVideoElement = room.localParticipant.videoTracks.values().next().value.track.attach()..style.objectFit = 'cover';
          return _cameraVideoElement!;
        } else {
          final localVideoTrackPublication = room.localParticipant.videoTracks.toDartMap()[_shareTrackSid];
          if (localVideoTrackPublication != null) {
            // localVideoTrackElement = localVideoTrackPublication.track.attach()
            _cameraVideoElement = localVideoTrackPublication.track.attach()..style.objectFit = 'cover';
          } else {
            return html.DivElement();
          }
          return _cameraVideoElement!;
        }
      } else {
        return html.DivElement();
      }
    });
  }

/* RMC 20221124 - THEIRS
  static void _createRemoteViewFactory(String remoteParticipantSid, String remoteVideoTrackSid) {
    ui.platformViewRegistry.registerViewFactory('remote-video-track-#$remoteVideoTrackSid-html', (int viewId) {
      final remoteVideoTrack = _room?.participants.toDartMap()[remoteParticipantSid]?.videoTracks.toDartMap()[remoteVideoTrackSid]?.track;
      // TODO: flatten this out
      if (remoteVideoTrack != null) {
        final remoteVideoTrackElement = remoteVideoTrack.attach()..style.objectFit = 'cover';
        debug('Created remote video track view for: $remoteParticipantSid');
        return remoteVideoTrackElement;
      } else {
        // TODO: review behaviour in scenario where `_room` is `null`.
        return DivElement();
      }
    });
  }
  */

  static void _createRemoteViewFactory(String remoteParticipantSid, String remoteVideoTrackSid, {bool isScreenShare = false}) {
    ui.platformViewRegistry.registerViewFactory('remote-video-track-#$remoteVideoTrackSid-html', (int viewId) {
      final remoteParticipant = _room?.participants.toDartMap()[remoteParticipantSid];
      final remoteVideoTrackPublication = remoteParticipant?.videoTracks.toDartMap()[remoteVideoTrackSid];
      if (remoteVideoTrackPublication != null) {
        //This assumes that the remote video track is already attached to the remote participant.
        //If the remote video track is not attached to the remote participant, the view will not be created.
        final remoteVideoTrack = remoteVideoTrackPublication.track;
        // flatten this out

        if (remoteVideoTrack != null) {
          final remoteVideoTrackElement = remoteVideoTrack.attach()..style.objectFit = isScreenShare ? 'contain' : 'cover';
          debug('Created remote video track view for: $remoteVideoTrackSid');
          return remoteVideoTrackElement;
        } else {
          return html.DivElement();
        }
      } else {
        return html.DivElement();
      }
    });
  }

/* RMC 20221124 - THEIRS
  //#region Functions
  @override
  Widget createLocalVideoTrackWidget({bool mirror = true, Key? key}) {
    final room = _room;

    if (room != null) {
      debug('Created local video track widget for: ${room.localParticipant.sid}');
      return HtmlElementView(viewType: 'local-video-track-html', key: key);
    } else {
      throw Exception('NotConnected. LocalVideoTrack is not fully initialized until connection.');
    }
  }
  */

  @override
  Widget createLocalVideoTrackWidget({bool isScreenShare = false, bool mirror = true, Key? key}) {
    final room = _room;

    if (room != null) {
      if (isScreenShare) {
        _createLocalViewFactory(isScreenShare: true);
      }
      debug('Created local video track widget for: ${room.localParticipant.sid}');
      return HtmlElementView(viewType: !isScreenShare ? 'local-video-track-html' : 'local-screen-share-track-html', key: key);
    } else {
      throw Exception('NotConnected. LocalVideoTrack is not fully initialized until connection.');
    }
  }

  @override
  Widget createRemoteVideoTrackWidget({
    required String remoteParticipantSid,
    required String remoteVideoTrackSid,
    bool mirror = true,
    Key? key,
    bool isScreenShare = false,
  }) {
    key ??= ValueKey(remoteVideoTrackSid);

    if (!_registeredRemoteParticipantViewFactories.contains(remoteVideoTrackSid)) {
      _createRemoteViewFactory(remoteParticipantSid, remoteVideoTrackSid, isScreenShare: isScreenShare);
      _registeredRemoteParticipantViewFactories.add(remoteVideoTrackSid);
      debug('Created remote video track widget for: $remoteVideoTrackSid');
    }
    return HtmlElementView(viewType: 'remote-video-track-#$remoteVideoTrackSid-html', key: key);
  }

  void _onConnected() async {
    final room = _room;
    if (room != null) {
      _roomListener = RoomEventListener(room, _roomStreamController, _remoteParticipantController, _remoteDataTrackController);
      _roomListener!.addListeners();
      _localParticipantListener = LocalParticipantEventListener(room.localParticipant, _localParticipantController);
      _localParticipantListener!.addListeners();

      final _roomModel = Connected(room.toModel());
      _roomStreamController.add(_roomModel);
      debug('Connected to room: ${room.name}');
      _roomStreamController.onListen = null;
    }
  }

  @override
  Future<int> connectToRoom(ConnectOptionsModel connectOptions) async {
    _roomStreamController.onListen = _onConnected;

    try {
      _room = await connectWithModel(connectOptions);
    } catch (err) {
      ProgrammableVideoPlugin.debug(err.toString());
      throw PlatformException(code: 'INIT_ERROR', message: 'Failed to connect to room', details: '');
    }
    return 0;
  }

  @override
  Future<void> disconnect() async {
    debug('Disconnecting to room: ${_room?.name}');
    final localParticipant = _room?.localParticipant;
    if (localParticipant != null) {
      final audioTracks = localParticipant.audioTracks.values();
      iteratorForEach<LocalAudioTrackPublication>(audioTracks, (publication) {
        debug('ProgrammableVideoWeb::disconnect => unpublishing ${publication.track.kind} track ${publication.trackSid}');
        /* RMC - 20221124 - OURS START */
        try {
          debug('ProgrammableVideoWeb::stopping => ${publication.track.kind} track ${publication.trackSid}');
          publication.track.stop();
        } catch (err) {
          debug('Error at disabling track $err');
        }
        debug('ProgrammableVideoWeb::disconnect => unpublishing ${publication.track.kind} track ${publication.trackSid}');
        /* RMC - 20221124 - OURS END */
        _room?.localParticipant.unpublishTrack(publication.track);
        return false;
      });

      final videoTracks = localParticipant.videoTracks.values();
      iteratorForEach<LocalVideoTrackPublication>(videoTracks, (publication) {
        debug('ProgrammableVideoWeb::disconnect => unpublishing ${publication.track.kind} track ${publication.trackSid}');

        /* RMC - 20221124 - OURS START */
        try {
          debug('ProgrammableVideoWeb::stopping => ${publication.track.kind} track ${publication.trackSid}');
          publication.track.stop();
        } catch (err) {
          debug('Error at disabling track $err');
        }
        debug('ProgrammableVideoWeb::disconnect => unpublishing ${publication.track.kind} track ${publication.trackSid}');
        /* RMC - 20221124 - OURS END */
        _room?.localParticipant.unpublishTrack(publication.track);
        return false;
      });

      final dataTracks = localParticipant.dataTracks.values();
      iteratorForEach<LocalDataTrackPublication>(dataTracks, (publication) {
        debug('ProgrammableVideoWeb::disconnect => unpublishing ${publication.track.kind} track ${publication.trackSid}');
        _room?.localParticipant.unpublishTrack(publication.track);
        return false;
      });
    } else {
      try {
        debug('ProgrammableVideoWeb::stopping microphone tracks manually');
        microphoneTrack?.stop();
        debug('ProgrammableVideoWeb::stopping camera tracks manually');
        cameraTrack?.stop();
        shareTrack?.stop();
      } catch (err) {
        debug('Error at stopping track $err');
      }
    }

    _roomListener?.removeListeners();
    _localParticipantListener?.removeListeners();
    _room?.disconnect();
    _room = null;
    _roomListener = null;
    _localParticipantListener = null;
  }

  @override
  Future<bool> enableAudioTrack(bool enable, String name) {
    final localAudioTracks = _room?.localParticipant.audioTracks.values();
    if (localAudioTracks != null) {
      iteratorForEach<LocalAudioTrackPublication>(localAudioTracks, (localAudioTrack) {
        final found = localAudioTrack.trackName == name;
        if (found) {
          enable ? localAudioTrack.track.enable() : localAudioTrack.track.disable();
        }
        return found;
      });
      debug('${enable ? 'Enabled' : 'Disabled'} Local Audio Track');
      return Future(() => enable);
    } else {
      throw PlatformException(code: 'NOT_FOUND', message: 'No LocalAudioTrack found with the name \'$name\'');
    }
  }

  /* RMC 20221124 - OURS STARTS */

  /// ### Gets the [MediaStream] from the `getDisplayMedia` method natively.
  ///
  /// - If it is not supported, it will fallback to `getUserMedia` with the `video: {mediaSource: 'screen'}` constraint.
  ///
  /// - If it fails, it will throw an error.
  ///
  /// #### Note: `dart:html` does not support `getDisplayMedia` yet as it uses the sky_engine implementation.
  ///
  Future<html.MediaStream> _getDisplayMedia(Map<String, dynamic> mediaConstraints) async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) throw Exception('MediaDevices is null');

      if (js_util.hasProperty(mediaDevices, 'getDisplayMedia')) {
        final arg = js_util.jsify(mediaConstraints);
        return await js_util.promiseToFuture<html.MediaStream>(js_util.callMethod(mediaDevices, 'getDisplayMedia', [arg]));
      } else {
        return await html.window.navigator.getUserMedia(video: {'mediaSource': 'screen'}, audio: mediaConstraints['audio'] ?? false);
      }
    } catch (err) {
      throw Exception('Failed to getDisplayMedia (Permission Denied or User canceled): $err');
    }
  }

  /// Calls native code to start screen share
  ///
  /// * Returns a [Future] that completes with a [Widget] indicating whether the screen share init was successful.
  ///
  /// ### Possible outcomes:
  /// [Widget] : the screen share was _**successful**_
  ///
  /// [null] : the screen share was _**cancelled**_ or _**permission is not granted**_
  ///
  /// [Exception] : screen share _**failed**_ or is _**not supported by the browser**_
  ///
  /// This function uses the Twilio Programmable Video SDK to [publish a track](https://media.twiliocdn.com/sdk/js/video/releases/2.13.1/docs/LocalParticipant.html#publishTrack__anchor)
  @override
  Future<Widget?> startScreenShare() async {
    final room = _room;
    if (room != null) {
      try {
        final tag = 'screen-share-html';
        _screenShareVideoElement = html.VideoElement();
        ui.platformViewRegistry.registerViewFactory(tag, (int viewId) => _screenShareVideoElement!);

        _screenShareWidget = HtmlElementView(viewType: tag);

        final mediaStream = await _getDisplayMedia({'video': true});
        shareTrack = mediaStream.getTracks().first;
        _screenShareVideoElement!.srcObject = mediaStream;
        _screenShareVideoElement!.autoplay = true;

        debug(' >>> shareTrack.kind: ${shareTrack!.kind}');
        debug(' >>> shareTrack.id: ${shareTrack!.id}');
        debug(' >>> shareTrack.constraints: ${shareTrack!.getConstraints()}');
        debug(' >>> shareTrack.settings: ${shareTrack!.getSettings()}');
        debug(' >>> shareTrack.capabilities: ${shareTrack!.getCapabilities()}');

        final localParticipant = room.localParticipant;

        // Add the track to the local participant tracks
        debug('Publishing startShareScreen() >> ${shareTrack!.label}');

        final shareLocalTrack = LocalVideoTrack(
          shareTrack!,
          CreateLocalTrackOptions(name: 'screen-share:${shareTrack!.label ?? 'screen:0'}'),
        );

        final publishedTrack = await localParticipant.publishTrack(shareLocalTrack);
        try {
          // listen to the track and unpublish it when it ends
          shareTrack!.onEnded.listen((_) {
            debug('Screen share track ended');
            shareTrack!.stop();
            localParticipant.unpublishTrack(shareTrack);
            _shareTrackSid = '';
          });
          final sid = publishedTrack.trackSid as String?;
          if (sid != null) {
            _shareTrackSid = sid;
          } else {
            _shareTrackSid = shareTrack!.id!;
          }

          debug('Published track sid >> $_shareTrackSid');
          debug('Published track >> ${shareTrack!.id!}');
          debug('Created view factory for >> local screen share');

          localParticipant.videoTracks.toDartMap()[_shareTrackSid] = publishedTrack as LocalVideoTrackPublication;
        } catch (err) {
          debug('Error at saving video tracks: $err');
        }
        return _screenShareWidget;
      } catch (err) {
        debug('Screen share permission not allowed: ${err.toString()}');
        return Container();
      }
    }
    return Container();
  }

  /// Calls native code to stop screen share
  ///
  /// This function uses the Twilio Programmable Video SDK to [unpublish a track](https://media.twiliocdn.com/sdk/js/video/releases/2.13.1/docs/LocalParticipant.html#unpublishTrack__anchor)
  @override
  void stopScreenShare() async {
    final room = _room;
    if (room != null) {
      try {
        final localParticipant = room.localParticipant;
        final localVideoTracks = localParticipant.videoTracks.values();
        iteratorForEach<LocalVideoTrackPublication>(localVideoTracks, (localVideoTrack) {
          final found = localVideoTrack.track.id == shareTrack!.id;
          if (found) {
            localVideoTrack.track.stop();
            localParticipant.unpublishTrack(localVideoTrack.track);
            _shareTrackSid = '';
          }
          return found;
        });
      } catch (err) {
        debug('Error at stopScreenShare() >> $err');
      }
    }
  }

  /// Calls native code to set the preferred camera device id.
  @override
  Future<bool> setCameraDeviceId(String deviceId) async {
    final localVideoTracks = _room?.localParticipant.videoTracks.values();
    if (localVideoTracks != null) {
      final mediaDevices = html.window.navigator.mediaDevices;
      await mediaDevices!.getUserMedia({
        'video': {'deviceId': deviceId},
      }).then((html.MediaStream stream) {
        if (cameraMediaStream != null) {
          cameraMediaStream!.getTracks().forEach((track) {
            track.stop();
          });
          _room?.localParticipant.unpublishTrack(cameraTrack);
        }
        cameraMediaStream = stream;
        cameraTrack = cameraMediaStream!.getTracks().first;
        _cameraVideoElement!.srcObject = cameraMediaStream;
        _cameraVideoElement!.autoplay = true;
        _cameraLocalTrack = LocalVideoTrack(cameraTrack, CreateLocalTrackOptions(name: 'camera-device-' + deviceId));

        _room?.localParticipant.publishTrack(_cameraLocalTrack);
      });
      return Future(() => true);
    } else {
      throw PlatformException(code: 'NOT_FOUND', message: 'No LocalAudioTrack found with the name \'$deviceId\'');
    }
  }

  /// Calls native code to set the preferred microphone device id.
  @override
  Future<bool> setMicrophoneDeviceId(String deviceId) {
    final localAudioTracks = _room?.localParticipant.audioTracks.values();
    if (localAudioTracks != null) {
      final mediaDevices = html.window.navigator.mediaDevices;
      mediaDevices!.getUserMedia({
        'audio': {'deviceId': deviceId},
      }).then((html.MediaStream stream) {
        if (microphoneMediaStream != null) {
          microphoneMediaStream!.getTracks().forEach((track) {
            track.stop();
          });
          _room?.localParticipant.unpublishTrack(microphoneTrack);
        }
        microphoneMediaStream = stream;
        microphoneTrack = microphoneMediaStream!.getTracks().first;
        _microphoneLocalTrack = LocalAudioTrack(microphoneTrack, CreateLocalTrackOptions(name: 'microphone-device-' + deviceId));
        _room?.localParticipant.publishTrack(_microphoneLocalTrack!);
      });
      return Future(() => true);
    } else {
      throw PlatformException(code: 'NOT_FOUND', message: 'No LocalAudioTrack found with the name \'$deviceId\'');
    }
  }

  /// Calls native code to set the preferred speaker device id.
  @override
  Future<bool> setSpeakerDeviceId(String deviceId) async {
    speakerDeviceId = deviceId;
    final remoteParticipants = _room?.participants.values();

    if (remoteParticipants != null) {
      iteratorForEach<RemoteParticipant>(remoteParticipants, (remoteParticipant) {
        final remoteAudioTracks = remoteParticipant.audioTracks.values();
        iteratorForEach<RemoteAudioTrackPublication>(remoteAudioTracks, (remoteAudioTrack) {
          final audioTrack = remoteAudioTrack.track;
          if (audioTrack != null) {
            debug('Detaching remote audio track >> ${audioTrack.name}');
            audioTrack.detach();
            debug('Attaching remote audio track >> ${audioTrack.name} to device >> $deviceId');
            final audioElement = audioTrack.attach();
            audioElement.setSinkId(speakerDeviceId).then((value) {
              audioElement.id = audioTrack.name;
              document.body?.append(audioElement);
            });
          }
          return true;
        });
        return true;
      });
    }
    return Future(() => true);
  }

  @override
  Future<bool> enableVideoTrack(bool enable, String name) {
    final localVideoTracks = _room?.localParticipant.videoTracks.values();
    if (localVideoTracks != null) {
      final localVideoTrack = localVideoTracks.next().value;
      if (enable) {
        localVideoTrack.track.enable();
      } else {
        localVideoTrack.track.disable();
      }
      debug('${enable ? 'Enabled' : 'Disabled'} Local Video Track');
      return Future(() => enable);
    } else {
      throw PlatformException(code: 'NOT_FOUND', message: 'No LocalVideoTrack found with the name \'$name\'');
    }
  }

  @override
  Future<void> setNativeDebug(bool native, bool audio) async {
    final logger = Logger.getLogger('twilio-video');
    // Currently also enabling SDK debugging when native is true
    if (native && !_sdkDebugSetup) {
      final originalFactory = logger.methodFactory;
      logger.methodFactory = allowInterop((methodName, logLevel, loggerName) {
        final method = originalFactory(methodName, logLevel, loggerName);
        return allowInterop((datetime, logLevel, component, message, [data = '', misc = '']) {
          final output = '[  WEBSDK  ] $datetime $logLevel $component $message $data';
          method(output, datetime, logLevel, component, message, data);
        });
      });
      _sdkDebugSetup = true;
    }
    // Adding native debugging
    _nativeDebug = native;

    // Adding sdk debugging (can be set to 'debug' for more detail"
    native ? logger.setLevel('info') : logger.setLevel('warn');
  }

  @override
  Future<bool> setSpeakerphoneOn(bool on) {
    return Future(() => true);
  }

  @override
  Future<bool> getSpeakerphoneOn() {
    return Future(() => true);
  }

  @override
  Future<List<CameraSource>> getSources() {
    return Future(() => []);
  }

  @override
  Future<CameraSource> switchCamera(CameraSource source) {
    return Future(() => source);
  }

  @override
  Future<void> setTorch(bool enabled) async {}

  @override
  Future<void> sendMessage(String message, String name) {
    final localDataTracks = _room?.localParticipant.dataTracks.values();
    var found = false;
    if (localDataTracks != null) {
      iteratorForEach<LocalDataTrackPublication>(localDataTracks, (localDataTrackPublication) {
        if (localDataTrackPublication.trackName == name) {
          localDataTrackPublication.track.send(message);
          found = true;
        }
        return found;
      });
    }

    if (found) {
      debug('Sent the string message: $message for local data track: $name');
    } else {
      throw PlatformException(code: 'NOT_FOUND', message: 'No LocalDataTrack found with the name \'$name\'');
    }
    return Future(() {});
  }

  @override
  Future<void> sendBuffer(ByteBuffer message, String name) {
    final localDataTracks = _room?.localParticipant.dataTracks.values();
    var found = false;
    if (localDataTracks != null) {
      iteratorForEach<LocalDataTrackPublication>(localDataTracks, (localDataTrackPublication) {
        if (localDataTrackPublication.trackName == name) {
          localDataTrackPublication.track.send(message);
          found = true;
        }
        return found;
      });
    }

    if (found) {
      debug('Sent the buffer message: $message for local data track: $name');
    } else {
      throw PlatformException(code: 'NOT_FOUND', message: 'No LocalDataTrack found with the name \'$name\'');
    }
    return Future(() {});
  }

  RemoteAudioTrack? _getRemoteAudioTrack(String sid) {
    var remoteAudioTrack;
    final room = _room;
    if (room != null) {
      iteratorForEach<RemoteParticipant>(room.participants.values(), (remoteParticipant) {
        var found = false;
        iteratorForEach<RemoteAudioTrackPublication>(remoteParticipant.audioTracks.values(), (audioTrack) {
          if (audioTrack.trackSid == sid) {
            remoteAudioTrack = audioTrack.track;
            found = true;
          }
          return found;
        });
        return found;
      });
      if (remoteAudioTrack == null) {
        throw PlatformException(code: 'NOT_FOUND', message: 'The track with sid: $sid was not found');
      }
      return remoteAudioTrack;
    }
    return null;
  }

  @override
  Future<void> enableRemoteAudioTrack(bool enable, String sid) {
    final remoteAudioTrack = _getRemoteAudioTrack(sid);
    if (remoteAudioTrack == null) {
      throw PlatformException(
        code: 'NOT_FOUND',
        message: 'No RemoteAudioTrack found with sid $sid',
        details: null,
      );
    }

    final remoteTrackElement = document.getElementById(remoteAudioTrack.name) as AudioElement?;
    if (remoteTrackElement == null) {
      throw PlatformException(
        code: 'NOT_FOUND',
        message: 'No AudioElement found for RemoteAudioTrack with sid: $sid',
        details: null,
      );
    }

    remoteTrackElement.muted = !enable;

    debug('${enable ? 'Enabled' : 'Disabled'} Remote Audio Track');
    return Future(() {});
  }

  @override
  Future<bool> isRemoteAudioTrackPlaybackEnabled(String sid) {
    final remoteAudioTrack = _getRemoteAudioTrack(sid);
    if (remoteAudioTrack == null) {
      return Future.value(false);
    }
    final remoteTrackElement = document.getElementById(remoteAudioTrack.name) as AudioElement?;
    final isEnabled = remoteTrackElement != null ? !remoteTrackElement.muted : false;
    return Future(() => isEnabled);
  }

  //#endregion

  //#region Streams

  /// Stream of the Screen share ended event.
  ///
  /// This stream is used to listen screen share termination from the user (not from ui).
  @override
  Stream<dynamic>? onScreenShareEndedStream() {
    return shareTrack?.onEnded;
  }

  @override
  Stream<BaseCameraEvent> cameraStream() {
    return _cameraStreamController.stream;
  }

  @override
  Stream<BaseRoomEvent> roomStream(int internalId) {
    return _roomStreamController.stream;
  }

  @override
  Stream<BaseRemoteParticipantEvent> remoteParticipantStream(int internalId) {
    return _remoteParticipantController.stream;
  }

  @override
  Stream<BaseLocalParticipantEvent> localParticipantStream(int internalId) {
    return _localParticipantController.stream;
  }

  @override
  Stream<BaseRemoteDataTrackEvent> remoteDataTrackStream(int internalId) {
    return _remoteDataTrackController.stream;
  }

  @override
  Stream<dynamic> loggingStream() {
    return _loggingStreamController.stream;
  }
//#endregion
}
