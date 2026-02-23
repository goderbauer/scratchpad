class RootClass {
  ExposedClass getExposed() => ExposedClass();
  void doSomething(AnotherExposedClass param) {}
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
