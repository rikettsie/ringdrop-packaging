# ringdrop-packaging

Distro packaging files for [ringdrop](https://github.com/rikettsie/ringdrop) — a secure, frugal P2P file transfer tool.

The installed binary is `rdrop` (not `ringdrop`).

## Structure

```
rpm/
  ringdrop.spec     RPM spec file (Fedora / COPR)
  vendor.sh         Helper to generate the vendored dependency tarball
deb/
  debian/           Standard Debian package directory
    control
    rules
    changelog
    copyright
    compat
```

## RPM (Fedora / COPR)

**Target distributions:** Fedora 38+, RHEL 9+ / CentOS Stream 9+.

Fedora does not allow network access at build time, so all Cargo dependencies
must be vendored — `make rpm-release` handles this automatically via `rpm/vendor.sh`.
The spec relies on `%cargo_prep` and `%cargo_build` from `rust-packaging >= 23`,
available in Fedora 38+ and the corresponding COPR build roots.

Once published, users install with:

```sh
dnf copr enable rikettsie/ringdrop
dnf install ringdrop
```

## DEB (Debian / Ubuntu)

**Target distributions:** Debian 12 (Bookworm)+, Ubuntu 22.04 (Jammy)+.

Uses `debhelper` compat level 13 and requires Rust stable 1.70+.
The `dch` tool (from `devscripts`) is required to run `make deb-release`.

## Releasing a new version

The vendor tarball must be generated on the same platform that will build the
package, to ensure `cargo vendor` produces `.orig` files compatible with that
platform's cargo version.

### Prerequisites

- The `v<VERSION>` tag must already exist in the [ringdrop](https://github.com/rikettsie/ringdrop)
  repository (i.e. the crate release must be published first).
- Both repos must be checked out as siblings: `../ringdrop` relative to this repo,
  or override with `RINGDROP=/path/to/ringdrop`.

### On Fedora (RPM)

Requires `devscripts` (`sudo dnf install devscripts`) for `dch`.

```sh
cd ringdrop-packaging
make rpm-release VERSION=0.13.0
```

This single command:

1. Checks out `v0.13.0` in the ringdrop source tree.
2. Runs `cargo vendor` to produce `ringdrop-0.13.0-vendor.tar.gz`.
3. Returns the ringdrop checkout to `main` — even if a step fails.
4. Bumps `Version:` in `rpm/ringdrop.spec` and prepends a `%changelog` entry.
5. Commits, pushes, and removes the tarball.

### On Ubuntu (DEB)

Requires `devscripts` (`sudo apt-get install devscripts`) for `dch`.

```sh
cd ringdrop-packaging
make deb-release VERSION=0.13.0
```

This single command:

1. Checks out `v0.13.0` in the ringdrop source tree.
2. Runs `cargo vendor` to produce `ringdrop_0.13.0.orig.tar.gz` (fat tarball with vendor).
3. Returns the ringdrop checkout to `main` — even if a step fails.
4. Prepends an entry to `deb/debian/changelog` via `dch`.
5. Commits, pushes, and removes the tarball.

### Individual targets

```sh
make vendor     VERSION=0.13.0   # RPM vendor tarball only
make deb-vendor VERSION=0.13.0   # DEB orig tarball only
make rpm-bump   VERSION=0.13.0   # RPM spec bump only
make deb-bump   VERSION=0.13.0   # Debian changelog bump only
```
