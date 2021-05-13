import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';

class SettingsPageStarter extends StatefulWidget {
  SettingsPageStarter() : super();

  @override
  SettingsPage createState() => SettingsPage();
}

class SettingsPage extends State<SettingsPageStarter> {

  SharedPreferencesWindows _prefsWin = SharedPreferencesWindows.instance;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  bool fingerprint = true;
  bool cachedDomains = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      if(Platform.isWindows) {
        _prefsWin.getAll().then((Map<String, Object> values) {
          bool? isCachedDomains = values['cachedDomains'] as bool?;
          print("isCachedDomains $isCachedDomains");
          cachedDomains = isCachedDomains ?? false;
        });

      } else {
        _prefs.then((SharedPreferences prefs) {
          bool? isCachedDomains = prefs.getBool("cachedDomains");
          print("isCachedDomains $isCachedDomains");
          cachedDomains = isCachedDomains ?? false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsList = SettingsList(
      sections: [
        SettingsSection(
          title: 'Common',
          tiles: [
            SettingsTile(
              title: 'A Tile',
              subtitle: 'A Subtitle',
              leading: Icon(Icons.language),
              //onPressed: (BuildContext context) {},
            ),
            // TODO: Add Authentication and Remoteserver
            SettingsTile.switchTile(
              title: 'Use fingerprint',
              leading: Icon(Icons.fingerprint),
              switchValue: fingerprint,
              onToggle: (bool value) {
                setState(() {
                  this.fingerprint = value;
                });
              },
            ),
          ],
        ),
        SettingsSection(
          title: 'Domains',
          tiles: [
            SettingsTile.switchTile(
              title: 'Use cached domains',
              leading: Icon(Icons.cloud),
              switchValue: cachedDomains,
              onToggle: (bool value) {
                setState(() {
                   _save('cachedDomains', value).then((bool success) {
                     return value;
                  }).then((value) => this.cachedDomains = value);
                });
              },
            )
          ],
        )
      ],
    );

    final scaffold = Scaffold(
        appBar: AppBar(
          title: Text("Settings"),
        ),
        body: SafeArea(
          child: settingsList,
        )
    );

    return scaffold;
  }

  Future<bool> _save(String key, Object value) async {
    if(Platform.isWindows) {
      print(value.runtimeType.toString());
      return _prefsWin.setValue(value.runtimeType.toString(), key, value);
    } else {
      return _prefs.then((SharedPreferences prefs) {
        if(value is String) {
          return prefs.setString(key, value);
        } else if (value is bool) {
          return prefs.setBool(key, value);
        } else if (value is int) {
          return prefs.setInt(key, value);
        } else {
          return Future.value(false);
        }
      });
    }
  }

  /*<Widget>[] settingsList() {
    var settingsList = SafeArea(
      child: ListView(
        children: [
          SizedBox(
              width: 100.0,
              height: 100.0,
              child:  SettingsToggleScreen(
                settingKey: 'key-of-your-setting',
                title: 'Settings Ui ',
                children: [],
              ) ),
          SimpleSettingsTile(
            title: 'Conditionally enabled.',
            enabledIfKey: 'key-of-parent',
            visibleByDefault: true,
          ),
          Settings().onBoolChanged(
            settingKey: 'key-of-your-setting',
            defaultValue: false,
            childBuilder: (BuildContext context, bool value){
              return Text(value.toString());
            },
          ),
          Settings().onStringChanged(
            settingKey: 'key-of-your-setting',
            defaultValue: 'Empty',
            childBuilder: (BuildContext context, String value){
              return Text(value);
            },
          ),
          SettingsContainer(
            children: [
              Text('First line'),
              Text('Second line'),
            ],
          ),
          SettingsContainer(
            child: Text('Settings container'),
          ),
          MaterialColorPickerSettingsTile(
            settingKey: 'key-of-your-setting',
            title: 'Color Picker',
            cancelCaption: 'Keep the old value',
            okCaption: 'Select new',
            confirmText: 'Are you sure want to modify the previously selected color?',
            confirmModalTitle: 'Are you sure?',
            confirmModalCancelCaption: 'Keep the old one',
            confirmModalConfirmCaption: 'Yes, I am sure',
          ),
        ],
      ),
    );
  }*/

}