@JS()
library remote_audio_track;

import 'dart:html';

import 'package:js/js.dart';
import 'package:programmable_video_web/src/interop/classes/remote_media_track.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.RemoteAudioTrack')
class RemoteAudioTrack extends RemoteMediaTrack {
  external factory RemoteAudioTrack(
    dynamic sid,
    dynamic mediaTrackReceiver,
    dynamic isEnabled,
    dynamic isSwitchedOff,
    dynamic setPriority,
    dynamic options,
  );

  external AudioElement attach();
}

extension Interop on RemoteAudioTrack {
  RemoteAudioTrackModel toModel() {
    return RemoteAudioTrackModel(
      enabled: isEnabled,
      name: name,
      sid: sid,
    );
  }
}
