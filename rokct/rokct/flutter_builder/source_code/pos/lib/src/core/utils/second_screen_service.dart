import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SecondScreenState {
  final double totalPrice;
  final double amountReceived;
  final double change;
  final String currency;
  final bool paymentConfirmed;
  final bool isOrderCalculateActive;
  final bool showBlankScreen; // Add this field

  SecondScreenState({
    this.totalPrice = 0,
    this.amountReceived = 0,
    this.change = 0,
    this.currency = '',
    this.paymentConfirmed = false,
    this.isOrderCalculateActive = false,
    this.showBlankScreen = true, // Default to true
  });

  SecondScreenState copyWith({
    double? totalPrice,
    double? amountReceived,
    double? change,
    String? currency,
    bool? paymentConfirmed,
    bool? isOrderCalculateActive,
    bool? showBlankScreen,
  }) {
    return SecondScreenState(
      totalPrice: totalPrice ?? this.totalPrice,
      amountReceived: amountReceived ?? this.amountReceived,
      change: change ?? this.change,
      currency: currency ?? this.currency,
      paymentConfirmed: paymentConfirmed ?? this.paymentConfirmed,
      isOrderCalculateActive:
          isOrderCalculateActive ?? this.isOrderCalculateActive,
      showBlankScreen: showBlankScreen ?? this.showBlankScreen,
    );
  }
}

class SecondScreenNotifier extends StateNotifier<SecondScreenState> {
  SecondScreenNotifier() : super(SecondScreenState());

  void updateState(SecondScreenState newState) {
    state = newState;
  }

  void resetState() {
    state = SecondScreenState();
  }

  void setOrderCalculateActive(bool isActive) {
    state = state.copyWith(isOrderCalculateActive: isActive);
  }

  void confirmPayment() {
    state = state.copyWith(paymentConfirmed: true);
    Timer(Duration(seconds: 5), () {
      resetState();
    });
  }
}

final secondScreenProvider =
    StateNotifierProvider<SecondScreenNotifier, SecondScreenState>(
        (ref) => SecondScreenNotifier());

class SecondScreenService {
  HttpServer? _server;
  List<WebSocketChannel> _clients = [];
  String _secondScreenUrl = '';

  Future<void> startServer() async {
    final handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(_handleRequest);

    _server = await io.serve(handler, InternetAddress.anyIPv4, 8080);

    String ipAddress = await _getIpAddress();
    _secondScreenUrl = 'http://$ipAddress:${_server!.port}';

    print('Serving at $_secondScreenUrl');
  }

  Future<String> _getIpAddress() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          return addr.address;
        }
      }
    }
    return 'localhost';
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    if (request.url.path == 'ws') {
      final handler = webSocketHandler((WebSocketChannel webSocket) {
        _clients.add(webSocket);
        webSocket.stream.listen(
          (message) {
            // Handle any incoming messages if needed
          },
          onDone: () {
            _clients.remove(webSocket);
          },
        );
      });
      return handler(request);
    }

    return shelf.Response.ok(
      _secondScreenHtml,
      headers: {'content-type': 'text/html'},
    );
  }

  void broadcastUpdate(SecondScreenState state) {
    final data = jsonEncode({
      'totalPrice': state.totalPrice,
      'amountReceived': state.amountReceived,
      'change': state.change,
      'currency': state.currency,
      'paymentConfirmed': state.paymentConfirmed,
      'isOrderCalculateActive': state.isOrderCalculateActive,
    });
    for (var client in _clients) {
      client.sink.add(data);
    }
  }

  String get secondScreenUrl => _secondScreenUrl;

  void dispose() {
    _server?.close();
    for (var client in _clients) {
      client.sink.close();
    }
  }
}

final secondScreenServiceProvider = Provider((ref) => SecondScreenService());

const _secondScreenHtml = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Order Display</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background-color: #000000;
            color: #ffffff;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            padding: 0;
        }
        .container {
            text-align: center;
            padding: 40px;
            width: 100%;
            height: 100%;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .small-text {
            font-size: 24px;
            margin-bottom: 10px;
        }
        .large-text {
            font-size: 72px;
            font-weight: bold;
            margin-bottom: 20px;
        }
        .thank-you {
            font-size: 96px;
            font-weight: bold;
            margin-bottom: 20px;
        }
        #blankScreen {
            width: 100%;
            height: 100%;
        }
    </style>
</head>
<body>
    <div class="container">
        <div id="blankScreen" style="display: none;"></div>
        <div id="content" style="display: none;">
            <div id="beforePayment">
                <div class="small-text">amount due</div>
                <div id="totalPrice" class="large-text"></div>
            </div>
            <div id="duringPayment" style="display: none;">
                <div class="small-text">amount received: <span id="amountReceived"></span></div>
                <div id="change" class="large-text"></div>
            </div>
            <div id="afterPayment" style="display: none;">
                <div class="thank-you">THANK YOU</div>
                <div class="small-text">please come again</div>
            </div>
        </div>
    </div>

    <script>
        const socket = new WebSocket('ws://' + window.location.host + '/ws');
        let currencySymbol = 'R';

        socket.onmessage = function(event) {
            console.log('Received message:', event.data);
            const data = JSON.parse(event.data);
            currencySymbol = data.currency || currencySymbol;
            
            requestAnimationFrame(() => {
                updateDisplay(data);
            });
        };

        function updateDisplay(data) {
            console.log('Updating display with:', data);
            
            if (data.showBlankScreen) {
                document.getElementById('blankScreen').style.display = 'block';
                document.getElementById('content').style.display = 'none';
                return;
            }

            document.getElementById('blankScreen').style.display = 'none';
            document.getElementById('content').style.display = 'block';

            const totalPrice = formatCurrency(data.totalPrice);
            const amountReceived = formatCurrency(data.amountReceived);
            const change = formatCurrency(data.change);

            if (data.paymentConfirmed) {
                document.getElementById('beforePayment').style.display = 'none';
                document.getElementById('duringPayment').style.display = 'none';
                document.getElementById('afterPayment').style.display = 'block';
            } else if (data.amountReceived > 0) {
                document.getElementById('beforePayment').style.display = 'none';
                document.getElementById('duringPayment').style.display = 'block';
                document.getElementById('afterPayment').style.display = 'none';
                document.getElementById('amountReceived').textContent = amountReceived;
                document.getElementById('change').textContent = change;
            } else {
                document.getElementById('beforePayment').style.display = 'block';
                document.getElementById('duringPayment').style.display = 'none';
                document.getElementById('afterPayment').style.display = 'none';
                document.getElementById('totalPrice').textContent = totalPrice;
            }
        }

        function formatCurrency(amount) {
            return currencySymbol + amount.toFixed(2);
        }
    </script>
</body>
</html>
''';

