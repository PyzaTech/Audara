import 'package:audara/screens/start/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/WebSocketHandler.dart';

class StartScreen extends StatelessWidget {
  final String serverUrl;
  final WebSocketHandler webSocketHandler;

  const StartScreen({super.key, required this.serverUrl, required this.webSocketHandler});

  void _closeConnection() {
    webSocketHandler.channel.sink.close(1000); // Use 1000 for normal closure
  }

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = MediaQuery.of(context).size.width * 0.8; // 90% of screen width

    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      body: Stack(
        children: [
          Column(
            children: [
              // Top half with image
              Expanded(
                flex: 1,
                child: Stack(
                  children: [
                    Image.network(
                      'https://portfolio.pizzalover.dev/assets/img/backgroundy.png',
                      fit: BoxFit.contain, // Ensures the image maintains its aspect ratio
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey, // Placeholder background color
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
                      color: Colors.black.withOpacity(0.5), // Dark overlay
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                          fixedSize: Size(buttonWidth, 48), // Set button width
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
                          side: const BorderSide(color: Colors.white, width: 1.5), // White stroke outline
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50), // Rounded corners
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Padding inside the button
                          fixedSize: Size(buttonWidth, 48), // Set button width
                        ),
                        child: Stack(
                          alignment: Alignment.center, // Center the text
                          children: [
                            Align(
                              alignment: Alignment.centerLeft, // Align the icon to the far left
                              child: SvgPicture.asset(
                                'assets/google.svg', // Path to your SVG file
                                width: 24, // Adjust the size as needed
                                height: 24,
                              ),
                            ),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: Colors.white, // White text
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
                              pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(webSocketHandler: webSocketHandler,),
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
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/app_icon.svg', // Path to your SVG file
                  width: 80, // Adjust the size as needed
                  height: 80,
                  color: Colors.white, // Set the desired color
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
          // Bottom "Connected to" text
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton(
                onPressed: () async {
                  _closeConnection(); // Close the connection
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