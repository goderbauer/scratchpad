#!/bin/bash
set -e

echo "Compiling bin/counter.dart to assets/counter.js..."
dart compile js --server-mode bin/counter.dart -o assets/counter.js
echo "Successfully compiled assets/counter.js"
