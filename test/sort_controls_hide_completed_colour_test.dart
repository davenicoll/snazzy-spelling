import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snazzy_spelling/models/color_theme.dart';
import 'package:snazzy_spelling/providers/wordlist_provider.dart';
import 'package:snazzy_spelling/widgets/sort_controls.dart';

// Covers the regression from Trello card Frt5dUyq:
// the unchecked "hide completed" avatar icon must derive its colour from the
// active theme's `colorScheme.tertiary`, not whatever the default chip styling
// resolves `primary` to. Star Brawls and Cell Super both ship with pink-family
// primaries, which is why Star Brawls previously looked like Cell Super.
void main() {
  Widget harness(ColorTheme theme, Brightness brightness) {
    final colorScheme = theme.buildColorScheme(brightness);
    return MaterialApp(
      theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
      home: Scaffold(
        body: SortControls(
          sortField: SortField.alphabetical,
          sortDirection: SortDirection.ascending,
          onToggleSort: (_) {},
          hideCompleted: false,
          onHideCompletedChanged: (_) {},
        ),
      ),
    );
  }

  Color uncheckedAvatarColour(WidgetTester tester) {
    final iconFinder = find.descendant(
      of: find.byKey(const Key('hide-completed-chip')),
      matching: find.byIcon(Icons.check_box_outline_blank),
    );
    expect(iconFinder, findsOneWidget);
    return (tester.widget(iconFinder) as Icon).color!;
  }

  for (final theme in ColorTheme.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'unchecked hide-completed avatar uses tertiary — '
        '${theme.label} / ${brightness.name}',
        (tester) async {
          await tester.pumpWidget(harness(theme, brightness));
          final expected = theme.buildColorScheme(brightness).tertiary;
          expect(uncheckedAvatarColour(tester), expected);
        },
      );
    }
  }

  testWidgets(
    'Cell Super unchecked avatar stays in the pink family (regression guard)',
    (tester) async {
      await tester.pumpWidget(harness(ColorTheme.cellSuper, Brightness.dark));
      final colour = uncheckedAvatarColour(tester);
      // HSL hue for magenta/pink sits roughly 280–340°; both Cell Super
      // tertiary values (E426C6 dark, E426C6 light) land in that band.
      final hsl = HSLColor.fromColor(colour);
      expect(hsl.hue, inInclusiveRange(280.0, 340.0));
    },
  );

  testWidgets(
    'Star Brawls unchecked avatar is not pink (regression guard)',
    (tester) async {
      await tester.pumpWidget(harness(ColorTheme.starBrawls, Brightness.dark));
      final colour = uncheckedAvatarColour(tester);
      final hsl = HSLColor.fromColor(colour);
      // Orange tertiary F28125 → hue ~25°. Must not drift into the
      // pink/magenta band that Cell Super occupies.
      expect(
        hsl.hue < 280.0 || hsl.hue > 340.0,
        isTrue,
        reason: 'Star Brawls unchecked avatar should not read as pink '
            '(got hue ${hsl.hue}°, colour $colour)',
      );
    },
  );
}
