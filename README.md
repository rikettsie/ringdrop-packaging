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
```

## RPM (Fedora / COPR)

**Target distributions:** Fedora 42, 43, 44.

Fedora does not allow network access at build time, so all Cargo dependencies
must be vendored — the CI handles this automatically via `rpm/vendor.sh`.
The spec relies on `%cargo_prep` and `%cargo_build` from `rust-packaging >= 23`,
available in Fedora 42+.

Install with:

```sh
dnf copr enable rikettsie/ringdrop
dnf install ringdrop
```

## DEB (Ubuntu)

**Target distributions:** Ubuntu 24.04 (Noble). Ubuntu 22.04 (Jammy) is
available via Launchpad package copy.

Uses `debhelper` compat level 13. Cargo dependencies are bundled in the
orig tarball so no network access is needed at build time.

Install with:

```sh
sudo add-apt-repository ppa:rikettsie/ringdrop
sudo apt-get install ringdrop
```

## CI automation

Releases are triggered automatically when a new tag is pushed to the
[ringdrop](https://github.com/rikettsie/ringdrop) repository. The workflow:

1. **RPM job** — generates the vendor tarball, bumps the spec, commits.
2. **COPR job** — builds an SRPM and submits it to [copr.fedorainfracloud.org/coprs/rikettsie/ringdrop](https://copr.fedorainfracloud.org/coprs/rikettsie/ringdrop).
3. **DEB job** — generates the orig tarball, bumps the changelog, commits.
4. **Launchpad job** — builds a signed source package and uploads it to [launchpad.net/~rikettsie/+archive/ubuntu/ringdrop](https://launchpad.net/~rikettsie/+archive/ubuntu/ringdrop).

To re-run a release manually:

```sh
gh workflow run package-release.yml -f version=0.13.1
```

## Local releasing

The `make` targets still work for local testing or emergency use.

### Prerequisites

- The `v<VERSION>` tag must already exist in the [ringdrop](https://github.com/rikettsie/ringdrop)
  repository (i.e. the crate release must be published first).
- Both repos must be checked out as siblings: `../ringdrop` relative to this repo,
  or override with `RINGDROP=/path/to/ringdrop`.

### RPM

```sh
make rpm-release VERSION=0.13.1
```

1. Checks out `v0.13.1` in the ringdrop source tree.
2. Runs `cargo vendor` to produce `ringdrop-0.13.1-vendor.tar.gz`.
3. Returns the ringdrop checkout to `main` — even if a step fails.
4. Bumps `Version:` in `rpm/ringdrop.spec` and prepends a `%changelog` entry.
5. Commits, pushes, and removes the tarball.

### DEB

Requires `devscripts` (`sudo apt-get install devscripts`) for `dch`.

```sh
make deb-release VERSION=0.13.1
```

1. Checks out `v0.13.1` in the ringdrop source tree.
2. Runs `cargo vendor` to produce `ringdrop_0.13.1.orig.tar.gz` (fat tarball with vendor).
3. Returns the ringdrop checkout to `main` — even if a step fails.
4. Prepends an entry to `deb/debian/changelog` via `dch`.
5. Commits, pushes, and removes the tarball.

### Individual targets

```sh
make vendor     VERSION=0.13.1   # RPM vendor tarball only
make deb-vendor VERSION=0.13.1   # DEB orig tarball only
make rpm-bump   VERSION=0.13.1   # RPM spec bump only
make deb-bump   VERSION=0.13.1   # Debian changelog bump only
```
