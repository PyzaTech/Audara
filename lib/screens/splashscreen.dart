import 'dart:async';
import 'dart:convert';
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

    print('Username: $username, Password: $password, Server URL: $serverUrl');

    if (username != null && password != null && serverUrl != null) {
      // Ensure the server URL has a valid WebSocket scheme
      if (!serverUrl.startsWith('ws://') && !serverUrl.startsWith('wss://')) {
        serverUrl = 'ws://$serverUrl'; // Default to ws:// if no scheme is provided
      }

      print('Formatted Server URL: $serverUrl');

      try {
        final webSocketHandler = Provider.of<WebSocketHandler>(context, listen: false);
        webSocketHandler.updateServerUrl(serverUrl);


        StreamSubscription? _AESSubscription;
        _AESSubscription = webSocketHandler.stream.listen(
          (message) async {

            final jsonResponse = jsonDecode(message);

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

            }
          },
        );

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
      print('Missing login details, redirecting to SelectServerScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SelectServerScreen()),
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