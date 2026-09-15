# pi-nix

A Nix flake packaging [pi](https://pi.dev/) from upstream's standalone release
binaries.

The released executable embeds its own JavaScript runtime, so this fetches that
binary rather than building from source — which keeps node/npm/bun out of the
closure entirely. The result is a single self-contained executable plus
`ripgrep` and `fd` on its PATH.

Supports `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.

This flake tracks `nixos-25.11`.

## Use

```nix
{
  inputs.pi.url = "github:ormandi/pi-nix";
}
```

Then add `pi.packages.${system}.default` to your package list.

## Using the binary cache

CI builds all four systems and pushes to
[`ormandi-pi.cachix.org`](https://app.cachix.org/cache/ormandi-pi). To fetch
those builds instead of repeating them, add to your consuming flake:

```nix
nixConfig = {
  extra-substituters = [ "https://ormandi-pi.cachix.org" ];
  extra-trusted-public-keys = [
    "ormandi-pi.cachix.org-1:pnfQdMO8AmoVnExIEbThbsSTRlXvGEI5k1g4+YOZhOA="
  ];
};
```

A store path is a hash of every input, so a cache hit requires your build to
have the same inputs as CI's. In practice that means **not** pointing this
flake's `nixpkgs` at a different one:

```nix
# No cache hits: pi is rebuilt against your nixpkgs, yielding a different
# store path than the one CI published.
inputs.pi = {
  url = "github:ormandi/pi-nix";
  inputs.nixpkgs.follows = "nixpkgs";   # only if yours is also nixos-25.11
};
```

Either omit `follows` entirely, or point it at an input that already tracks
`nixos-25.11`. [`ormandi/nix_shell_env`](https://github.com/ormandi/nix_shell_env)
does the latter — its own `nixpkgs` is a frozen 2024 rev, so its `pi` input
follows a separate `nixpkgs-k9s` input on `nixos-25.11` instead.

To check whether a path is cached, take the hash before the first `-` in the
store path and request its `.narinfo` (200 means cached, 404 means not):

```console
$ nix eval --raw .#packages.aarch64-darwin.pi.outPath
/nix/store/fa7dsnkiyaxh06nws47dp8schzfpz3ap-pi-0.85.1
$ curl -sI https://ormandi-pi.cachix.org/fa7dsnkiyaxh06nws47dp8schzfpz3ap.narinfo | head -1
HTTP/2 200
```

Cachix has no web file browser; lookups are by hash like the above.

## Bumping the version

1. Pick the release and read its digests:
   `curl -sL https://github.com/earendil-works/pi/releases/download/vX.Y.Z/SHA256SUMS`
2. Convert each to SRI: `nix hash convert --hash-algo sha256 --to sri <hex>`
3. Update `version` and the `releases` hashes in `pkgs/pi.nix`.
4. `nix build .#pi && ./result/bin/pi --version`
