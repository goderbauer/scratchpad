import 'dart:async';

import 'package:macros/macros.dart';

// ignore_for_file: deprecated_member_use

/// Creates the StatefulWidget subclass (just the empty shell) for the annotated
/// State object.
macro class Stateful implements ClassTypesMacro, ClassDeclarationsMacro, ClassDefinitionMacro {
  const Stateful();

  String _toStatefulWidgetClassName(ClassDeclaration clazz) => '\$${clazz.identifier.name}';

  @override
  FutureOr<void> buildTypesForClass(ClassDeclaration clazz, ClassTypeBuilder builder) async {
    final Identifier widget = await builder.resolveIdentifier(
      Uri.parse('package:flutter/src/widgets/framework.dart'),
      'Widget',
    );
    builder.appendInterfaces([NamedTypeAnnotationCode(name: widget)]);
    // Create StatefulWidget subclass.
    final String statefulWidgetClassName = _toStatefulWidgetClassName(clazz);
    final Identifier statefulWidget = await builder.resolveIdentifier(
      Uri.parse('package:flutter/src/widgets/framework.dart'),
      'StatefulWidget',
    );
    final Identifier statefulWidgetMacro = await builder.resolveIdentifier(
      Uri.parse('package:macros_playground/src/macro.dart'),
      'InternalStateful',
    );
    builder.declareType(
      statefulWidgetClassName,
      DeclarationCode.fromParts([
        // TODO: Pass in clazz.identifier when https://github.com/dart-lang/sdk/issues/55424 allows it.
        '@', statefulWidgetMacro, '("${clazz.library.uri}", "${clazz.identifier.name}")\n',
        'class $statefulWidgetClassName extends ', statefulWidget, ' implements ', clazz.identifier, ' {}',
      ]),
    );
  }

  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final String statefulWidgetClassName = _toStatefulWidgetClassName(clazz);
    // Private constructor for the actual State object.
    builder.declareInType(DeclarationCode.fromParts([
      '  ', clazz.identifier.name, '._();'
    ]));
    // Public forwarding constructor for the widget.
    final Identifier key = await builder.resolveIdentifier(
      Uri.parse('package:flutter/src/foundation/key.dart'),
      'Key',
    );
    final Iterable<MethodDeclaration> inputs = await _inputs(builder, clazz);
    builder.declareInType(DeclarationCode.fromParts([
      '  const factory ', clazz.identifier.name, '({\n',
      '    ', key, '? key,\n', // TODO: don't generate this if it is explicitly included in inputs below.
      for (MethodDeclaration input in inputs) ...[
        '    ', input.returnType.code, ' ',  input.identifier.name, ',\n'
      ],
      '  }) = ', statefulWidgetClassName, ';'
    ]));
    // noSuchMethod
    await _buildNoSuchMethod(builder);
  }

  @override
  FutureOr<void> buildDefinitionForClass(ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final String statefulWidgetClassName = _toStatefulWidgetClassName(clazz);
    // TODO: unify this with InternalStateful.
    final Iterable<MethodDeclaration> inputs = await _inputs(builder, clazz);
    for (MethodDeclaration input in inputs) {
      final FunctionDefinitionBuilder defBuilder = await builder.buildMethod(input.identifier);
      defBuilder.augment(FunctionBodyCode.fromParts([
        '=> (widget as ', statefulWidgetClassName, ').', input.identifier.name, ';'
      ]));
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
    builder.declareInType(DeclarationCode.fromParts([
      '  const ${clazz.identifier.name}({\n',
      '    ', key, '? key,\n', // TODO: don't generate this if it is explicitly included in inputs below.
      for (MethodDeclaration input in inputs) ...[
        '    this.',  input.identifier.name, ',\n'
      ],
      '  }) : super(key: key);\n' // TODO: Use super.key, https://github.com/dart-lang/sdk/issues/55428
    ]));
    // Fields.
    for (MethodDeclaration input in inputs) {
      builder.declareInType(DeclarationCode.fromParts([
        '  final ', input.returnType.code, ' ', input.identifier.name, ';'
      ]));
    }
    // Method: createState.
    final Identifier state = await builder.resolveIdentifier(
      Uri.parse('package:flutter/src/widgets/framework.dart'),
      'State',
    );
    builder.declareInType(DeclarationCode.fromParts([
        '\n',
        '  ', state, ' createState() => ', originalClass, '._();'
    ]));
    // noSuchMethod
    await _buildNoSuchMethod(builder);
  }
}

const Input input = Input();

class Input {
  const Input();
}

Future<void> _buildNoSuchMethod(MemberDeclarationBuilder builder) async {
  final Identifier invocation = await builder.resolveIdentifier(Uri.parse('dart:core'), 'Invocation');
  builder.declareInType(DeclarationCode.fromParts([
    '\n',
    '  noSuchMethod(', invocation, ' invocation) {\n'
    '    throw "Cannot be called";\n' // TODO: figure out what to do here, call super?
    '  }'
  ]));
}

Future<Iterable<MethodDeclaration>> _inputs(DeclarationPhaseIntrospector introspector, ClassDeclaration clazz) async {
  // TODO: check for the @input annotation and that its public
  return (await introspector.methodsOf(clazz)).where((MethodDeclaration method) => method.isGetter);
}
