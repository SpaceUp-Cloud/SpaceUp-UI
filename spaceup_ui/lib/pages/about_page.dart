import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';


class AboutPageStarter extends StatefulWidget {
  @override
  AboutPage createState() => AboutPage();
}

class AboutPage extends State<AboutPageStarter> {
  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("About SpaceUp"),
      ),
      body: Markdown(
          selectable: false,
          data: _description,
          extensionSet: md.ExtensionSet(
            <md.BlockSyntax>[],
            <md.InlineSyntax>[md.EmojiSyntax()],
          ),
          onTapLink: (String txt, String? href, String title) async => {
            if(await canLaunch(href)) { await launch(href) }
          },
      )
    );

    return scaffold;
  }

}

const String _description = '''
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

Licenses:  
[SpaceUp-Ui License](https://git.iatlas.dev/SpaceUp/SpaceUp-UI)  
[SpaceUp-Server License](https://git.iatlas.dev/SpaceUp/SpaceUp-Server)
''';