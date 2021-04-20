import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dartlin/dartlin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:pedantic/pedantic.dart';
import 'package:programmable_video_web/src/interop/classes/js_map.dart';
import 'package:programmable_video_web/src/interop/classes/local_audio_track.dart';
import 'package:programmable_video_web/src/interop/classes/local_audio_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/local_data_track.dart';
import 'package:programmable_video_web/src/interop/classes/local_data_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/local_participant.dart';
import 'package:programmable_video_web/src/interop/classes/local_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/local_video_track.dart';
import 'package:programmable_video_web/src/interop/classes/local_video_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/remote_audio_track.dart';
import 'package:programmable_video_web/src/interop/classes/remote_audio_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/remote_data_track.dart';
import 'package:programmable_video_web/src/interop/classes/remote_data_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/remote_participant.dart';
import 'package:programmable_video_web/src/interop/classes/remote_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/remote_video_track.dart';
import 'package:programmable_video_web/src/interop/classes/remote_video_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/room.dart';
import 'package:programmable_video_web/src/interop/classes/track.dart';
import 'package:programmable_video_web/src/interop/classes/twilio_error.dart';
import 'package:programmable_video_web/src/interop/connect.dart';
import 'package:programmable_video_web/src/interop/network_quality_level.dart';

import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

class ProgrammableVideoPlugin extends ProgrammableVideoPlatform {
  static Room _room;

  static final _roomStreamController = StreamController<BaseRoomEvent>();
  static final _localParticipantController = StreamController<BaseLocalParticipantEvent>();
  static final _remoteParticipantController = StreamController<BaseRemoteParticipantEvent>();

  static void registerWith(Registrar registrar) {
    ProgrammableVideoPlatform.instance = ProgrammableVideoPlugin();
  }

  //#region Functions
  @override
  Widget createLocalVideoTrackWidget({bool mirror = true, Key key}) {
    if (_room == null) {
      return null;
    }

    final localVideoTrackElement = _room.localParticipant.videoTracks.values().next().value.track.attach()..style.objectFit = 'cover';

    ui.platformViewRegistry.registerViewFactory(
      'local-video-track-html',
      (int viewId) => localVideoTrackElement,
    );

    return HtmlElementView(viewType: 'local-video-track-html');
  }

  @override
  Widget createRemoteVideoTrackWidget({
    String remoteParticipantSid,
    String remoteVideoTrackSid,
    bool mirror = true,
    Key key,
  }) {
    final remoteVideoTrackElement = _room.participants.toDartMap()[remoteParticipantSid].videoTracks.toDartMap()[remoteVideoTrackSid].track.attach()..style.objectFit = 'cover';

    ui.platformViewRegistry.registerViewFactory(
      'remote-video-track-#$remoteVideoTrackSid-html',
      (int viewId) => remoteVideoTrackElement,
    );

    return HtmlElementView(viewType: 'remote-video-track-#$remoteVideoTrackSid-html');
  }

  @override
  Future<int> connectToRoom(ConnectOptionsModel connectOptions) async {
    unawaited(
      connectWithModel(connectOptions).then((room) {
        _room = room;

        _roomStreamController.add(
          Connected(_room.toModel()),
        );

        _addRoomEventListeners();
        _addLocalParticipantEventListeners(_room.localParticipant);
      }),
    );

    return 0;
  }

  @override
  Future<void> disconnect() async {
    _room?.disconnect();
  }

  @override
  Future<bool> enableAudioTrack({bool enable, String name}) {
    final localAudioTrack = _room?.localParticipant?.audioTracks?.values()?.next()?.value?.track;

    enable ? localAudioTrack?.enable() : localAudioTrack?.disable();

    return Future(() => enable);
  }

  @override
  Future<bool> enableVideoTrack({bool enabled, String name}) {
    final localVideoTrack = _room?.localParticipant?.videoTracks?.values()?.next()?.value?.track;

    enabled ? localVideoTrack?.enable() : localVideoTrack?.disable();

    return Future(() => enabled);
  }

