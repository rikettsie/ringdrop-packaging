#!/usr/bin/env python3
"""
Patch vendored crates that declare edition = "2024" down to "2021".

edition2024 was stabilised in cargo 1.85; Ubuntu Noble ships cargo 1.75.
The two editions are backward-compatible for the constructs used by the
affected crates, so this downgrade is safe. The Cargo.toml checksum in
.cargo-checksum.json is updated so cargo --locked does not reject the change.
"""
import glob
import hashlib
import json
import os

for toml_path in glob.glob("vendor/*/Cargo.toml"):
    content = open(toml_path, "rb").read()
    if b'edition = "2024"' not in content:
        continue
    new_content = content.replace(b'edition = "2024"', b'edition = "2021"')
    open(toml_path, "wb").write(new_content)

    checksum_path = os.path.join(os.path.dirname(toml_path), ".cargo-checksum.json")
    if not os.path.exists(checksum_path):
        continue
    new_hash = hashlib.sha256(new_content).hexdigest()
    data = json.loads(open(checksum_path).read())
    data["files"]["Cargo.toml"] = new_hash
    open(checksum_path, "w").write(json.dumps(data, sort_keys=True))
    print(f"patched {toml_path}: edition 2024 -> 2021")
