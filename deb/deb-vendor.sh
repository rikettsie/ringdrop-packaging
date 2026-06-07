#!/usr/bin/env bash
# Generates the Debian orig tarball with vendored Cargo dependencies bundled in.
# Run this from the root of the ringdrop source tree.
#
# Usage:
#   cd /path/to/ringdrop
#   bash /path/to/ringdrop-packaging/deb/deb-vendor.sh
#
# Output: ringdrop_<version>.orig.tar.gz in the current directory.
# The tarball includes the full source tree + vendor/ + .cargo/config.toml.

set -euo pipefail

VERSION=$(cargo metadata --no-deps --format-version 1 \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['packages'][0]['version'])")

WORKDIR=$(mktemp -d)
SRCDIR="$WORKDIR/ringdrop-$VERSION"

# Track whether vendor/ already existed so we don't delete user's work.
VENDOR_EXISTED=false
[ -d vendor ] && VENDOR_EXISTED=true

cleanup() {
    rm -rf "$WORKDIR"
    $VENDOR_EXISTED || rm -rf vendor
}
trap cleanup EXIT

# Vendor in the real source tree so cargo has full access to the registry
# cache and Cargo.lock — this ensures all Cargo.toml.orig files are created
# correctly and their checksums match what .cargo-checksum.json expects.
echo "Vendoring dependencies..."
$VENDOR_EXISTED || cargo vendor

echo "Exporting source tree for ringdrop v${VERSION}..."
git archive --prefix="ringdrop-$VERSION/" HEAD | tar x -C "$WORKDIR"

# Ubuntu Noble ships cargo 1.75 which cannot parse Cargo.lock v4 (requires 1.78+).
# Downgrade to v3 — v4 only adds workspace metadata unused by single-crate builds.
sed -i 's/^version = 4$/version = 3/' "$SRCDIR/Cargo.lock"

echo "Copying vendor directory..."
cp -r vendor "$SRCDIR/"

echo "Writing .cargo/config.toml..."
mkdir -p "$SRCDIR/.cargo"
cat > "$SRCDIR/.cargo/config.toml" << 'EOF'
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"
EOF

TARBALL="ringdrop_${VERSION}.orig.tar.gz"
echo "Creating ${TARBALL}..."
SOURCE_DATE_EPOCH=$(git log -1 --format=%ct HEAD)
find "$WORKDIR" -exec touch -d "@${SOURCE_DATE_EPOCH}" {} +
# Pipe through `gzip -n` to suppress filename/mtime from the gzip header —
# tar's internal gzip may ignore SOURCE_DATE_EPOCH, making the output non-reproducible.
tar cf - \
    --sort=name \
    --mtime="@${SOURCE_DATE_EPOCH}" \
    --owner=0 --group=0 --numeric-owner \
    -C "$WORKDIR" "ringdrop-$VERSION" | gzip -n > "$TARBALL"

echo "Created ${TARBALL}"
