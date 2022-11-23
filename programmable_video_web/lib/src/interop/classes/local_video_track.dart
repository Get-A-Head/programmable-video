@JS()
library local_video_track;

import 'dart:html';
import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/video_track.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

@JS('Twilio.Video.LocalVideoTrack')
class LocalVideoTrack extends VideoTrack {
  external String get id;
  external bool get isStopped;

  external factory LocalVideoTrack(
    dynamic mediaStreamTrack,
    dynamic options,
  );
  external VideoElement attach();

  external LocalVideoTrack disable();
  external LocalVideoTrack enable();
  external LocalVideoTrack stop();
}

extension Interop on LocalVideoTrack {
  LocalVideoTrackModel toModel() {
    final isScreenShare = name.contains('screen-share');
    return LocalVideoTrackModel(
      cameraCapturer: CameraCapturerModel(
        CameraSource(isScreenShare ? 'SCREEN_SHARE' : 'FRONT_CAMERA', false, false, false),
        'CameraCapturer',
      )..isScreencast = isScreenShare,
      enabled: isEnabled,
      name: name,
    );
  }
}
