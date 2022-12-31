import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:spaceup_ui/SUGradient.dart';
import 'package:spaceup_ui/ui_data.dart';
import 'package:spaceup_ui/util.dart';

class LogsPageStarter extends StatefulWidget {
  LogsPageStarter(this.context, this.servicename) : super();

  final BuildContext context;
  final String servicename;

  @override
  LogsPage createState() => LogsPage();
}

class LogsPage extends State<LogsPageStarter> with SingleTickerProviderStateMixin  {
  ScrollController scrollController = ScrollController();
  ScrollController scrollControllerError = ScrollController();
  late TabController tabController =
      TabController(initialIndex: 0, length: 2, vsync: this);
  var refreshKey = GlobalKey<RefreshIndicatorState>();

  bool _showBackToTopButton = false;

  late Future<Logs> logs = Future.value(Logs([], []));

  // Tabs
  var tabs = [
    Tab(text: 'Info', height: 35,),
    Tab(text: 'Error', height: 35,),
  ];

  // TabColor
  late Color tabcolor = Theme.of(context).colorScheme.primary;
  late Color primary = Theme.of(context).colorScheme.primary;
  late Color error = Colors.redAccent;

  /// default filters
  var limit = 5000;
  var reversed = true;

  // TODO: use enum instead
  var type = "both"; // info, error, both

  @override
  void initState() {
    super.initState();
    setState(() {
      logs = _getLogs(widget.servicename);
    });

    tabController.addListener(() {
      setState(() {
        tabcolor = tabController.index == 0
            ? primary : error;
      });
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

    scrollControllerError.addListener(() {
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
  void dispose() {
    scrollController.dispose();
    scrollControllerError.dispose();
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var body = NestedScrollView(
      /*physics: AlwaysScrollableScrollPhysics(),
          controller: scrollController,*/
      headerSliverBuilder: (context, value) {
        return [
          // Add here Filter component
          SliverToBoxAdapter(
            child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color.fromRGBO(4, 2, 46, 1),
                labelPadding: EdgeInsets.fromLTRB(0, 2, 0, 2),
                indicator: BoxDecoration(
                    color: tabcolor),
                controller: tabController,
                onTap: (index) {
                  _scrollToTop();
                },
                tabs: tabs),
          ),
        ];
      }, body: _getLogsBuilder(),
    );

    var scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primary,
        titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20.0
        ),
        flexibleSpace: SUGradient.gradientContainer,
        title: Text("${widget.servicename} Logs"),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
              child: body,
              onRefresh: _refreshLogs,
              key: refreshKey
          )
        ],
      ),
      floatingActionButton: _showBackToTopButton == false
          ? null
          : FloatingActionButton(
              onPressed: _scrollToTop,
              child: Icon(Icons.arrow_upward),
            ),
    );

    return scaffold;
  }

  FutureBuilder<Logs> _getLogsBuilder() {
    return FutureBuilder<Logs>(
        future: logs,
        builder: (context, AsyncSnapshot<Logs> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            var infoLogs = snapshot.data!.info;
            var errorLogs = snapshot.data!.error;

            return _buildLogView(infoLogs, errorLogs);
          } else if (!snapshot.hasData && snapshot.data == null) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Unable to gather logs: ${snapshot.error}"),
            );
          }

          return Center(
            child: LinearProgressIndicator(),
          );
        });
  }

  Widget _buildLogView(List<String> infoLogs, List<String> errorLogs) {
    final logTabContent = <CustomScrollView>[];

    var infoCustomSrollView = CustomScrollView(
      //shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      controller: scrollController,
      slivers: [
        SliverList(
            delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return SelectableText(infoLogs[index],
                      style: TextStyle(
                          fontSize: 14.0
                      )
                  );
                }, childCount: infoLogs.length,
            )
        )
      ],
    );
    logTabContent.add(infoCustomSrollView);

    var errorCustomSrollView = CustomScrollView(
      physics: const BouncingScrollPhysics(),
      controller: scrollControllerError,
      slivers: [
        SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return SelectableText(errorLogs[index],
                    style: TextStyle(
                        fontSize: 14.0
                    )
                );
              },
              childCount: errorLogs.length,
            ))
      ],
    );
    logTabContent.add(errorCustomSrollView);

    // error log
    /*var errors = <Widget>[];
    if (errorLogs.isNotEmpty) {
      errorLogs.forEach((log) {
        errors.add(
          SelectableText(log),
        );
      });
    }*/

    /*logTabContent.add(ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: errors,
      controller: scrollController,
    ));*/

    return TabBarView(controller: tabController, children: logTabContent);
  }

  void _scrollToTop() {
    /*scrollController.animateTo(0,
        duration: Duration(seconds: 1), curve: Curves.fastLinearToSlowEaseIn);*/
    scrollController.jumpTo(0);
    scrollControllerError.jumpTo(0);
  }

  Future<Logs> _getLogs(String servicename) async {
    Logs logs = Logs([], []);

    final client = RetryClient(http.Client());
    try {
      final url = await URL().baseUrl;
      final jwt = await Util().getJWT();
      final logsUri = Uri.tryParse(
          '$url/service/logs/$servicename?limit=$limit&reversed=$reversed&type=$type');
      print(logsUri);
      var response = await client.get(logsUri!, headers: jwt);
      if (response.body.isNotEmpty && response.statusCode == 200) {
        final parsed = json.decode(response.body);
        logs = Logs.fromJson(parsed);
      } else {
        print("""
        code: ${response.statusCode}\n
        body: ${response.body}
            """);
      }
    } finally {
      client.close();
    }

    return logs;
  }

  Future<void> _refreshLogs() async {
    setState(() {
      logs = _getLogs(widget.servicename);
    });
  }
}

class Logs {
  List<String> info = [];
  List<String> error = [];

  Logs(this.info, this.error);

  factory Logs.fromJson(Map<String, dynamic> json) => _logsFromJson(json);
}

Logs _logsFromJson(Map<String, dynamic> json) {
  final List<String> info = List<String>.from(json["log"]["info"]).toList();
  final List<String> error = List<String>.from(json["log"]["error"]).toList();

  List<String> cleanedInfo = [];
  List<String> cleanedError = [];

  if (info.isNotEmpty) {
    info.forEach((element) {
      var trimmed = element.trim();
      cleanedInfo.add(trimmed);
    });
  }

  if (error.isNotEmpty) {
    error.forEach((element) {
      var trimmed = element.trim();
      cleanedError.add(trimmed);
    });
  }

  return Logs(cleanedInfo, cleanedError);
}