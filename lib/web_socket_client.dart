import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:web_socket_client/web_socket_client.dart';

class WebSocketClient extends StatefulWidget {
  const WebSocketClient({super.key});

  @override
  State<WebSocketClient> createState() => _WebSocketClientState();
}

class _WebSocketClientState extends State<WebSocketClient> {
  bool _connected = false;
  final TextEditingController _outputCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _groupCtrl = TextEditingController();

  final ScrollController _outputScroll = ScrollController();
  final ScrollController _messageScroll = ScrollController();
  late WebSocket socket;

  StreamSubscription? _connSubs;

  @override
  void initState() {
    super.initState();

    _userCtrl.text = 'user1';
    _groupCtrl.text = 'group1';

    _connSubs = _fetchConnectionState().listen((connected) {
      if (connected) {
        ping();
      }
    });
  }

  @override
  void dispose() {
    _connSubs?.cancel();
    _connSubs = null;

    super.dispose();
  }

  void output(String val) {
    _outputCtrl.text += "$val \n";
    _outputScroll.jumpTo(_outputScroll.position.maxScrollExtent);
  }

  void message(String val) {
    _messageCtrl.text += "$val \n";
    _messageScroll.jumpTo(_messageScroll.position.maxScrollExtent);
  }

  void connect() {
    final backoff = BinaryExponentialBackoff(initial: Duration(seconds: 3), maximumStep: 3);
    socket = WebSocket(
      Uri.parse('ws://192.168.18.234:3131'),
      headers: {"app_key": "/app/ac824d4958a5fe8a9553b90c28560f91?"},
      backoff: backoff,
    );

    socket.messages.listen((event) {
      if (event == null && (event as String).isEmpty) {
        return;
      }

      final json = jsonDecode(event);
      if (json['event'] == 'pusher:pong') {
        log("$event", name: "PONG");
        return;
      }

      message(event.toString());

      log(event.toString(), name: 'MESSAGE');
    });

    socket.connection.listen((state) {
      setState(() {
        if (state is Connected) {
          _connected = true;
          output("Connected");

          // DEFAULT SUBSCRIBES
          subscribePublic();
        } else if (state is Reconnected) {
          _connected = true;
          output("Reconnected");

          // DEFAULT SUBSCRIBES
          subscribePublic();
        } else if (state is Disconnected) {
          _connected = false;
          output("Disconnected");
        }
      });
      log("$state", name: 'STATE');
    });
  }

  void disconnect() {
    socket.close();
  }

  Stream<bool> _fetchConnectionState() async* {
    while (true) {
      log('check connection', name: 'STREAM');
      yield _connected;

      await Future.delayed(Duration(seconds: 50));
    }
  }

  void ping() {
    var msg = {"event": "pusher:ping"};
    socket.send(jsonEncode(msg));
    // output('send ping');
    log(jsonEncode(msg), name: "PING");
  }

  void subscribe(String channel) {
    if (channel.contains('private-')) {
      
    }
    if (channel.contains('presence-')) {

    }
    
  }

  void subscribePublic() {
    var msg = {
      "event": "pusher:subscribe",
      "data": {"channel": "notification"}
    };
    socket.send(jsonEncode(msg));
    output('subscribe: notification');
  }

  void subscribePrivate() {
    var msg = {
      "event": "pusher:subscribe",
      "data": {"channel": "private-"}
    };
    socket.send(jsonEncode(msg));
    output('subscribe: notification');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Web Socket Client')),
      body: Column(
        spacing: 20,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              Text('Received Message :'),
              Scrollbar(
                child: TextField(
                  controller: _messageCtrl,
                  scrollController: _messageScroll,
                  maxLines: 10,
                  readOnly: true,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text('Connection State :'),
              Scrollbar(
                child: TextField(
                  controller: _outputCtrl,
                  scrollController: _outputScroll,
                  maxLines: 5,
                  readOnly: true,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => _connected ? disconnect() : connect(),
            child: Text(_connected ? 'Disconnect' : 'Connect'),
          ),
          // Row(
          //   spacing: 20,
          //   children: [
          //     ElevatedButton(
          //       onPressed: () => subscribePublic(),
          //       child: Text('Subscribe public'),
          //     ),
          //   ],
          // ),
          Row(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: TextField(
                controller: _userCtrl,
                decoration: InputDecoration(labelText: 'Current user'),
              )),
              ElevatedButton(
                onPressed: () => connect(),
                child: Text('Subscribe user'),
              ),
            ],
          ),
          Row(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () => connect(),
                child: Text('Subscribe group'),
              ),
              Expanded(child: TextField(controller: _groupCtrl)),
            ],
          ),
          // SizedBox(
          //   height: 50,
          //   child: ListView(
          //     scrollDirection: Axis.horizontal,
          //     shrinkWrap: true,
          //     children: [
          //       Row(
          //         spacing: 10,
          //         children: [
          //           ElevatedButton(
          //             onPressed: () => connect(),
          //             child: Text('Subscribe group'),
          //           ),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
