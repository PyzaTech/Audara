import 'package:audara/main.dart';
import 'package:audara/screens/start/LoginScreen.dart';
import 'package:audara/screens/start/SelectServerScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/WebSocketHandler.dart';

class StartScreen extends StatelessWidget {
  final String serverUrl;
  final WebSocketHandler webSocketHandler;

  const StartScreen({super.key, required this.serverUrl, required this.webSocketHandler});

  void _closeConnection() {
    webSocketHandler.channel?.sink.close(1000); // Use 1000 for normal closure
    Navigator.push(
      navigatorKey.currentContext!,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SelectServerScreen(serverUrl: serverUrl),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = MediaQuery.of(context).size.width * 0.8;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // Top half with image
              Expanded(
                flex: 1,
                child: Stack(
                  children: [
                    if(!isLandscape)
                      Image.network(
                        'https://portfolio.pizzalover.dev/assets/img/backgroundy.png',
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
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
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              // Bottom half with buttons and text
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: isLandscape
                        ? MainAxisAlignment.start // Align items to the top in landscape
                        : MainAxisAlignment.center, // Center items in portrait
                    children: [
                      if (isLandscape) const SizedBox(height: 16), // Add spacing in landscape
                      ElevatedButton(
                        onPressed: () {
                          // Handle "Sign up free" action
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          fixedSize: Size(buttonWidth, 48),
                        ),
                        child: const Text(
                          'Sign up free',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          // Handle "Continue with Google" action
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          fixedSize: Size(buttonWidth, 48),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SvgPicture.asset(
                                'assets/google.svg',
                                width: 24,
                                height: 24,
                              ),
                            ),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  LoginScreen(webSocketHandler: webSocketHandler),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Centered logo and text
          Align(
            alignment: isLandscape ? Alignment.topCenter : Alignment.center,
            child: Padding(
              padding: isLandscape
                  ? const EdgeInsets.only(top: 100.0) // Adjust padding in landscape
                  : EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                ],
              ),
            ),
          ),
          // Bottom "Connected to" text
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton(
                onPressed: () async {
                  _closeConnection();
                },
                child: Text(
                  'Connected to:\n$serverUrl',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}