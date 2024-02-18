import 'package:flutter/material.dart';
import 'package:gps_tracking/socket_service.dart';
import 'package:gps_tracking/stream_socket.dart';
import 'package:gps_tracking/timer_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // This is to convert the time in seconds to a string with the format '00:00'.
  String _convertToDisplayTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours == 0) {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Timer app"),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          (SocketService.socket != null && SocketService.socket!.connected)
              ? StreamBuilder(
                  stream: streamSocket.getResponse,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data.toString() == "0") {
                        return const Text("Socket Status : TICKING TIMEOUT");
                      } else {
                        return Text(
                          'Socket Status : TIMER TICKING - ${_convertToDisplayTime(
                            Duration(
                              seconds: int.parse(snapshot.data.toString()),
                            ),
                          ).toString()}',
                        );
                      }
                    } else {
                      if (SocketService.socket!.connected) {
                        return const Text("Socket Status : CONNECTED");
                      } else {
                        return const Text("Socket Status : DISCONNECTED");
                      }
                    }
                  },
                )
              : const Text('Socket Status : DISCONNECTED'),
          ElevatedButton.icon(
            onPressed: () {
              // Populate these two values with your own values.
              // Get token from Firebase Auth or other authentication service.
              // Get deviceId using `device_info_plus` package.
              SocketService.connectAndListenToSocket('token',
                  'deviceId'); // Start a socket channel with the server.

              // Update the UI when anything change in the socket.
              SocketService.socket!.onAny((event, data) {
                setState(() {});
              });
            },
            label: const Text('Connect Socket'),
            icon: const Icon(Icons.connect_without_contact_rounded),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              TimerService.startServerTimer(
                  10); // Start the server-side timer with 10 seconds.
            },
            label: const Text('Start Server Countdown'),
            icon: const Icon(Icons.timer),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[900],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              TimerService.stopServerTimer();
            },
            label: const Text('Stop Server Countdown'),
            icon: const Icon(Icons.timer_off),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[900],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Disconnect from the socket. (Does not remove the listeners.)
              SocketService.disconnectSocket();
            },
            label: const Text(
                'Disconnect Socket\n(Does not remove the listeners)'),
            icon: const Icon(Icons.remove_done),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Disconnect the socket and remove the listeners.
              SocketService.disposeSocket();
            },
            label: const Text(
                'Dispose Socket\n(Fresh Start - removes all listeners)'),
            icon: const Icon(Icons.cancel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
          ),
        ],
      )),
    );
  }
}