  @override
  Future<void> setNativeDebug(bool native) async {}

  @override
  Future<bool> setSpeakerphoneOn(bool on) {
    return Future(() => true);
  }

  @override
  Future<bool> getSpeakerphoneOn() {
    return Future(() => true);
  }

  @override
  Future<CameraSource> switchCamera() {
    return Future(() => CameraSource.FRONT_CAMERA);
  }

  @override
  Future<bool> hasTorch() async {
    return Future(() => false);
  }

  @override
  Future<void> setTorch(bool enabled) async {}

  @override
  Future<void> sendMessage({String message, String name}) {
    return Future(() {});
  }

  @override
  Future<void> sendBuffer({ByteBuffer message, String name}) {
    return Future(() {});
  }

  @override
  Future<void> enableRemoteAudioTrack({bool enable, String sid}) {
    return Future(() {});
  }

  @override
  Future<bool> isRemoteAudioTrackPlaybackEnabled(String sid) {
    return Future(() => false);
  }

  //#endregion

  //#region Streams
  @override
  Stream<BaseCameraEvent> cameraStream() {
    return Stream.empty();
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
    return Stream.empty();
  }

  @override
  Stream<dynamic> loggingStream() {
    return Stream.empty();
  }
  //#endregion

  void _addRoomEventListeners() {
    void on(String eventName, Function eventHandler) => _room.on(
          eventName,
          allowInterop(eventHandler),
        );

    on(
      'disconnected',
      (Room room, TwilioError error) => _roomStreamController.add(Disconnected(
        room.toModel(),
        error.let((it) => it.toModel()),
      )),
    );
    on(
      'dominantSpeakerChanged',
      (RemoteParticipant dominantSpeaker) => _roomStreamController.add(
        DominantSpeakerChanged(_room.toModel(), dominantSpeaker.toModel()),
      ),
    );
    on('participantConnected', (RemoteParticipant participant) {
      _roomStreamController.add(
        ParticipantConnected(_room.toModel(), participant.toModel()),
      );
      _addRemoteParticipantEventListeners(participant);
    });
    on(
      'participantDisconnected',
      (RemoteParticipant participant) => _roomStreamController.add(
        ParticipantDisconnected(_room.toModel(), participant.toModel()),
      ),
    );
    on(
      'reconnected',
      () => _roomStreamController.add(
        Reconnected(_room.toModel()),
      ),
    );
    on(
      'reconnecting',
      (TwilioError error) => _roomStreamController.add(
        Reconnecting(_room.toModel(), error.toModel()),
      ),
    );
    on(
      'recordingStarted',
      () => _roomStreamController.add(
        RecordingStarted(_room.toModel()),
      ),
    );
    on(
      'recordingStopped',
      () => _roomStreamController.add(
        RecordingStopped(_room.toModel()),
      ),
    );
  }

