import 'package:gps_tracking/socket_events.dart';
import 'package:gps_tracking/socket_service.dart';

class TimerService {
  // Timer methods.
  static startServerTimer(int duration) {
    if (SocketService.socket!.connected) {
      SocketService.socket!
          .emit(TimerEvents.timerStart.toString().split('.').last, {
        "dur": duration,
      });
    } else {
      print("No socket connection found.");
    }
  }

  static stopServerTimer() {
    if (SocketService.socket!.connected) {
      SocketService.socket!
          .emit(TimerEvents.timerStop.toString().split('.').last);
    } else {
      print("No socket connection found.");
    }
  }
}
