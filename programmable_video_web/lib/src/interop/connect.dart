@JS()
library interop;

import 'dart:html';

import 'package:collection/collection.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_audio_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_data_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_video_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/room.dart';
import 'package:twilio_programmable_video_web/twilio_programmable_video_web.dart';

@JS('Twilio.Video.connect')
external Future<Room> connect(
  String token, [
  ConnectOptions options,
]);

@JS()
@anonymous
class NetworkQualityConfiguration {
  external factory NetworkQualityConfiguration({
    int local,
    int remote,
  });
}

@JS('Twilio.Video.createLocalAudioTrack')
external Future<LocalAudioTrack> createLocalAudioTrack([
  CreateLocalTrackOptions options,
]);

@JS('Twilio.Video.createLocalVideoTrack')
external Future<LocalAudioTrack> createLocalVideoTrack([
  CreateLocalTrackOptions options,
]);

//dynamic types might still need to be implemented with custom classes
@JS()
@anonymous
class ConnectOptions {
  external factory ConnectOptions({
    dynamic audio,
    bool automaticSubscription,
    dynamic bandwidthProfile,
    bool? dominantSpeaker,
    bool dscpTagging,
    bool enableDscp,
    dynamic iceServers,
    dynamic iceTransportPolicy,
    bool insights,
    int maxAudioBitrate,
    int maxVideoBitrate,
    String? name,
    dynamic networkQuality = false,
    String region,
    List<dynamic> preferredAudioCodecs,
    List<dynamic> preferredVideoCodecs,
    dynamic logLevel,
    String loggerName,
    List<dynamic> tracks,
    dynamic video,
  });
}

@JS()
@anonymous
class CreateLocalTrackOptions {
  external factory CreateLocalTrackOptions({
    String name,
  });
}

