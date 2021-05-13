import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:page_transition/page_transition.dart';
import 'package:spaceup_ui/domain_page.dart';
import 'package:spaceup_ui/settings_page.dart';
import 'package:spaceup_ui/ui_data.dart';

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
      theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.teal,
          primarySwatch: Colors.deepOrange),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal.shade800,
        accentColor: Colors.teal.shade600,
        primaryColorDark: Colors.white,
        primarySwatch: Colors.teal,
      ),
      home: MyHomePage("Home"),
      initialRoute: null,
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/domains':
            {
              return PageTransition(
                  child: DomainPageStarter(),
                  type: PageTransitionType.leftToRight);
            }
          case '/settings':
            {
              return PageTransition(
                  child: SettingsPageStarter(),
                  type: PageTransitionType.leftToRight);
            }
          default:
            {
              return PageTransition(
                  child: MyHomePage("Home"),
                  type: PageTransitionType.leftToRight);
            }
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(this.title) : super();

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Depending on platform the home widget shows x cards per column
  late int maxElementsPerLine;

  @override
  void initState() {
    super.initState();

    if (Platform.isWindows || Platform.isLinux) {
      maxElementsPerLine = 8;
    } else if (Platform.isAndroid || Platform.isIOS) {
      maxElementsPerLine = 2;
    } else {
      maxElementsPerLine = 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title!),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                  // TODO: Display SpaceUp Icon
                  decoration: BoxDecoration(color: Colors.teal),
                  child: Text('Menu')),
              ListTile(
                title: Text('Settings'),
                onTap: () {
                  Navigator.pushNamed(context, UIData.settingsRoute);
                },
              ),
              ListTile(
                title: Text('About'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        body: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: Center(
          child: GridView.count(
            crossAxisCount: maxElementsPerLine,
            scrollDirection: Axis.vertical,
            children: [
              _createCard(
                  "Domains", UIData.domainsRoute, Colors.teal, Colors.white),
            ],
          ),
        )));
  }

  InkWell _createCard(
      String cardTitle, String path, MaterialColor bgColor, Color fontColor) {
    return InkWell(
        onTap: () {
          Navigator.pushNamed(context, path);
        },
        child: Card(
          semanticContainer: true,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 4,
          margin: EdgeInsets.all(10),
          color: bgColor,
          child: Center(
            child: Text(
              cardTitle,
              style: TextStyle(
                  color: fontColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ));
  }
}
