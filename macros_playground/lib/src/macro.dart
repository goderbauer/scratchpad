import 'dart:async';

import 'package:macros/macros.dart';

// TODO: How to avoid using deprecated builder.resolveIdentifier API?
// ignore_for_file: deprecated_member_use

/// Creates the StatefulWidget subclass (without body) and fills in missing
/// pieces (constructors, body for @Input getter) in annotated State subclass.
///
/// The body of the generated StatefulWidget subclass is filled in by the
/// [InternalStateful] macro.
macro class Stateful implements ClassTypesMacro, ClassDeclarationsMacro, ClassDefinitionMacro {
  const Stateful();

  String _toStatefulWidgetClassName(ClassDeclaration clazz) => '\$${clazz.identifier.name}';

  /// Introduces the StatefulWidget subclass (without any body) and adds
  /// "implements Widget" to State subclass.
  ///
  /// The body of the generated StatefulWidget subclass is filled in by the
  /// [InternalStateful] macro.
  @override
  FutureOr<void> buildTypesForClass(ClassDeclaration clazz, ClassTypeBuilder builder) async {
    // Add "implements StatefulWidget" to State subclass.
    final Identifier statefulWidget = await builder.resolveIdentifier(
      Uri.parse('package:flutter/src/widgets/framework.dart'),
      'StatefulWidget',
    );
    builder.appendInterfaces([NamedTypeAnnotationCode(name: statefulWidget)]);
    // Create StatefulWidget subclass.
    final String statefulWidgetClassName = _toStatefulWidgetClassName(clazz);
    final Identifier statefulWidgetMacro = await builder.resolveIdentifier(
      Uri.parse('package:macros_playground/src/macro.dart'),
      'InternalStateful',
    );
    builder.declareType(
      statefulWidgetClassName,
      DeclarationCode.fromParts([
        // TODO: Pass in clazz.identifier when https://github.com/dart-lang/sdk/issues/55424 allows it.
        '@', statefulWidgetMacro, '("${clazz.library.uri}", "${clazz.identifier.name}")\n',
        'class $statefulWidgetClassName extends ', statefulWidget, ' implements ', clazz.identifier, ' {}\n',
      ]),
    );
  }

  /// Adds constructors and noSuchMethod to annotated State subclass.
  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final String statefulWidgetClassName = _toStatefulWidgetClassName(clazz);
    final String stateClassName = clazz.identifier.name;
    // Private constructor for the actual State object.
    builder.declareInType(DeclarationCode.fromString('$stateClassName._();\n'));
    // Public forwarding constructor for the widget.
    final Identifier key = await builder.resolveIdentifier(
      Uri.parse('package:flutter/src/foundation/key.dart'),
      'Key',
    );
    List<Object> toConstructorArg(MethodDeclaration input) {
      final Iterable<ExpressionCode> positionalArgs = _inputAnnotation(input).positionalArguments;
      if (positionalArgs.isNotEmpty) {
        return ['  ', input.returnType.code, ' ${input.identifier.name},\n'];
      }
      return ['  required ', input.returnType.code, ' ${input.identifier.name},\n'];
    }
    final Iterable<MethodDeclaration> inputs = await _inputs(builder, clazz);
    builder.declareInType(DeclarationCode.fromParts([
      'const factory $stateClassName({\n',
      '  ', key, '? key,\n', // TODO: don't generate this if it is explicitly included in inputs below.
      for (MethodDeclaration input in inputs)
        ...toConstructorArg(input),
      '}) = $statefulWidgetClassName;'
    ]));
    // noSuchMethod
    await _buildNoSuchMethod(builder);
  }

  /// Fills in body for @Input getters in annotated State subclass.
  @override
  FutureOr<void> buildDefinitionForClass(ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final String statefulWidgetClassName = _toStatefulWidgetClassName(clazz);
    final Iterable<MethodDeclaration> inputs = await _inputs(builder, clazz);
    for (MethodDeclaration input in inputs) {
      final FunctionDefinitionBuilder defBuilder = await builder.buildMethod(input.identifier);
      defBuilder.augment(FunctionBodyCode.fromString(
        '=> (widget as $statefulWidgetClassName).${input.identifier.name};',
      ));
    }
  }
}

