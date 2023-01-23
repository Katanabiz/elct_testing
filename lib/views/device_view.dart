import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../dummy_data.dart';
import 'package:http/http.dart' as http;

import '../widgets/characteristic_tile_widget.dart';
import '../widgets/descriptor_tile_widget.dart';
import '../widgets/service_tile_widget.dart';

class DeviceView extends StatelessWidget {
  const DeviceView({Key? key, required this.device}) : super(key: key);

  final BluetoothDevice device;

  List<int> _getRandomBytes() {
    final math = Random();
    return [
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255)
    ];
  }

  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
    return services
        .map(
          (s) => ServiceTileWidget(
            service: s,
            characteristicTiles: s.characteristics
                .map(
                  (c) => CharacteristicTile(
                    characteristic: c,
                    onReadPressed: () async {
                      await c.read().then((v) => c.value.listen((value) {
                            print("value: ${String.fromCharCodes(value)}");
                          }));

                      var value = DummyData.lookup1(
                          c.serviceUuid.toString().toLowerCase());
                      print(value);
                    },
                    onNotificationPressed: () async {
                      await c.setNotifyValue(!c.isNotifying);
                      await c.read();
                    },
                    descriptorTiles: c.descriptors
                        .map(
                          (d) => DescriptorTile(
                            descriptor: d,
                            onReadPressed: () => d.read(),
                            onWritePressed: () => d.write(_getRandomBytes()),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(device.name)),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => device.disconnect();
                  text = '';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => device.connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return TextButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        ?.copyWith(color: Colors.white),
                  ));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    snapshot.data == BluetoothDeviceState.connected
                        ? const Icon(Icons.bluetooth_connected,
                            color: Colors.lightGreen)
                        : const Icon(Icons.bluetooth_disabled,
                            color: Colors.red),
                    // snapshot.data == BluetoothDeviceState.connected
                    //     ? StreamBuilder<int>(
                    //         stream: rssiStream(),
                    //         builder: (context, snapshot) {
                    //           return Text(
                    //               snapshot.hasData ? '${snapshot.data}dBm' : '',
                    //               style: Theme.of(context).textTheme.caption);
                    //         })
                    //     : Text('', style: Theme.of(context).textTheme.caption),
                  ],
                ),
                title: Text(
                    'Device is ${snapshot.data.toString().split('.')[1]}.',
                    style: (snapshot.data == BluetoothDeviceState.connected)
                        ? const TextStyle(color: Colors.lightGreen)
                        : const TextStyle(color: Colors.red)),
                subtitle: Text('${device.name}'),
                trailing: snapshot.data == BluetoothDeviceState.connected
                    ? StreamBuilder<bool>(
                        stream: device.isDiscoveringServices,
                        initialData: false,
                        builder: (c, snapshot) => IndexedStack(
                          index: snapshot.data! ? 1 : 0,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: Colors.lightBlue, size: 40),
                              splashColor: Colors.transparent,
                              onPressed: () => device.discoverServices(),
                            ),
                            const IconButton(
                              icon: SizedBox(
                                width: 18.0,
                                height: 18.0,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.grey),
                                ),
                              ),
                              onPressed: null,
                            )
                          ],
                        ),
                      )
                    : SizedBox.fromSize(),
              ),
            ),
            // StreamBuilder<int>(
            //   stream: device.mtu,
            //   initialData: 0,
            //   builder: (c, snapshot) => ListTile(
            //     title: const Text('Title'),
            //     subtitle: Text('${snapshot.data} bytes'),
            //     trailing: IconButton(
            //       icon: const Icon(Icons.edit),
            //       onPressed: () => device.requestMtu(223),
            //     ),
            //   ),
            // ),
            StreamBuilder<List<BluetoothService>>(
              stream: device.services,
              initialData: const [],
              builder: (c, snapshot) {
                return Column(
                  children: _buildServiceTiles(snapshot.data!),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Stream<int> rssiStream() async* {
    var isConnected = true;
    final subscription = device.state.listen((state) {
      isConnected = state == BluetoothDeviceState.connected;
    });
    while (isConnected) {
      yield await device.readRssi();
      await Future.delayed(const Duration(seconds: 10));
      //call services
      device.services.listen((List<BluetoothService> services) {
        readServices(services);
      });
    }
    subscription.cancel();
    // Device disconnected, stopping RSSI stream
  }

  readServices(List<BluetoothService> services) async {
    List sendingData = [];
    for (BluetoothService service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.read) {
          // characteristic.value.listen((value) {
          //   print("value: ${String.fromCharCodes(value)}");
          //   characteristic.read();
          // });
          try {
            await characteristic.read().then((value) => () {
                  if (value.isNotEmpty) {
                    var jsondata = {
                      "serviceName": characteristic.uuid.toString(),
                      "serviceValue": value.toString(),
                      "name": DummyData.lookup1(characteristic.uuid.toString()),
                      "value": (String.fromCharCodes(value) != "")
                          ? String.fromCharCodes(value)
                          : "--"
                    };
                    print("value: $jsondata");
                    sendingData.add(jsondata);
                  }
                });
          } catch (err) {
            print("error: $err");
          }
        }
      }
    }

    if (sendingData.isNotEmpty) sendData(sendingData);
  }

  Future<RawData> sendData(data) async {
    final http.Response response = await http.post(
        Uri.parse('https://uzoffer.com/cte/device/BulkInsertRawData'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        // body: jsonEncode(<String, String>{
        //   'title': title,
        // }),
        body: jsonEncode(data));

    // Dispatch action depending upon
    // the server response
    if (response.statusCode == 201 || response.statusCode == 200) {
      return RawData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Raw data sending failed!');
    }
  }
}

class RawData {
  final int id;
  final String serviceName;
  final String serviceValue;
  final String name;
  final String value;

  RawData(
      {required this.id,
      required this.serviceName,
      required this.serviceValue,
      required this.name,
      required this.value});

  factory RawData.fromJson(Map<String, dynamic> json) {
    return RawData(
      id: json['id'],
      serviceName: json['serviceName'],
      serviceValue: json['serviceValue'],
      name: json['name'],
      value: json['value'],
    );
  }
}
