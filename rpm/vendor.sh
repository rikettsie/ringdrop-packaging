#!/usr/bin/env bash
# Generates the vendor tarball required by the RPM spec.
# Run this from the root of the ringdrop source tree.
#
# Usage:
#   cd /path/to/ringdrop
#   bash /path/to/ringdrop-packaging/rpm/vendor.sh
#
# Output: ringdrop-<version>-vendor.tar.gz in the current directory.

set -euo pipefail

VERSION=$(cargo metadata --no-deps --format-version 1 \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['packages'][0]['version'])")

echo "Vendoring dependencies for ringdrop v${VERSION}..."
cargo vendor vendor

tar czf "ringdrop-${VERSION}-vendor.tar.gz" vendor/
rm -rf vendor/

echo "Created ringdrop-${VERSION}-vendor.tar.gz"
