import 'dart:async';
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_data_track.dart';
import 'package:twilio_programmable_video_web/src/listeners/base_listener.dart';

class RemoteDataTrackEventListener extends BaseListener {
  final RemoteDataTrack _remoteDataTrack;
  final StreamController<BaseRemoteDataTrackEvent> _remoteDataTrackController;

  RemoteDataTrackEventListener(this._remoteDataTrack, this._remoteDataTrackController);

  void addListeners() {
    debug('Adding RemoteDataTrackListeners for ${_remoteDataTrack.sid}');
    _remoteDataTrack.on('message', allowInterop(onMessage));
  }

  void removeListeners() {
    debug('Removing RemoteDataTrackListeners for ${_remoteDataTrack.sid}');
    _remoteDataTrack.off('message', allowInterop(onMessage));
  }

  void onMessage(dynamic data, RemoteDataTrack track) {
    if (data is String) {
      debug('Added RemoteDataTrack StringMessage Event');
      _remoteDataTrackController.add(StringMessage(track.toModel(), data));
    } else if (data is ByteBuffer) {
      debug('Added RemoteDataTrack BufferMessage Event');
      _remoteDataTrackController.add(BufferMessage(track.toModel(), data));
    } else {
      debug('Added RemoteDataTrack Unknown Event');
      _remoteDataTrackController.add(UnknownEvent(track.toModel(), data));
    }
  }
}
