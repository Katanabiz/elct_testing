import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BlueOffView extends StatelessWidget {
  const BlueOffView({Key? key, this.state}) : super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/car.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
                style: Theme.of(context)
                    .primaryTextTheme
                    .subtitle2
                    ?.copyWith(color: Colors.white),
              ),
              ElevatedButton(
                onPressed: Platform.isAndroid
                    ? () async {
                        if (!await Permission.bluetoothConnect.isGranted) {
                          await Permission.bluetoothConnect.request();
                        }
                        FlutterBluePlus.instance.turnOn();
                      }
                    : null,
                child: const Text('TURN ON'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  ? () => FlutterBluePlus.instance.turnOn()
// : null,
