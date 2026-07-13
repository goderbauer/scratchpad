import 'a2ui_framework.dart';

void main() {
  runWidget(const CounterApp(), surfaceId: 'counter');
}

class CounterApp extends StatefulWidget {
  const CounterApp({super.key});

  @override
  State<CounterApp> createState() => _CounterAppState();
}

class _CounterAppState extends State<CounterApp> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const Text('Counter App', variant: 'h2'),
          Text('Current count: $count', variant: 'h3'),
          Row(
            children: [
              Button(
                onPressed: () {
                  setState(() {
                    count--;
                  });
                },
                child: const Text('Decrement (-)'),
              ),
              Button(
                onPressed: () {
                  setState(() {
                    count++;
                  });
                },
                child: const Text('Increment (+)'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
