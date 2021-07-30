import 'dart:io' show Platform;

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

    final submenus = <Widget>[];
    if(util.isMobile) {
      // ... mobile specific
      submenus.add(
          SettingsContainer(
            children: [
              Text("App"),
              SwitchSettingsTile(
                title: 'Fingerprint enabled',
                icon: Icon(Icons.fingerprint),
                settingKey: "fingerprint_enabled",
                defaultValue: false,
              )
            ],
          )
      );
    }
    if(util.isWeb) {
      // ... web specific
    }

    /*if(util.isDesktop) {
      // ... desktop specific
    }*/

    // Das not work yet on desktop but web
    if(!util.isDesktop || util.isWeb) {
      /*submenus.add(SimpleSettingsTile(
        title: "Advanced",
        screen:
      ));*/
      submenus.add(
        SettingsContainer(
          children: [
            Text("Profiles"),
            TextFieldModalSettingsTile(
                settingKey: "profiles",
                title: "Profiles",
                subtitle: "Separate by semicolon.",
                keyboardType: TextInputType.multiline,
            )
          ],
        )
      );
      submenus.add(
          SettingsContainer(
            children: [
              Text("Domains"),
              SwitchSettingsTile(
                title: 'Cached Domains',
                settingKey: "isCachedDomain",
                defaultValue: false,
              )
            ],
          )
      );
    }

    if(util.isDesktop && !util.isWeb){
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

    return Scaffold(
        body: settingsList
    );
  }

}