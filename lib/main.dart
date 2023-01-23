import 'views/blue_off_view.dart';
import 'views/find_devices_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const ElogTrackApp());
}

class ElogTrackApp extends StatelessWidget {
  const ElogTrackApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBluePlus.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data!;
            if (state == BluetoothState.on) {
              return const FindDevicesView();
            }
            return BlueOffView(state: state);
          }),
    );
  }
}
