@JS()
library remote_media_track;

import 'package:js/js.dart';
import 'package:programmable_video_web/src/interop/classes/track.dart';

@JS('Twilio.Video.RemoteMediaTrack')
class RemoteMediaTrack extends Track {
  external bool get isEnabled;
  external bool get isSwitchedOff;
  external String get sid;
  external dynamic get priority;

  external factory RemoteMediaTrack(
    dynamic sid,
    dynamic mediaTrackReceiver,
    dynamic isEnabled,
    dynamic isSwitchedOff,
    dynamic setPriority,
    dynamic options,
  );
}
