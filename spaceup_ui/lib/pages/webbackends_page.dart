import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/forms/webbackend.dart';
import 'package:spaceup_ui/util.dart';

import '../SUGradient.dart';
import '../services/webbackendService.dart';

class WebbackendsPageStarter extends StatefulWidget {
  WebbackendsPageStarter() : super();

  @override
  WebbackendPage createState() => WebbackendPage();
}

/**
 * Feature implementation in this page:
 * - Read web backends
 * - Add web backend
 * - Delete web backend
 * - Read 'physical' running services
 */

class WebbackendPage extends State<WebbackendsPageStarter> {
  final scrollController = ScrollController();
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  late Timer _timer;
  bool fabIsVisible = true;

  late Future<List<Webbackend>> webbackends;

  // 'Physical' running services, e.g. a Python process
  late Future<List<Service>> services;

  @override
  void initState() {
    super.initState();
    Util.checkJWT();

    services = WebbackendService.getServices();
    webbackends = WebbackendService.getWebbackends();

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
    try {
      _timer.cancel();
    } catch (ex) {
      print("Timer was not initialize");
    }
  }

  @override
  Widget build(BuildContext context) {
    final addWebbackendWidget = FloatingActionButton(
      onPressed: () =>
      {
        showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          var dialog = AlertDialog(
            title: Text("Add web backend"),
            content: Container(
              width: MediaQuery.of(context).size.width * 2.5,
              child: AddWebbackendForm(onResult: (BuildContext context,  Response response) {
                if(response.statusCode == 200) {
                  Util.showMessage(context, "Created new web backend");
                  setState(() { // Refresh web backends
                    webbackends = WebbackendService.getWebbackends();
                  });
                } else {
                  Util.showMessage(context,
                      "Could not create web backend",
                      durationInSeconds: 5
                  );
                }
              }),
            ),
          );

          return dialog;
        })
      },
      tooltip: "Add web backend",
      child: Icon(Icons.add),
    );

    final scrollView = SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      controller: scrollController,
      child: Container(
        child: createWebbackendCards(),
      ),
    );

    final scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        flexibleSpace: SUGradient.gradientContainer,
        title: Text("Web backends"),
      ),
      floatingActionButton: AnimatedOpacity(
        duration: Duration(milliseconds: 200),
        opacity: fabIsVisible ? 1 : 0,
        child: addWebbackendWidget,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Stack(
        children: [
          RefreshIndicator(
            child: scrollView,
            onRefresh: _refreshPageData,
            key: refreshKey,
          )
        ],
      ),
    );

    return scaffold;
  }

  FutureBuilder<List<Webbackend>> createWebbackendCards() {
    return FutureBuilder<List<Webbackend>>(
        future: webbackends,
        initialData: <Webbackend>[],
        builder: (context, AsyncSnapshot<List<Webbackend>> snapshot) {
          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty) {
            return Column(children: createCards(snapshot.data!));
          } else if (snapshot.hasError && snapshot.error != null) {
            //Util.showMessage(context, snapshot.error.toString());
            return Column(
              children: [
                Center(
                    child: LinearProgressIndicator()
                ),
                Text(snapshot.error.toString())
              ],
            );
          }

          // By default, show a loading spinner.
          return Column(
            children: [
              Center(
                  child: LinearProgressIndicator()
              ),
            ],
          );
        }
    );
  }

  List<Card> createCards(List<Webbackend> webbackends) {
    var cards = <Card>[];
    ThemeData theme = Theme.of(context);

    if (webbackends.isEmpty) return cards;

    webbackends.forEach((wb) {
      final subtexts = <Widget>[];
      if(!wb.service.isEmpty) {
        final serviceWidget = Text("Service: ${wb.service}");
        subtexts.add(serviceWidget);
      }
      if(!wb.process.isEmpty) {
        final processWidget = Text("Process: ${wb.process}");
        subtexts.add(processWidget);
      }
      if(!wb.prefix.isEmpty) {
        final prefixWidget = Text("Prefix: ${wb.prefix}");
        subtexts.add(prefixWidget);
      }

      const String nok = "NOT OK";
      // 1. web has => NOT OK
      final bool webHasError = wb.web.contains(nok);
      // 2. Prefix has => NOT OK
      final bool prefixHasError = wb.process.contains(nok) ||
          wb.prefix.contains(nok);
      // 3. / apache (default)
      final bool defaultHasError = (webHasError || prefixHasError)
          && (subtexts.length > 0);

      // Check if webackend has error
      final bool hasError = webHasError || prefixHasError || defaultHasError;

      Widget cardContent = subtexts.length == 0 ?
        ListTile(
          leading: Icon(Icons.electrical_services),
          title: Text(wb.web),
        ) :
        ExpansionTile(
          leading: Icon(Icons.electrical_services),
          title: Text(wb.web),
          children: subtexts,
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          childrenPadding: const EdgeInsets.only(
              left: 8, bottom: 8, top: 8),
        );

      var card = Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: ColoredBox(
                      color: hasError ? Colors.deepOrangeAccent
                          : theme.colorScheme.secondaryContainer,
                      child: cardContent,
                    )
                ),
                PopupMenuButton<int>(
                  onSelected: (item) => handleCardAction(item, wb),
                    itemBuilder: (context) =>
                [
                  PopupMenuItem(value: 0, child:
                  Container(
                    child: Text("Delete", style: TextStyle(color: Colors.red)
                    ),
                  ))
                ])
              ],
            ),
          ],
        ),
      );
      cards.add(card);
    });

    return cards;
  }

  Future<void> handleCardAction(int item, Webbackend wb) async {
    switch (item) {
      case 0:
        WebbackendService.deleteWebbackend(context, wb.web, _refreshPageData);
    }
  }


  Future<void> _refreshPageData() async {
    setState(() {
      services = WebbackendService.getServices();
      webbackends = WebbackendService.getWebbackends();
    });
  }

  Future<void> _refreshView() async {
    bool refreshView = await Settings().getBool("refreshView", true);

    if (refreshView) {
      print("Initialize view refresher");
      _timer = Timer.periodic(Duration(seconds: 30), (timer) {
        _refreshPageData();
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

