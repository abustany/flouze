#!/bin/sh

MY_DIR=$(cd $(dirname $0) && pwd)

if [ ! -f "$MY_DIR/.packages" ]; then
	echo "Please run flutter packages get in the project directory first"
	exit 1
fi

FLUTTER_ROOT_DIR="$(grep '^flutter:file:///' $MY_DIR/.packages | sed 's,flutter:file://,,')/../../.."

if [ -z "$FLUTTER_ROOT_DIR" ]; then
	echo "Cannot find the Flutter root directory"
	exit 1
fi

FLUTTER_ROOT_DIR=$(cd "$FLUTTER_ROOT_DIR" && pwd)

echo "Flutter root dir is: $FLUTTER_ROOT_DIR"

if [ ! -f "$FLUTTER_ROOT_DIR/bin/cache/dart-sdk/bin/dart" ]; then
	echo "Cannot find a Dart installation in the Flutter directory"
	exit 1
fi

#export PATH="$FLUTTER_ROOT_DIR/.pub-cache/hosted/pub.dartlang.org/protoc_plugin-0.8.0/bin:$PATH"

PROTOC=$(which protoc)

if [ -z "$PROTOC" ]; then
	echo "protoc does not seem to be installed"
	exit 1
fi

cat >$MY_DIR/protoc-gen-dart <<EOF
#!/bin/sh
export PATH="$FLUTTER_ROOT_DIR/bin/cache/dart-sdk/bin:\$PATH"
export DART_PACKAGE_ROOT="$FLUTTER_ROOT_DIR/.pub-cache/hosted/pub.dartlang.org/protoc_plugin-0.8.0/lib"
exec dart --packages=$MY_DIR/.packages \$DART_PACKAGE_ROOT/../bin/protoc_plugin.dart -c "\$@"
EOF

chmod a+x protoc-gen-dart

set -e

$PROTOC --plugin=$MY_DIR/protoc-gen-dart --dart_out=$MY_DIR/lib $MY_DIR/../lib/proto/flouze.proto -I $MY_DIR/../lib/proto
echo "Generated models in $MY_DIR/lib"
