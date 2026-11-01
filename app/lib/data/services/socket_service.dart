import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/config/app_config.dart';
import '../models/message_model.dart';

class SocketService {
  io.Socket? _socket;
  String? _currentToken;
  String? _activeGroupId;

  final _messageController = StreamController<MessageModel>.broadcast();
  final _expenseAddedController = StreamController<Map<String, dynamic>>.broadcast();
  final _expenseUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _cycleClosedController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<MessageModel> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onExpenseAdded => _expenseAddedController.stream;
  Stream<Map<String, dynamic>> get onExpenseUpdated => _expenseUpdatedController.stream;
  Stream<Map<String, dynamic>> get onCycleClosed => _cycleClosedController.stream;
  Stream<bool> get onConnectionStatus => _connectionStatusController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    if (_socket != null && _currentToken == token && _socket!.connected) {
      return;
    }

    _currentToken = token;
    _disconnectInternal();

    final socketUrl = AppConfig.socketBaseUrl;
    debugPrint('[Socket] Connecting to $socketUrl...');

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(99999)
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket] Connected successfully!');
      _connectionStatusController.add(true);
      if (_activeGroupId != null) {
        joinGroupRoom(_activeGroupId!);
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket] Disconnected');
      _connectionStatusController.add(false);
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket] Connection error: $err');
      _connectionStatusController.add(false);
    });

    // Listen to real-time events
    _socket!.on('new_message', (data) {
      debugPrint('[Socket] Event: new_message received');
      if (data is Map<String, dynamic>) {
        try {
          final message = MessageModel.fromJson(data);
          _messageController.add(message);
        } catch (e) {
          debugPrint('[Socket] Error parsing new_message: $e');
        }
      }
    });

    _socket!.on('expense_added', (data) {
      debugPrint('[Socket] Event: expense_added received');
      if (data is Map<String, dynamic>) {
        _expenseAddedController.add(data);
      }
    });

    _socket!.on('expense_updated', (data) {
      debugPrint('[Socket] Event: expense_updated received');
      if (data is Map<String, dynamic>) {
        _expenseUpdatedController.add(data);
      }
    });

    _socket!.on('cycle_closed', (data) {
      debugPrint('[Socket] Event: cycle_closed received');
      if (data is Map<String, dynamic>) {
        _cycleClosedController.add(data);
      }
    });
  }

  void joinGroupRoom(String groupId) {
    _activeGroupId = groupId;
    if (_socket != null && _socket!.connected) {
      debugPrint('[Socket] Joining room for group: $groupId');
      _socket!.emit('join_group', {'groupId': groupId});
    }
  }

  void leaveGroupRoom(String groupId) {
    if (_activeGroupId == groupId) {
      _activeGroupId = null;
    }
    if (_socket != null && _socket!.connected) {
      debugPrint('[Socket] Leaving room for group: $groupId');
      _socket!.emit('leave_group', {'groupId': groupId});
    }
  }

  void _disconnectInternal() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }

  void disconnect() {
    _disconnectInternal();
    _currentToken = null;
    _activeGroupId = null;
    _connectionStatusController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _expenseAddedController.close();
    _expenseUpdatedController.close();
    _cycleClosedController.close();
    _connectionStatusController.close();
  }
}
