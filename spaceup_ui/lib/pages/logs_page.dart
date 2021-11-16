import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:spaceup_ui/ui_data.dart';
import 'package:spaceup_ui/util.dart';

class LogsPageStarter extends StatefulWidget {
  LogsPageStarter(this.servicename): super();

  final String servicename;

  @override
  LogsPage createState() => LogsPage();
}

class LogsPage extends State<LogsPageStarter> {
  ScrollController scrollController = ScrollController();
  var refreshKey = GlobalKey<RefreshIndicatorState>();

  bool _showBackToTopButton = false;

  late Future<Logs> logs = Future.value(Logs([], []));

  /// default filters
  var limit = 500;
  var reversed = true;
  var type = "both"; // info, error, both

  @override
  void initState() {
    super.initState();
    setState(() {
      logs = _getLogs(widget.servicename);
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

    return Scaffold(
      appBar: AppBar(
        title: Text("Logs"),
      ),
      body: body,
      floatingActionButton: _showBackToTopButton == false
        ? null
        : FloatingActionButton(
          onPressed: _scrollToTop,
          child: Icon(Icons.arrow_upward),
      ),
    );
  }

  FutureBuilder<Logs> _getLogsBuilder() {
    return FutureBuilder<Logs>(
        future: logs,
        initialData: null,
        builder: (context, AsyncSnapshot<Logs> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            var infoLogs = snapshot.data!.info;
            var errorLogs = snapshot.data!.error;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildLogView(infoLogs, errorLogs),
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

  List<Widget> _buildLogView(List<String> infoLogs, List<String> errorLogs) {
    var transformed = <Widget>[];
    transformed.add(
        ListTile(
          tileColor: Theme.of(context).primaryColor,
          visualDensity: VisualDensity(horizontal: 0, vertical: -4),
          minVerticalPadding: 0,
          title: Text("Info Log"),
        )
    );

    var logs = <Widget>[];
    infoLogs.forEach((log) {
      logs.add(
        Text(log),
      );
    });
    transformed.add(
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: logs,
          ),
        )
    );
    transformed.add(
        ListTile(
          tileColor: Theme.of(context).errorColor,
          visualDensity: VisualDensity(horizontal: 0, vertical: -4),
          minVerticalPadding: 0,
          title: Text("Error Log"),
        )
    );
    var errors = <Widget>[];
    errorLogs.forEach((log) {
      errors.add(
        Text(log),
      );
    });
    transformed.add(
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors,
          ),
        )
    );

    return transformed;
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
      var response =
      await client.get(logsUri!, headers: jwt);
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

  info.forEach((element) {
    var trimmed = element.trim();
    cleanedInfo.add(trimmed);
  });

  error.forEach((element) {
    var trimmed = element.trim();
    cleanedError.add(trimmed);
  });

  return Logs(cleanedInfo, cleanedError);
}