import 'dart:async';
import 'dart:convert';

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/ui_data.dart';
import 'package:spaceup_ui/util.dart';

class DomainPageStarter extends StatefulWidget {
  DomainPageStarter() : super();

  @override
  DomainPage createState() => DomainPage();
}

class DomainPage extends State<DomainPageStarter> {
  ScrollController scrollController = ScrollController();
  var refreshKey = GlobalKey<RefreshIndicatorState>();
  late Timer _timer;

  bool fabIsVisible = true;

  late Future<List<Domain>> domains;

  @override
  void initState() {
    super.initState();
    Util.checkJWT(context);
    domains = _getDomains(true);

    scrollController.addListener(() {
      setState(() {
        fabIsVisible = scrollController.position.userScrollDirection ==
            ScrollDirection.forward;
      });
    });

    _refreshView();
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final addDomainsWidget = FloatingActionButton(
      onPressed: () => _addDomainDialog(),
      tooltip: "Add domain",
      child: Icon(Icons.add),
    );

    final scrollCardsView = SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      controller: scrollController,
      child: createDomainCards(),
    );

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text("Domains"),
      ),
      floatingActionButton: AnimatedOpacity(
        duration: Duration(milliseconds: 200),
        opacity: fabIsVisible ? 1 : 0,
        child: addDomainsWidget,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Stack(
        children: [
          RefreshIndicator(
              child: scrollCardsView,
              onRefresh: _refreshDomains,
              key: refreshKey)
        ],
      ),
    );

    return scaffold;
  }

  Future<void> _refreshDomains() async {
    setState(() {
      domains = _getDomains(false);
    });
  }

  List<FlipCard> createCards(List<Domain> domains) {
    var cards = <FlipCard>[];
    if (domains.isEmpty) return cards;

    domains.forEach((domain) {
      var card = FlipCard(
        direction: FlipDirection.VERTICAL,
        front: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          ListTile(
            leading: Icon(Icons.cloud),
            title: Text(domain.url),
          ),
        ]),
        back: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                _deleteDomainDialog(domain);
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
      );
      cards.add(card);
    });

    return cards;
  }

  FutureBuilder<List<Domain>> createDomainCards() {
    return FutureBuilder<List<Domain>>(
        future: domains,
        initialData: <Domain>[],
        builder: (context, AsyncSnapshot<List<Domain>> snapshot) {
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

  Future<void> _deleteDomainDialog(Domain domain) async {
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Warning!"),
            content: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Text("Are you sure you want to delete: ${domain.url}?")
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                  child: Text('Confirm'),
                  onPressed: () {
                    _deleteDomain(domain);
                    Navigator.of(context).pop();
                  }),
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  Future<void> _addDomainDialog() async {
    TextEditingController _textFieldController = TextEditingController();

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Add Domains!"),
            content: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _textFieldController,
                    textInputAction: TextInputAction.go,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                        hintText: "Add here... x.y.z; a.b.c; ..."),
                  )
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                  child: Text('Submit'),
                  onPressed: () {
                    _addDomain(_textFieldController.value.text);
                    Navigator.of(context).pop();
                  }),
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  Future<void> _deleteDomain(Domain domain) async {
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    try {
      var url = await URL().baseUrl;
      var uri = Uri.tryParse('$url/domain/delete/${domain.url}');
      var jwt = await Util().getJWT();
      var response = await client.delete(uri!, headers: jwt);

      if (response.body.isNotEmpty && response.statusCode == 200) {
        Util.showFeedback(context, response.body);
        _refreshDomains();
      }
    } finally {
      client.close();
    }
  }

  Future<void> _addDomain(String domain) async {
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    List<dynamic> domains = <dynamic>[];
    domain.split(";").forEach((element) {
      var map = Map<String, String>();
      map["url"] = element;
      domains.add(map);
    });

    try {
      var url = await URL().baseUrl;
      var jwt = await Util().getJWT();
      var addDomainUrl = Uri.tryParse('$url/domain/add');
      var response = await client.post(addDomainUrl!,
          headers: jwt, body: json.encode(domains));

      if (response.body.isNotEmpty && response.statusCode == 200) {
        Util.showFeedback(context, response.body);
        _refreshDomains();
      }
    } finally {
      client.close();
    }
  }

  Future<List<Domain>> _getDomains(bool useCached) async {
    var domains = <Domain>[];
    final httpClient = http.Client();
    final client = RetryClient(httpClient);
    var isCached =
        await Settings().getBool("isCachedDomain", false) && useCached;

    try {
      var url = await URL().baseUrl;
      var jwt = await Util().getJWT();
      var getDomainsUrl = "$url/domain/list?cached=$isCached";
      var response =
          await client.get(Uri.tryParse(getDomainsUrl)!, headers: jwt);
      print(response.body);
      if (response.statusCode == 200) {
        domains = _parseDomains(response.body);
      }
    } finally {
      client.close();
    }
    return domains;
  }

  Future<void> _refreshView() async {
    bool refreshView = await Settings().getBool("refreshView", true);

    if(refreshView) {
      print("Initialize view refresher");
      _timer = Timer.periodic(Duration(seconds: 5), (timer) {
        setState(() {
          domains = _getDomains(true);
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

  List<Domain> _parseDomains(String body) {
    final parsed = json.decode(body).cast<Map<String, dynamic>>();
    return parsed.map<Domain>((json) => Domain.fromJson(json)).toList();
  }
}

class Domain {
  String url;

  Domain({required this.url});

  factory Domain.fromJson(Map<String, dynamic> json) => _domainFromJson(json);
}

Domain _domainFromJson(Map<String, dynamic> json) {
  return Domain(url: json["url"] as String);
}
