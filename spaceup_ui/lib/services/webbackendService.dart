import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http/retry.dart';

import '../ui_data.dart';
import '../util.dart';

class WebbackendService {
  static Future<List<Webbackend>> getWebbackends() async {
    var webbackends = <Webbackend>[];

    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    try {
      final baseurl = await URL().baseUrl;
      final jwt = await Util().getJWT();

      final url = "$baseurl/web/backend/read";
      final response = await client.get(Uri.parse(url), headers: jwt);

      if (response.statusCode == 200) {
        final parsed = json.decode(response.body).cast<Map<String, dynamic>>();
        webbackends = parsed
            .map<Webbackend>((json) => Webbackend.fromJson(json))
            .toList();
      }
    } finally {
      client.close();
    }

    return webbackends;
  }

  static Future<void> deleteWebbackend(BuildContext context,
      String domain, VoidCallback callback) async {
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    try {
      final baseurl = await URL().baseUrl;
      final jwt = await Util().getJWT();

      final trimmedUrl = domain.split("/")[0];
      final deleteWbUrl = "$baseurl/web/backend/delete/$trimmedUrl";
      final response = await client.delete(Uri.parse(deleteWbUrl), headers: jwt);
      if(response.statusCode == 200) {
        Util.showMessage(context, "Deleted web backend for $trimmedUrl",
            durationInSeconds: 5);
        callback();
      } else {
        Util.showMessage(context, response.body, durationInSeconds: 10);
      }
    } finally {
      client.close();
    }
  }

  static Future<List<Service>> getServices() async {
    var services = <Service>[];

    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    try {
      final baseurl = await URL().baseUrl;
      final jwt = await Util().getJWT();

      final getServicesUrl = "$baseurl/network/read/programs";
      final response =
      await client.get(Uri.parse(getServicesUrl), headers: jwt);

      if (response.statusCode == 200) {
        final parsed = json.decode(response.body).cast<Map<String, dynamic>>();
        services =
            parsed.map<Service>((json) => Service.fromJson(json)).toList();
      }
    } finally {
      client.close();
    }

    return services;
  }

  static Future<void> createWebbackend({
    required WebbackendConfiguration configuration,
    required BuildContext context,
    Function(BuildContext context, Response response)? onResponse}) async {
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    try {
      final baseurl = await URL().baseUrl;
      final jwt = await Util().getJWT();

      final getServicesUrl = "$baseurl/web/backend/create";
      final response =
      await client.post(Uri.parse(getServicesUrl),
          headers: jwt, body: jsonEncode(configuration));

      if(onResponse != null) onResponse(context, response);
    } finally {
      client.close();
    }
  }
}

/*
[
  {
    "web": "string",
    "prefix": "string",
    "process": "string",
    "service": "string"
  }
]
*/
class Webbackend {
  String web;
  String prefix = "";
  String process = "";
  String service = "";

  Webbackend({required this.web,
    required this.prefix,
    required this.process,
    required this.service});

  factory Webbackend.fromJson(Map<String, dynamic> json) =>
      _webbackendFromJson(json);
}

Webbackend _webbackendFromJson(Map<String, dynamic> json) {
  final web = json["web"];
  final process = json["process"];
  final service = json["service"];
  final prefix = json["prefix"];

  return Webbackend(
      web: web != null ? web : "",
      prefix: prefix != null ? prefix : "",
      process: process != null ? process : "",
      service: service != null ? service : "");
}

class WebbackendConfiguration {
  String url;
  bool isApache;
  bool isHttp;
  bool removePrefix;
  int port;

  WebbackendConfiguration({
    required this.url, required this.isApache, required this.isHttp,
    required this.removePrefix, required this.port
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'isApache': isApache,
    'isHttp': isHttp,
    'removePrefix': removePrefix,
    'port': port
  };
}

/*
{
port*	integer($int32)
pid*	integer($int32)
program*	string
}
*/
class Service {
  int port;
  int pid;
  String program;

  Service({required this.port, required this.pid, required this.program});

  factory Service.fromJson(Map<String, dynamic> json) => _serviceFromJson(json);
}

Service _serviceFromJson(Map<String, dynamic> json) {
  return Service(
      port: json["port"], pid: json["pid"], program: json["program"]);
}
