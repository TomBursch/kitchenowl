import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/widgets/open_container_navigator.dart';

void main() {
  testWidgets('supports Hero flights and forwards the root pop',
      (tester) async {
    late BuildContext sourceContext;
    var flightStarted = false;
    String? closeResult;

    await tester.pumpWidget(
      MaterialApp(
        home: OpenContainer<String>(
          onClosed: (result) => closeResult = result,
          closedBuilder: (context, openContainer) => ElevatedButton(
            onPressed: openContainer,
            child: const Text('Open container'),
          ),
          openBuilder: (context, closeContainer) =>
              OpenContainerNavigator<String>(
            closeContainer: closeContainer,
            child: Builder(
              builder: (context) {
                sourceContext = context;
                return Scaffold(
                  body: Column(
                    children: [
                      Hero(
                        tag: 'image',
                        flightShuttleBuilder: (
                          flightContext,
                          animation,
                          flightDirection,
                          fromHeroContext,
                          toHeroContext,
                        ) {
                          flightStarted = true;
                          return const SizedBox.square(dimension: 100);
                        },
                        child: const SizedBox.square(dimension: 100),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => Scaffold(
                              body: Column(
                                children: [
                                  Hero(
                                    tag: 'image',
                                    flightShuttleBuilder: (
                                      flightContext,
                                      animation,
                                      flightDirection,
                                      fromHeroContext,
                                      toHeroContext,
                                    ) {
                                      flightStarted = true;
                                      return const SizedBox.square(
                                          dimension: 200);
                                    },
                                    child:
                                        const SizedBox.square(dimension: 200),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Back'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        child: const Text('Open photo'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open container'));
    await tester.pumpAndSettle();

    expect(ModalRoute.of(sourceContext), isA<PageRoute<String>>());
    expect(OpenContainerNavigator.isInside(sourceContext), isTrue);

    await tester.tap(find.text('Open photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(flightStarted, isTrue);

    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    Navigator.of(sourceContext).pop('updated');
    await tester.pumpAndSettle();

    expect(closeResult, 'updated');
    expect(find.text('Open container'), findsOneWidget);
  });
}
