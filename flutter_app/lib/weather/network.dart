import 'package:http/http.dart' as http;
import 'dart:convert';

class Network {
  final String url;
  final String url2;
  final String url3;
  Network(this.url, this.url2, this.url3);

  Future<dynamic> getJsonData() async {
    http.Response response = await http.get(Uri.parse(url)); // 문자열을 Uri로 변환
    if (response.statusCode == 200) {
      String jsonData = response.body;
      var parsingData = jsonDecode(jsonData);
      return parsingData;
    }
  }

  Future<dynamic> getAirData() async {
    http.Response response = await http.get(Uri.parse(url2)); // 문자열을 Uri로 변환
    if (response.statusCode == 200) {
      String jsonData = response.body;
      var parsingData = jsonDecode(jsonData);
      return parsingData;
    }
  }

  Future<dynamic> getWindData() async {
    http.Response response = await http.get(Uri.parse(url3)); // 문자열을 Uri로 변환
    if (response.statusCode == 200) {
      String jsonData = response.body;
      var parsingData = jsonDecode(jsonData);
      return parsingData;
    }
  }
}
