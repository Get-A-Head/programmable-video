import 'dart:async';

import 'package:dartlin/dartlin.dart';
import 'package:js/js.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/js_map.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_participant.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/room.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/twilio_error.dart';
import 'package:twilio_programmable_video_web/src/listeners/base_listener.dart';
import 'package:twilio_programmable_video_web/src/listeners/remote_participant_event_listener.dart';

class RoomEventListener extends BaseListener {
  final Room _room;
  final StreamController<BaseRoomEvent> _roomStreamController;
  final StreamController<BaseRemoteParticipantEvent> _remoteParticipantController;
  final Map<String, RemoteParticipantEventListener> _remoteParticipantListeners = {};
  /* TWILIO - 1.0.1
  RoomEventListener(this._room, this._roomStreamController, this._remoteParticipantController) {
    _addPriorRemoteParticipantListeners();
  }
   */
  /// OUR IMPLEMENTATION - START
  final StreamController<BaseRemoteDataTrackEvent> _remoteDataTrackController;
  RoomEventListener(this._room, this._roomStreamController, this._remoteParticipantController, this._remoteDataTrackController) {
    _addPriorRemoteParticipantListeners();
  }

  /// OUR IMPLEMENTATION - END

  void addListeners() {
    debug('Adding RoomEventListeners for ${_room.sid}');
    _on('disconnected', onDisconnected);
    _on('dominantSpeakerChanged', onDominantSpeakerChanged);
    _on('participantConnected', onParticipantConnected);
    _on('participantDisconnected', onParticipantDisconnected);
    _on('reconnected', onReconnected);
    _on('reconnecting', onReconnecting);
    _on('recordingStarted', onRecordingStarted);
    _on('recordingStopped', onRecordingStopped);
  }

  void removeListeners() {
    debug('Removing RoomEventListeners for ${_room.sid} - ${_remoteParticipantListeners.length}');
    _off('disconnected', onDisconnected);
    _off('dominantSpeakerChanged', onDominantSpeakerChanged);
    _off('participantConnected', onParticipantConnected);
    _off('participantDisconnected', onParticipantDisconnected);
    _off('reconnected', onReconnected);
    _off('reconnecting', onReconnecting);
    _off('recordingStarted', onRecordingStarted);
    _off('recordingStopped', onRecordingStopped);
    _remoteParticipantListeners.values.forEach((remoteParticipantListener) => remoteParticipantListener.removeListeners());
    _remoteParticipantListeners.clear();
  }

  void _addPriorRemoteParticipantListeners() {
    final remoteParticipants = _room.participants.values();
    iteratorForEach<RemoteParticipant>(remoteParticipants, (remoteParticipant) {
      /* TWILIO - 1.0.1
      final remoteParticipantListener = RemoteParticipantEventListener(remoteParticipant, _remoteParticipantController, _remoteDataTrackController);
       */
      /// OUR IMPLEMENTATION - START
      final remoteParticipantListener = RemoteParticipantEventListener(remoteParticipant, _remoteParticipantController, _remoteDataTrackController);
      remoteParticipantListener.addListeners();
      _remoteParticipantListeners[remoteParticipant.sid] = remoteParticipantListener;
      return false;

      /// OUR IMPLEMENTATION - END
    });
  }

  void _on(String eventName, Function eventHandler) => _room.on(
        eventName,
        allowInterop(eventHandler),
      );

  void _off(String eventName, Function eventHandler) => _room.off(
        eventName,
        allowInterop(eventHandler),
      );

  void onDisconnected(Room room, dynamic error) {
    debug('On Disconnected Room Event');
    debug(error.toString());
    if (error is TwilioError?) {
      _roomStreamController.add(Disconnected(room.toModel(), error?.let((it) => it.toModel())));
    } else {
      _roomStreamController.add(Disconnected(room.toModel(), null));
    }
    debug('Added Disconnected Room Event');
  }

  void onDominantSpeakerChanged(RemoteParticipant? dominantSpeaker) {
    _roomStreamController.add(DominantSpeakerChanged(_room.toModel(), dominantSpeaker?.toModel()));
    debug('Added DominantSpeakerChanged Room Event');
  }

  void onParticipantConnected(RemoteParticipant participant) {
    _roomStreamController.add(ParticipantConnected(_room.toModel(), participant.toModel()));
    debug('Added ParticipantConnected Room Event');
    /* TWILIO - 1.0.1
    final remoteParticipantListener = RemoteParticipantEventListener(participant, _remoteParticipantController);

     */
    /// OUR IMPLEMENTATION - START
    final remoteParticipantListener = RemoteParticipantEventListener(participant, _remoteParticipantController, _remoteDataTrackController);
    remoteParticipantListener.addListeners();
    _remoteParticipantListeners[participant.sid] = remoteParticipantListener;

    /// OUR IMPLEMENTATION - END
  }

  void onParticipantDisconnected(RemoteParticipant participant) {
    _roomStreamController.add(
      ParticipantDisconnected(_room.toModel(), participant.toModel()),
    );
    final remoteParticipantListener = _remoteParticipantListeners.remove(participant.sid);
    remoteParticipantListener?.removeListeners();
    debug('Added ParticipantDisconnected Room Event');
  }

  void onReconnected() {
    _roomStreamController.add(Reconnected(_room.toModel()));
    debug('Added Reconnected Room Event');
  }

  void onReconnecting(dynamic error) {
    if (error is TwilioError) {
      _roomStreamController.add(Reconnecting(_room.toModel(), error.toModel()));
    } else {
      _roomStreamController.add(Reconnecting(_room.toModel(), null));
    }
    debug('Added Reconnecting Room Event');
  }

  void onRecordingStarted() {
    _roomStreamController.add(RecordingStarted(_room.toModel()));
    debug('Added RecordingStarted Room Event');
  }

  void onRecordingStopped() {
    _roomStreamController.add(RecordingStopped(_room.toModel()));
    debug('Added RecordingStopped Room Event');
  }
}
