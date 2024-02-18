// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gps_tracking/main.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String? _currentAddress = '';
  Position? _currentPosition;
  late IO.Socket socket;
  bool connected = false;
  late Timer _locationTimer;
  bool _isLocationSendingActive = false;
  String? deviceId = '';
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();

    socket = IO.io('https://sgs-ws.scieverinc.com', <String, dynamic>{
      'transports': ['websocket'],
    });
    logger.i(socket.id);
    socket.on('connect', (_) {
      setState(() {
        connected = true;
      });
      logger.i('Connected to server!');
    });

    socket.on('disconnect', (_) {
      setState(() {
        connected = false;
      });
      logger.e('Disconnected from server!');
    });

    // Initialize the timer, but don't start it immediately
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (_isLocationSendingActive) {
        _getCurrentPosition();
      }
    });
    _initializeAsyncTasks();
  }

  Future<void> _initializeAsyncTasks() async {
    await _initSharedPreferences();
    setState(() {}); // Update the UI after deviceId is initialized
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    deviceId = _prefs.getString('deviceId') ?? const Uuid().v4();
    await _prefs.setString('deviceId', deviceId!); // Ensure persistence
  }

  // _initSharedPreferences() async {
  //   _prefs = await SharedPreferences.getInstance();

  //   deviceId = _prefs.getString('deviceId') ?? const Uuid().v4();
  //   _prefs.setString('deviceId', deviceId!); // Ensure persistence
  // }

  void _toggleLocationSending() {
    setState(() {
      _isLocationSendingActive = !_isLocationSendingActive;
    });

    if (_isLocationSendingActive) {
      // Start the timer
      _locationTimer =
          Timer.periodic(const Duration(seconds: 10), (Timer timer) {
        _getCurrentPosition();
      });
    } else {
      // Stop the timer
      _locationTimer.cancel();
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
      _getAddressFromLatLng(_currentPosition!);
      sendPositionUpdate(position);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  void sendPositionUpdate(Position position) {
    final data = {
      'deviceId': deviceId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'address': _currentAddress,
    };
    socket.emit('newMessage', data);
    logger.i('Sent position update: $data');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('GPS Tracker'),
            const Spacer(),
            Text(connected ? "Connected" : "Disconnected",
                style: TextStyle(
                  fontSize: 14,
                  color: connected ? Colors.green : Colors.red,
                )),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('DEVICE ID: ${deviceId ?? ""}'),
              Text('LAT: ${_currentPosition?.latitude ?? ""}'),
              Text('LNG: ${_currentPosition?.longitude ?? ""}'),
              Text('ADDRESS: ${_currentAddress ?? ""}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _toggleLocationSending,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isLocationSendingActive ? Colors.red : Colors.green,
                ),
                child: Text(
                  _isLocationSendingActive
                      ? "Stop Sending Location"
                      : "Start Sending Location",
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    socket.close();
    super.dispose();
  }
}
