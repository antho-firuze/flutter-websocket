import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pusher_webman/pusher_webman.dart';
import 'package:uuid/uuid.dart';

class PusherClient extends StatefulWidget {
  const PusherClient({super.key});

  @override
  State<PusherClient> createState() => _PusherClientState();
}

class _PusherClientState extends State<PusherClient> {
  bool _connected = false;
  final TextEditingController _outputCtrl = TextEditingController();
  final TextEditingController _messageRcvCtrl = TextEditingController();
  final TextEditingController _userCtrl = TextEditingController(text: 'user1');
  final TextEditingController _messageSendCtrl = TextEditingController(text: 'hello');

  final ScrollController _outputScroll = ScrollController();
  final ScrollController _messageScroll = ScrollController();
  late Pusher? _pusher;
  late String userId;

  @override
  void initState() {
    userId = Uuid().v4();
    super.initState();
  }

  void message(String val) {
    final timeStr = DateFormat('HH:mm:ss').format(DateTime.now());
    _messageRcvCtrl.text += "$timeStr $val \n";
    _messageScroll.animateTo(
      _outputScroll.position.maxScrollExtent,
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
    );
    log("$timeStr $val \n", name: 'message');
  }

  void output(String val) {
    final timeStr = DateFormat('HH:mm:ss').format(DateTime.now());
    _outputCtrl.text += "$timeStr $val \n";
    _outputScroll.animateTo(
      _outputScroll.position.maxScrollExtent,
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  void connect() async {
    final host = '';
    _pusher = Pusher(
      url: 'ws://49.0.1.125:3131',
      // url: 'ws://192.168.18.234:3131',
      key: "ac824d4958a5fe8a9553b90c28560f91",
      auth: PusherAuth('http://49.0.1.125/api/v1/pusher/auth'),
      // auth: PusherAuth('http://192.168.18.234/api/v1/pusher/auth'),
      connectionState: (state) {
        output(state.name);
        setState(() {
          _connected = state == ConnState.connected ? true : false;
        });
      },
      onSubscribed: (channelName) {
        output("Subscribed to [$channelName]");
      },
      onError: (data) {
        output("Error: $data");
      },
    );
    _pusher?.connect();

    // =======================================================
    // final channel = pusher.subscribe('presence-');
    // final channel = pusher.subscribe('private-');
    // final channel = pusher.subscribe('public_channel');
    // =======================================================
  }

  void disconnect() {
    _pusher?.disconnect();
  }

  void subscribePublic() {
    final channel = _pusher?.subscribe('public-channel');
    channel?.bind('public-message', (event) {
      message("$event");
    });
  }

  void unsubscribePublic() {
    _pusher?.unsubscribe('public-channel');
  }

  void subscribePrivate() {
    final privateChannel = _pusher?.subscribe('private-user-$userId');
    privateChannel?.bind('client-message', (event) {
      final userFrom = event['from'];
      final msg = event['message'];
      message("[$userFrom] $msg");
    });
  }

  void unsubscribePrivate() {
    _pusher?.unsubscribe('private-user-$userId');
  }

  void subscribePresence() {
    final userName = _userCtrl.text;
    _pusher?.subscribe('presence-channel', userId: userId, userInfo: {"name": userName});
  }

  void unsubscribePresence() {
    _pusher?.unsubscribe('presence-channel');
  }

  void sendMessage(String msg) {
    final userFrom = _userCtrl.text;
    message("[me] $msg");
    _pusher?.trigger(channelName: 'private-channel', eventName: 'message', data: {"from": userFrom, "message": msg});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pusher Webman')),
      resizeToAvoidBottomInset: true,
      body: Column(
        spacing: 20,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Column(
              spacing: 10,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    spacing: 20,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _userCtrl,
                          decoration: InputDecoration(labelText: 'Current user'),
                          readOnly: _connected,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _connected ? disconnect() : connect(),
                        child: Text(_connected ? 'Disconnect' : 'Connect'),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 5,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    ElevatedButton(onPressed: () => subscribePublic(), child: Text('Subs-Public')),
                    ElevatedButton(onPressed: () => unsubscribePublic(), child: Text('UnSubs-Public')),
                    ElevatedButton(onPressed: () => subscribePrivate(), child: Text('Subs-Private')),
                    ElevatedButton(onPressed: () => unsubscribePrivate(), child: Text('UnSubs-Private')),
                    ElevatedButton(onPressed: () => subscribePresence(), child: Text('Subs-Presence')),
                    ElevatedButton(onPressed: () => unsubscribePresence(), child: Text('UnSubs-Presence')),
                  ],
                ),
                Text('Received Message :'),
                Expanded(
                  child: Scrollbar(
                    child: TextField(
                      controller: _messageRcvCtrl,
                      scrollController: _messageScroll,
                      maxLines: 20,
                      readOnly: true,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text('Pusher Info :'),
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Row(
              spacing: 20,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: TextField(controller: _messageSendCtrl)),
                ElevatedButton(
                  onPressed: _connected ? () => sendMessage(_messageSendCtrl.text) : null,
                  child: Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
