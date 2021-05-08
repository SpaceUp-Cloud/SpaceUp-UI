import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:page_transition/page_transition.dart';
import 'package:spaceup_ui/domain_page.dart';
import 'package:spaceup_ui/ui_data.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpaceUp Client',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primaryColor: Colors.teal,
          primarySwatch: Colors.deepOrange),
      home: MyHomePage(title: "Home"),
      initialRoute: null,
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/domains':
            {
              return PageTransition(
                  child: DomainPageStarter(),
                  type: PageTransitionType.leftToRight);
            }
          default:
            {
              return PageTransition(
                  child: MyHomePage(), type: PageTransitionType.leftToRight);
            }
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late int maxElementsPerLine;

  @override
  void initState() {
    super.initState();

    if(Platform.isWindows ||Platform.isLinux) {
      maxElementsPerLine = 8;
    } else if(Platform.isAndroid || Platform.isIOS) {
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
        body: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: Center(
          child: GridView.count(
            crossAxisCount: maxElementsPerLine,
            scrollDirection: Axis.vertical,
            children: [
              _createCard("Domains", UIData.domainsRoute, Colors.teal, Colors.white),
              _createCard("Domains", UIData.domainsRoute, Colors.teal, Colors.white),
              _createCard("Domains", UIData.domainsRoute, Colors.teal, Colors.white),
              _createCard("Domains", UIData.domainsRoute, Colors.teal, Colors.white)
            ],
          ),
        )));
  }

  InkWell _createCard(
      String cardTitle,
      String path,
      MaterialColor bgColor,
      Color fontColor) {
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
                  color: fontColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        )
    );
  }
}