  void _addLocalParticipantEventListeners(LocalParticipant localParticipant) {
    localParticipant.on('trackPublished', allowInterop((LocalTrackPublication publication) {
      when(publication.kind, {
        'audio': () {
          _localParticipantController.add(LocalAudioTrackPublished(
            localParticipant.toModel(),
            (publication as LocalAudioTrackPublication).toModel(),
          ));
        },
        'data': () {
          _localParticipantController.add(LocalDataTrackPublished(
            localParticipant.toModel(),
            (publication as LocalDataTrackPublication).toModel(),
          ));
        },
        'video': () {
          _localParticipantController.add(LocalVideoTrackPublished(
            localParticipant.toModel(),
            (publication as LocalVideoTrackPublication).toModel(),
          ));
        },
      });
    }));

    localParticipant.on('trackPublicationFailed', allowInterop((TwilioError error, dynamic localTrack) {
      when(localTrack.kind, {
        'audio': () {
          _localParticipantController.add(LocalAudioTrackPublicationFailed(
            exception: error.toModel(),
            localAudioTrack: (localTrack as LocalAudioTrack).toModel(),
            localParticipantModel: localParticipant.toModel(),
          ));
        },
        'data': () {
          _localParticipantController.add(LocalDataTrackPublicationFailed(
            exception: error.toModel(),
            localDataTrack: (localTrack as LocalDataTrack).toModel(true),
            localParticipantModel: localParticipant.toModel(),
          ));
        },
        'video': () {
          _localParticipantController.add(LocalVideoTrackPublicationFailed(
            exception: error.toModel(),
            localVideoTrack: (localTrack as LocalVideoTrack).toModel(),
            localParticipantModel: localParticipant.toModel(),
          ));
        },
      });
    }));

    localParticipant.on(
      'networkQualityLevelChanged',
      allowInterop(
        (int networkQualityLevel, dynamic networkQualityStats) {
          _localParticipantController.add(
            LocalNetworkQualityLevelChanged(
              localParticipant.toModel(),
              networkQualityLevelFromInt(networkQualityLevel),
            ),
          );
        },
      ),
    );
  }

