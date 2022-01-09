import 'dart:io' show Platform;

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/ui_data.dart';
import 'package:spaceup_ui/util.dart';

class SettingsPageStarter extends StatefulWidget {
  SettingsPageStarter() : super();

  @override
  SettingsPage createState() => SettingsPage();
}

class SettingsPage extends State<SettingsPageStarter> {

  // Add desktop/web specific settings
  //get desktopAndWebSettings =>

  @override
  Widget build(BuildContext context) {
    final Util util = Util();

    final submenus = <Widget>[];
    if (util.isMobile) {
      // ... mobile specific
      submenus.add(
          SettingsTileGroup(
            title: 'App',
            children: [
              SwitchSettingsTile(
                title: 'Fingerprint enabled',
                icon: Icon(Icons.fingerprint),
                settingKey: "fingerprint_enabled",
                defaultValue: false,
              ),
              SwitchSettingsTile(
                settingKey: 'refreshView',
                icon: Icon(Icons.refresh),
                title: 'Automatically refresh views',
                defaultValue: true,
              ),
              SettingsTileGroup(
                title: 'Theme',
                children: [
                  RadioSettingsTile(
                    icon: Icon(Icons.wb_sunny),
                    defaultKey: 'system',
                    settingKey: 'themeMode',
                    expandable: true,
                    title: 'Theme mode',
                    values: {
                      'system': 'System mode',
                      'light': 'Light mode',
                      'dark': 'Dark mode'
                    },
                  ),
                  ThemeSwitcher(
                    clipper: ThemeSwitcherCircleClipper(),
                    builder: (context) {
                      return OutlinedButton(
                        child: Text('Apply Theme'),
                        onPressed: () {
                          Future.delayed(Duration(microseconds: 500), () =>
                              changeTheme(context));
                        },
                      );
                    },
                  )
                ],

              )

            ],
          )
      );
    }
    if (util.isWeb) {
      // ... web specific
    }

    /*if(util.isDesktop) {
      // ... desktop specific
    }*/

    // Das not work yet on desktop but web
    if (!util.isDesktop || util.isWeb) {
      submenus.add(
          SettingsTileGroup(
            title: 'Behaviour',
            children: [
              SwitchSettingsTile(
                title: 'Cached Domains',
                settingKey: "isCachedDomain",
                defaultValue: false,
              )
            ],
          )
      );
    }

    if (util.isDesktop && !util.isWeb) {
      submenus.add(
          SettingsContainer(
            child: Text("Does not work yet on desktop."),
          )
      );
    }

    // ... for all platforms


    final settingsList = SettingsScreen(
      title: "SpaceUp Settings",
      children: submenus,
    );

    return ThemeSwitchingArea(
        child: Scaffold(
            body: settingsList
        ));
  }

  Future<void> changeTheme(BuildContext context) async {
    String themeMode = await Settings().getString("themeMode", "system");
    print("Change theme $themeMode");

    final lightMode = ThemeConfig.lightMode;
    final darkMode = ThemeConfig.darkMode;
    final systemMode =
    WidgetsBinding.instance!.window.platformBrightness == Brightness.dark
        ? ThemeConfig.darkMode : ThemeConfig.lightMode;

    print(systemMode);
    if (themeMode == 'system') {
      //var brightness = ThemeProvider.of(context)!.brightness;

      ThemeSwitcher.of(context).changeTheme(
          //isReversed: brightness == Brightness.dark ? true : false,
          theme: systemMode
      );
    } else if (themeMode == 'dark') {
      ThemeSwitcher.of(context).changeTheme(
          theme: darkMode
      );
    } else {
      ThemeSwitcher.of(context).changeTheme(
          theme: lightMode
      );
    }
  }

}