import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart';
import 'package:spaceup_ui/services/domainService.dart';

import '../services/webbackendService.dart';
import '../util.dart';

class AddWebbackendForm extends StatefulWidget {
  final Function(BuildContext context, Response response) onResult;
  final String domain;

  AddWebbackendForm({
    required this.onResult,

    this.domain = ""
  }): super();

  @override
  AddWebbackend createState() => AddWebbackend(
      onResult: onResult, domain: domain);
}

class AddWebbackend extends State<AddWebbackendForm>{
  AddWebbackend({
    required this.onResult,

    this.domain = ""
  }): super();

  // Callback function
  final Function(BuildContext context, Response response) onResult;
  // Optional parameter if we want to add webbackend from another page,
  // where we can provide the domain
  final String domain;

  /*
  "url": "string",
  "isApache": true,
  "isHttp": true,
  "removePrefix": true,
  "port": 0
  */

  String url = "";
  int? port = null;
  bool isHttp = true;
  bool isApache = false;
  bool removePrefix = false;

  String selectedUrl = "";
  late int selectedPort;

  late List<Domain> domains;
  late List<Service> services;

  @override
  void initState() {
    super.initState();
    if(domain.isNotEmpty) {
      url = domain;
    }

    setState(() {
      DomainService.getDomains(true).then((value) => domains = value);
      WebbackendService.getServices().then((value) => services = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    //const maxSuggestionWidth = MediaQuery.of(context).size.width * 2.5;
    final double desktopSuggestionWeb = 700;
    final double mobileSuggestionWeb = 300;

    final double suggestionWidth = Util().isMobile
        ? mobileSuggestionWeb : desktopSuggestionWeb;

    final form = Container(
      child: ListView(
        shrinkWrap: true,
        children: [
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Domain"),
                // Domain/url
                Autocomplete(
                  optionsBuilder: (TextEditingValue value) {
                    if (value.text.isEmpty) {
                      return const Iterable<String>.empty();
                    } else {
                      final matches = <String>[];
                      matches.addAll(domains.map((Domain e) {
                        return e.url;
                      }));

                      matches.retainWhere((d) {
                        return d
                            .toLowerCase()
                            .contains(value.text.toLowerCase());
                      });

                      return matches;
                    }
                  },
                  onSelected: (String value) {
                    setState(() {
                      selectedUrl = value;
                    });
                  },
                  optionsViewBuilder: (BuildContext context,
                      AutocompleteOnSelected<String> onSelected,
                      Iterable<String> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight: 200, maxWidth: suggestionWidth),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            //shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: Container(
                                  color: Theme.of(context).focusColor,
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(option),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Service"),
                // Port
                Autocomplete(
                    displayStringForOption: (Service s) => s.program,
                    optionsBuilder: (TextEditingValue value) {
                      if(value.text.isEmpty) {
                        return const Iterable<Service>.empty();
                      } else {
                        final matches = <Service>[];
                        matches.addAll(services);

                        matches.retainWhere((p) {
                          return p.program.contains(value.text);
                        });
                        return matches;
                      }
                    },
                    onSelected: (Service s) {
                      setState(() {
                        selectedPort = s.port;
                      });
                    },
                  optionsViewBuilder: (BuildContext context,
                      AutocompleteOnSelected<Service> onSelected,
                      Iterable<Service> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight: 200, maxWidth: suggestionWidth),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            //shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Service option = options.elementAt(index);
                              return InkWell(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: Container(
                                  color: Theme.of(context).focusColor,
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(option.program),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
          // isAHttp
          CheckboxListTile(
              title: Text("Is Http"),
              value: isHttp,
              onChanged: (bool? value) {
                setState(() {
                  isHttp = value!;
                });
              }),
          // removePrefix
          CheckboxListTile(
              title: Text("Remove prefix"),
              value: removePrefix,
              onChanged: (bool? value) {
                setState(() {
                  removePrefix = value!;
                });
              }),
          // isApache
          CheckboxListTile(
              title: Text("Is Apache"),
              value: isApache,
              onChanged: (bool? value) {
                setState(() {
                  isApache = value!;
                });
              }),
          OutlinedButton(
              child: Text("Add webbackend"),
              onPressed: () {
                // Create web backend object and pass it to service to submit
                final config = WebbackendConfiguration(
                    url: selectedUrl,
                    isApache: isApache,
                    isHttp: isHttp,
                    removePrefix: removePrefix,
                    port: selectedPort);

                WebbackendService.createWebbackend(
                  context: context,
                    configuration: config,
                  onResponse: onResult
                );
              })
        ],
      ),
    );

    return form;
  }

}