#!/bin/bash
#
# Copies the dynamic module compiler and support files into assets/dbc.
#
# Run this from the root of the package.

set -euo pipefail

APP_PACKAGE=bc

ENGINE_PATH="$(dirname $(dirname $(which flutter)))/engine"

# So that .dart_tool gets created.
flutter pub get

mkdir -p assets/dbc

"$ENGINE_PATH/src/out/host_release_arm64/dart-sdk/bin/dartaotruntime" \
  --disable-dart-dev \
  "$ENGINE_PATH/src/out/host_release_arm64/dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot" \
  --sdk-root "$ENGINE_PATH/src/out/host_release_arm64/flutter_patched_sdk/" \
  --target=flutter \
  --no-print-incremental-dependencies \
  -Ddart.vm.profile=false \
  -Ddart.vm.product=true \
  --delete-tostring-package-uri=dart:ui \
  --delete-tostring-package-uri=package:flutter \
  --no-aot \
  --packages ".dart_tool/package_config.json" \
  --output-dill assets/dbc/host_app_not_aot_full.dill \
  --no-embed-source-text \
  --verbosity=error \
  --dynamic-interface=dynamic_interface.yaml \
  "package:$APP_PACKAGE/main.dart"

cp "$ENGINE_PATH/src/out/host_release_arm64/flutter_patched_sdk/platform_strong.dill" assets/dbc/platform_strong_full.dill

"$ENGINE_PATH/src/out/host_release_arm64/dart-sdk/bin/dart" \
  "$ENGINE_PATH/src/flutter/third_party/dart/pkg/front_end/tool/trim.dart" \
  --input assets/dbc/host_app_not_aot_full.dill \
  --platform assets/dbc/platform_strong_full.dill \
  --output assets/dbc/host_app_not_aot.dill \
  --output-platform assets/dbc/platform_strong.dill \
  --dynamic-interface dynamic_interface.yaml

rm assets/dbc/host_app_not_aot_full.dill assets/dbc/platform_strong_full.dill
cp .dart_tool/package_config.json assets/dbc/package_config.json
cp dynamic_interface.yaml assets/dbc/dynamic_interface.yaml
