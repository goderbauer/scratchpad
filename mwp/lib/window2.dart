import 'package:flutter/material.dart';

class Window extends StatefulWidget {
  const Window({super.key, this.controller, required this.child});

  final WindowController? controller;
  final Widget child;

  @override
  State<Window> createState() => _WindowState();
}

class _WindowState extends State<Window> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class WindowController extends ChangeNotifier {
  WindowController({
    BoxConstraints constraints = const BoxConstraints.tightFor(width: 400, height: 800),
  }) : _requestedConfiguration = _WindowConfigurationRequest(constraints: constraints);

  _WindowConfigurationRequest _requestedConfiguration;
  _WindowConfiguration? _configuration;

  bool get isAttached => _configuration != null;

  Size get size => _configuration!.size;
}

@immutable
class _WindowConfigurationRequest {
  const _WindowConfigurationRequest({
    this.constraints,
  });

  final BoxConstraints? constraints;
}

@immutable
class _WindowConfiguration {
  const _WindowConfiguration({
    required this.size,
  });

  final Size size;
}
