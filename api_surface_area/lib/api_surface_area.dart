class RootClass {
  ExposedClass getExposed() => ExposedClass();
  void doSomething(AnotherExposedClass param) {}

  // This private field uses a public class.
  // The tool should NOT include InternallyUsedPublicClass when analyzing RootClass.
  final InternallyUsedPublicClass _internal = InternallyUsedPublicClass();
}

class InternallyUsedPublicClass {
  void doWork() {}
}

class ExposedClass {
  TransitiveExposedClass getTransitive() => TransitiveExposedClass();
}

class AnotherExposedClass {
  int someValue = 0;
  String someString = '';
}

class TransitiveExposedClass {
  double value = 1.0;
}

class NotExposedClass {
  void secret() {}
}
