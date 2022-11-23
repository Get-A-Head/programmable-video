import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:twilio_programmable_video_platform_interface/src/camera_source.dart';

import 'method_channel_programmable_video.dart';
import 'models/model_exports.dart';

export 'audio_codecs/audio_codec.dart';
export 'enums/enum_exports.dart';
export 'models/model_exports.dart';
export 'video_codecs/video_codec.dart';

/// The interface that implementations of programmable_video must implement.
///
/// Platform implementations should extend this class rather than implement it as `programmable_video`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [ProgrammableVideoPlatform] methods.
abstract class ProgrammableVideoPlatform extends PlatformInterface {
  /// Constructs a ProgrammableVideoPlatform.
  ProgrammableVideoPlatform() : super(token: _token);

  static final Object _token = Object();

  static ProgrammableVideoPlatform _instance = MethodChannelProgrammableVideo();

  /// The default instance of [ProgrammableVideoPlatform] to use.
  ///
  /// Defaults to [MethodChannelProgrammableVideo].
  static ProgrammableVideoPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [ProgrammableVideoPlatform] when they register themselves.
  static set instance(ProgrammableVideoPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  //#region Functions
  /// Calls native code to create a widget displaying the LocalVideoTrack's video.
  Widget createLocalVideoTrackWidget({bool isScreenShare = false, bool mirror = true, Key? key}) {
    throw UnimplementedError('createLocalVideoTrackWidget() has not been implemented.');
  }

  /// Calls native code to create a widget displaying a RemoteVideoTrack's video.
  Widget createRemoteVideoTrackWidget({
    required String remoteParticipantSid,
    required String remoteVideoTrackSid,
    bool mirror = true,
    Key? key,
  }) {
    throw UnimplementedError('createRemoteVideoTrackWidget() has not been implemented.');
  }

  /// Calls native code to disconnect from a room.
  Future<void> disconnect() {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  /// You can listen to these logs on the [loggingStream].
  Future<void> setNativeDebug(bool native) {
    throw UnimplementedError('setNativeDebug() has not been implemented.');
  }

  /// Calls native code to set the speaker mode on or off.
  ///
  /// Returns the new state of the speaker mode.
  Future<bool?> setSpeakerphoneOn(bool on) {
    throw UnimplementedError('setSpeakerphoneOn() has not been implemented.');
  }

  /// Calls native code to check if speaker mode is enabled.
  Future<bool?> getSpeakerphoneOn() {
    throw UnimplementedError('getSpeakerphoneOn() has not been implemented.');
  }

  /// Calls native code to get stats
  Future<Map<dynamic, dynamic>?> getStats() {
    throw UnimplementedError('getStats() has not been implemented.');
  }

  /// Calls native code to check if the device has a receiver.
  Future<bool> deviceHasReceiver() {
    throw UnimplementedError('deviceHasReceiver() has not been implemented.');
  }

  /// Calls native code to connect to a room.
  Future<int?> connectToRoom(ConnectOptionsModel connectOptions) {
    throw UnimplementedError('connectToRoom() has not been implemented.');
  }

  /// Calls native code to create video track
  Future<void> createVideoTrack(LocalVideoTrackModel localVideoTrack) {
    throw UnimplementedError('createVideoTrack() has not been implemented.');
  }

  /// Calls native code to publish video track
  Future<void> publishVideoTrack(String name) {
    throw UnimplementedError('publishVideoTrack() has not been implemented.');
  }

  /// Calls native code to unpublish video track
  Future<void> unpublishVideoTrack(String name) {
    throw UnimplementedError('unpublishVideoTrack() has not been implemented.');
  }

  /// Calls native code to release video track
  Future<void> releaseVideoTrack(String name) {
    throw UnimplementedError('releaseVideoTrack() has not been implemented.');
  }

  /// Calls native code to set the state of the local video track.
  ///
  /// The results of this operation are signaled to other Participants in the same Room.
  /// When a video track is disabled, blank frames are sent in place of video frames from a video capturer.
  Future<bool?> enableVideoTrack(bool enabled, String name) {
    throw UnimplementedError('enableVideoTrack() has not been implemented.');
  }

  /// Calls native code to send a String message.
  Future<void> sendMessage(String message, String name) {
    throw UnimplementedError('sendMessage() has not been implemented.');
  }

  /// Calls native code to send a ByteBuffer message.
  Future<void> sendBuffer(ByteBuffer message, String name) {
    throw UnimplementedError('sendBuffer() has not been implemented.');
  }

  /// Calls native code to enable the LocalAudioTrack.
  Future<bool?> enableAudioTrack(bool enable, String name) {
    throw UnimplementedError('enableAudioTrack() has not been implemented.');
  }

  /// Calls native code to enable playback of the RemoteAudioTrack.
  Future<void> enableRemoteAudioTrack(bool enable, String sid) {
    throw UnimplementedError('enableRemoteAudioTrack() has not been implemented.');
  }

  /// Calls native code to check if playback is enabled for the RemoteAudioTrack.
  Future<bool?> isRemoteAudioTrackPlaybackEnabled(String sid) {
    throw UnimplementedError('isRemoteAudioTrackPlaybackEnabled() has not been implemented.');
  }

  /// Calls native code for retrieving the different camera sources available.
  Future<List<CameraSource>> getSources() {
    throw UnimplementedError('getSources() has not been implemented.');
  }

  /// Calls native code to switch the camera.
  Future<CameraSource> switchCamera(CameraSource source) {
    throw UnimplementedError('switchCamera() has not been implemented.');
  }

  /// Calls native code to start screen share
  ///
  /// * Returns a [Future] that completes with a [bool] indicating whether the screen share init was successful.
  ///
  /// ### Possible outcomes:
  /// [true] : the screen share was _**successful**_
  ///
  /// [false] : the screen share was _**cancelled**_ or _**permission is not granted**_
  ///
  /// [Exception] : screen share _**failed**_ or is _**not supported by the browser**_
  ///
  /// This function uses the Twilio Programmable Video SDK to [publish a track](https://media.twiliocdn.com/sdk/js/video/releases/2.13.1/docs/LocalParticipant.html#publishTrack__anchor)
  Future<Widget?> startScreenShare() {
    throw UnimplementedError('startScreenShare() has not been implemented.');
  }

  /// Calls native code to stop screen share
  ///
  /// This function uses the Twilio Programmable Video SDK to [unpublish a track](https://media.twiliocdn.com/sdk/js/video/releases/2.13.1/docs/LocalParticipant.html#unpublishTrack__anchor)
  void stopScreenShare() async {
    throw UnimplementedError('stopScreenShare() has not been implemented.');
  }

  /// Calls native code to set the preferred camera device id.
  Future<bool> setCameraDeviceId(String deviceId) async {
    throw UnimplementedError('setCameraDeviceId has not been implemented.');
  }

  /// Calls native code to set the preferred microphone device id.
  Future<bool> setMicrophoneDeviceId(String deviceId) async {
    throw UnimplementedError('setCameraDeviceId has not been implemented.');
  }

  /// Calls native code to set the preferred speaker device id.
  Future<bool> setSpeakerDeviceId(String deviceId) async {
    throw UnimplementedError('setCameraDeviceId has not been implemented.');
  }

  /// Calls native code to change the torch state.
  Future<void> setTorch(bool enabled) {
    throw UnimplementedError('setTorch(bool enabled) has not been implemented.');
  }

  //#endregion

  //#region Streams

  /// Stream of the Screen share ended event.
  ///
  /// This stream is used to listen screen share termination from the user (not from ui).
  Stream<dynamic>? onScreenShareEndedStream() {
    throw UnimplementedError('cameraStream() has not been implemented');
  }

  /// Stream of the CameraEvent model.
  ///
  /// This stream is used to listen for async events after interactions with the camera.
  Stream<BaseCameraEvent>? cameraStream() {
    throw UnimplementedError('cameraStream() has not been implemented');
  }

  /// Stream of the BaseRoomEvent model.
  ///
  /// This stream is used to update the Room in a plugin implementation.
  Stream<BaseRoomEvent>? roomStream(int internalId) {
    throw UnimplementedError('roomStream() has not been implemented');
  }

  /// Stream of the BaseRemoteParticipantEvent model.
  ///
  /// This stream is used to update the RemoteParticipants in a plugin implementation.
  Stream<BaseRemoteParticipantEvent>? remoteParticipantStream(int internalId) {
    throw UnimplementedError('remoteParticipantStream() has not been implemented');
  }

  /// Stream of the BaseLocalParticipantEvent model.
  ///
  /// This stream is used to update the LocalParticipant in a plugin implementation.
  Stream<BaseLocalParticipantEvent>? localParticipantStream(int internalId) {
    throw UnimplementedError('localParticipantStream() has not been implemented');
  }

  /// Stream of the BaseRemoteDataTrackEvent model.
  ///
  /// This stream is used to update the RemoteDataTrack in a plugin implementation.
  Stream<BaseRemoteDataTrackEvent>? remoteDataTrackStream(int internalId) {
    throw UnimplementedError('remoteDataTrackStream() has not been implemented');
  }

  /// Stream of dynamic that contains all the native logging output.
  Stream<dynamic> loggingStream() {
    throw UnimplementedError('loggingStream() has not been implemented');
  }
//#endregion
}
