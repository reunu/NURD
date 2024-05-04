import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nurd/blinker_arrow.dart';
import 'package:nurd/clock_widget.dart';
import 'package:redis/redis.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

String redisIPScooter = "192.168.7.1";
String redisIPLocal = "192.168.193.247";
int redisPort = 6379;

bool useLocalRedis = true;

class _MyHomePageState extends State<MyHomePage> {
  bool _connected = false;
  int _speed = 0;
  bool _blinkLeft = false;
  bool _blinkRight = false;
  LatLng _location = const LatLng(50.930422, 11.592763); // change later
  double _rotation = 0;
  late final RedisConnection link;
  final MapController mapController = MapController();

  void _connectRedis() async {
    link = RedisConnection();
    try {
      Command cmd;
      if (useLocalRedis) {
        cmd = await link.connect(redisIPLocal, redisPort);
      } else {
        cmd = await link.connect(redisIPScooter, redisPort);
      }
      await cmd.send_object(["HSET", "dashboard", "ready", "true"]);
      await cmd.send_object(["PUBLISH", "dashboard", "ready"]);
      setState(() {
        _connected = true;
      });
      log("Connected to Redis");
      _subscribeData(cmd);
    } catch (e) {
      log("Error during connection: $e");
    }
  }

  void _subscribeData(Command cmd) async {
    Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      cmd.send_object(["HGET", "engine-ecu", "speed"]).then((speedRes) {
        setState(() {
          _speed = int.parse(speedRes);
        });
      });
      cmd.send_object(["HGET", "gps", "latitude"]).then((latStr) {
        final lat = double.parse(latStr);
        setState(() {
          _location = LatLng(lat, _location.longitude);
          mapController.move(_location, 18);
        });
      });

      cmd.send_object(["HGET", "gps", "longitude"]).then((lonStr) {
        final lon = double.parse(lonStr);
        setState(() {
          _location = LatLng(_location.latitude, lon);
          mapController.move(_location, 18);
        });
      });

      cmd.send_object(["HGET", "gps", "course"]).then((courseStr) {
        final rotation = double.parse(courseStr);
        setState(() {
          _rotation = rotation;
          mapController.rotate(_rotation);
        });
      });

      cmd.send_object(["HGET", "vehicle", "blinker:state"]).then((blinkerRes) {
        if (blinkerRes == "left") {
          setState(() {
            _blinkLeft = true;
            _blinkRight = false;
          });
        } else if (blinkerRes == "right") {
          setState(() {
            _blinkLeft = false;
            _blinkRight = true;
          });
        } else {
          setState(() {
            _blinkLeft = false;
            _blinkRight = false;
          });
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _connectRedis();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body:
       Column(
        children: [
          Padding(padding: const EdgeInsetsDirectional.all(8),
              child: SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Clock(
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const FlutterLogo(size: 32),
                    Icon(
                      _connected ? Icons.link_rounded : Icons.link_off_rounded,
                      color: _connected ? Colors.white : Colors.red,
                      weight: 900,
                      size: 32,
                    )
                  ],
                ),
              ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: const MapOptions(
                initialCenter: LatLng(50.930422, 11.592763), // change later
                initialZoom: 18.0,
                maxZoom: 19,
                minZoom: 18,
                initialRotation: 42,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  // Plenty of other options available!
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsetsDirectional.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BlinkerArrow(
                  blink: _blinkLeft,
                  direction: BlinkerDirection.left,
                ),
                Column(
                  children: [
                    Text(
                      _speed.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 64,
                        height: 1,
                      ),
                    ),
                    const Text("km/h",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        )),
                  ],
                ),
                BlinkerArrow(
                  blink: _blinkRight,
                  direction: BlinkerDirection.right,
                ),
              ],
            )
          ),
        ],
      ),
    );
  }
}
