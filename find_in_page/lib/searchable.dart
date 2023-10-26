import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

class SearchableText extends StatefulWidget {
  const SearchableText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  State<SearchableText> createState() => _SearchableTextState();
}

class _SearchableTextState extends State<SearchableText> implements Searchable {
  List<TextSpan>? _children;
  List<String> _pieces = <String>[];

  SearchConductor? _searchConductor;
  int? _activeIndex;
  String? _searchTerm;

  @override
  void initState() {
    super.initState();
    _updateChildren();
  }

  @override
  void didUpdateWidget(SearchableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      throw UnimplementedError('Changing text is not implemented.');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final SearchConductor newConductor = SearchConductor.of(context);
    if (_searchConductor != newConductor) {
      _searchConductor?.unregister(this);
      newConductor.register(this);
      // TODO: Tell new conductor about hits.
    }
  }

  @override
  void dispose() {
    _searchConductor?.unregister(this);
    super.dispose();
  }

  @override
  void clear() {
    setState(() {
      _searchTerm = null;
      _children = null;
      _activeIndex = null;
      _pieces = <String>[];
    });
  }

  @override
  int searchFor(String term) {
    setState(() {
      _pieces = widget.text.split(term);
      _searchTerm = term;
      _children = null;
      _activeIndex = null;
    });
    return _pieces.length - 1;
  }

  @override
  bool next() {
    int newIndex = _activeIndex == null ? 0 : _activeIndex! + 1;
    if (newIndex >= _pieces.length - 1) {
      if (_activeIndex != null) {
        setState(() {
          _children = null;
          _activeIndex = null;
        });
      }
      return false;
    }
    setState(() {
      _children = null;
      _activeIndex = newIndex;
    });
    _ensureVisible();
    return true;
  }

  @override
  bool previous() {
    int newIndex =
        _activeIndex == null ? _pieces.length - 2 : _activeIndex! - 1;
    if (newIndex < 0) {
      if (_activeIndex != null) {
        setState(() {
          _children = null;
          _activeIndex = null;
        });
      }
      return false;
    }
    setState(() {
      _children = null;
      _activeIndex = newIndex;
    });
    _ensureVisible();
    return true;
  }

  bool _scheduled = false;

  void _ensureVisible() {
    if (_scheduled) {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _scheduled = false;
      if (!mounted) {
        return;
      }
      final RenderParagraph paragraph =
          context.findRenderObject()! as RenderParagraph;
      int start = _children!
          .sublist(0, _activeIndex! * 2 + 1)
          .fold(0, (int i, TextSpan span) => i + span.text!.length);

      List<TextBox> boxes = paragraph.getBoxesForSelection(
        TextSelection(
          baseOffset: start,
          extentOffset: start + _children![_activeIndex! * 2 + 1].text!.length,
        ),
      );
      final Rect? boundingBox = boxes.fold<Rect?>(
        null,
        (Rect? rect, TextBox box) =>
            rect?.expandToInclude(box.toRect()) ?? box.toRect(),
      );
      paragraph.showOnScreen(rect: boundingBox!);
    });
    _scheduled = true;
  }

  void _updateChildren() {
    final List<TextSpan> children = <TextSpan>[];
    if (_pieces.isEmpty) {
      children.add(TextSpan(
        text: widget.text,
        style: widget.style,
      ));
      _children = children;
      return;
    }
    int index = 0;
    for (String piece in _pieces) {
      children.add(TextSpan(
        text: piece,
        style: widget.style,
      ));
      final Color highlight =
          index == _activeIndex ? Colors.yellow : Colors.grey;
      children.add(TextSpan(
        text: _searchTerm,
        style: widget.style?.copyWith(backgroundColor: highlight) ??
            TextStyle(backgroundColor: highlight),
      ));
      index++;
    }
    children.removeLast();
    _children = children;
  }

  @override
  Widget build(BuildContext context) {
    if (_children == null) {
      _updateChildren();
    }
    return Text.rich(TextSpan(children: _children));
  }
}

class SearchInPage extends StatefulWidget {
  const SearchInPage({
    super.key,
    required this.child,
    required this.searchTerm,
  });

  final Widget child;
  final TextEditingController searchTerm;

  @override
  State<SearchInPage> createState() => _SearchInPageState();
}

class _SearchInPageState extends State<SearchInPage>
    implements SearchConductor {
  final List<Searchable> _searchables = <Searchable>[];
  Searchable? _currentActive;

  @override
  void initState() {
    super.initState();
    widget.searchTerm.addListener(_handleSearch);
    // TODO: implement didUpdateWidget
  }

  @override
  void dispose() {
    widget.searchTerm.removeListener(_handleSearch);
    super.dispose();
  }

  void _handleSearch() {
    if (widget.searchTerm.value.text.isEmpty) {
      for (final Searchable searchable in _searchables) {
        searchable.clear();
      }
      return;
    }
    bool needsNext = true;
    for (final Searchable searchable in _searchables) {
      searchable.searchFor(widget.searchTerm.value.text);
      if (needsNext) {
        needsNext = !searchable.next();
        if (!needsNext) {
          _currentActive = searchable;
        }
      }
    }
  }

  @override
  void next() {
    final List<Searchable> searchSpace;
    if (_currentActive == null) {
      searchSpace = _searchables;
    } else {
      int activeIndex = _searchables.indexOf(_currentActive!);
      searchSpace = [
        _currentActive!,
        ..._searchables.sublist(activeIndex + 1),
        ..._searchables.sublist(0, activeIndex)
      ];
    }
    bool needsNext = true;
    for (final Searchable searchable in searchSpace) {
      if (needsNext) {
        needsNext = !searchable.next();
        if (!needsNext) {
          _currentActive = searchable;
          break;
        }
      }
    }
  }

  @override
  void previous() {
    final List<Searchable> searchSpace;
    if (_currentActive == null) {
      searchSpace = _searchables;
    } else {
      int activeIndex = _searchables.indexOf(_currentActive!);
      searchSpace = [
        ..._searchables.sublist(activeIndex + 1),
        ..._searchables.sublist(0, activeIndex),
        _currentActive!,
      ];
    }
    bool needsNext = true;
    for (final Searchable searchable in searchSpace.reversed) {
      if (needsNext) {
        needsNext = !searchable.previous();
        if (!needsNext) {
          _currentActive = searchable;
          break;
        }
      }
    }
  }

  @override
  void clear() {
    _currentActive = null;
    for (final Searchable searchable in _searchables) {
      searchable.clear();
    }
  }

  @override
  void register(Searchable searchable) {
    _searchables.add(searchable);
  }

  @override
  void unregister(Searchable searchable) {
    _searchables.remove(searchable);
  }

  @override
  Widget build(BuildContext context) {
    return _SearchConductorScope(
      conductor: this,
      child: widget.child,
    );
  }
}

abstract class Searchable {
  /// Returns the number of found instances.
  int searchFor(String string);

  void clear();

  /// Returns false if there is no next.
  bool next();
  bool previous();
}

abstract class SearchConductor {
  void register(Searchable searchable);
  void unregister(Searchable searchable);

  void next();
  void previous();
  void clear();

  static SearchConductor of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SearchConductorScope>()!
        .conductor;
  }
}

class _SearchConductorScope extends InheritedWidget {
  const _SearchConductorScope({
    required this.conductor,
    required super.child,
  });

  final SearchConductor conductor;

  @override
  bool updateShouldNotify(_SearchConductorScope oldWidget) =>
      conductor != oldWidget.conductor;
}