  void _addRemoteParticipantEventListeners(RemoteParticipant remoteParticipant) {
    void on(String eventName, Function eventHandler) => remoteParticipant.on(
          eventName,
          allowInterop(eventHandler),
        );

    void onPublication(
      String eventName, {
      void Function(RemoteAudioTrackPublication remoteAudioTrackPublication) audioHandler,
      void Function(RemoteDataTrackPublication remoteDataTrackPublication) dataHandler,
      void Function(RemoteVideoTrackPublication remoteVideoTrackPublication) videoHandler,
    }) {
      on(eventName, (RemoteTrackPublication publication) {
        when(publication.kind, {
          'audio': () => audioHandler?.call(publication),
          'data': () => dataHandler?.call(publication),
          'video': () => videoHandler?.call(publication),
        });
      });
    }

    onPublication(
      'trackDisabled',
      audioHandler: (publication) => _remoteParticipantController.add(
        RemoteAudioTrackDisabled(
          remoteParticipant.toModel(),
          publication.toModel(),
        ),
      ),
      videoHandler: (publication) => _remoteParticipantController.add(
        RemoteVideoTrackDisabled(
          remoteParticipant.toModel(),
          publication.toModel(),
        ),
      ),
    );

    onPublication(
      'trackEnabled',
      audioHandler: (publication) => _remoteParticipantController.add(
        RemoteAudioTrackEnabled(
          remoteParticipant.toModel(),
          publication.toModel(),
        ),
      ),
      videoHandler: (publication) => _remoteParticipantController.add(
        RemoteVideoTrackEnabled(
          remoteParticipant.toModel(),
          publication.toModel(),
        ),
      ),
    );

    onPublication(
      'trackPublished',
      audioHandler: (publication) => _remoteParticipantController.add(
        RemoteAudioTrackPublished(
          remoteParticipant.toModel(),
          publication.toModel(),
        ),
      ),
      dataHandler: (publication) => _remoteParticipantController.add(
        RemoteDataTrackPublished(
          remoteParticipant.toModel(),
          publication.toModel(),
        ),
      ),
      videoHandler: (publication) => _remoteParticipantController.add(
        RemoteVideoTrackPublished(
          remoteParticipant.toModel(),
          publication.toModel(),
        ),
      ),
    );

    onPublication(
      'trackUnpublished',
      audioHandler: (publication) => _remoteParticipantController.add(
        RemoteAudioTrackUnpublished(
          remoteParticipant.toModel(),
          publication.toModel(),
        ),
      ),
      dataHandler: (publication) => _remoteParticipantController.add(
        RemoteDataTrackUnpublished(
          remoteParticipant.toModel(),
          publication.toModel(),
        ),
      ),
      videoHandler: (publication) => _remoteParticipantController.add(
        RemoteVideoTrackUnpublished(
          remoteParticipant.toModel(),
          publication.toModel(),
        ),
      ),
    );

    on('trackSubscribed', (Track track, RemoteTrackPublication publication) {
      when(track.kind, {
        'audio': () {
          _remoteParticipantController.add(
            RemoteAudioTrackSubscribed(
              remoteParticipantModel: remoteParticipant.toModel(),
              remoteAudioTrackPublicationModel: (publication as RemoteAudioTrackPublication).toModel(),
              remoteAudioTrackModel: (track as RemoteAudioTrack).toModel(),
            ),
          );
        },
        'data': () {
          _remoteParticipantController.add(
            RemoteDataTrackSubscribed(
              remoteParticipantModel: remoteParticipant.toModel(),
              remoteDataTrackPublicationModel: (publication as RemoteDataTrackPublication).toModel(),
              remoteDataTrackModel: (publication as RemoteDataTrack).toModel(),
            ),
          );
        },
        'video': () {
          _remoteParticipantController.add(
            RemoteVideoTrackSubscribed(
              remoteParticipantModel: remoteParticipant.toModel(),
              remoteVideoTrackPublicationModel: (publication as RemoteVideoTrackPublication).toModel(),
              remoteVideoTrackModel: (track as RemoteVideoTrack).toModel(),
            ),
          );
        },
      });
    });

    on('trackUnsubscribed', (Track track, RemoteTrackPublication publication) {
      when(track.kind, {
        'audio': () {
          _remoteParticipantController.add(
            RemoteAudioTrackUnsubscribed(
              remoteParticipantModel: remoteParticipant.toModel(),
              remoteAudioTrackPublicationModel: (publication as RemoteAudioTrackPublication).toModel(),
              remoteAudioTrackModel: (track as RemoteAudioTrack).toModel(),
            ),
          );
        },
        'data': () {
          _remoteParticipantController.add(
            RemoteDataTrackUnsubscribed(
              remoteParticipantModel: remoteParticipant.toModel(),
              remoteDataTrackPublicationModel: (publication as RemoteDataTrackPublication).toModel(),
              remoteDataTrackModel: (publication as RemoteDataTrack).toModel(),
            ),
          );
        },
        'video': () {
          _remoteParticipantController.add(
            RemoteVideoTrackUnsubscribed(
              remoteParticipantModel: remoteParticipant.toModel(),
              remoteVideoTrackPublicationModel: (publication as RemoteVideoTrackPublication).toModel(),
              remoteVideoTrackModel: (track as RemoteVideoTrack).toModel(),
            ),
          );
        },
      });
    });

    on('trackSubscriptionFailed', (TwilioError error, RemoteTrackPublication publication) {
      when(publication.kind, {
        'audio': () {
          _remoteParticipantController.add(
            RemoteAudioTrackSubscriptionFailed(
              remoteParticipantModel: remoteParticipant.toModel(),
              remoteAudioTrackPublicationModel: (publication as RemoteAudioTrackPublication).toModel(),
              exception: error.toModel(),
            ),
          );
        },
        'data': () {
          _remoteParticipantController.add(
            RemoteDataTrackSubscriptionFailed(
              remoteParticipantModel: remoteParticipant.toModel(),
              remoteDataTrackPublicationModel: (publication as RemoteDataTrackPublication).toModel(),
              exception: error.toModel(),
            ),
          );
        },
        'video': () {
          _remoteParticipantController.add(
            RemoteVideoTrackSubscriptionFailed(
              remoteParticipantModel: remoteParticipant.toModel(),
              remoteVideoTrackPublicationModel: (publication as RemoteVideoTrackPublication).toModel(),
              exception: error.toModel(),
            ),
          );
        },
      });
    });

    on('networkQualityLevelChanged', (int networkQualityLevel, dynamic networkQualityStats) {
      _remoteParticipantController.add(
        RemoteNetworkQualityLevelChanged(
          remoteParticipant.toModel(),
          networkQualityLevelFromInt(networkQualityLevel),
        ),
      );
    });
  }
}
