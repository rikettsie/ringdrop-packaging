#!/usr/bin/env python3
"""
Remove .cargo-checksum.json entries for Cargo.toml.orig files that don't
exist in the vendor directory.

cargo vendor only creates Cargo.toml.orig when it modifies a crate's
Cargo.toml, but newer cargo versions write a checksum entry for it
regardless. This mismatch causes "failed to calculate checksum" errors
during offline builds. Removing the dangling entries fixes it.
"""
import os
import json
import glob

for path in glob.glob("vendor/*/.cargo-checksum.json"):
    crate_dir = os.path.dirname(path)
    with open(path) as f:
        data = json.load(f)
    files = data.get("files", {})
    missing = [
        k for k in list(files)
        if k.endswith(".orig") and not os.path.exists(os.path.join(crate_dir, k))
    ]
    if missing:
        for k in missing:
            del files[k]
        with open(path, "w") as f:
            json.dump(data, f, sort_keys=True)
        print(f"fixed {path}: removed {missing}")
