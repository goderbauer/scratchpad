import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    print('Usage: api_surface_area <path_to_codebase> <class_name>');
    exit(1);
  }

  final rootPath = p.canonicalize(args[0]);
  final className = args[1];

  if (!Directory(rootPath).existsSync()) {
    print('Error: Directory does not exist: $rootPath');
    exit(1);
  }

  print('Analyzing codebase at $rootPath...');
  final collection = AnalysisContextCollection(includedPaths: [rootPath]);
  final context = collection.contextFor(rootPath);
  final session = context.currentSession;

  final classElement = await _findClassElement(context, session, className);
  if (classElement == null) {
    print('Error: Class "$className" not found in the codebase.');
    exit(1);
  }

  print('Found class "${classElement.displayName}" in ${classElement.library.uri}');
  print('Collecting exposed types transitively...');

  final collector = _TypeCollector();
  collector.collect(classElement.thisType);

  final results = collector.exposedElements.toList();
  final grouped = <String, List<Element>>{};
  for (final element in results) {
    final libraryUri = element.library?.uri.toString() ?? 'unknown';
    grouped.putIfAbsent(libraryUri, () => []).add(element);
  }

  final sortedLibraries = grouped.keys.toList()..sort();

  print('\nExposed types by library:');
  for (final libraryUri in sortedLibraries) {
    print('\n$libraryUri:');
    final elements = grouped[libraryUri]!
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    for (final element in elements) {
      print('- ${element.displayName}');
    }
  }
}

Future<InterfaceElement?> _findClassElement(
    AnalysisContext context, AnalysisSession session, String className) async {
  for (final filePath in context.contextRoot.analyzedFiles()) {
    if (!filePath.endsWith('.dart')) continue;

    final unitResult = await session.getUnitElement(filePath);
    if (unitResult is! UnitElementResult) continue;

    final library = unitResult.fragment.element;
    for (final clazz in library.classes) {
      if (clazz.name == className) return clazz;
    }
    for (final mixin in library.mixins) {
      if (mixin.name == className) return mixin;
    }
    for (final enum_ in library.enums) {
       if (enum_.name == className) return enum_;
    }
  }
  return null;
}

class _TypeCollector {
  final Set<Element> exposedElements = {};
  final Set<Element> _visited = {};

  void collect(DartType? type) {
    if (type == null) return;

    if (type is InterfaceType) {
      _processElement(type.element);
      for (final arg in type.typeArguments) {
        collect(arg);
      }
    } else if (type is FunctionType) {
      collect(type.returnType);
      for (final param in type.formalParameters) {
        collect(param.type);
      }
    } else if (type is TypeParameterType) {
      _processElement(type.element);
      collect(type.bound);
    } else if (type is RecordType) {
      for (final field in type.positionalFields) {
        collect(field.type);
      }
      for (final field in type.namedFields) {
        collect(field.type);
      }
    }
  }

  void _processElement(Element? element) {
    if (element == null) return;
    if (_visited.contains(element)) return;
    _visited.add(element);

    if (element.isPrivate) return;

    // We consider it exposed if it's a named type (Class, Enum, Mixin, Typedef, etc.)
    if (element is InterfaceElement || element is TypeAliasElement || element is EnumElement) {
       exposedElements.add(element);
    }

    if (element is InterfaceElement) {
      // Methods
      for (final method in element.methods.where((m) => !m.isPrivate)) {
        collect(method.returnType);
        for (final param in method.formalParameters) {
          collect(param.type);
        }
      }
      // Fields
      for (final field in element.fields.where((f) => !f.isPrivate)) {
        collect(field.type);
      }
      // Getters
      for (final getter in element.getters.where((g) => !g.isPrivate)) {
        collect(getter.returnType);
      }
      // Setters
      for (final setter in element.setters.where((s) => !s.isPrivate)) {
        for (final param in setter.formalParameters) {
          collect(param.type);
        }
      }
      // Constructors
      for (final constructor in element.constructors.where((c) => !c.isPrivate)) {
        for (final param in constructor.formalParameters) {
          collect(param.type);
        }
      }
      // Supertypes
      for (final superType in element.allSupertypes) {
        collect(superType);
      }
    } else if (element is TypeAliasElement) {
      collect(element.aliasedType);
    }
  }
}
