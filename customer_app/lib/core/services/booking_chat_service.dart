import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Real 2-Human Dynamic Chat Synchronization Service
/// Cross-process IPC via disk and local server synchronization.
/// Zero mock data, zero AI/bot replies.
class BookingChatService {
  BookingChatService._internal();
  static final BookingChatService instance = BookingChatService._internal();

  static const String _serverUrl = 'http://127.0.0.1:8080';
  final Map<String, StreamController<List<Map<String, dynamic>>>> _streamControllers = {};
  final Map<String, Timer> _pollingTimers = {};
  final Map<String, List<Map<String, dynamic>>> _inMemoryCache = {};

  List<File> _getChatStorageFiles() {
    final list = <File>[];
    try {
      if (Platform.isWindows) {
        list.add(File(r'C:\Users\Public\ServiceHub\service_hub_chat_messages.json'));
      }
    } catch (_) {}

    try {
      final tempDir = Directory.systemTemp;
      list.add(File('${tempDir.path}/service_hub_chat_messages.json'));
    } catch (_) {}

    return list;
  }

  /// Streams real messages for a specific booking in real time.
  Stream<List<Map<String, dynamic>>> streamMessages(String bookingId) {
    if (!_streamControllers.containsKey(bookingId) || _streamControllers[bookingId]!.isClosed) {
      _streamControllers[bookingId] = StreamController<List<Map<String, dynamic>>>.broadcast(
        onCancel: () {
          _pollingTimers[bookingId]?.cancel();
          _pollingTimers.remove(bookingId);
        },
      );

      // Start periodic polling while someone is listening
      _pollMessages(bookingId);
      _pollingTimers[bookingId] = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        _pollMessages(bookingId);
      });
    }

    // Immediately push whatever is currently cached
    final cached = _inMemoryCache[bookingId] ?? [];
    scheduleMicrotask(() {
      if (_streamControllers.containsKey(bookingId) && !_streamControllers[bookingId]!.isClosed) {
        _streamControllers[bookingId]!.add(List<Map<String, dynamic>>.from(cached));
      }
    });

    return _streamControllers[bookingId]!.stream;
  }

  /// Stop polling when leaving chat
  void closeChatStream(String bookingId) {
    _pollingTimers[bookingId]?.cancel();
    _pollingTimers.remove(bookingId);
    _streamControllers[bookingId]?.close();
    _streamControllers.remove(bookingId);
  }

  /// Retrieves messages synchronously from local memory cache
  List<Map<String, dynamic>> getCachedMessages(String bookingId) {
    return _inMemoryCache[bookingId] ?? [];
  }

  /// Polls disk files and server for latest genuine messages
  Future<List<Map<String, dynamic>>> _pollMessages(String bookingId) async {
    List<Map<String, dynamic>>? latestMessages;

    // 1. Check local shared disk IPC
    try {
      for (final file in _getChatStorageFiles()) {
        if (file.existsSync()) {
          final content = file.readAsStringSync().trim();
          if (content.isNotEmpty) {
            final decoded = jsonDecode(content);
            if (decoded is Map && decoded.containsKey(bookingId)) {
              final list = decoded[bookingId];
              if (list is List) {
                latestMessages = list.cast<Map<String, dynamic>>();
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[BookingChatService] Disk read warning: $e');
    }

    // 2. Fetch from local backend sync server
    try {
      final res = await http.get(Uri.parse('$_serverUrl/api/chat?booking_id=$bookingId')).timeout(const Duration(milliseconds: 1200));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          latestMessages = decoded.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {
      // Server not reachable or timed out, disk data is source of truth
    }

    if (latestMessages != null) {
      _inMemoryCache[bookingId] = latestMessages;
      if (_streamControllers.containsKey(bookingId) && !_streamControllers[bookingId]!.isClosed) {
        _streamControllers[bookingId]!.add(List<Map<String, dynamic>>.from(latestMessages));
      }
      return latestMessages;
    }

    return _inMemoryCache[bookingId] ?? [];
  }

  /// Send a genuine human message
  Future<void> sendMessage({
    required String bookingId,
    required String text,
    required String senderRole, // 'customer' or 'partner'
    required String senderName,
    required String senderPhone,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final messagePayload = {
      'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
      'booking_id': bookingId,
      'sender_role': senderRole,
      'sender_name': senderName,
      'sender_phone': senderPhone,
      'text': cleanText,
      'timestamp': now,
      'created_at': now,
    };

    // Update in-memory cache immediately for instantaneous UI response
    final currentList = List<Map<String, dynamic>>.from(_inMemoryCache[bookingId] ?? []);
    currentList.add(messagePayload);
    _inMemoryCache[bookingId] = currentList;

    if (_streamControllers.containsKey(bookingId) && !_streamControllers[bookingId]!.isClosed) {
      _streamControllers[bookingId]!.add(List<Map<String, dynamic>>.from(currentList));
    }

    // Persist to shared disk files
    try {
      for (final file in _getChatStorageFiles()) {
        try {
          if (!file.parent.existsSync()) {
            file.parent.createSync(recursive: true);
          }
          Map<String, dynamic> allChats = {};
          if (file.existsSync()) {
            final existing = file.readAsStringSync().trim();
            if (existing.isNotEmpty) {
              final dec = jsonDecode(existing);
              if (dec is Map) {
                allChats = Map<String, dynamic>.from(dec);
              }
            }
          }
          final bookingList = List<dynamic>.from(allChats[bookingId] ?? []);
          bookingList.add(messagePayload);
          allChats[bookingId] = bookingList;
          file.writeAsStringSync(jsonEncode(allChats), flush: true);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[BookingChatService] Disk persist error: $e');
    }

    // Post to server asynchronously
    try {
      await http.post(
        Uri.parse('$_serverUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(messagePayload),
      ).timeout(const Duration(milliseconds: 1500));
    } catch (e) {
      debugPrint('[BookingChatService] Server post error: $e');
    }
  }
}
