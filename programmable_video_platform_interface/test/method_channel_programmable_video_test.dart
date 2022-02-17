import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:twilio_programmable_video_platform_interface/src/camera_source.dart';
import 'package:twilio_programmable_video_platform_interface/src/method_channel_programmable_video.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/programmable_video_platform_interface.dart';

import 'event_channel_maps.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelProgrammableVideo instance;
  final methodCalls = <MethodCall>[];

  var nativeDebugIsCalled = false;
  var nativeSendStringIsCalled = false;
  var nativeEnableAudioTrackIsCalled = false;
  var nativeEnableVideoTrackIsCalled = false;
  var nativeSendByteBufferIsCalled = false;
  var nativeEnableRemoteAudioTrackIsCalled = false;
  var nativeIsRemoteAudioTrackPlaybackEnabledIsCalled = false;
  var nativeDisconnectIsCalled = false;
  var nativeConnectIsCalled = false;
  var nativeSetSpeakerphoneOnIsCalled = false;
  var nativeSpeakerPhoneOn = false;
  var nativeCameraId = '';
  var nativeGetSpeakerphoneOnIsCalled = false;
  var nativeSwitchCameraIsCalled = false;

  var cameraSource = CameraSource('BACK_CAMERA', false, false, false);

  StreamController cameraController;
  late StreamController roomController;
  late StreamController remoteParticipantController;
  late StreamController localParticipantController;
  late StreamController remoteDataTrackController;

  setUpAll(() {
    cameraController = StreamController<dynamic>.broadcast(sync: true);
    final cameraChannel = MockEventChannel();
    when(cameraChannel.receiveBroadcastStream(0)).thenAnswer((Invocation invoke) => cameraController.stream);

    roomController = StreamController<dynamic>.broadcast(sync: true);
    final roomChannel = MockEventChannel();
    when(roomChannel.receiveBroadcastStream(0)).thenAnswer((Invocation invoke) => roomController.stream);

    remoteParticipantController = StreamController<dynamic>.broadcast(sync: true);
    final remoteParticipantChannel = MockEventChannel();
    when(remoteParticipantChannel.receiveBroadcastStream(0)).thenAnswer((Invocation invoke) => remoteParticipantController.stream);

    localParticipantController = StreamController<dynamic>.broadcast(sync: true);
    final localParticipantChannel = MockEventChannel();
    when(localParticipantChannel.receiveBroadcastStream(0)).thenAnswer((Invocation invoke) => localParticipantController.stream);

    remoteDataTrackController = StreamController<dynamic>.broadcast(sync: true);
    final remoteDataTrackChannel = MockEventChannel();
    when(remoteDataTrackChannel.receiveBroadcastStream(0)).thenAnswer((Invocation invoke) => remoteDataTrackController.stream);

    instance = MethodChannelProgrammableVideo.private(
      MethodChannel('twilio_programmable_video'),
      cameraChannel,
      roomChannel,
      remoteParticipantChannel,
      localParticipantChannel,
      remoteDataTrackChannel,
    );

    MethodChannel('twilio_programmable_video').setMockMethodCallHandler((MethodCall methodCall) async {
      methodCalls.add(methodCall);
      switch (methodCall.method) {
        case 'debug':
          nativeDebugIsCalled = true;
          break;
        case 'LocalDataTrack#sendString':
          nativeSendStringIsCalled = true;
          break;
        case 'LocalAudioTrack#enable':
          nativeEnableAudioTrackIsCalled = true;
          break;
        case 'LocalVideoTrack#enable':
          nativeEnableVideoTrackIsCalled = true;
          break;
        case 'LocalDataTrack#sendByteBuffer':
          nativeSendByteBufferIsCalled = true;
          break;
        case 'RemoteAudioTrack#enablePlayback':
          nativeEnableRemoteAudioTrackIsCalled = true;
          break;
        case 'RemoteAudioTrack#isPlaybackEnabled':
          nativeIsRemoteAudioTrackPlaybackEnabledIsCalled = true;
          break;
        case 'disconnect':
          nativeDisconnectIsCalled = true;
          break;
        case 'connect':
          nativeConnectIsCalled = true;
          break;
        case 'setSpeakerphoneOn':
          nativeSetSpeakerphoneOnIsCalled = true;
          nativeSpeakerPhoneOn = methodCall.arguments['on'];
          break;
        case 'getSpeakerphoneOn':
          nativeGetSpeakerphoneOnIsCalled = true;
          return nativeSpeakerPhoneOn;
        case 'CameraCapturer#switchCamera':
          nativeSwitchCameraIsCalled = true;
          nativeCameraId = methodCall.arguments['cameraId'];
          return {'type': 'CameraCapturer', 'source': cameraSource.toMap()};
        default:
          throw Exception('Methodcall: ${methodCall.method} was not found');
      }
      return null;
    });
  });

  tearDown(() async {
    methodCalls.clear();
  });

  tearDownAll(() async {
    await roomController.close();
    await remoteParticipantController.close();
    await localParticipantController.close();
    await remoteDataTrackController.close();
  });

  group('.debug()', () {
    test('should enable native debug in dart', () async {
      await instance.setNativeDebug(true);
      expect(nativeDebugIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'debug',
          arguments: {'native': true},
        )
      ]);
    });
  });

  group('.sendMessage()', () {
    test('should call native code to send a String message in dart', () async {
      final testMessage = 'testMessage';
      final testName = 'testName';

      await instance.sendMessage(testMessage, testName);
      expect(nativeSendStringIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'LocalDataTrack#sendString',
          arguments: {'name': testName, 'message': testMessage},
        )
      ]);
    });
  });

  group('.enableAudioTrack()', () {
    test('should call native code to enable an audiotrack in dart', () async {
      final testEnable = true;
      final testName = 'testName';

      await instance.enableAudioTrack(testEnable, testName);
      expect(nativeEnableAudioTrackIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'LocalAudioTrack#enable',
          arguments: {'name': testName, 'enable': testEnable},
        )
      ]);
    });
  });

  group('.enableVideoTrack()', () {
    test('should call native code to enable a videotrack in dart', () async {
      final testEnabled = true;
      final testName = 'testName';

      await instance.enableVideoTrack(testEnabled, testName);
      expect(nativeEnableVideoTrackIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'LocalVideoTrack#enable',
          arguments: {'name': testName, 'enable': testEnabled},
        )
      ]);
    });
  });

  group('.sendBuffer()', () {
    test('should call native code to send a ByteBuffer message in dart', () async {
      final list = 'This data has been sent over the ByteBuffer channel of the DataTrack API'.codeUnits;
      final bytes = Uint8List.fromList(list);
      final testMessage = bytes.buffer;
      final testName = 'testName';

      await instance.sendBuffer(testMessage, testName);
      expect(nativeSendByteBufferIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'LocalDataTrack#sendByteBuffer',
          arguments: {'name': testName, 'message': testMessage.asUint8List()},
        )
      ]);
    });
  });

  group('.enableRemoteAudioTrack()', () {
    test('should call native code to enable playback of a remote audiotrack', () async {
      final testEnable = true;
      final testSid = 'testSid';

      await instance.enableRemoteAudioTrack(testEnable, testSid);
      expect(nativeEnableRemoteAudioTrackIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'RemoteAudioTrack#enablePlayback',
          arguments: {'sid': testSid, 'enable': testEnable},
        )
      ]);
    });
  });

  group('.isRemoteAudioTrackPlaybackEnabled()', () {
    test('should call native code to check if playback of a remote audiotrack is enabled', () async {
      final testSid = 'testSid';

      await instance.isRemoteAudioTrackPlaybackEnabled(testSid);
      expect(nativeIsRemoteAudioTrackPlaybackEnabledIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'RemoteAudioTrack#isPlaybackEnabled',
          arguments: {'sid': testSid},
        )
      ]);
    });
  });

  group('.disconnect()', () {
    test('should call native disconnect code in dart', () async {
      await instance.disconnect();
      expect(nativeDisconnectIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'disconnect',
          arguments: null,
        )
      ]);
    });
  });

  group('.connectToRoom()', () {
    test('should call native code to connect to a room in dart', () async {
      await instance.connectToRoom(
        ConnectOptionsModel(
          '123',
          audioTracks: null,
          dataTracks: null,
          enableAutomaticSubscription: false,
          enableDominantSpeaker: false,
          preferredAudioCodecs: null,
          preferredVideoCodecs: null,
          region: Region.us1,
          roomName: '',
          videoTracks: null,
          enableNetworkQuality: false,
          networkQualityConfiguration: null,
        ),
      );
      expect(nativeConnectIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'connect',
          arguments: {
            'connectOptions': {
              'accessToken': '123',
              'roomName': '',
              'region': 'us1',
              'preferredAudioCodecs': null,
              'preferredVideoCodecs': null,
              'audioTracks': null,
              'dataTracks': null,
              'videoTracks': null,
              'enableDominantSpeaker': false,
              'enableAutomaticSubscription': false,
              'enableNetworkQuality': false,
              'networkQualityConfiguration': null,
            },
          },
        )
      ]);
    });
  });

  group('.setSpeakerphoneOn() & .getSpeakerphoneOn()', () {
    final callBool = true;

    test('should call native setSpeakerPhone code in dart', () async {
      await instance.setSpeakerphoneOn(callBool);
      expect(nativeSetSpeakerphoneOnIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'setSpeakerphoneOn',
          arguments: {'on': callBool},
        )
      ]);
    });

    test('should call native getSpeakerPhone code in dart and get same bool as previously set', () async {
      final result = await instance.getSpeakerphoneOn();
      expect(result, callBool);
      expect(nativeGetSpeakerphoneOnIsCalled, true);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'getSpeakerphoneOn',
          arguments: null,
        )
      ]);
    });
  });

  group('.switchCamera()', () {
    test('should call native switchCamera code in dart', () async {
      final source = CameraSource('FRONT_CAMERA', false, false, false);
      await instance.switchCamera(source);
      expect(nativeSwitchCameraIsCalled, true);
      expect(nativeCameraId, source.cameraId);
      expect(methodCalls, <Matcher>[
        isMethodCall(
          'CameraCapturer#switchCamera',
          arguments: {'cameraId': source.cameraId},
        ),
      ]);
    });
  });

  group('.roomStream()', () {
    test('should return a Stream of BaseRoomEvent', () {
      expect(instance.roomStream(0), isA<Stream<BaseRoomEvent>>());
    });

    BaseRoomEvent? lastEvent;
    late StreamSubscription subscription;
    setUp(() {
      subscription = instance.roomStream(0).listen((data) {
        lastEvent = data;
      });
    });
    tearDown(() async {
      await subscription.cancel();
    });

    test('connectFailure event map should result in ConnectFailure', () {
      roomController.add({
        'name': 'connectFailure',
        'data': {'room': EventChannelMaps.roomMap},
        'error': EventChannelMaps.errorMap
      });
      expect(lastEvent, isA<ConnectFailure>());
    });

    test('connected event map should result in Connected', () {
      roomController.add({
        'name': 'connected',
        'data': {'room': EventChannelMaps.roomMap},
        'error': null
      });
      expect(lastEvent, isA<Connected>());
    });

    test('disconnected event map should result in Disconnected', () {
      roomController.add({
        'name': 'disconnected',
        'data': {'room': EventChannelMaps.roomMap},
        'error': EventChannelMaps.errorMap
      });
      expect(lastEvent, isA<Disconnected>());
    });

    test('participantConnected event map should result in ParticipantConnected', () {
      roomController.add({
        'name': 'participantConnected',
        'data': {
          'room': EventChannelMaps.roomMap,
          'remoteParticipant': EventChannelMaps.remoteParticipantMap,
        },
        'error': null
      });
      expect(lastEvent, isA<ParticipantConnected>());
    });

    test('participantDisconnected event map should result in ParticipantDisconnected', () {
      roomController.add({
        'name': 'participantDisconnected',
        'data': {
          'room': EventChannelMaps.roomMap,
          'remoteParticipant': EventChannelMaps.remoteParticipantMap,
        },
        'error': null
      });
      expect(lastEvent, isA<ParticipantDisconnected>());
    });

    test('reconnected event map should result in Reconnected', () {
      roomController.add({
        'name': 'reconnected',
        'data': {'room': EventChannelMaps.roomMap},
        'error': null
      });
      expect(lastEvent, isA<Reconnected>());
    });

    test('reconnecting event map should result in Reconnecting', () {
      roomController.add({
        'name': 'reconnecting',
        'data': {'room': EventChannelMaps.roomMap},
        'error': EventChannelMaps.errorMap
      });
      expect(lastEvent, isA<Reconnecting>());
    });

    test('recordingStarted event map should result in RecordingStarted', () {
      roomController.add({
        'name': 'recordingStarted',
        'data': {'room': EventChannelMaps.roomMap},
        'error': null
      });
      expect(lastEvent, isA<RecordingStarted>());
    });

    test('recordingStopped event map should result in RecordingStopped', () {
      roomController.add({
        'name': 'recordingStopped',
        'data': {'room': EventChannelMaps.roomMap},
        'error': null
      });
      expect(lastEvent, isA<RecordingStopped>());
    });

    test('dominantSpeakerChanged event map should result in DominantSpeakerChanged', () {
      roomController.add({
        'name': 'dominantSpeakerChanged',
        'data': {
          'room': EventChannelMaps.roomMap,
          'dominantSpeaker': EventChannelMaps.remoteParticipantMap,
        },
        'error': null
      });
      expect(lastEvent, isA<DominantSpeakerChanged>());
    });

    test('invalid map should result in SkipAbleRoomEvent', () {
      roomController.add({'data': {}});
      expect(lastEvent, isA<SkipAbleRoomEvent>());
    });
  });

  group('.remoteParticipantStream()', () {
    test('should return a Stream of BaseRemoteParticipantEvent', () {
      expect(instance.remoteParticipantStream(0), isA<Stream<BaseRemoteParticipantEvent>>());
    });

    BaseRemoteParticipantEvent? lastEvent;
    late StreamSubscription subscription;
    setUp(() {
      subscription = instance.remoteParticipantStream(0).listen((data) => lastEvent = data);
    });
    tearDown(() async {
      await subscription.cancel();
    });

    test('audioTrackDisabled event map should result in RemoteAudioTrackDisabled', () {
      remoteParticipantController.add({
        'name': 'audioTrackDisabled',
        'data': {
          'remoteParticipant': EventChannelMaps.remoteParticipantMap,
          'remoteAudioTrackPublication': EventChannelMaps.remoteAudioTrackPublicationMap,
        },
        'error': null
      });
      expect(lastEvent, isA<RemoteAudioTrackDisabled>());
    });

    test('audioTrackEnabled event map should result in RemoteAudioTrackEnabled', () {
      remoteParticipantController.add({
        'name': 'audioTrackEnabled',
        'data': {
          'remoteParticipant': EventChannelMaps.remoteParticipantMap,
          'remoteAudioTrackPublication': EventChannelMaps.remoteAudioTrackPublicationMap,
        },
        'error': null
      });
      expect(lastEvent, isA<RemoteAudioTrackEnabled>());
    });

    test('audioTrackSubscribed event map should result in RemoteAudioTrackSubscribed', () {
      remoteParticipantController.add({
        'name': 'audioTrackSubscribed',
        'data': {
          'remoteParticipant': EventChannelMaps.remoteParticipantMap,
          'remoteAudioTrackPublication': EventChannelMaps.remoteAudioTrackPublicationMap,
          'remoteAudioTrack': EventChannelMaps.remoteAudioTrackMap,
        },
        'error': null
      });
      expect(lastEvent, isA<RemoteAudioTrackSubscribed>());
    });

    test('audioTrackSubscriptionFailed event map should result in RemoteAudioTrackSubscriptionFailed', () {
      remoteParticipantController.add({
        'name': 'audioTrackSubscriptionFailed',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteAudioTrackPublication': EventChannelMaps.remoteAudioTrackPublicationMap},
        'error': EventChannelMaps.errorMap
      });
      expect(lastEvent, isA<RemoteAudioTrackSubscriptionFailed>());
    });

    test('audioTrackUnpublished event map should result in RemoteAudioTrackUnpublished', () {
      remoteParticipantController.add({
        'name': 'audioTrackUnpublished',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteAudioTrackPublication': EventChannelMaps.remoteAudioTrackPublicationMap},
        'error': null
      });
      expect(lastEvent, isA<RemoteAudioTrackUnpublished>());
    });

    test('audioTrackUnsubscribed event map should result in RemoteAudioTrackUnsubscribed', () {
      remoteParticipantController.add({
        'name': 'audioTrackUnsubscribed',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteAudioTrackPublication': EventChannelMaps.remoteAudioTrackPublicationMap, 'remoteAudioTrack': EventChannelMaps.remoteAudioTrackMap},
        'error': null
      });
      expect(lastEvent, isA<RemoteAudioTrackUnsubscribed>());
    });

    test('dataTrackPublished event map should result in RemoteDataTrackPublished', () {
      remoteParticipantController.add({
        'name': 'dataTrackPublished',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteDataTrackPublication': EventChannelMaps.remoteDataTrackPublicationMap},
        'error': null
      });
      expect(lastEvent, isA<RemoteDataTrackPublished>());
    });

    test('dataTrackSubscribed event map should result in RemoteDataTrackSubscribed', () {
      remoteParticipantController.add({
        'name': 'dataTrackSubscribed',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteDataTrackPublication': EventChannelMaps.remoteDataTrackPublicationMap, 'remoteDataTrack': EventChannelMaps.remoteDataTrackMap},
        'error': null
      });
      expect(lastEvent, isA<RemoteDataTrackSubscribed>());
    });

    test('dataTrackSubscriptionFailed event map should result in RemoteDataTrackSubscriptionFailed', () {
      remoteParticipantController.add({
        'name': 'dataTrackSubscriptionFailed',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteDataTrackPublication': EventChannelMaps.remoteDataTrackPublicationMap},
        'error': EventChannelMaps.errorMap
      });
      expect(lastEvent, isA<RemoteDataTrackSubscriptionFailed>());
    });

    test('dataTrackUnpublished event map should result in RemoteDataTrackUnpublished', () {
      remoteParticipantController.add({
        'name': 'dataTrackUnpublished',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteDataTrackPublication': EventChannelMaps.remoteDataTrackPublicationMap},
        'error': null
      });
      expect(lastEvent, isA<RemoteDataTrackUnpublished>());
    });

    test('dataTrackUnsubscribed event map should result in RemoteDataTrackUnsubscribed', () {
      remoteParticipantController.add({
        'name': 'dataTrackUnsubscribed',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteDataTrackPublication': EventChannelMaps.remoteDataTrackPublicationMap, 'remoteDataTrack': EventChannelMaps.remoteDataTrackMap},
        'error': null
      });
      expect(lastEvent, isA<RemoteDataTrackUnsubscribed>());
    });

    test('videoTrackDisabled event map should result in RemoteVideoTrackDisabled', () {
      remoteParticipantController.add({
        'name': 'videoTrackDisabled',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteVideoTrackPublication': EventChannelMaps.remoteVideoTrackPublicationMap},
        'error': null
      });
      expect(lastEvent, isA<RemoteVideoTrackDisabled>());
    });

    test('videoTrackEnabled event map should result in RemoteVideoTrackEnabled', () {
      remoteParticipantController.add({
        'name': 'videoTrackEnabled',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteVideoTrackPublication': EventChannelMaps.remoteVideoTrackPublicationMap},
        'error': null
      });
      expect(lastEvent, isA<RemoteVideoTrackEnabled>());
    });

    test('videoTrackPublished event map should result in RemoteVideoTrackPublished', () {
      remoteParticipantController.add({
        'name': 'videoTrackPublished',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteVideoTrackPublication': EventChannelMaps.remoteVideoTrackPublicationMap},
        'error': null
      });
      expect(lastEvent, isA<RemoteVideoTrackPublished>());
    });

    test('videoTrackSubscribed event map should result in RemoteVideoTrackSubscribed', () {
      remoteParticipantController.add({
        'name': 'videoTrackSubscribed',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteVideoTrackPublication': EventChannelMaps.remoteVideoTrackPublicationMap},
        'error': null
      });
      expect(lastEvent, isA<RemoteVideoTrackSubscribed>());
    });

    test('videoTrackSubscriptionFailed event map should result in RemoteVideoTrackSubscriptionFailed', () {
      remoteParticipantController.add({
        'name': 'videoTrackSubscriptionFailed',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteVideoTrackPublication': EventChannelMaps.remoteVideoTrackPublicationMap},
        'error': EventChannelMaps.errorMap
      });
      expect(lastEvent, isA<RemoteVideoTrackSubscriptionFailed>());
    });

    test('videoTrackUnpublished event map should result in RemoteVideoTrackUnpublished', () {
      remoteParticipantController.add({
        'name': 'videoTrackUnpublished',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteVideoTrackPublication': EventChannelMaps.remoteVideoTrackPublicationMap},
        'error': null
      });
      expect(lastEvent, isA<RemoteVideoTrackUnpublished>());
    });

    test('videoTrackUnsubscribed event map should result in RemoteVideoTrackUnsubscribed', () {
      remoteParticipantController.add({
        'name': 'videoTrackUnsubscribed',
        'data': {'remoteParticipant': EventChannelMaps.remoteParticipantMap, 'remoteVideoTrackPublication': EventChannelMaps.remoteVideoTrackPublicationMap, 'remoteVideoTrack': EventChannelMaps.remoteVideoTrackMap},
        'error': null
      });
      expect(lastEvent, isA<RemoteVideoTrackUnsubscribed>());
    });

    test('invalid map should result in SkipAbleRemoteParticipantEvent', () {
      remoteParticipantController.add({'data': {}});
      expect(lastEvent, isA<SkipAbleRemoteParticipantEvent>());
    });
  });

  group('.localParticipantStream()', () {
    test('should return a Stream of LocalDataTrackPublished', () {
      expect(instance.localParticipantStream(0), isA<Stream<BaseLocalParticipantEvent>>());
    });

    BaseLocalParticipantEvent? lastEvent;
    late StreamSubscription subscription;
    setUp(() {
      subscription = instance.localParticipantStream(0).listen((data) => lastEvent = data);
    });
    tearDown(() async {
      await subscription.cancel();
    });

    test('audioTrackPublished event map should result in LocalAudioTrackPublished', () {
      localParticipantController.add({
        'name': 'audioTrackPublished',
        'data': {'localParticipant': EventChannelMaps.localParticipantMap, 'localAudioTrackPublication': EventChannelMaps.localAudioTrackPublicationMap},
        'error': null
      });
      expect(lastEvent, isA<LocalAudioTrackPublished>());
    });

    test('audioTrackPublicationFailed event map should result in LocalAudioTrackPublicationFailed', () {
      localParticipantController.add({
        'name': 'audioTrackPublicationFailed',
        'data': {'localParticipant': EventChannelMaps.localParticipantMap, 'localAudioTrack': EventChannelMaps.localAudioTrackMap},
        'error': EventChannelMaps.errorMap
      });
      expect(lastEvent, isA<LocalAudioTrackPublicationFailed>());
    });

    test('dataTrackPublished event map should result in LocalDataTrackPublished', () {
      localParticipantController.add({
        'name': 'dataTrackPublished',
        'data': {'localParticipant': EventChannelMaps.localParticipantMap, 'localDataTrackPublication': EventChannelMaps.localDataTrackPublicationMap},
        'error': null
      });
      expect(lastEvent, isA<LocalDataTrackPublished>());
    });

    test('dataTrackPublicationFailed event map should result in LocalDataTrackPublicationFailed', () {
      localParticipantController.add({
        'name': 'dataTrackPublicationFailed',
        'data': {'localParticipant': EventChannelMaps.localParticipantMap, 'localDataTrack': EventChannelMaps.localDataTrackMap},
        'error': EventChannelMaps.errorMap
      });
      expect(lastEvent, isA<LocalDataTrackPublicationFailed>());
    });

    test('videoTrackPublished event map should result in LocalVideoTrackPublished', () {
      localParticipantController.add({
        'name': 'videoTrackPublished',
        'data': {'localParticipant': EventChannelMaps.localParticipantMap, 'localVideoTrackPublication': EventChannelMaps.localVideoTrackPublicationMap},
        'error': null
      });
      expect(lastEvent, isA<LocalVideoTrackPublished>());
    });

    test('videoTrackPublicationFailed event map should result in LocalVideoTrackPublicationFailed', () {
      localParticipantController.add({
        'name': 'videoTrackPublicationFailed',
        'data': {'localParticipant': EventChannelMaps.localParticipantMap, 'localVideoTrack': EventChannelMaps.localVideoTrackMap},
        'error': EventChannelMaps.errorMap
      });
      expect(lastEvent, isA<LocalVideoTrackPublicationFailed>());
    });

    test('invalid map should result in SkipAbleLocalParticipantEvent', () {
      localParticipantController.add({'data': {}});
      expect(lastEvent, isA<SkipAbleLocalParticipantEvent>());
    });
  });

  group('.remoteDataTrackStream()', () {
    test('should return a Stream of BaseRemoteDataTrackEvent', () {
      expect(instance.remoteDataTrackStream(0), isA<Stream<BaseRemoteDataTrackEvent>>());
    });

    BaseRemoteDataTrackEvent? lastEvent;
    late StreamSubscription subscription;
    setUp(() {
      subscription = instance.remoteDataTrackStream(0).listen((data) => lastEvent = data);
    });
    tearDown(() async {
      await subscription.cancel();
    });

    final remoteDataTrackMap = EventChannelMaps.remoteDataTrackMap;
    test('invalid map should result in SkipAbleRemoteDataTrackEvent', () {
      remoteDataTrackController.add({'data': {}});
      expect(lastEvent, isA<SkipAbleRemoteDataTrackEvent>());
    });

    test('valid map with unknown event name should result in UnknownEvent', () {
      remoteDataTrackController.add({
        'name': 'unimplemented',
        'data': {'remoteDataTrack': remoteDataTrackMap}
      });
      expect(lastEvent, isA<UnknownEvent>());
    });

    test('stringMessage event map should result in StringMessage', () {
      remoteDataTrackController.add({
        'name': 'stringMessage',
        'data': {'message': 'hi', 'remoteDataTrack': remoteDataTrackMap}
      });
      expect(lastEvent, isA<StringMessage>());
    });

    test('bufferMessage event map should result in BufferMessage', () {
      remoteDataTrackController.add({
        'name': 'bufferMessage',
        'data': {
          'message': [5, 1, 0],
          'remoteDataTrack': remoteDataTrackMap,
        }
      });
      expect(lastEvent, isA<BufferMessage>());
    });
  });

  group('.loggingStream()', () {
    test('should return a Stream of dynamic', () {
      expect(instance.loggingStream(), isA<Stream<dynamic>>());
    });
  });
}

class MockEventChannel extends Mock implements EventChannel {
  @override
  Stream<dynamic> receiveBroadcastStream([dynamic arguments]) => super.noSuchMethod(
        Invocation.method(#receiveBroadcastStream, [arguments]),
        returnValue: StreamController<dynamic>().stream,
      );
}
