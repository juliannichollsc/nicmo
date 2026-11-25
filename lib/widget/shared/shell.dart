import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/app_info.dart';
import 'package:nicmo/widget/shared/lightdark.dart';
import 'package:nicmo/widget/shared/menu.dart';

/// Scaffold of the shell: lets other screens close the side menu (e.g.
/// after switching city from the cities screen pushed over it).
final GlobalKey<ScaffoldState> appScaffoldKey = GlobalKey<ScaffoldState>();

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.appBarTheme.foregroundColor ?? Colors.white;
    final currentIndex = navigationShell.currentIndex;
    // The map is full screen, under the status bar, with its own floating
    // menu button; settings keeps a title bar.
    final isMap = currentIndex == 0;
    final isDark = theme.brightness == Brightness.dark;

    final scaffold = Scaffold(
      key: appScaffoldKey,
      drawer: const MenuWidget(),
      appBar: isMap
          ? null
          : AppBar(
              leading: Builder(
                builder: (ctx) => IconButton(
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  icon: Icon(Icons.menu, color: iconColor),
                ),
              ),
              centerTitle: true,
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  _title(context, currentIndex),
                  key: ValueKey(currentIndex),
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(themeBackground(context)),
            fit: BoxFit.cover,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(top: !isMap, child: navigationShell),
      ),
    );
    // Always wrapped (same tree on every tab, so the shell keeps its state);
    // on the other tabs the app bar sets the status bar style itself.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Transparent status bar over the map, icons readable on its theme.
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: scaffold,
    );
  }

  String _title(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    switch (index) {
      case 1:
        return l10n.settings;
      default:
        return kAppName;
    }
  }
}
