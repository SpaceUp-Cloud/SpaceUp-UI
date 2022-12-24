import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:spaceup_ui/ui_data.dart';
import 'package:spaceup_ui/util.dart';

import '../SUGradient.dart';

class SwsPageStarter extends StatefulWidget {
  SwsPageStarter() : super();

  @override
  SwsPage createState() => SwsPage();
}

class SwsPage extends State<SwsPageStarter> {
  late ThemeData theme;

  ScrollController scrollController = ScrollController();
  var refreshKey = GlobalKey<RefreshIndicatorState>();
  bool _showBackToTopButton = false;

  Map<String, TextEditingController> textControllers = {};
  late Future<List<Sws>> _sws;

  @override
  void initState() {
    super.initState();

    _sws = _loadSws();
    _sws.then((swsList) => {
      swsList.forEach((sws) {
        final textController = TextEditingController(text: sws.content);
        textControllers.putIfAbsent(sws.name, () => textController);
      })
    });

    scrollController.addListener(() {
      setState(() {
        if (scrollController.offset >= 50) {
          _showBackToTopButton = true; // show the back-to-top button
        } else {
          _showBackToTopButton = false; // hide the back-to-top button
        }
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);

    final scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20.0
        ),
        flexibleSpace: SUGradient.gradientContainer,
        title: Text("Server Web Scripts"),
        actions: [
          IconButton(
              onPressed: _onRefresh,
              icon: Icon(Icons.refresh)
          ),
          IconButton(
              onPressed: () {}, //_addSws,
              icon: Icon(Icons.add)
          )
        ],
      ),
      body: createSwsCards(),
      floatingActionButton: _showBackToTopButton == false
          ? null
          : FloatingActionButton(
        onPressed: _scrollToTop,
        child: Icon(Icons.arrow_upward),
      ),
    );

    return scaffold;
  }

  void _scrollToTop() {
    /*scrollController.animateTo(0,
        duration: Duration(seconds: 1), curve: Curves.fastLinearToSlowEaseIn);*/
    scrollController.jumpTo(0);
  }

  Future<void> _onRefresh() async {
    setState(() {
      _sws = _loadSws();
      _sws.then((swsList) => {
        swsList.forEach((sws) {
          textControllers.update(sws.name, (value) => TextEditingController(text: sws.content));
        })
      });
    });
  }

