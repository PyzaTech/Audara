import 'dart:async';
import 'dart:convert';
import 'package:audara/screens/start/StartScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/AesCrypto.dart';
import '../../utils/WebSocketHandler.dart';
import 'home.dart';
import 'start/SelectServerScreen.dart';
import 'start/LoginScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    String? serverUrl = prefs.getString('server_url');
    WebSocketHandler webSocketHandler;

    print('Username: $username, Password: $password, Server URL: $serverUrl');

    if(serverUrl == null) {
      // If no server URL is found, redirect to SelectServerScreen
      print('No server URL found, redirecting to SelectServerScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SelectServerScreen()),
      );
      return;
    }

    // Ensure the server URL has a valid WebSocket scheme
    if (!serverUrl.startsWith('ws://') && !serverUrl.startsWith('wss://')) {
      serverUrl = 'ws://$serverUrl'; // Default to ws:// if no scheme is provided
    }


    webSocketHandler = Provider.of<WebSocketHandler>(context, listen: false);
    print(serverUrl);
    webSocketHandler.updateServerUrl(serverUrl);


    StreamSubscription? _AESSubscription;
    _AESSubscription = webSocketHandler.stream.listen(
          (message) async {

        final jsonResponse = jsonDecode(message);

        print('AES Subscription Message: $jsonResponse');
        if (jsonResponse['type'] == 'session-key') {
          final aesKey = jsonResponse['key'];
          AesCrypto().initFromBase64(aesKey);
          await AesCrypto().saveToPrefs();
          print('✅ AES session key saved. $aesKey');
          _AESSubscription?.cancel();

          final loginData = jsonEncode({
            "action": "login",
            "username": username,
            "password": password,
          });

          final encrypted = AesCrypto().encryptText(loginData);
          webSocketHandler.channel?.sink.add(encrypted);
          if(webSocketHandler.heartbeatTimer == null) {
            webSocketHandler.startHeartbeat;
          }

        }
      },
    );

    if (username != null && password != null) {
      print('Username and password found, attempting to connect to WebSocket');

      print('Formatted Server URL: $serverUrl');

      try {

        StreamSubscription? _subscription;
        _subscription = webSocketHandler.stream.listen((message) async {
          final json = jsonDecode(message);
          if(json != null) {
            if(json['type'] == 'session-key') {
              return;
            }
          }
          final decryptedMessage = AesCrypto().decryptText(message);
          final jsonResponse = jsonDecode(decryptedMessage);

          print('Server Response: $jsonResponse');

          if (jsonResponse['success'] == false) {
            print('Login failed, redirecting to LoginScreen');
            _subscription?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen(webSocketHandler: webSocketHandler)),
            );
          } else {
            _subscription?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Home(),
              ),
            );
          }
        });
      } catch (e) {
        print('Error during WebSocket connection or login: $e');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SelectServerScreen()),
        );
      }
    } else {
      print('Missing login info, but found Server URL, redirecting to Start Screen.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => StartScreen(serverUrl: prefs.getString('server_url')!, webSocketHandler: webSocketHandler)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}