import 'dart:async';
import 'dart:convert';

import 'package:audara/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/AesCrypto.dart';


import '../../utils/WebSocketHandler.dart';

class LoginScreen extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final WebSocketHandler webSocketHandler;


  LoginScreen({super.key, required this.webSocketHandler});


  @override
  Widget build(BuildContext context) {
    final double buttonWidth = MediaQuery.of(context).size.width * 0.8;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Login to Audara',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: buttonWidth,
                  child: TextFormField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Username',
                      hintStyle: const TextStyle(color: Colors.white54),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your username.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: buttonWidth,
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.white54),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your password.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      // Get the username and password
                      String username = _usernameController.text.trim();
                      String password = _passwordController.text.trim();

                      // Create a JSON object
                      Map<String, String> loginData = {
                        "action": "login",
                        "username": username,
                        "password": password,
                      };

                      // Convert the JSON object to a string
                      String jsonString = jsonEncode(loginData);

                      // Encrypt the JSON string
                      final encrypted = AesCrypto().encryptText(jsonString);

                      // Send the encrypted message to the server
                      webSocketHandler.channel.sink.add(encrypted);

                      print("Sent encrypted login data: $encrypted");

                      StreamSubscription? _subscription;
                      _subscription = webSocketHandler.stream.listen(
                            (message) async {
                          try {
                            // Decrypt the message
                            final decryptedMessage = AesCrypto().decryptText(message);
                            print('Decrypted message: $decryptedMessage');

                            // Parse the decrypted JSON string
                            final Map<String, dynamic> jsonResponse = jsonDecode(decryptedMessage);

                            // Access specific fields from the JSON
                            print('Response from server: $jsonResponse');
                            print(jsonResponse['success']);
                            if (jsonResponse['success'] == true) {
                              print('Login successful for user: ${jsonResponse['username']}');

                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.setString('username', username);
                              await prefs.setString('password', password);

                              // Navigate to the home screen or perform other actions
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => Home(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );

                              _subscription?.cancel();

                            } else {
                              print('Login failed: ${jsonResponse['message']}');
                              _subscription?.cancel();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Login failed: ${jsonResponse['message']}'),
                                ),
                              );
                            }
                          } catch (e) {
                            print('Error processing server response: $e');
                          }
                        },
                        onError: (error) {
                          print('WebSocket error: $error');
                        },
                      );

                    }
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
                    'Login',
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
      ),
    );
  }

  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
  }
}