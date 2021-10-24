import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';

class UIData {
  static const String domainsRoute = "/domains";
  static const String settingsRoute = "/settings";
  static const String servicesRoute = "/services";
  static const String homeRoute = "/home";
  static const String loginRoute = "/";
}

class URL {
  // http://192.168.178.24:9090/api
  Future<String> get baseUrl async {
    String baseApiUrl = "/api";

    baseApiUrl = await Settings().getString("profile_active", "") + baseApiUrl;
    print("BaseApiUrl: $baseApiUrl");
    return baseApiUrl;
  }

  Future<String> get serverUrl async {
    return await Settings().getString("profile_active", "");
  }
}

class ThemeConfig {

  static ThemeData get lightMode {
    return ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.teal,
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal,
            brightness: Brightness.light)
            .copyWith(secondary: Colors.teal.shade300)
    );
  }

  static ThemeData get darkMode {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.teal.shade700,
      primaryColorDark: Colors.white,
      primarySwatch: Colors.teal,
      colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal,
          brightness: Brightness.dark)
          .copyWith(secondary: Colors.teal.shade500),
    );
  }
}