  FutureBuilder<List<Sws>> createSwsCards() {
    return FutureBuilder(
        future: _sws,
        builder: (context, AsyncSnapshot<List<Sws>> snapshot) {
          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty) {
            return CustomScrollView(
              slivers: createCards(snapshot.data!),
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner.
          return Center(
            child: CircularProgressIndicator(),
          );
        }
    );
  }

  List<Widget> createCards(List<Sws> swsList) {
    var cards = <Widget>[];
    if (swsList.isEmpty && textControllers.isNotEmpty) return cards;

    swsList.forEach((sws) {
      var header = SliverStickyHeader(
        overlapsContent: false,
        header: Container(
          color: theme.colorScheme.secondaryContainer,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.extension),
                style: ListTileStyle.list,
                visualDensity: VisualDensity.compact,
                title: Text(sws.name),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    MaterialButton(
                      child: Text("Save"),
                      onPressed: () {
                        _saveSws(textControllers[sws.name]!.value.text);
                      },
                    ),
                    MaterialButton(
                      child: Text("Delete", style: TextStyle(
                          color: theme.colorScheme.error
                      )),
                      onPressed: () {
                        // TODO Show popup and warn be deleting
                      },
                    ),
                    MaterialButton(
                      child: Text("Execute"),
                      onPressed: () {
                        print("Execute ${sws.name}");
                        // TODO
                        _showExecutionDialog(sws.name, sws.content);
                      },
                    ),
                  ],
                ),
              ),

            ],
          )
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
                  (context, i) =>
                      ExpansionTile(
                          title: Text("Script"),
                          children: [
                            TextField(
                              controller: textControllers[sws.name]!,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              style: TextStyle(
                                  fontSize: 14.0
                              ),
                            ),
                          ],
                      ),
            childCount: 1
          ),
        ),
      );


      cards.add(header);
    });

    return cards;
  }

  Future<void> _showExecutionDialog(String swsName, String swsContent) {
    // Get a list of params, which we can wrap in a TextField list
    final paramTextFields = <TextField>[];
    final regex =
    RegExp(r"SERVER_ENDPOINT:\s*([a-zA-Z]+)\s*(/{0,1}[a-zA-Z]+/{0,1})+\?")
        .firstMatch(swsContent);
    final String? httpMethod = regex?[1];
    print("Found http method: $httpMethod");
    // SWS URI
    final String? swsUri = regex?[2];
    print("SWS uri: $swsUri");

    // ...?myparam=defaultValue&anotherParam ...
    // myparam=defaultValue,anotherParam
    final listParamPairs = RegExp(r"([^&?]+?)=?([^&?]+)?", multiLine: false)
        .allMatches(swsContent);
    listParamPairs.forEach((matchGroup) {
      var match = matchGroup[0];
      // length check is a workaround as the regex isn't perfect
      TextEditingController textController = TextEditingController();
      if(match != null && match.contains("=")) {
        String key = match.split("=")[0];
        String value = match.split("=")[1].split("\n")[0];
        textController.text = value;
        paramTextFields.add(
          TextField(
            controller: textController,
            decoration: InputDecoration(
              labelText: key
            ),
          )
        );
      } else if(match != null && match.length < 40) {
        textController.text = "";
        paramTextFields.add(
            TextField(
              controller: textController,
              decoration: InputDecoration(
                  labelText: match.split("\n")[0]
              ),
            )
        );
      }
    });

    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Container(
              child: Form(
                child: Column(
                  //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("SWS Input data", style: TextStyle(
                      fontWeight: FontWeight.bold
                    )),
                    Column(
                      children: paramTextFields,
                    ),
                    Padding(padding: EdgeInsets.fromLTRB(0.0, 10, 0.0, 10)),
                    MaterialButton(
                        child: Text("Execute $swsName"),
                        onPressed: () {} //_swsExecute(httpMethod, swsUrl, paramTextFields)
                    )
                  ],
                ),
              ),
            )
          );
        }
    );
  }

  Future<void> _swsExecute(
      String httpMethod, String swsUrl, List<TextField> textfields) async {

    print("Http-Method: $httpMethod");
    print("SWS-URL: $swsUrl");
    //print("Http-Params: $httpParams");
  }

  Future<void> _saveSws(String content) async {
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    try {
      final url = await URL().baseUrl;
      final jwt = await Util().getJWT();
      jwt["Content-Type"] = "text/plain";
      var response =
        await client.put(
            Uri.tryParse('$url/sws/update')!,
            body: content,
            headers: jwt);
      if(response.statusCode == 200) {
        print("Updated sws");
        Util.showFeedback(context, response.body);
        setState(() {
          _sws = _loadSws();
        });
      } else {
        if(response.body.isNotEmpty) {
          Util.showFeedback(context, response.body);
        }
      }
    } finally {
      client.close();
    }
  }

  Future<List<Sws>> _loadSws() async {
    var sws = <Sws>[];
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    try {
      final url = await URL().baseUrl;
      final jwt = await Util().getJWT();
      var response =
        await client.get(Uri.tryParse('$url/sws/all')!, headers: jwt);

      if (response.statusCode == 200) {
        sws = _parseSws(response.body);
      }
    } finally {
      client.close();
    }

    return sws;
  }

  List<Sws> _parseSws(String body) {
    final parsed = json.decode(body).cast<Map<String, dynamic>>();
    return parsed.map<Sws>((json) => Sws.fromJson(json)).toList();
  }
}

class Sws {
  String name;
  String content;

  Sws({required this.name, required this.content});

  factory Sws.fromJson(Map<String, dynamic> json) => _swsFromJson(json);
}

Sws _swsFromJson(Map<String, dynamic> json) {
  return Sws(
    name: json["name"] as String,
    content: json["content"] as String
  );
}