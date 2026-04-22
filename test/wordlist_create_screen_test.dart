import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:snazzy_spelling/providers/wordlist_provider.dart';
import 'package:snazzy_spelling/screens/settings/wordlist_create_screen.dart';

void main() {
  group('WordlistCreateScreen — name field initial state', () {
    testWidgets('opens with an empty title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<WordlistProvider>(
            create: (_) => WordlistProvider(),
            child: const WordlistCreateScreen(),
          ),
        ),
      );

      final nameField = find.widgetWithText(TextField, 'Wordlist Name');
      expect(nameField, findsOneWidget);

      final TextField field = tester.widget(nameField);
      expect(field.controller!.text, isEmpty,
          reason: 'Title field should not be pre-populated with a date or any other value.');
    });

    testWidgets('renders a subtle placeholder on the title field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<WordlistProvider>(
            create: (_) => WordlistProvider(),
            child: const WordlistCreateScreen(),
          ),
        ),
      );

      final TextField field = tester.widget(
        find.widgetWithText(TextField, 'Wordlist Name'),
      );
      expect(field.decoration?.hintText, 'Wordlist title');
    });

    testWidgets('save button is disabled when title is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<WordlistProvider>(
            create: (_) => WordlistProvider(),
            child: const WordlistCreateScreen(),
          ),
        ),
      );

      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save Wordlist'),
      );
      expect(saveButton.onPressed, isNull,
          reason: 'An empty title must keep the save button disabled.');
    });
  });
}
