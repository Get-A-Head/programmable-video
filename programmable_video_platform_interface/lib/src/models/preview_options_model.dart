import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

class PreviewOptionsModel {
  final LocalAudioTrackModel audioTrack;
  final LocalVideoTrackModel videoTrack;

  PreviewOptionsModel({
    required this.audioTrack,
    required this.videoTrack,
  });

  Map<String, Object> toMap() {
    return {
      'previewOptions': {
        'audioTrack': audioTrack.toMap(),
        'videoTrack': videoTrack.toMap(),
      }
    };
  }
}
