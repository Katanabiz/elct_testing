import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BlueOffView extends StatelessWidget {
  const BlueOffView({Key? key, this.state}) : super(key: key);

  final BluetoothState? state;



  Future<void> requestLocationAndBlutoothPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetoothConnect,
    ].request();
    final serviceStatusLocation = await Permission.locationWhenInUse.isGranted;
    final serviceStatusbluetooth = await Permission.bluetoothConnect.isGranted;

    bool isLocation = (serviceStatusLocation && serviceStatusbluetooth) ==
        ServiceStatus.enabled;

    if (!await serviceStatusLocation && serviceStatusbluetooth) {
      await statuses;
    }
    FlutterBluePlus.instance.turnOn();
    isLocation;
  }

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
                onPressed: () {
                  requestLocationAndBlutoothPermission();
                },
                child: const Text('TURN ON'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


