import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';

class UIData {
  static const String domainsRoute = "/domains";
  static const String settingsRoute = "/settings";
  static const String servicesRoute = "/services";
  static const String webbackendsRoute = "/webbackends";
  static const String homeRoute = "/home";
  static const String aboutRoute = "/about";
  static const String swsRoute = "/sws";
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

  Future<CorePalette?> getCoreColors() async {
    final palette = await DynamicColorPlugin.getCorePalette();
    return palette;
  }

  /*ThemeData lightMode(BuildContext context) {
    var lightTheme = ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.teal,
    ); // Default

    DynamicColorBuilder(builder: (lightColor, darkColor) {
      if(lightColor != null) {
        lightTheme = ThemeData(
          colorScheme: lightColor,
          useMaterial3: true
        );
      }
    });



    /*
    if(Util().isMobile) {
      this.getCoreColors().then((value) => {
        themeData = ThemeData(
            colorScheme: value
        ).copyWith(useMaterial3: true)
      });
    } else {
      return ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.teal,
      );
    }*/

  }

  static ThemeData get darkMode {
    if(Util().isMobile) {
      return ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal.shade700,
            brightness: Brightness.dark
        )
      ).copyWith(useMaterial3: true);
    }
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.teal.shade700,
    );
  }*/
}