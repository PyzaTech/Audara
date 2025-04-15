import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../screens/start/SelectServerScreen.dart';
import 'AesCrypto.dart';

class WebSocketHandler {
  final WebSocketChannel _channel;
  final StreamController<dynamic> _controller = StreamController.broadcast();
  Timer? _heartbeatTimer; // Timer for the heartbeat
  final Duration _heartbeatInterval = const Duration(seconds: 1); // Interval for heartbeats
  final BuildContext context;

  WebSocketHandler(String serverUrl, this.context)
      : _channel = WebSocketChannel.connect(Uri.parse(serverUrl)) {
    // Listen to the WebSocket channel and add messages to the stream
    _channel.stream.listen(
          (message) {
        print('Message received: $message'); // Debug log
        _controller.add(message);
      },
      onError: (error) {
        print('WebSocket error: $error'); // Debug log
        _controller.addError(error);
      },
      onDone: () async {
        print('WebSocket connection closed'); // Debug log
        _stopHeartbeat(); // Stop the heartbeat when the connection is closed
        _controller.close();
        final prefs = await SharedPreferences.getInstance();

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => SelectServerScreen(serverUrl: prefs.getString('server_url'),),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
    );

    _startHeartbeat(); // Start the heartbeat when the connection is established
  }

  // Expose the stream for listeners
  Stream<dynamic> get stream => _controller.stream;

  WebSocketChannel get channel => _channel;

  // Send a message through the WebSocket
  void sendMessage(dynamic message) {
    _channel.sink.add(message);
  }

  // Close the WebSocket connection
  void close() {
    _stopHeartbeat(); // Stop the heartbeat before closing
    _channel.sink.close();
    _controller.close();
  }

  // Start the heartbeat timer
  void _startHeartbeat() {
    // Add a wait to ensure the connection is established before starting the heartbeat
    Future.delayed(const Duration(seconds: 2), () {
      print('Heartbeat started');
    });
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      // print('Sending heartbeat...');

      Map<String, String> data = {
        "action": "heartbeat",
      };

      // Convert the JSON object to a string
      String jsonString = jsonEncode(data);

      // Encrypt the JSON string
      final encrypted = AesCrypto().encryptText(jsonString);

      // Send the encrypted message to the server
      channel.sink.add(encrypted);
        });
  }

  // Stop the heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}