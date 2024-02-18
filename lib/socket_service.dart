import 'package:gps_tracking/socket_events.dart';
import 'package:gps_tracking/stream_socket.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SocketService {
  static Socket? socket;

  static connectAndListenToSocket(String authToken, String deviceId) {
    socket = io(
        'http://192.168.1.92:3000', // Replace with your network IP
        OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({
              'token': 'Bearer $authToken',
            })
            .setQuery({
              'deviceId': deviceId,
            })
            .disableAutoConnect()
            .build());

    if (!socket!.connected) {
      socket!.connect();
      print('connecting....');
    }

    socket!.onConnect((_) {
      print('connected and listening to socket!.');
    });

    socket!.onDisconnect((_) => print('disconnected from socket!.'));

    socket!.onError((data) => print(data));

    socket!.onConnectError((data) => {print(data)});

    // When the message event 'tick' received from server, that data is added to a stream 'streamSocket'.
    socket!.on(TimerEvents.tick.toString().split('.').last, (data) {
      streamSocket.addResponse(data['timer'].toString());
    });
  }

  static disconnectSocket() async {
    socket!.disconnect();
  }

  static disposeSocket() async {
    socket!.dispose();
  }
}
