import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';
import '../../features/auth/providers/auth_provider.dart';

class SocketService {
  io.Socket? _socket;
  final _connectionStateController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionStateController.stream;
  bool get isConnected => _socket?.connected ?? false;

  void init(String? token) {
    if (_socket != null) {
      if (_socket!.connected) return;
      _socket!.dispose();
    }

    final uri = '${ApiConstants.socketUrl}/events';
    debugPrint('🔌 Connecting to WebSocket: $uri');

    _socket = io.io(
      uri,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setAuth({'token': token ?? ''})
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('✅ WebSocket Connected: ${_socket?.id}');
      _connectionStateController.add(true);
    });

    _socket!.onDisconnect((reason) {
      debugPrint('❌ WebSocket Disconnected: $reason');
      _connectionStateController.add(false);
    });

    _socket!.onConnectError((err) {
      debugPrint('⚠️ WebSocket Connect Error: $err');
      _connectionStateController.add(false);
    });

    _socket!.connect();
  }

  void joinOrder(String orderId) {
    if (_socket?.connected == true) {
      debugPrint('📡 Emitting [order:join] for order $orderId');
      _socket!.emit('order:join', {'orderId': orderId});
    }
  }

  void leaveOrder(String orderId) {
    if (_socket?.connected == true) {
      debugPrint('📡 Emitting [order:leave] for order $orderId');
      _socket!.emit('order:leave', {'orderId': orderId});
    }
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _connectionStateController.close();
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  final authState = ref.watch(authProvider);

  if (authState.accessToken != null) {
    service.init(authState.accessToken);
  }

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
