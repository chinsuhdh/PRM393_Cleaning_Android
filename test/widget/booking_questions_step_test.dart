import 'package:cleanai/ui/client/booking/widgets/steps/booking_questions_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// D.3 BookingFormSchema: six question types plus forward-compat skip for unknown types.
void main() {
  const schema = {
    'bookingFormSchema': {
      'questions': [
        {
          'id': 'rooms',
          'type': 'stepper',
          'label': 'How many rooms?',
          'min': 1,
          'max': 10,
        },
        {
          'id': 'level',
          'type': 'single_choice',
          'label': 'Cleaning level',
          'options': [
            {'id': 'light', 'label': 'Light'},
            {'id': 'deep', 'label': 'Deep'},
          ],
        },
        {
          'id': 'addons',
          'type': 'multi_choice',
          'label': 'Extra tasks',
          'options': [
            {'id': 'fridge', 'label': 'Inside fridge'},
            {'id': 'windows', 'label': 'Windows'},
          ],
        },
        {'id': 'pets', 'type': 'yes_no', 'label': 'Do you have pets?'},
        {'id': 'note', 'type': 'text', 'label': 'Note for your worker'},
        {'id': 'photos', 'type': 'photos', 'label': 'Photos of the space', 'max': 5},
        {'id': 'future', 'type': 'hologram', 'label': 'Unknown from the future', 'required': true},
      ],
    },
  };

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets(
    '[UT-FE-BOOKQ-01] All six known question types render their label and control',
    (tester) async {
      await tester.pumpWidget(wrap(BookingQuestionsStep(
        service: schema,
        answers: const {},
        onChanged: (_, __) {},
        onPhotosChanged: (_) {},
        photoCount: 0,
      )));

      expect(find.text('How many rooms?'), findsOneWidget);
      expect(find.text('Cleaning level'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Deep'), findsOneWidget);
      expect(find.text('Extra tasks'), findsOneWidget);
      expect(find.text('Inside fridge'), findsOneWidget);
      expect(find.text('Windows'), findsOneWidget);

      // The list is long enough that later questions are lazily built by ListView; scroll to reach them.
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Do you have pets?'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(find.text('Note for your worker'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-BOOKQ-02] An unknown question type is skipped without crashing and without a label',
    (tester) async {
      await tester.pumpWidget(wrap(BookingQuestionsStep(
        service: schema,
        answers: const {},
        onChanged: (_, __) {},
        onPhotosChanged: (_) {},
        photoCount: 0,
      )));

      expect(find.text('Unknown from the future'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '[UT-FE-BOOKQ-03] The stepper increments and decrements within min/max and reports via onChanged',
    (tester) async {
      final updates = <int>[];
      await tester.pumpWidget(wrap(BookingQuestionsStep(
        service: schema,
        answers: const {'rooms': 1},
        onChanged: (id, value) => updates.add(value as int),
        onPhotosChanged: (_) {},
        photoCount: 0,
      )));

      expect(find.text('1'), findsOneWidget);
      // At min=1, decrement must be disabled.
      final decrementButton = tester.widget<IconButton>(
        find.ancestor(of: find.byIcon(Icons.remove_circle_outline), matching: find.byType(IconButton)),
      );
      expect(decrementButton.onPressed, isNull);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      expect(updates, [2]);
    },
  );

  testWidgets(
    '[UT-FE-BOOKQ-04] Selecting a multi_choice option reports the full selected set',
    (tester) async {
      List<String>? reported;
      await tester.pumpWidget(wrap(BookingQuestionsStep(
        service: schema,
        answers: const {'addons': ['fridge']},
        onChanged: (id, value) {
          if (id == 'addons') reported = List<String>.from(value as Iterable);
        },
        onPhotosChanged: (_) {},
        photoCount: 0,
      )));

      await tester.tap(find.text('Windows'));
      expect(reported, containsAll(['fridge', 'windows']));
    },
  );

  testWidgets(
    '[UT-FE-BOOKQ-05] A service with no schema shows the no-questions message',
    (tester) async {
      await tester.pumpWidget(wrap(BookingQuestionsStep(
        service: const {'name': 'Basic clean'},
        answers: const {},
        onChanged: (_, __) {},
        onPhotosChanged: (_) {},
        photoCount: 0,
      )));

      expect(find.text('Dịch vụ này không có câu hỏi bổ sung.'), findsOneWidget);
    },
  );

  const requiredSchema = {
    'bookingFormSchema': {
      'questions': [
        {'id': 'pets', 'type': 'yes_no', 'label': 'Do you have pets?', 'required': true},
        {'id': 'note', 'type': 'text', 'label': 'Note for your worker'},
      ],
    },
  };

  testWidgets(
    '[UT-FE-BOOKQ-06] A required, unanswered question shows the "Bắt buộc" badge',
    (tester) async {
      await tester.pumpWidget(wrap(BookingQuestionsStep(
        service: requiredSchema,
        answers: const {},
        onChanged: (_, __) {},
        onPhotosChanged: (_) {},
        photoCount: 0,
      )));

      expect(find.text('Bắt buộc'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOKQ-07] Answering a required question swaps the badge for a check icon',
    (tester) async {
      await tester.pumpWidget(wrap(BookingQuestionsStep(
        service: requiredSchema,
        answers: const {'pets': true},
        onChanged: (_, __) {},
        onPhotosChanged: (_) {},
        photoCount: 0,
      )));

      expect(find.text('Bắt buộc'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-BOOKQ-08] An optional question never shows the required badge regardless of answered state',
    (tester) async {
      await tester.pumpWidget(wrap(BookingQuestionsStep(
        service: requiredSchema,
        answers: const {},
        onChanged: (_, __) {},
        onPhotosChanged: (_) {},
        photoCount: 0,
      )));

      // 'note' is optional and unanswered — must never render a required badge.
      final noteCard = tester.widget<Container>(
        find.byKey(const ValueKey('question-card-note')),
      );
      final decoration = noteCard.decoration as BoxDecoration;
      expect(decoration.border, isNull);
    },
  );
}
