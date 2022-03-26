import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:spaceup_ui/SUGradient.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';


class AboutPageStarter extends StatefulWidget {
  @override
  AboutPage createState() => AboutPage();
}

class AboutPage extends State<AboutPageStarter> {

  @override
  void initState() {
    super.initState();

    _getAboutText();

  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("About SpaceUp"),
        flexibleSpace: SUGradient.gradientContainer,
      ),
      body: FutureBuilder(
        future: _getAboutText(),
        builder: (context, AsyncSnapshot<String> snapshot) {
          if(snapshot.hasData && snapshot.data != null) {
            return Markdown(
              selectable: false,
              data: snapshot.data as String,
              extensionSet: md.ExtensionSet(
                <md.BlockSyntax>[],
                <md.InlineSyntax>[md.EmojiSyntax()],
              ),
              onTapLink: (String txt, String? href, String title) async => {
                if(await canLaunch(href!)) { await launch(href) }
              },
            );
          } else {
            return Container(
              child: CircularProgressIndicator(),
            );
          }
        },
      )
    );

    return scaffold;
  }

  Future<String> _getAboutText() async {
    String server = "";
    await Settings().getString("server", "").then((value) => server = value!);

    var _description = '''
### SpaceUp is an opensource solution to handle your webservices on your webhoster easily!  

### Features
* Control your supervisor services
* Add and delete domains
* Watch the logs from your services
* Have a look your quota space
* REST API to easily adapt and overcome
* Safely stored credentials for Login and SSH
* And many will follow! :smiley:
  * Native builds for SpaceUp-Server
  * Handle web backends (uberspace web commands)
  * Handle mail (uberspace mail commands)
  * Self-Updating JAR
  * ...
---
\u00A9 2022 Gino Atlas <thraax.session@iatlas.technology>

For documentations open the [website]($server) of your installed SpaceUp.

Licenses:  

[SpaceUp-Ui License](https://git.iatlas.dev/SpaceUp/SpaceUp-UI)  
  
[SpaceUp-Server License](https://git.iatlas.dev/SpaceUp/SpaceUp-Server)
''';

    return _description;
  }

}

