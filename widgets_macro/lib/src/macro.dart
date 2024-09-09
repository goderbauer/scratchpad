import 'dart:async';

import 'package:macros/macros.dart';

macro class Stateless implements ClassTypesMacro, ClassDeclarationsMacro, ClassDefinitionMacro {
  const Stateless();

  @override
  FutureOr<void> buildTypesForClass(ClassDeclaration clazz, ClassTypeBuilder builder) async {
    await addExtends(builder, 'StatelessWidget');
  }

  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    await addFieldsForConstructorParams(builder, clazz);
  }

  @override
  FutureOr<void> buildDefinitionForClass(ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    await assignConstructorParamsToFields(builder, clazz);
  }
}

macro class Stateful implements ClassTypesMacro, ClassDeclarationsMacro, ClassDefinitionMacro {
  const Stateful(this.stateClass);

  final String stateClass;

  @override
  FutureOr<void> buildTypesForClass(ClassDeclaration clazz, ClassTypeBuilder builder) async {
    await addExtends(builder, 'StatefulWidget');
  }

  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    await addFieldsForConstructorParams(builder, clazz);

    // Method: createState.
    final Identifier state = await builder.resolveIdentifier(
      Uri.parse('package:flutter/src/widgets/framework.dart'),
      'State',
    );
    builder.declareInType(DeclarationCode.fromParts([
      '  ', state, '<${clazz.identifier.name}> createState() => ', '$stateClass();'
    ]));
  }

  @override
  FutureOr<void> buildDefinitionForClass(ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    await assignConstructorParamsToFields(builder, clazz);
  }
}


// TODO: the macro could really use inheritance, but analyzer crashes.


Future<void> addExtends(ClassTypeBuilder builder, String superclass) async {
  final Identifier statelessWidget = await builder.resolveIdentifier(
    Uri.parse('package:flutter/src/widgets/framework.dart'),
    superclass,
  );
  builder.extendsType(NamedTypeAnnotationCode(name: statelessWidget));
}

Future<void> addFieldsForConstructorParams(MemberDeclarationBuilder builder, ClassDeclaration clazz) async {
  final List<ConstructorDeclaration> constructors = await builder.constructorsOf(clazz);
  // TODO: deal with other constructors and positional arguments.
  for (FormalParameterDeclaration param in constructors.first.namedParameters) {
    if (paramNeedsAugmentation(param)) {
      builder.declareInType(DeclarationCode.fromParts([
        '  final ', param.type.code, ' ', param.identifier, ';'
      ]));
    }
  }
}

Future<void> assignConstructorParamsToFields(TypeDefinitionBuilder builder, ClassDeclaration clazz) async {
  final List<ConstructorDeclaration> constructors = await builder.constructorsOf(clazz);
  // TODO: deal with other constructors.
  final ConstructorDefinitionBuilder constructorBuilder = await builder.buildConstructor(constructors.first.identifier);
  constructorBuilder.augment(initializers: [
    // TODO: deal with positional arguments
    for (FormalParameterDeclaration param in constructors.first.namedParameters)
      if (paramNeedsAugmentation(param))
        DeclarationCode.fromParts([param.identifier, ' = ', param.identifier]),
  ]);
}

bool paramNeedsAugmentation(FormalParameterDeclaration param) {
  return switch (param.style) {
    ParameterStyle.normal => true,
    ParameterStyle.fieldFormal => false,
    ParameterStyle.superFormal => false,
  };
}