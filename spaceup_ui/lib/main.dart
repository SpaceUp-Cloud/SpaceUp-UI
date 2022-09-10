import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:page_transition/page_transition.dart';
import 'package:spaceup_ui/pages/about_page.dart';
import 'package:spaceup_ui/pages/domain_page.dart';
import 'package:spaceup_ui/pages/home_page.dart';
import 'package:spaceup_ui/pages/login_page.dart';
import 'package:spaceup_ui/pages/services_page.dart';
import 'package:spaceup_ui/pages/settings_page.dart';
import 'package:spaceup_ui/pages/webbackends_page.dart';
import 'package:spaceup_ui/util.dart';
import 'package:window_size/window_size.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  final util = Util();
  if (util.isDesktop && !util.isWeb && !util.isMobile) {
    final minSize = const Size(600, 700);
    final maxSize = const Size(900, 700);
    setWindowMinSize(minSize);
    setWindowMaxSize(maxSize);
  }
  runApp(MyApp(savedThemeMode: savedThemeMode));
}

class MyApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;

  // This widget is the root of your application.
  MyApp({Key? key, this.savedThemeMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: AdaptiveTheme(
        initial: savedThemeMode ?? AdaptiveThemeMode.system,
        light: ThemeConfig.lightMode,
        dark: ThemeConfig.darkMode,
        builder: (theme, darkTheme) {
          return GetMaterialApp(
            title: 'SpaceUp Client',
            debugShowCheckedModeBanner: false,
            //themeMode: ThemeMode.system,
            theme: theme,
            darkTheme: darkTheme,
            home: LoginPage(),
            initialRoute: '/',
            onGenerateRoute: (RouteSettings settings) {
              switch (settings.name) {
                case '/domains':
                  {
                    return PageTransition(
                        child: DomainPageStarter(),
                        type: PageTransitionType.leftToRight);
                  }
                case '/services':
                  {
                    return PageTransition(
                        child: ServicesPageStarter(),
                        type: PageTransitionType.leftToRight);
                  }
                case '/webbackends':
                  {
                    return PageTransition(
                        child: WebbackendsPageStarter(),
                        type: PageTransitionType.leftToRight);
                  }
                case '/settings':
                  {
                    return PageTransition(
                        child: SettingsPageStarter(),
                        type: PageTransitionType.leftToRight);
                  }
                case '/home':
                  {
                    return PageTransition(
                        child: HomePage("Home"),
                        type: PageTransitionType.leftToRight);
                  }
                case '/about':
                  {
                    return PageTransition(
                        child: AboutPageStarter(),
                        type: PageTransitionType.fade);
                  }
                case '/':
                  {
                    return PageTransition(
                        child: LoginPage(),
                        type: PageTransitionType.leftToRight);
                  }
                default:
                  {
                    return PageTransition(
                        child: LoginPage(),
                        type: PageTransitionType.leftToRight);
                  }
              }
            },
          );
        },
      ),
    );
  }
}

