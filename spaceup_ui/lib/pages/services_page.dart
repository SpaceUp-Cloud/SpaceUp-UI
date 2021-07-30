import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:spaceup_ui/ui_data.dart';
import 'package:spaceup_ui/util.dart';

class ServicesPageStarter extends StatefulWidget {
  ServicesPageStarter() : super();

  @override
  ServicesPage createState() => ServicesPage();
}

class ServicesPage extends State<ServicesPageStarter> {
  ScrollController scrollController = ScrollController();
  var refreshKey = GlobalKey<RefreshIndicatorState>();

  late ThemeData theme;

  late Future<List<Service>> services;

  @override
  void initState() {
    super.initState();
    services = _getServices();
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);

    final servicesView = SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      controller: scrollController,
      child: createServicCards()
    );

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text("Services"),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
              child: servicesView,
              onRefresh: _onRefresh,
              key: refreshKey)
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
      var card = Card(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            ListTile(
              leading: Icon(Icons.miscellaneous_services),
              title: Text(service.name),
              tileColor: (service.status == "FATAL" || service.status == "STOPPED")
                  ? theme.errorColor : Colors.lightGreen,
              subtitle: Text(service.info),
              //onTap: _openLogs(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                // START, STOP, RESTART, ...more
                TextButton(
                  child: const Text('Start', /*style: TextStyle(fontSize: 18),*/),
                  onPressed: () {
                    _doServiceAction(service.name, "START");
                  },
                ),
                TextButton(
                  child: const Text('Stop', /*style: TextStyle(fontSize: 18),*/),
                  onPressed: () {
                    _doServiceAction(service.name, "STOP");
                  },
                ),
                TextButton(
                  child: const Text('Restart', /*style: TextStyle(fontSize: 18),*/),
                  onPressed: () {
                    _doServiceAction(service.name, "RESTART");
                  },
                ),
              ],
            )
          ]));
      cards.add(card);
    });

    return cards;
  }

  Future<List<Service>> _getServices() async {
    var domains = <Service>[];
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    try {
      var url = await URL().baseUrl;
      var response = await client
          .get(Uri.tryParse('$url/service/list')!);
      if (response.statusCode == 200) {
        domains = _parseServices(response.body);
      }
    } finally {
      client.close();
    }
    return domains;
  }

  Future<void> _doServiceAction(String servicename, String action) async {
    final client = RetryClient(http.Client());

    try {
      var url = await URL().baseUrl;
      var uri = Uri.tryParse('$url/service/execute/$servicename/$action');
      var response  = await client.post(uri!);
      if(response.body.isNotEmpty) {
        Util.showFeedback(context, response.body);
        _onRefresh();
      }
    } finally {
      client.close();
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

  Service({
    required this.name,
    required this.status,
    required this.info
  });

  factory Service.fromJson(Map<String, dynamic> json)
    => _serviceFromJson(json);
}

Service _serviceFromJson(Map<String, dynamic> json) {
  return Service(
      name: json["name"] as String,
      status: json["status"] as String,
      info: json["info"] as String);
}