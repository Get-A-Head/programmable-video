@JS()
library remote_track_publication_signaling;

import 'package:js/js.dart';

@JS()
@anonymous
class RemoteTrackPublicationSignaling {
  external factory RemoteTrackPublicationSignaling({
    String sid,
    String name,
    // can be "audio", "video", or "data".
    String kind,
    bool isEnabled,
    // can be "low", "standard", or "high".
    String priority,
    bool isSwitchedOff,
  });
}
