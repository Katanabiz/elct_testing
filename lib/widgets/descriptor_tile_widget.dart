import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../dummy_data.dart';

class DescriptorTile extends StatelessWidget {
  final BluetoothDescriptor descriptor;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;

  const DescriptorTile(
      {Key? key,
      required this.descriptor,
      this.onReadPressed,
      this.onWritePressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Descriptor'),
          Text(DummyData.lookup1(descriptor.uuid.toString()),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      subtitle: StreamBuilder<List<int>>(
          stream: descriptor.value,
          initialData: descriptor.lastValue,
          builder: (c, snapshot) {
            final descriptorValue = snapshot.data;
            return Text(
                'Descriptor Value: ${String.fromCharCodes(descriptorValue!)}');
          }),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.file_download,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            onPressed: onReadPressed,
          ),
          // IconButton(
          //   icon: Icon(
          //     Icons.file_upload,
          //     color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
          //   ),
          //   onPressed: onWritePressed,
          // )
        ],
      ),
    );
  }
}
