import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

class DomainPageStarter extends StatefulWidget {
  DomainPageStarter() : super();

  @override
  DomainPage createState() => DomainPage();
}

class DomainPage extends State<DomainPageStarter> {
  late Future<List<Domain>> domains;
  ScrollController scrollController = ScrollController();
  bool fabIsVisible = true;

  @override
  void initState() {
    super.initState();
    domains = getDomains();

    scrollController.addListener(() {
      setState(() {
        fabIsVisible =
            scrollController.position.userScrollDirection == ScrollDirection.forward;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final addDomainsWidget = FloatingActionButton(
      onPressed: _addDomain,
      tooltip: "Add domain",
      child: Icon(Icons.add),

    );

    // createDomainCards(),

    return Scaffold(
      floatingActionButton: AnimatedOpacity(
        duration: Duration(milliseconds: 200),
        opacity: fabIsVisible ? 1 : 0,
        child: addDomainsWidget,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      body: SingleChildScrollView(
        controller: scrollController,
        child: createDomainCards(),
      ),
    );

    /*return SingleChildScrollView(
      child: Row(
        children: [


        ],
      ),
    );*/
  }

  void _addDomain() {
    final snackbar = SnackBar(content: Text('TODO: Add domain'));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
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
                    /* ... */
                  },
                ),
                const SizedBox(width: 8),
              ],
            )
          ]));
      cards.add(card);
    });

    return cards;
  }

  FutureBuilder<List<Domain>> createDomainCards() {
    return FutureBuilder<List<Domain>>(
        future: domains,
        builder: (context, snapshot) {
          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty) {
            return Column(children: createCards(snapshot.data!));
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner.
          return Center(
            child: CircularProgressIndicator(),
          );
        });
  }
}

Future<List<Domain>> getDomains() async {
  var domains = <Domain>[];
  final httpClient = http.Client();
  final client = RetryClient(httpClient);

  try {
    //await client.get(Uri.parse('http://192.168.178.24:9090/api/domain/list?cached=true'));
    var response = await http
        .get(Uri.tryParse('${URL.BASE_URL}/domain/list?cached=true')!);
    if (response.statusCode == 200) {
      domains = parseDomains(response.body);
    }
  } finally {
    client.close();
  }
  return domains;
}

class Domain {
  String url;

  Domain({required this.url});

  factory Domain.fromJson(Map<String, dynamic> json) => _domainFromJson(json);
}

Domain _domainFromJson(Map<String, dynamic> json) {
  return Domain(url: json["url"] as String);
}

List<Domain> parseDomains(String body) {
  final parsed = json.decode(body).cast<Map<String, dynamic>>();
  return parsed.map<Domain>((json) => Domain.fromJson(json)).toList();
}

class URL {
  static const String BASE_URL = 'http://192.168.178.24:9090/api';
}
