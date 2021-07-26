import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';

class SettingsPageStarter extends StatefulWidget {
  SettingsPageStarter() : super();

  @override
  SettingsPage createState() => SettingsPage();
}

class SettingsPage extends State<SettingsPageStarter> {

  @override
  Widget build(BuildContext context) {
    final settingsList = SettingsScreen(
      title: "SpaceUp Settings",
      children: [
        SimpleSettingsTile(
          title: "App",
          screen: SettingsScreen(
            title: "App",
            children: [
              SwitchSettingsTile(
                title: 'Fingerprint enabled',
                icon: Icon(Icons.fingerprint),
                settingKey: "isFingerprintEnabled",
                defaultValue: false,
              ),
            ],
          ),
        ),
        SimpleSettingsTile(
          title: "Domains",
          screen: SettingsScreen(
            title: "Domains",
            children: [
              SwitchSettingsTile(
                title: 'Cached Domains',
                settingKey: "isCachedDomain",
                defaultValue: false,
              ),
            ],
          ),
        ),
      ],
    );

    final scaffold = Scaffold(
        body: settingsList
    );

    return scaffold;
  }

}