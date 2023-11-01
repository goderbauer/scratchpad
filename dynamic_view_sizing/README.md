# dynamic_view_sizing

Prototype that demonstrates dynamic view sizing, i.e. the FlutterView is sized
by its content.

Currently, the FlutterView is given unconstrained constraints meaning that
FlutterView can be any size it wants. These constrains are currently
hard-coded, but would ultimately be read from the FlutterView (which would
get them from the embedder.

Left-clicking on the View will increase the size chosen by the framework for
the FlutterView and right-clicking will decrease it.

This prototype is to be used with the following framework prototype branch: https://github.com/goderbauer/flutter/tree/dynamic-view-sizing-prototype
and the following engine prototype branch: https://github.com/goderbauer/engine/tree/dynamic-view-sizing-prototype

Currently, only MacOS is supported.