/// Calls twilio-video.js connect method with values from the [ConnectOptionsModel]
///
/// Setting custom track names is not yet supported.
Future<Room?> connectWithModel(ConnectOptionsModel model) async {
  // In the future tracks should be created manually before calling connect.
  // This would make it possible to use custom track names that might be in the provided model.
  //
  // See:
  // https://media.twiliocdn.com/sdk/js/video/releases/2.13.1/docs/global.html#ConnectOptions__anchor
  // https://media.twiliocdn.com/sdk/js/video/releases/2.13.1/docs/global.html#LocalTrackOptions
  final networkQualityConfiguration = model.networkQualityConfiguration;
  final tracks = <dynamic>[];

  final audioTracks = model.audioTracks;
  if (audioTracks != null) {
    await Future.forEach(audioTracks, (LocalAudioTrackModel track) async {
      /* TWILIO - 1.0.1
      final options = CreateLocalTrackOptions(name: track.name);
      final jsTrack = await promiseToFuture<LocalAudioTrack>(createLocalAudioTrack(options));
      tracks.add(jsTrack);

      */

      /// OUR IMPLEMENTATION -- START
      final options = CreateLocalTrackOptions(name: 'microphone-device-#' + track.name);

      ProgrammableVideoPlugin.debug('Trying to connect audio with specific device id >>> ${track.name}');
      final audioStream = await window.navigator.mediaDevices!.getUserMedia({
        'audio': {'deviceId': track.name},
      });
      if (audioStream.getAudioTracks().isNotEmpty) {
        ProgrammableVideoPlugin.microphoneMediaStream = audioStream;
        ProgrammableVideoPlugin.microphoneTrack = audioStream.getAudioTracks().first;

        final audioTrack = LocalAudioTrack(ProgrammableVideoPlugin.microphoneTrack, options);
        // if (!track.enabled) {
        // ProgrammableVideoPlugin.microphoneTrack!.stop();
        // audioTrack.stop();
        // }
        tracks.add(audioTrack);
      }

      /// OUR IMPLEMENTATION - END
    });
  }

  final videoTracks = model.videoTracks;
  if (videoTracks != null) {
    await Future.forEach(videoTracks, (LocalVideoTrackModel track) async {
      /* TWILIO - 1.0.1
      final options = CreateLocalTrackOptions(name: track.name);
      final jsTrack = await promiseToFuture(createLocalVideoTrack(options));
      tracks.add(jsTrack);

       */

      /// OUR IMPLEMENTATION -- START
      final options = CreateLocalTrackOptions(name: 'camera-device-#' + track.name);

      ProgrammableVideoPlugin.debug('Trying to connect video with specific device id >>> ${track.name}');

      final cameraStream = await window.navigator.mediaDevices!.getUserMedia({
        'video': {'deviceId': track.name},
      });
      if (cameraStream.getTracks().isNotEmpty) {
        ProgrammableVideoPlugin.cameraMediaStream = cameraStream;
        ProgrammableVideoPlugin.cameraTrack = cameraStream.getTracks().first;

        final videoTrack = LocalVideoTrack(ProgrammableVideoPlugin.cameraTrack, options);
        // if (!track.enabled) {
        //   ProgrammableVideoPlugin.cameraTrack!.stop();
        //   videoTrack.disable();
        // }
        tracks.add(videoTrack);
      }

      /// OUR IMPLEMENTATION - END
    });
  }

  /// OUR IMPLEMENTATION -- START
  ProgrammableVideoPlugin.speakerDeviceId = model.speakerDeviceId ?? 'default';

  /// OUR IMPLEMENTATION - END
  final dataTracks = model.dataTracks;
  dataTracks?.forEach((track) async {
    final jsTrack = LocalDataTrack(
      LocalDataTrackOptions(maxRetransmits: track.maxRetransmits >= 0 ? track.maxRetransmits : null, maxPacketLifeTime: track.maxPacketLifeTime >= 0 ? track.maxPacketLifeTime : null, ordered: track.ordered),
    );
    tracks.add(jsTrack);
  });

  final room = await promiseToFuture<Room>(
    connect(
      model.accessToken,
      // Some named parameters are assigned their default values with the ?? operator.
      // This is because those paramaters are optional non nullable parameters in js.
      ConnectOptions(
        automaticSubscription: model.enableAutomaticSubscription ?? true,
        dominantSpeaker: model.enableDominantSpeaker,
        name: model.roomName,
        networkQuality: networkQualityConfiguration != null && model.enableNetworkQuality
            ? NetworkQualityConfiguration(
                local: networkQualityConfiguration.local.index,
                remote: networkQualityConfiguration.remote.index,
              )
            : model.enableNetworkQuality,
        region: model.region != null ? EnumToString.convertToString(model.region) : 'gll',
        preferredAudioCodecs: model.preferredAudioCodecs?.map((e) => e.name).toList() ?? [],
        preferredVideoCodecs: model.preferredVideoCodecs?.map((e) => e.name).toList() ?? [],
        tracks: tracks,
      ),
    ),
  );

  room.localParticipant.audioTracks.forEach((publication, key, map) {
    if (audioTracks != null) {
      final modelTrack = audioTracks.firstWhereOrNull((track) => track.name == publication.trackName);
      if (modelTrack != null) {
        ProgrammableVideoPlugin.debug('ProgrammableVideoWeb::connectWithModel => enableAudioTrack(${modelTrack.name}): ${modelTrack.enabled}');
        modelTrack.enabled ? publication.track.enable() : publication.track.disable();
      }
    }
  });
  // iteratorForEach<LocalAudioTrackPublication>(room.localParticipant.audioTracks.values(), (publication) {
  //   if (audioTracks != null) {
  //     final modelTrack = audioTracks.firstWhereOrNull((track) => track.name == publication.trackName);
  //     if (modelTrack != null) {
  //       ProgrammableVideoPlugin.debug('ProgrammableVideoWeb::connectWithModel => enableAudioTrack(${modelTrack.name}): ${modelTrack.enabled}');
  //       modelTrack.enabled ? publication.track.enable() : publication.track.disable();
  //     }
  //   }
  //   return false;
  // });

  room.localParticipant.videoTracks.forEach((publication, key, map) {
    if (videoTracks != null) {
      final modelTrack = videoTracks.firstWhereOrNull((track) => track.name == publication.trackName);
      if (modelTrack != null) {
        ProgrammableVideoPlugin.debug('ProgrammableVideoWeb::connectWithModel => enableVideoTrack(${modelTrack.name}): ${modelTrack.enabled}');
        modelTrack.enabled ? publication.track.enable() : publication.track.disable();
      }
    }
  });

  // iteratorForEach<LocalVideoTrackPublication>(room.localParticipant.videoTracks.values(), (publication) {
  //   if (videoTracks != null) {
  //     final modelTrack = videoTracks.firstWhereOrNull((track) => track.name == publication.trackName);
  //     if (modelTrack != null) {
  //       ProgrammableVideoPlugin.debug('ProgrammableVideoWeb::connectWithModel => enableVideoTrack(${modelTrack.name}): ${modelTrack.enabled}');
  //       modelTrack.enabled ? publication.track.enable() : publication.track.disable();
  //     }
  //   }
  //   return false;
  // });

  return room;
}
