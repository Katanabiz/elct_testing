import 'dart:convert';

import 'package:http/http.dart' as http;

class Api {
  static Future<void> sendData(data) async {
    final http.Response response = await http.post(
        Uri.parse('https://uzoffer.com/cte/device/InsertRawData'),
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
      //return RawData.fromJson(json.decode(response.body));
      print("success");
    } else {
      print('Raw data sending failed!');
    }
  }
}
