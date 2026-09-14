# pi-nix

A Nix flake packaging [pi](https://pi.dev/) from upstream's standalone release
binaries.

The released executable embeds its own JavaScript runtime, so this fetches that
binary rather than building from source — which keeps node/npm/bun out of the
closure entirely. The result is a single self-contained executable plus
`ripgrep` and `fd` on its PATH.

Supports `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.

## Use

```nix
{
  inputs.pi = {
    url = "github:ormandi/pi-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Then add `pi.packages.${system}.default` to your package list.

## Bumping the version

1. Pick the release and read its digests:
   `curl -sL https://github.com/earendil-works/pi/releases/download/vX.Y.Z/SHA256SUMS`
2. Convert each to SRI: `nix hash convert --hash-algo sha256 --to sri <hex>`
3. Update `version` and the `releases` hashes in `pkgs/pi.nix`.
4. `nix build .#pi && ./result/bin/pi --version`
