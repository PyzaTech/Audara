import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audara/utils/WebSocketHandler.dart';
import 'package:audara/screens/start/StartScreen.dart';

import '../../utils/AesCrypto.dart';

class SelectServerScreen extends StatefulWidget {
  final String? serverUrl;

  const SelectServerScreen({super.key, this.serverUrl});

  @override
  State<SelectServerScreen> createState() => _SelectServerScreenState();
}

class _SelectServerScreenState extends State<SelectServerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _serverController;

  @override
  void initState() {
    super.initState();
    print('Server URL passed: ${widget.serverUrl}'); // Debug log
    _serverController = TextEditingController(text: widget.serverUrl ?? '');
  }

  void _onNextPressed() async {
    if (_formKey.currentState?.validate() ?? false) {
      final serverName = _serverController.text.trim();
      final secureServerUrl = 'wss://$serverName';
      final insecureServerUrl = 'ws://$serverName';

      try {
        WebSocketHandler webSocketHandler = await _tryConnect(secureServerUrl);
        print('Connected to secure WebSocket: $secureServerUrl');
        _handleWebSocketConnection(webSocketHandler, serverName);
      } catch (e) {
        try {
          WebSocketHandler webSocketHandler = await _tryConnect(insecureServerUrl);
          print('Connected to insecure WebSocket: $insecureServerUrl');
          _handleWebSocketConnection(webSocketHandler, serverName);
        } catch (e) {
          _showError('Unable to connect to the server. Please try again.');
        }
      }
    }
  }

  Future<WebSocketHandler> _tryConnect(String url) async {
    try {
      final webSocketHandler = WebSocketHandler(url, context);
      return webSocketHandler;
    } on SocketException {
      throw Exception('Failed to connect to the server.');
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }

  // void _navigateToStartScreen(WebSocketHandler webSocketHandler, String serverURL) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('server_url', serverURL);
  //
  //   Navigator.push(
  //     context,
  //     PageRouteBuilder(
  //       pageBuilder: (context, animation, secondaryAnimation) =>
  //           StartScreen(serverUrl: serverURL, webSocketHandler: webSocketHandler),
  //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
  //         return FadeTransition(opacity: animation, child: child);
  //       },
  //     ),
  //   );
  // }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      print('Widget is not mounted. Error: $message'); // Fallback log
    }
  }

  void _handleWebSocketConnection(WebSocketHandler handler, String serverURL) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', serverURL); // Save the server URL
    print('Server URL saved: $serverURL'); // Debug log

    StreamSubscription? _subscription;
    _subscription = handler.stream.listen(
          (message) async {
        print('Connected: $message');

        try {
          final decoded = jsonDecode(message);
          if (decoded['type'] == 'session-key') {
            final aesKey = decoded['key'];
            AesCrypto().initFromBase64(aesKey);
            await AesCrypto().saveToPrefs();
            print('✅ AES session key saved. $aesKey');
            _subscription?.cancel();
          }
        } catch (_) {
          // If it's not a session key message, continue with navigation
          return;
        }

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                StartScreen(serverUrl: serverURL, webSocketHandler: handler,),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = MediaQuery
        .of(context)
        .size
        .width * 0.8;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Image.network(
                          'https://portfolio.pizzalover.dev/assets/img/backgroundy.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 300,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 300,
                              color: Colors.grey,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            );
                          },
                        ),
                        Container(
                          height: 300,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                    // Footer stuff
                    Column(
                      children: [
                        SvgPicture.asset(
                          'assets/app_icon.svg',
                          width: 80,
                          height: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Millions of Songs.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Free on Audara.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                    // Spacer between image and form
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Enter Your Server URL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Form(
                              key: _formKey,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: buttonWidth,
                                      child: TextFormField(
                                        controller: _serverController,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white10,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide.none,
                                          ),
                                          hintText: 'Enter server name',
                                          hintStyle: const TextStyle(color: Colors.white54),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Please enter a server name.';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _onNextPressed,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        fixedSize: Size(buttonWidth, 48),
                                      ),
                                      child: const Text(
                                        'Next',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );



  }

    @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }
}