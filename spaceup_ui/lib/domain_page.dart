import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/util.dart';
import 'package:spaceup_ui/ui_data.dart';

class DomainPageStarter extends StatefulWidget {
  DomainPageStarter() : super();

  @override
  DomainPage createState() => DomainPage();
}

class DomainPage extends State<DomainPageStarter> {
  ScrollController scrollController = ScrollController();
  var refreshKey = GlobalKey<RefreshIndicatorState>();

  late Future<List<Domain>> domains;
  bool isCached = false;

  bool fabIsVisible = true;

  @override
  void initState() {
    super.initState();
    domains = _getDomains();

    scrollController.addListener(() {
      setState(() {
        fabIsVisible = scrollController.position.userScrollDirection ==
            ScrollDirection.forward;
      });
    });
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
      domains = _getDomains();
    });
  }

  List<Card> createCards(List<Domain> domains) {
    var cards = <Card>[];
    if (domains.isEmpty) return cards;

    domains.forEach((domain) {
      var card = Card(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        ListTile(
          leading: Icon(Icons.cloud),
          title: Text(domain.url),
        ),
        Row(
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
      ]));
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
            child:  LinearProgressIndicator(),
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
                      hintText: "Add here... x.y.z; a.b.c; ..."
                    ),
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
      var uri = Uri.tryParse('${URL.BASE_URL}/domain/delete/${domain.url}');
      var response = await client.delete(uri!);

      if(response.body.isNotEmpty && response.statusCode == 200) {
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
      var uri = Uri.tryParse('${URL.BASE_URL}/domain/add');
      var response = await client.post(
          uri!,
          headers: {"Content-Type": "application/json"},
          body: json.encode(domains));

      if(response.body.isNotEmpty && response.statusCode == 200) {
        Util.showFeedback(context, response.body);
        _refreshDomains();
      }
    } finally {
      client.close();
    }
  }

  Future<List<Domain>> _getDomains() async {
    var domains = <Domain>[];
    final httpClient = http.Client();
    final client = RetryClient(httpClient);
    var isCached = await Settings().getBool("isCachedDomain", false);

    try {
      var response = await client
          .get(Uri.tryParse('${URL.BASE_URL}/domain/list?cached=$isCached')!);
      if (response.statusCode == 200) {
        domains = _parseDomains(response.body);
      }
    } finally {
      client.close();
    }
    return domains;
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
