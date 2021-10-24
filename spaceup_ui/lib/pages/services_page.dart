import 'dart:async';
import 'dart:convert';

import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/ui_data.dart';
import 'package:spaceup_ui/util.dart';

class ServicesPageStarter extends StatefulWidget {
  ServicesPageStarter() : super();

  @override
  ServicesPage createState() => ServicesPage();
}

class ServicesPage extends State<ServicesPageStarter> {
  ScrollController scrollController = ScrollController();
  FlipCardController flipCardController = new FlipCardController();
  var refreshKey = GlobalKey<RefreshIndicatorState>();
  late Timer _timer;

  late ThemeData theme;

  late Future<List<Service>> services;

  @override
  void initState() {
    super.initState();
    Util.checkJWT(context);
    services = _getServices();

    _refreshView();
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);

    final servicesView = SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        controller: scrollController,
        child: Container(
          child: createServicCards(),
        )
    );

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text("Services"),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
              child: servicesView, onRefresh: _onRefresh, key: refreshKey)
        ],
      ),
    );

    return scaffold;
  }

  Future<void> _onRefresh() async {
    setState(() {
      services = _getServices();
    });
  }

  FutureBuilder<List<Service>> createServicCards() {
    return FutureBuilder<List<Service>>(
        future: services,
        builder: (context, AsyncSnapshot<List<Service>> snapshot) {
          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty) {
            return Column(children: createCards(snapshot.data!));
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner.
          return Center(
            child: LinearProgressIndicator(),
          );
        });
  }

  List<Card> createCards(List<Service> services) {
    var cards = <Card>[];
    if (services.isEmpty) return cards;

    services.forEach((service) {
      var actionButtons = [
        ListTile(
          //leading: Icon(Icons.miscellaneous_services),
          title: Text(service.name),
          //onTap: _openLogs(),
        ),
        TextButton(
          style: TextButton.styleFrom(
              primary: Colors.white
          ),
          child: const Text(
            'Show Logs', /*style: TextStyle(fontSize: 18),*/
          ),
          onPressed: () {
            _doServiceAction(service.name, "Logs");
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
              primary: Colors.white
          ),
          child: const Text(
            'Start', /*style: TextStyle(fontSize: 18),*/
          ),
          onPressed: () {
            _doServiceAction(service.name, "START");
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
              primary: Colors.white
          ),
          child: const Text(
            'Stop', /*style: TextStyle(fontSize: 18),*/
          ),
          onPressed: () {
            _doServiceAction(service.name, "STOP");
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
              primary: Colors.white
          ),
          child: const Text(
            'Restart', /*style: TextStyle(fontSize: 18),*/
          ),
          onPressed: () {
            _doServiceAction(service.name, "RESTART");
          },
        )
      ];

      var card = FlipCard(
          fill: Fill.fillBack,
          controller: flipCardController,
          direction: FlipDirection.VERTICAL,
          front: Column(children: <Widget>[
            ColoredBox(
              color: (service.status == "FATAL" || service.status == "STOPPED")
                  ? theme.errorColor
                  : theme.colorScheme.secondary,
              child: ListTile(
                leading: Icon(Icons.miscellaneous_services),
                title: Text(service.name),
                subtitle: Text(service.info,),
                //onTap: _openLogs(),
              ),
            )
          ]),
          back: ColoredBox(
            color: (service.status == "FATAL" || service.status == "STOPPED")
                ? theme.errorColor
                : theme.colorScheme.secondary,
            child: ListView(
              //crossAxisAlignment: CrossAxisAlignment.end,
              //mainAxisSize: MainAxisSize.min,
              children: [
                GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: actionButtons.length,
                    children: actionButtons
                )
                /*GridView.builder(
                    itemCount: actionButtons.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2
                    ),
                    itemBuilder: (context, index) {
                      return Container(
                        child: actionButtons[index],
                      );
                    })*/

              ],
            ),
          )
      );
      cards.add(
          Card(
            margin: EdgeInsets.only(top: 2.5, bottom: 1.25),
            child: card,
      ));
    });

    return cards;
  }

  Future<List<Service>> _getServices() async {
    var services = <Service>[];
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    try {
      var url = await URL().baseUrl;
      var jwt = await Util().getJWT();
      var response =
          await client.get(Uri.tryParse('$url/service/list')!, headers: jwt);
      print(response.body);
      if (response.statusCode == 200) {
        services = _parseServices(response.body);
      }
    } finally {
      client.close();
    }
    return services;
  }

  Future<void> _doServiceAction(String servicename, String action) async {
    final client = RetryClient(http.Client());

    try {
      var url = await URL().baseUrl;
      var jwt = await Util().getJWT();
      var uri = Uri.tryParse('$url/service/execute/$servicename/$action');
      var response = await client.post(uri!, headers: jwt);
      print(response.body);
      if (response.statusCode != 200) {
        print(response.body);
        Util.showMessage(context, response.body);
      } else if (response.body.isNotEmpty && response.statusCode == 200) {
        Util.showFeedback(context, response.body);
        _onRefresh();
      }
    } finally {
      client.close();
    }
  }

  Future<void> _refreshView() async {
    bool refreshView = await Settings().getBool("refreshView", true);

    if(refreshView) {
      print("Initialize view refresher");
      _timer = Timer.periodic(Duration(seconds: 5), (timer) {
        setState(() {
          services = _getServices();
        });
      });
    } else {
      try {
        if(_timer.isActive) {
          _timer.cancel();
        }
      } catch(e) {
        print("View refresh timer is not initialized");
      }
    }
  }

  List<Service> _parseServices(String body) {
    final parsed = json.decode(body).cast<Map<String, dynamic>>();
    return parsed.map<Service>((json) => Service.fromJson(json)).toList();
  }
}

/// DTO part
class Service {
  String name;
  String status;
  String info;

  Service({required this.name, required this.status, required this.info});

  factory Service.fromJson(Map<String, dynamic> json) => _serviceFromJson(json);
}

Service _serviceFromJson(Map<String, dynamic> json) {
  return Service(
      name: json["name"] as String,
      status: json["status"] as String,
      info: json["info"] as String);
}
