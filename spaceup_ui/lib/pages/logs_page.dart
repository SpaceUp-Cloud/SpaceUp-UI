import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:spaceup_ui/ui_data.dart';
import 'package:spaceup_ui/util.dart';

class LogsPageStarter extends StatefulWidget {
  LogsPageStarter(this.servicename) : super();

  final String servicename;

  @override
  LogsPage createState() => LogsPage();
}

class LogsPage extends State<LogsPageStarter> with TickerProviderStateMixin {
  ScrollController scrollController = ScrollController();
  late TabController tabController =
      TabController(initialIndex: 0, length: 2, vsync: this);
  var refreshKey = GlobalKey<RefreshIndicatorState>();

  bool _showBackToTopButton = false;

  late Future<Logs> logs = Future.value(Logs([], []));

  // Tabs
  var tabs = [
    Text('Info'),
    Text('Error'),
  ];

  // TabColor
  late MaterialAccentColor tabcolor = Colors.greenAccent;

  /// default filters
  var limit = 500;
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
            ? Colors.greenAccent
            : Colors.deepOrangeAccent;
      });
    });

    scrollController.addListener(() {
      setState(() {
        if (scrollController.offset >= 100) {
          _showBackToTopButton = true; // show the back-to-top button
        } else {
          _showBackToTopButton = false; // hide the back-to-top button
        }
      });
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var body = Container(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        key: refreshKey,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          controller: scrollController,
          child: _getLogsBuilder(),
        ),
      ),
    );

    var scaffold = Scaffold(
      appBar: AppBar(
        title: Text("${widget.servicename} Logs"),
        bottom: TabBar(
            labelColor: Color.fromRGBO(4, 2, 46, 1),
            indicatorColor: Color.fromRGBO(4, 2, 46, 1),
            labelPadding: EdgeInsets.fromLTRB(0, 10, 0, 10),
            indicator: BoxDecoration(
                //borderRadius: BorderRadius.circular(50), // Creates border
                color: tabcolor),
            controller: tabController,
            tabs: tabs),
      ),
      body: body,
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
        initialData: null,
        builder: (context, AsyncSnapshot<Logs> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            var infoLogs = snapshot.data!.info;
            var errorLogs = snapshot.data!.error;

            return Container(
              child: _buildLogView(infoLogs, errorLogs),
            );
          } else if (!snapshot.hasData && snapshot.data == null) {
            return Center(
              child: Text(
                  'No logs found. Service log path is correctly configured?'),
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
    var transformed = <Widget>[];

    var logTabContent = <Widget>[];
    var logs = <Widget>[];

    // Info log
    if (infoLogs.isNotEmpty) {
      infoLogs.forEach((log) {
        logs.add(
          Text(log),
        );
      });
    }

    logTabContent.add(SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: logs,
      ),
    ));

    // error log
    var errors = <Widget>[];
    if (errorLogs.isNotEmpty) {
      errorLogs.forEach((log) {
        errors.add(
          Text(log),
        );
      });
    }

    logTabContent.add(SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: errors,
      ),
    ));

    transformed
        .add(TabBarView(controller: tabController, children: logTabContent));

    return Column(
      children: transformed,
    );
  }

  void _scrollToTop() {
    scrollController.animateTo(0,
        duration: Duration(seconds: 1), curve: Curves.fastLinearToSlowEaseIn);
  }

  Future<void> _onRefresh() async {
    setState(() {
      logs = _getLogs(widget.servicename);
    });
  }

  Future<Logs> _getLogs(String servicename) async {
    Logs logs = Logs([], []);

    final client = RetryClient(http.Client());
    try {
      final url = await URL().baseUrl;
      final jwt = await Util().getJWT(context);
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
}

class Logs {
  List<String> info = [];
  List<String> error = [];

  Logs(this.info, this.error);

  factory Logs.fromJson(Map<String, dynamic> json) => _logsFromJson(json);
}

Logs _logsFromJson(Map<String, dynamic> json) {
  print("Error log: $json");
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