/// Fills the annotated StatefulWidget subclass with content (constructor,
/// fields, methods).
// TODO: Would be nice to keep this private since it is only used internally.
macro class InternalStateful implements ClassDeclarationsMacro {
  const InternalStateful(this.originalLibrary, this.originalClassName);

  final String originalLibrary;
  final String originalClassName;

  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final Identifier originalClass = await builder.resolveIdentifier(Uri.parse(originalLibrary), originalClassName);
    final ClassDeclaration stateClass = await builder.typeDeclarationOf(originalClass) as ClassDeclaration;
    final Iterable<MethodDeclaration> inputs = await _inputs(builder, stateClass);
    // Constructor.
    final Identifier key = await builder.resolveIdentifier(
      Uri.parse('package:flutter/src/foundation/key.dart'),
      'Key',
    );
    List<Object> toConstructorArg(MethodDeclaration input) {
      final Iterable<ExpressionCode> positionalArgs = _inputAnnotation(input).positionalArguments;
      if (positionalArgs.isNotEmpty) {
        return ['  this.${input.identifier.name} = ', positionalArgs.first, ',\n'];
      }
      return ['  required this.${input.identifier.name},\n'];
    }
    builder.declareInType(DeclarationCode.fromParts([
      'const ${clazz.identifier.name}({\n',
      '  ', key, '? key,\n', // TODO: don't generate this if it is explicitly included in inputs below.
      for (MethodDeclaration input in inputs)
        ...toConstructorArg(input),
      '}) : super(key: key);\n' // TODO: Use super.key, https://github.com/dart-lang/sdk/issues/55428
    ]));
    // Fields.
    for (MethodDeclaration input in inputs) {
      builder.declareInType(DeclarationCode.fromParts([
        'final ', input.returnType.code, ' ${input.identifier.name};',
      ]));
    }
    // noSuchMethod
    await _buildNoSuchMethod(builder);
    // Method: createState.
    final Identifier state = await builder.resolveIdentifier(
      Uri.parse('package:flutter/src/widgets/framework.dart'),
      'State',
    );
    builder.declareInType(DeclarationCode.fromParts([
      state, ' createState() => ', originalClass, '._();'
    ]));
  }
}

/// Fills in missing pieces (constructors, body for @Input getter) in annotated
/// StatelessWidget subclass.
macro class Stateless implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const Stateless();

  /// Adds constructors and fields for @Input's to annotated StatelessWidget subclass.
  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final Iterable<MethodDeclaration> inputs = await _inputs(builder, clazz);
    // Constructor.
    final Identifier key = await builder.resolveIdentifier(
      Uri.parse('package:flutter/src/foundation/key.dart'),
      'Key',
    );
    List<Object> toConstructorArg(MethodDeclaration input) {
      final Iterable<ExpressionCode> positionalArgs = _inputAnnotation(input).positionalArguments;
      if (positionalArgs.isNotEmpty) {
        return ['  ', input.returnType.code, ' ${input.identifier.name} = ', positionalArgs.first, ',\n'];
      }
      return ['  required ', input.returnType.code, ' ${input.identifier.name},\n'];
    }
    builder.declareInType(DeclarationCode.fromParts([
      'const ${clazz.identifier.name}({\n',
      '  ', key, '? key,\n', // TODO: don't generate this if it is explicitly included in inputs below.
      for (MethodDeclaration input in inputs)
        ...toConstructorArg(input),
      '}) : ',
      for (MethodDeclaration input in inputs) ...[
        '  _${input.identifier.name} = ${input.identifier.name},\n'
      ],
      '  super(key: key);\n' // TODO: Use super.key, https://github.com/dart-lang/sdk/issues/55428
    ]));
    // Fields.
    for (MethodDeclaration input in inputs) {
      builder.declareInType(DeclarationCode.fromParts([
        'final ', input.returnType.code, ' _${input.identifier.name};'
      ]));
    }
  }

  /// Fills in body for @Input getters in StatelessWidget subclass.
  @override
  FutureOr<void> buildDefinitionForClass(ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final Iterable<MethodDeclaration> inputs = await _inputs(builder, clazz);
    for (MethodDeclaration input in inputs) {
      final FunctionDefinitionBuilder defBuilder = await builder.buildMethod(input.identifier);
      defBuilder.augment(FunctionBodyCode.fromString(
        '=> _${input.identifier.name};',
      ));
    }
  }
}

class Input {
  const Input([Object? defaultValue]);
}

Future<void> _buildNoSuchMethod(MemberDeclarationBuilder builder) async {
  final Identifier invocation = await builder.resolveIdentifier(Uri.parse('dart:core'), 'Invocation');
  builder.declareInType(DeclarationCode.fromParts([
    '\n',
    'noSuchMethod(', invocation, ' invocation) {\n',
    '  throw "Cannot be called";\n', // TODO: figure out what to do here, call super?
    '}\n',
  ]));
}

Future<Iterable<MethodDeclaration>> _inputs(DeclarationPhaseIntrospector introspector, ClassDeclaration clazz) async {
  // TODO: check for the @Input annotation and that its public.
  return (await introspector.methodsOf(clazz)).where((MethodDeclaration method) => method.isGetter);
}

ConstructorMetadataAnnotation _inputAnnotation(MethodDeclaration input) {
  // TODO: check that the metadata is actually an Input annotation.
  return input.metadata.single as ConstructorMetadataAnnotation;
}
