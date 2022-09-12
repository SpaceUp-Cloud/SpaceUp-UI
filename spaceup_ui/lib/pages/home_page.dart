import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/SUGradient.dart';
import 'package:spaceup_ui/ui_data.dart';
import 'package:spaceup_ui/util.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class HomePage extends StatefulWidget {
  HomePage(this.title) : super();

  final String? title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /*final LocalAuthentication _localAuthentication = LocalAuthentication();
  bool _authenticated = false;*/

  ScrollController scrollController = ScrollController();
  var refreshKeyServerVersion = GlobalKey<RefreshIndicatorState>();
  var refreshKeyHostname = GlobalKey<RefreshIndicatorState>();
  var refreshKeyDisk = GlobalKey<RefreshIndicatorState>();
  late Timer _timer;

  // Depending on platform the home widget shows x cards per column
  late int maxElementsPerLine;

  // System information
  late Future<String> serverVersion;
  late Future<String> hostname;
  late Future<Disk> disk;

  @override
  void initState() {
    super.initState();
    Util.checkJWT();

    setState(() {
      hostname = _getHostname();
      disk = _getDisk();
      serverVersion = _getServerVersion();
    });

    final Util util = Util();
    if (util.isDesktop) {
      maxElementsPerLine = 12;
    } else if (util.isMobile) {
      maxElementsPerLine = 2;
    } else {
      maxElementsPerLine = 2;
    }

    _refreshView();
  }

  @override
  void dispose() {
    super.dispose();
    try {
      _timer.cancel();
    } catch(ex) {
      print("Time was not initialized");
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    //checkingForBioMetrics().then((value) => _authenticateMe());

    final util = Util();
    return Scaffold(
        appBar: AppBar(
          backgroundColor: theme.primaryColor,
          titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20.0
          ),
          title: Text(widget.title!),
          flexibleSpace: SUGradient.gradientContainer,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                  height: (util.isDesktop || util.isWeb) ? 60 : 100,
                  child: DrawerHeader(
                      decoration: SUGradient.boxDecoration,
                      child: FutureBuilder(
                        future: _getConnectedServer(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              snapshot.data as String,
                              style: TextStyle(color: Colors.white),
                            );
                          } else {
                            return CircularProgressIndicator();
                          }
                        },
                      ))),
              ListTile(
                title: Text("Domains"),
                onTap: () {
                  Get.toNamed(UIData.domainsRoute);
                },
              ),
              ListTile(
                title: Text("Services"),
                onTap: () {
                  Get.toNamed(UIData.servicesRoute);
                },
              ),
              ListTile(
                title: Text("Webbackends"),
                onTap: () {
                  Get.toNamed(UIData.webbackendsRoute);
                },
              ),
              Divider(
                height: 1.0,
              ),
              ListTile(
                title: Text('Settings'),
                onTap: () {
                  Get.toNamed(UIData.settingsRoute);
                },
              ),
              ListTile(
                title: Text('About'),
                onTap: () {
                  Get.toNamed(UIData.aboutRoute);
                },
              ),
              Divider(
                height: 1.0,
              ),
              ListTile(
                title: Text('Logout'),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        final dialog = AlertDialog(
                          title: Text("Want to forget server?"),

                          actions: [
                            TextButton(
                              child: Text("Yes"),
                              onPressed: () {
                                Util.forgetServer();
                                Util.logout(manual: true);
                              },
                            ),
                            TextButton(
                                child: Text("Nope, keep it!"),
                                onPressed: () {
                                  Util.logout(manual: true);
                                }
                            )
                          ],
                        );

                        return dialog;
                      }
                  );
                },
              )
            ],
          ),
        ),
        body: Column(
          children: [
            getServerVersionBuilder(),
            getHostnameBuilder(),
            getDiskBuilder()
          ],
        ));
  }

  Card createServerVersionCard(String version) {
    return Card(
        //margin: EdgeInsets.fromLTRB(10.0, 5.0, 0.0, 5.0),
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ListTile(
          leading: Icon(Icons.miscellaneous_services),
          title: Text("Server version: " + version),
        ),
      ],
    ));
  }

  Card createHostnameCard(String hostname) {
    return Card(
        //margin: EdgeInsets.fromLTRB(10.0, 5.0, 0.0, 5.0),
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ListTile(
          leading: Icon(Icons.cloud),
          title: Text("Hostname: " + hostname),
        ),
      ],
    ));
  }

  FutureBuilder<String> getServerVersionBuilder() {
    return FutureBuilder<String>(
        future: serverVersion,
        initialData: "",
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return createServerVersionCard(snapshot.data!);
          } else if (snapshot.hasError) {
            //Util.showMessage(context, "${snapshot.error}");
          }

          return Card(
            child: Center(
                child: CircularProgressIndicator()
            ),
          );
        });
  }

  FutureBuilder<String> getHostnameBuilder() {
    return FutureBuilder<String>(
        future: hostname,
        initialData: "",
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return createHostnameCard(snapshot.data!);
          } else if (snapshot.hasError && snapshot.error != null) {
            //Util.showMessage(context, "${snapshot.error!}");
          }

          return Card(
            child: Center(
                child: CircularProgressIndicator()
            ),
          );
        });
  }

  FutureBuilder<Disk> getDiskBuilder() {
    return FutureBuilder<Disk>(
        future: disk,
        initialData: Disk(
            availableQuota: 0.0, quota: "", space: "", spacePercentage: 0.0),
        builder: (context, AsyncSnapshot<Disk> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return createDiskCard(snapshot.data!);
          } else if (snapshot.hasError && snapshot.error != null) {
            //Util.showMessage(context, "${snapshot.error!}");
          }

          return Card(
            child: Center(
                child: CircularProgressIndicator()
            ),
          );
        });
  }

  Widget createDiskCard(Disk disk) {
    final primaryColor = Theme.of(context).textTheme.bodyText1?.color;
    var max = 1.0;
    var spaceLeft = 0.0;

    try {
      max = double.parse(disk.quota.split("M")[0]);
      spaceLeft = double.parse(disk.space.split("M")[0]);
    } catch(ex) {
      // NOP
    }

    final gauge = SfRadialGauge(
      title: GaugeTitle(
        alignment: GaugeAlignment.center,
        text: 'Disk Usage',
          textStyle: TextStyle(fontSize: 20.0)
      ),
      enableLoadingAnimation: true,
      axes: <RadialAxis>[
        RadialAxis(
            axisLabelStyle: GaugeTextStyle(color: primaryColor),
            axisLineStyle: AxisLineStyle(color: primaryColor),
            majorTickStyle: MajorTickStyle(color: primaryColor),
            minimum: 0,
            maximum: max,
            ranges: <GaugeRange>[
          GaugeRange(startValue: 0, endValue: max, color: Colors.teal),
          GaugeRange(startValue: 0, endValue: spaceLeft, color: Colors.deepOrangeAccent,)
        ],
        pointers: [
          NeedlePointer(
            value: spaceLeft,
            needleColor: primaryColor,
            knobStyle: KnobStyle(color: primaryColor),
            tailStyle: TailStyle(color: primaryColor),
          )
        ],
        annotations: <GaugeAnnotation>[
          GaugeAnnotation(
            angle: 90,
            positionFactor: 1.0,
            widget: Container(
              child: Text("${disk.availableQuota}% / ${disk.space} of ${disk.quota}"),
            )
          )
        ]),
      ],
    );

    return Card(
      child: gauge,
    );
  }

  Future<String> _getServerVersion() async {
    String serverVersion = "";

    final client = RetryClient(http.Client());
    try {
      final url = await URL().baseUrl;
      final jwt = await Util().getJWT();
      var response =
          await client.get(Uri.tryParse('$url/system/version')!, headers: jwt);
      if (response.body.isNotEmpty && response.statusCode == 200) {
        print(response.body);
        serverVersion = response.body;
      }
    } finally {
      client.close();
    }
    return serverVersion;
  }

  Future<String> _getHostname() async {
    String hostname = "";

    final client = RetryClient(http.Client());
    try {
      final url = await URL().baseUrl;
      final jwt = await Util().getJWT();
      var response =
          await client.get(Uri.tryParse('$url/system/hostname')!, headers: jwt);
      print(response.body);
      if (response.body.isNotEmpty && response.statusCode == 200) {
        hostname = jsonDecode(response.body)["hostname"];
      }
    } finally {
      client.close();
    }
    return hostname;
  }

  Future<Disk> _getDisk() async {
    Disk disk =
        Disk(space: "", spacePercentage: 0.0, quota: "", availableQuota: 0.0);

    final client = RetryClient(http.Client());
    try {
      final url = await URL().baseUrl;
      final jwt = await Util().getJWT();

      var response =
          await client.get(Uri.tryParse('$url/system/disk')!, headers: jwt);
      print(response.body);
      if (response.body.isNotEmpty && response.statusCode == 200) {
        disk = Disk.fromJson(jsonDecode(response.body));
      }
    } finally {
      client.close();
    }

    return disk;
  }

  Future<String> _getConnectedServer() async {
    return (await Settings().getString("server", ""))!;
  }

  Future<void> _refreshView() async {
    bool refreshView = await Settings().getBool("refreshView", true);

    if (refreshView) {
      print("Initialize view refresher");
      _timer = Timer.periodic(Duration(seconds: 5), (timer) {
        setState(() {
          disk = _getDisk();
          serverVersion = _getServerVersion();
        });
      });
    } else {
      try {
        if (_timer.isActive) {
          _timer.cancel();
        }
      } catch (e) {
        print("View refresh timer is not initialized");
      }
    }
  }

/*
  Future<bool> checkingForBioMetrics() async {
    bool canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
    print(canCheckBiometrics);
    return canCheckBiometrics;
  }

  Future<void> _authenticateMe() async {
    var authenticated = false;
    try {
      authenticated = await _localAuthentication.authenticate(
          biometricOnly: true,
          localizedReason: "Just for SpaceUp users",
          // message for dialog
          useErrorDialogs: true,
          // show error in dialog
          stickyAuth: true);
    } catch (e) {
      print(e);
    }

    setState(() {
      print("Authenticated: $authenticated");
      _authenticated = authenticated;
    });

    if (!mounted) return;
  }*/
}

class Disk {
  String space;
  double spacePercentage;
  String quota;
  double availableQuota;

  Disk(
      {required this.space,
      required this.spacePercentage,
      required this.quota,
      required this.availableQuota});

  factory Disk.fromJson(Map<String, dynamic> json) => _diskFromJson(json);
}

Disk _diskFromJson(Map<String, dynamic> json) {
  return Disk(
      space: json["space"],
      spacePercentage: json["spacePercentage"],
      quota: json["quota"],
      availableQuota: json["availableQuota"]);
}
