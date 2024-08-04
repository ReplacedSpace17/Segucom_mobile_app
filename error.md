
I/org.webrtc.Logging(10841): CameraStatistics: Camera fps: 30.
D/Android: [Awesome Notifications](10841): Awesome Notifications plugin detached from Android 34 (AwesomeNotificationsPlugin:180)
D/FlutterWebRTCPlugin(10841): Stopping the audio manager...
D/libMEOW (10841): meow delete tls: 0xb400006f6fb4ffc0
D/AndroidRuntime(10841): Shutting down VM
E/AndroidRuntime(10841): FATAL EXCEPTION: main
E/AndroidRuntime(10841): Process: com.segucom.segucom_app, PID: 10841
E/AndroidRuntime(10841): android.app.RemoteServiceException$ForegroundServiceDidNotStartInTimeException: Context.startForegroundService() did not then call Service.startForeground(): ServiceRecord{5376b1f u0 com.segucom.segucom_app/id.flutter.flutter_background_service.BackgroundService}
E/AndroidRuntime(10841):        at android.app.ActivityThread.generateForegroundServiceDidNotStartInTimeException(ActivityThread.java:2315)
E/AndroidRuntime(10841):        at android.app.ActivityThread.throwRemoteServiceException(ActivityThread.java:2286)
E/AndroidRuntime(10841):        at android.app.ActivityThread.-$$Nest$mthrowRemoteServiceException(Unknown Source:0)
E/AndroidRuntime(10841):        at android.app.ActivityThread$H.handleMessage(ActivityThread.java:2611)
E/AndroidRuntime(10841):        at android.os.Handler.dispatchMessage(Handler.java:106)
E/AndroidRuntime(10841):        at android.os.Looper.loopOnce(Looper.java:230)
E/AndroidRuntime(10841):        at android.os.Looper.loop(Looper.java:319)
E/AndroidRuntime(10841):        at android.app.ActivityThread.main(ActivityThread.java:8900)
E/AndroidRuntime(10841):        at java.lang.reflect.Method.invoke(Native Method)
E/AndroidRuntime(10841):        at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:608)
E/AndroidRuntime(10841):        at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:1103)
E/AndroidRuntime(10841): Caused by: android.app.StackTrace: Last startServiceCommon() call for this service was made here
E/AndroidRuntime(10841):        at android.app.ContextImpl.startServiceCommon(ContextImpl.java:2023)
E/AndroidRuntime(10841):        at android.app.ContextImpl.startForegroundService(ContextImpl.java:1967)
E/AndroidRuntime(10841):        at android.content.ContextWrapper.startForegroundService(ContextWrapper.java:847)
E/AndroidRuntime(10841):        at androidx.core.content.ContextCompat$Api26Impl.startForegroundService(ContextCompat.java:1189)
E/AndroidRuntime(10841):        at androidx.core.content.ContextCompat.startForegroundService(ContextCompat.java:752)
E/AndroidRuntime(10841):        at id.flutter.flutter_background_service.FlutterBackgroundServicePlugin.start(FlutterBackgroundServicePlugin.java:82)
E/AndroidRuntime(10841):        at id.flutter.flutter_background_service.FlutterBackgroundServicePlugin.onMethodCall(FlutterBackgroundServicePlugin.java:113)
E/AndroidRuntime(10841):        at io.flutter.plugin.common.MethodChannel$IncomingMethodCallHandler.onMessage(MethodChannel.java:267)
E/AndroidRuntime(10841):        at io.flutter.embedding.engine.dart.DartMessenger.invokeHandler(DartMessenger.java:292)
E/AndroidRuntime(10841):        at io.flutter.embedding.engine.dart.DartMessenger.lambda$dispatchMessageToQueue$0$io-flutter-embedding-engine-dart-DartMessenger(DartMessenger.java:319)
E/AndroidRuntime(10841):        at io.flutter.embedding.engine.dart.DartMessenger$$ExternalSyntheticLambda0.run(Unknown Source:12)
E/AndroidRuntime(10841):        at android.os.Handler.handleCallback(Handler.java:958)
E/AndroidRuntime(10841):        at android.os.Handler.dispatchMessage(Handler.java:99)
E/AndroidRuntime(10841):        ... 6 more
I/Process (10841): Sending signal. PID: 10841 SIG: 9
Lost connection to device.