import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'searchable.dart';
import 'src/text.dart';

void main() {
  runApp(const SearchInPageExample());
}

class SearchInPageExample extends StatelessWidget {
  const SearchInPageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xff6750a4),
        useMaterial3: true,
      ),
      home: const RootWidget(),
    );
  }
}

class RootWidget extends StatefulWidget {
  const RootWidget({super.key});

  @override
  State<RootWidget> createState() => _RootWidgetState();
}

class _RootWidgetState extends State<RootWidget> {
  bool showSearch = false;
  ShortcutRegistryEntry? entry;
  final TextEditingController _controller = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    entry?.dispose();
    final Intent intent = VoidCallbackIntent(() {
      setState(() {
        showSearch = true;
      });
    });
    entry = ShortcutRegistry.of(context).addAll(<ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true): intent,
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): intent,
    });
  }

  @override
  void dispose() {
    entry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchInPage(
      searchTerm: _controller,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  AppBar(
                    title: const SearchableText('Fairy Tales'),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        NavigationRail(
                          extended: true,
                          selectedIndex: 1,
                          groupAlignment: -1.0,
                          onDestinationSelected: (int index) {
                            // This is a demo, we ignore the other pages.
                          },
                          destinations: const <NavigationRailDestination>[
                            NavigationRailDestination(
                              icon: Icon(Icons.book_outlined),
                              selectedIcon: Icon(Icons.book),
                              label: SearchableText('Hänsel and Gretel'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.book_outlined),
                              selectedIcon: Icon(Icons.book),
                              label: SearchableText('Little Red-Cap'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.book_outlined),
                              selectedIcon: Icon(Icons.book),
                              label: SearchableText('Rapunzel'),
                            ),
                          ],
                        ),
                        const VerticalDivider(thickness: 1, width: 1),
                        // This is the main content.
                        const Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.all(30.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SearchableText(
                                    'Little Red-Cap',
                                    style: TextStyle(fontSize: 28),
                                  ),
                                  SizedBox(
                                    height: 15.0,
                                  ),
                                  SearchableText(story),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showSearch)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Builder(builder: (BuildContext context) {
                    final SearchConductor conductor =
                    SearchConductor.of(context);
                    return Shortcuts(
                      shortcuts: <ShortcutActivator, Intent>{
                        const SingleActivator(LogicalKeyboardKey.enter):
                        VoidCallbackIntent(
                              () {
                            conductor.next();
                          },
                        ),
                        const SingleActivator(LogicalKeyboardKey.escape):
                        VoidCallbackIntent(
                              () {
                            _controller.clear();
                            conductor.clear();
                            setState(() {
                              showSearch = false;
                            });
                          },
                        ),
                      },
                      child: ColoredBox(
                        color: Colors.grey,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: 200,
                                child: Center(
                                  child: TextField(
                                    controller: _controller,
                                    autofocus: true,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                conductor.previous();
                              },
                              icon: const Icon(Icons.expand_less),
                            ),
                            IconButton(
                              onPressed: () {
                                conductor.next();
                              },
                              icon: const Icon(Icons.expand_more),
                            ),
                            IconButton(
                              onPressed: () {
                                _controller.clear();
                                setState(() {
                                  showSearch = false;
                                });
                                conductor.clear();
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
