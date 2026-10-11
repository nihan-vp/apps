import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class LanDropServer extends ChangeNotifier {
  HttpServer? _server;
  int _port = 8080;
  String _localIp = '0.0.0.0';
  final List<String> _receivedNotes = [];
  bool get isRunning => _server != null;
  int get port => _port;
  String get localIp => _localIp;
  List<String> get receivedNotes => List.unmodifiable(_receivedNotes);

  Future<void> start({int port = 8080, String localIp = '127.0.0.1'}) async {
    if (_server != null) await stop();
    _port = port;
    _localIp = localIp;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _server!.listen(_handleRequest);
      notifyListeners();
    } catch (e) {
      _server = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      notifyListeners();
    }
  }

  void _handleRequest(HttpRequest request) async {
    final res = request.response;
    res.headers.set('Access-Control-Allow-Origin', '*');

    if (request.method == 'GET' && request.uri.path == '/') {
      res.headers.contentType = ContentType.html;
      res.write('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>FocusON LAN Drop</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #101216; color: #F3F4F6; padding: 24px; }
    .card { background: #181B22; border: 1px solid #2E3442; border-radius: 12px; padding: 20px; max-width: 600px; margin: 0 auto; }
    h2 { color: #0091FF; margin-top: 0; }
    textarea { width: 100%; height: 120px; background: #222630; border: 1px solid #2E3442; color: #fff; padding: 10px; border-radius: 8px; box-sizing: border-box; }
    button { background: #0091FF; color: white; border: none; padding: 12px 20px; border-radius: 8px; font-weight: bold; cursor: pointer; margin-top: 12px; }
    .note { background: #222630; padding: 12px; border-radius: 6px; margin-top: 8px; border-left: 3px solid #00E676; font-size: 14px; }
  </style>
</head>
<body>
  <div class="card">
    <h2>FocusON LAN Drop</h2>
    <p>Transfer text, code snippets, or notes from your browser straight to your Android device over Wi-Fi without internet.</p>
    <form method="POST" action="/drop">
      <textarea name="content" placeholder="Paste text or code snippet here..."></textarea>
      <button type="submit">Drop to Phone</button>
    </form>
    <h3>Recent Drops on Phone:</h3>
    ${_receivedNotes.map((n) => '<div class="note">' + htmlEscape.convert(n) + '</div>').join('')}
  </div>
</body>
</html>
''');
      await res.close();
    } else if (request.method == 'POST' && request.uri.path == '/drop') {
      final body = await utf8.decoder.bind(request).join();
      var content = body;
      if (body.startsWith('content=')) {
        content = Uri.decodeQueryComponent(body.substring(8).replaceAll('+', ' '));
      }
      if (content.isNotEmpty) {
        _receivedNotes.insert(0, content);
        notifyListeners();
      }
      res.redirect(Uri.parse('/'));
    } else {
      res.statusCode = HttpStatus.notFound;
      res.write('Not Found');
      await res.close();
    }
  }

  void clearNotes() {
    _receivedNotes.clear();
    notifyListeners();
  }
}
