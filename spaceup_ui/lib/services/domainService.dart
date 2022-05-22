import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';

import '../ui_data.dart';
import '../util.dart';

class DomainService {
  static Future<List<Domain>> getDomains(bool useCached) async {
    var domains = <Domain>[];
    final httpClient = http.Client();
    final client = RetryClient(httpClient);
    var isCached =
        await Settings().getBool("isCachedDomain", false) && useCached;

    try {
      var url = await URL().baseUrl;
      var jwt = await Util().getJWT();
      var getDomainsUrl = "$url/domain/list?cached=$isCached";
      var response =
      await client.get(Uri.tryParse(getDomainsUrl)!, headers: jwt);
      print(response.body);
      if (response.statusCode == 200) {
        domains = _parseDomains(response.body);
      }
    } finally {
      client.close();
    }
    return domains;
  }

  static Future<void> deleteDomain(BuildContext context, Domain domain) async {
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    try {
      var url = await URL().baseUrl;
      var uri = Uri.tryParse('$url/domain/delete/${domain.url}');
      var jwt = await Util().getJWT();
      var response = await client.delete(uri!, headers: jwt);

      if (response.body.isNotEmpty && response.statusCode == 200) {
        Util.showFeedback(context, response.body);
      }
    } finally {
      client.close();
    }
  }
}

class Domain {
  String url;

  Domain({required this.url});

  factory Domain.fromJson(Map<String, dynamic> json) => _domainFromJson(json);
}

Domain _domainFromJson(Map<String, dynamic> json) {
  return Domain(url: json["url"] as String);
}

List<Domain> _parseDomains(String body) {
  final parsed = json.decode(body).cast<Map<String, dynamic>>();
  return parsed.map<Domain>((json) => Domain.fromJson(json)).toList();
}