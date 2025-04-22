import 'dart:async';

import 'package:audara/screens/splashscreen.dart';
import 'package:audara/utils/AudioPlayer.dart';
import 'package:audara/utils/PlayQueue.dart';
import 'package:audara/utils/WebSocketHandler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final webSocketHandler = WebSocketHandler("", null);
    final audioPlayerHandler = AudioStreamHandler();
    final playQueue = PlayQueue(audioPlayerHandler);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: playQueue),
          ChangeNotifierProvider.value(value: webSocketHandler),
          ChangeNotifierProvider.value(value: audioPlayerHandler), // Provide AudioPlayerHandler
        ],
        child: MyApp(audioPlayerHandler: audioPlayerHandler),
      ),
    );
  }, (error, stackTrace) {
    print('Unhandled error: $error');
    print('Stack trace: $stackTrace');
  });
}

class MyApp extends StatelessWidget {
  final AudioStreamHandler audioPlayerHandler;

  const MyApp({super.key, required this.audioPlayerHandler});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Audara',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SplashScreen(), // Set SplashScreen as the initial screen
      debugShowCheckedModeBanner: false,
    );
  }
}