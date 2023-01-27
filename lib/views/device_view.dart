import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../api/api.dart';
import '../dummy_data.dart';

import '../widgets/characteristic_tile_widget.dart';
import '../widgets/descriptor_tile_widget.dart';
import '../widgets/service_tile_widget.dart';

class DeviceView extends StatelessWidget {
  const DeviceView({Key? key, required this.device}) : super(key: key);

  final BluetoothDevice device;

  // List<int> _getRandomBytes() {
  //   final math = Random();
  //   return [
  //     math.nextInt(255),
  //     math.nextInt(255),
  //     math.nextInt(255),
  //     math.nextInt(255)
  //   ];
  // }

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
                            onReadPressed: () async {
                              await d
                                  .read()
                                  .then((v) => d.value.listen((value) {
                                        print(
                                            "value: ${String.fromCharCodes(value)}");
                                      }));

                              var value = DummyData.lookup1(
                                  d.serviceUuid.toString().toLowerCase());
                              print(value);
                            },
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
                    // snapshot.data == BluetoothDeviceState.connected
                    //     ? const Icon(Icons.bluetooth_connected,
                    //         color: Colors.lightGreen)
                    //     : const Icon(Icons.bluetooth_disabled,
                    //         color: Colors.r ed),
                    snapshot.data == BluetoothDeviceState.connected
                        ? StreamBuilder<int>(
                            stream: rssiStream(),
                            builder: (context, snapshot) {
                              return Text(
                                  snapshot.hasData ? '${snapshot.data}dBm' : '',
                                  style: Theme.of(context).textTheme.caption);
                            })
                        : Text('', style: Theme.of(context).textTheme.caption),
                  ],
                ),
                title: Text(
                    'Device is ${snapshot.data.toString().split('.')[1]}.',
                    style: (snapshot.data == BluetoothDeviceState.connected)
                        ? const TextStyle(color: Colors.lightGreen)
                        : const TextStyle(color: Colors.red)),
                subtitle: snapshot.data == BluetoothDeviceState.connected
                    ? Text('${device.name}')
                    : Text(''),
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
      floatingActionButton:
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        SizedBox(width: 5),
        FloatingActionButton(
            child: const Icon(Icons.radio_button_on),
            onPressed: (() {
              device.services.listen((List<BluetoothService> services) {
                readServices(services, 2, 2);
              });
            })),
        FloatingActionButton(
            child: const Icon(Icons.close_outlined),
            onPressed: (() {
              device.services.listen((List<BluetoothService> services) {
                readServices(services, 2, 3);
              });
            })),
        FloatingActionButton(
            child: const Icon(Icons.single_bed_sharp),
            onPressed: (() {
              device.services.listen((List<BluetoothService> services) {
                readServices(services, 2, 4);
              });
            })),
        FloatingActionButton(
            child: const Icon(Icons.car_repair_sharp),
            onPressed: (() {
              device.services.listen((List<BluetoothService> services) {
                readServices(services, 2, 1);
              });
            })),
      ]),
    );
  }

  Stream<int> rssiStream() async* {
    var isConnected = true;
    final subscription = device.state.listen((state) {
      isConnected = state == BluetoothDeviceState.connected;
    });
    while (isConnected) {
      yield await device.readRssi();
      await Future.delayed(const Duration(minutes: 2));
      //call services
      device.services.listen((List<BluetoothService> services) {
        readServices(services, 1, 1);
      });
    }
    subscription.cancel();
    // Device disconnected, stopping RSSI stream
  }

  readServices(
      List<BluetoothService> services, int sendingType, int status) async {
    //List sendingData = [];
    for (BluetoothService service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.read) {
          try {
            await characteristic.read().then((value) async {
              if (value.isNotEmpty) {
                var descriptors = characteristic.descriptors.toString();
                // var descValue = "";
                // for (BluetoothDescriptor d in descriptors) {
                //   await d.read().then((value) {
                //     descValue = value;
                //   });
                // }

                //call current

                var jsondata = {
                  "serviceName": characteristic.uuid.toString(),
                  "serviceValue": value.toString(),
                  "name": DummyData.lookup1(characteristic.uuid.toString()),
                  "value": (String.fromCharCodes(value) != "")
                      ? String.fromCharCodes(value)
                      : "--",
                  "description": descriptors,
                  "sendingType": sendingType,
                  "status": status,
                  "latitude": 1,
                  "longitude": 1,
                  "currentTimeZone": "-8:30"
                };
                print("value: $jsondata");
                Api.sendData(jsondata);
              }
            });
          } catch (err) {
            print("error: $err");
          }
        }
      }
    }

    //if (sendingData.isNotEmpty) sendData(sendingData);
  }
}
