import 'dart:io' show Platform;

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
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
    final isPartlyDesktop = (!util.isDesktop || Platform.isLinux);

    final submenus = <Widget>[];
    submenus.add(SwitchSettingsTile(
      settingKey: 'refreshView',
      icon: Icon(Icons.refresh),
      title: 'Automatically refresh views',
      defaultValue: true,
    ));
    submenus.add(SwitchSettingsTile(
        settingKey: "rememberLogin",
        title: "Remember login"
    ));
    submenus.add(SwitchSettingsTile(
        settingKey: "autoLogin",
        title: "Auto login"
    ));
    submenus.add(SettingsTileGroup(
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
        MaterialButton(
          child: Text('Apply Theme'),
          onPressed: () {
            changeTheme(context);
          },
        )
      ],
    ));

    if (util.isMobile) {
      // ... mobile specific
      submenus.add(SettingsTileGroup(
        title: 'App',
        children: [
          SwitchSettingsTile(
            title: 'Fingerprint enabled',
            icon: Icon(Icons.fingerprint),
            settingKey: "fingerprint_enabled",
            defaultValue: false,
          ),
        ],
      ));
    }
    if (util.isWeb) {
      // ... web specific
    }

    /*if(util.isDesktop) {
      // ... desktop specific
    }*/

    // Das not work yet on desktop (except Linux) but web
    if (isPartlyDesktop || util.isWeb) {
      submenus.add(SettingsTileGroup(
        title: 'Behaviour',
        children: [
          SwitchSettingsTile(
            title: 'Cached Domains',
            settingKey: "isCachedDomain",
            defaultValue: false,
          )
        ],
      ));
    }

    if (util.isDesktop && !isPartlyDesktop && !util.isWeb) {
      submenus.add(SettingsContainer(
        child: Text("Does not work yet on this desktop."),
      ));
    }

    // ... for all platforms

    final settingsList = SettingsScreen(
      title: "SpaceUp Settings",
      children: submenus,
      appBarBackgroundColor: Theme.of(context).primaryColor,
    );

    return Scaffold(body: settingsList);
  }

  Future<void> changeTheme(BuildContext context) async {
    String themeMode = (await Settings().getString("themeMode", "system"))!;
    print("Change theme $themeMode");

    if (themeMode == 'system') {
      AdaptiveTheme.of(context).setSystem();
    } else if (themeMode == 'dark') {
      AdaptiveTheme.of(context).setDark();
    } else {
      AdaptiveTheme.of(context).setLight();
    }
  }
}
