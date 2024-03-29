import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/SUGradient.dart';
import 'package:spaceup_ui/ui_data.dart';
import 'package:spaceup_ui/util.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/domainService.dart';

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
    Util.checkJWT();
    domains = DomainService.getDomains(true);

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
      child: Container(
        child: createDomainCards(),
      ),
    );

    ThemeData theme = Theme.of(context);
    final scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20.0
        ),
        flexibleSpace: SUGradient.gradientContainer,
        title: Text("Domains"),
      ),
      floatingActionButton: AnimatedOpacity(
        duration: Duration(milliseconds: 200),
        opacity: fabIsVisible ? 1 : 0,
        child: addDomainsWidget,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
      domains = DomainService.getDomains(false);
    });
  }

  List<Card> createCards(List<Domain> domains) {
    var cards = <Card>[];
    if (domains.isEmpty) return cards;

    domains.forEach((domain) {
      var card = Card(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: ListTile(
                  leading: Icon(Icons.cloud),
                  title: SelectableText(domain.url),
                )),
                PopupMenuButton<int>(
                  onSelected: (item) => handleCardAction(item, domain),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 0, child: Text("Open")),
                    PopupMenuItem(
                        value: 1,
                        child: Container(
                          child: Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ))
                  ],
                )
              ],
            )
          ],
        ),
      );
      cards.add(card);
    });

    return cards;
  }

  Future<void> handleCardAction(int item, Domain domain) async {
    switch (item) {
      case 0:
        final urlToLaunch = "http://${domain.url}";
        if(await canLaunchUrl(Uri.parse(urlToLaunch))) {
          await launchUrl(
              Uri.parse(urlToLaunch),
              mode: LaunchMode.inAppWebView,
              webViewConfiguration: WebViewConfiguration()
          );
        } else {
          Util.showMessage(context, "Unable to open $urlToLaunch",
              durationInSeconds: 5);
        }
        break;
      case 1:
        _deleteDomainDialog(domain);
        break;
    }
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
            child: CircularProgressIndicator(),
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
                    DomainService.deleteDomain(context, domain).then((value) => {
                      this.domains = DomainService.getDomains(false)
                    });
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
    /*final double desktopSuggestionWeb = 700;
    final double mobileSuggestionWeb = 300;

    final double suggestionWidth = Util().isMobile
        ? mobileSuggestionWeb : desktopSuggestionWeb;*/

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          var dialog = AlertDialog(
            alignment: Alignment.center,
            title: Text("Add your domains"),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            content: Container(
              width: MediaQuery.of(context).size.width * 2.5,
              child: Form(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: _textFieldController,
                      textInputAction: TextInputAction.go,
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      validator: (value) {
                        return (value != null && value.isNotEmpty)
                            ? value
                            : "Please enter domains";
                      },
                      decoration: InputDecoration(
                          hintText:
                              "your.domain; foo.bar.de; blub.foo.bar; ..."),
                    )
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                  child: Text('Submit'),
                  onPressed: () {
                    if (_textFieldController.value.text.isNotEmpty) {
                      _addDomain(_textFieldController.value.text);
                      Navigator.of(context).pop();
                    } else {
                      Util.showMessage(context, "You have to enter domains!");
                    }
                  }),
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );

          return dialog;
        });
  }



  Future<void> _addDomain(String domain) async {
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    List<dynamic> domains = <dynamic>[];
    domain.split(";").forEach((element) {
      if(element.isNotEmpty) {
        var map = Map<String, String>();
        map["url"] = element;
        domains.add(map);
      }
    });

    Util.showMessage(context, "Going to create $domain", durationInSeconds: 5);

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



  Future<void> _refreshView() async {
    bool refreshView = await Settings().getBool("refreshView", true);

    if (refreshView) {
      print("Initialize view refresher");
      _timer = Timer.periodic(Duration(seconds: 30), (timer) {
        setState(() {
          domains = DomainService.getDomains(false);
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


}

