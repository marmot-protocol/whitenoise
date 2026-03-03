import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/theme.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'main.directories.g.dart';

@widgetbook.App()
void main() {
  runApp(const WidgetbookApp());
}

class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      initialRoute: '?path=introduction/resources',
      addons: [
        InspectorAddon(),
        ThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light', data: lightTheme),
            WidgetbookTheme(name: 'Dark', data: darkTheme),
          ],
          themeBuilder: (context, theme, child) {
            return ScreenUtilInit(
              designSize: const Size(420, 912),
              minTextAdapt: true,
              enableScaleWH: () => false,
              enableScaleText: () => false,
              child: Localizations(
                locale: const Locale('en'),
                delegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                child: Theme(data: theme, child: child),
              ),
            );
          },
        ),
      ],
      directories: directories,
    );
  }
}
