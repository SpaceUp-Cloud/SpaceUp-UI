import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';

class UIData {
  static const String domainsRoute = "/domains";
  static const String settingsRoute = "/settings";
  static const String servicesRoute = "/services";
  static const String homeRoute = "/home";
  static const String aboutRoute = "/about";
  static const String loginRoute = "/";
}

class URL {
  // http://192.168.178.24:9090/api
  Future<String> get baseUrl async {
    String baseApiUrl = "/api";

    baseApiUrl = (await Settings().getString("server", ""))! + baseApiUrl;
    print("BaseApiUrl: $baseApiUrl");
    return baseApiUrl;
  }

  Future<String> get serverUrl async {
    return (await Settings().getString("server", ""))!;
  }
}

class ThemeConfig {

  static ThemeData get lightMode {
    return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.teal,
    );
  }

  static ThemeData get darkMode {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.teal.shade700,
    );
  }
}