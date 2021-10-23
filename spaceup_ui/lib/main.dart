import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:spaceup_ui/pages/domain_page.dart';
import 'package:spaceup_ui/pages/home_page.dart';
import 'package:spaceup_ui/pages/login_page.dart';
import 'package:spaceup_ui/pages/services_page.dart';
import 'package:spaceup_ui/pages/settings_page.dart';

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
          primarySwatch: Colors.teal,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal,
              brightness: Brightness.light)
              .copyWith(secondary: Colors.teal.shade300)
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal.shade700,
        primaryColorDark: Colors.white,
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal,
            brightness: Brightness.dark)
            .copyWith(secondary: Colors.teal.shade500),
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

