# API Surface Area Tool

A Dart command-line tool that analyzes a codebase and transitively collects all publicly exposed types for a given set of classes or the entire package.

## Features

- **Transitive Collection:** Identifies types used as return types, parameters, fields, and superclasses, following them recursively to find the full API surface.
- **Multiple Modes:**
  - **Full Package Mode:** Analyzes all public types in the package (excluding the `test/` directory).
  - **Class Entry Points:** Analyzes only the API reachable from one or more specified classes.
- **Grouped Summaries:**
  - Provides a count of exposed types per package.
  - Lists all exposed types grouped by their defining library URI.
- **Visualization:**
  - Generates a Graphviz-compatible **DOT file** to visualize the transitive relationships between types.
  - Option to hide `dart:` SDK types from the graph for a cleaner view of your custom API.

## Setup

Ensure you have the Dart SDK installed. Clone the repository and fetch dependencies:

```bash
dart pub get
```

## Usage

```bash
dart bin/api_surface_area.dart <path_to_codebase> [class_name1 class_name2 ...] [options]
```

### Options

- `-d, --dot-file=<path>`: Path to output a DOT file for visualization.
- `--hide-dart`: Hide types from the `dart:` SDK in the relationship graph (DOT file).

## Examples

### 1. Analyze the entire package
Collects all types reachable from any public class in `lib/`:

```bash
dart bin/api_surface_area.dart .
```

### 2. Analyze a specific class and its dependencies
Traces everything exposed by `RootClass`:

```bash
dart bin/api_surface_area.dart . RootClass
```

### 3. Generate a visualization graph
Creates a DOT file of the transitive API surface, hiding standard `dart:` types:

```bash
dart bin/api_surface_area.dart . RootClass --hide-dart --dot-file api_surface.dot
```

To convert the DOT file to an image (requires [Graphviz](https://graphviz.org/)):
```bash
dot -Tpng api_surface.dot -o api_surface.png
```

## How it Works

The tool uses `package:analyzer` to build an element model of the target codebase. It identifies the root elements (either specified classes or all public elements in the source tree) and then recursively visits their public signatures:
- Method return types and parameter types.
- Field types.
- Getter/Setter types.
- Constructor parameter types.
- Supertypes (classes, mixins, interfaces).
- Generic type arguments (e.g., `T` in `List<T>`).
- Function type components.
- Record type fields.

Only public members and non-private types are considered as part of the public API surface.
