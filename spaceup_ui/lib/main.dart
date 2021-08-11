import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:local_auth/local_auth.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/pages/domain_page.dart';
import 'package:spaceup_ui/pages/home_page.dart';
import 'package:spaceup_ui/pages/login_page.dart';
import 'package:spaceup_ui/pages/services_page.dart';
import 'package:spaceup_ui/pages/settings_page.dart';
import 'package:spaceup_ui/ui_data.dart';
import 'package:spaceup_ui/util.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  MyApp() : super();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpaceUp Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.teal,
          accentColor: Colors.teal.shade300,
          primarySwatch: Colors.deepOrange
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal.shade700,
        accentColor: Colors.teal.shade500,
        primaryColorDark: Colors.white,
        primarySwatch: Colors.teal,
      ),
      //home: LoginPage(),
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/domains':
            {
              return PageTransition(
                  child: DomainPageStarter(),
                  type: PageTransitionType.leftToRight);
            }
          case '/services':
            {
              return PageTransition(
                  child: ServicesPageStarter(),
                  type: PageTransitionType.leftToRight);
            }
          case '/settings':
            {
              return PageTransition(
                  child: SettingsPageStarter(),
                  type: PageTransitionType.leftToRight);
            }
          case '/home':
            {
              return PageTransition(
                  child: HomePage("Home"),
                  type: PageTransitionType.leftToRight);
            }
          case '/':
            {
              return PageTransition(
                  child: LoginPage(),
                  type: PageTransitionType.leftToRight);
            }
          default:
            {
              return PageTransition(
                  child: LoginPage(),
                  type: PageTransitionType.leftToRight);
            }
        }
      },
    );
  }
}

