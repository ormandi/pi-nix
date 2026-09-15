{
  description = "The pi coding agent, packaged from upstream's standalone release binaries";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    # x86_64-darwin is omitted: nixpkgs 26.11 dropped it, so evaluating that
    # system throws. pkgs/pi.nix still carries its hash, so re-adding it here
    # is all that's needed if the flake ever tracks a nixpkgs that supports it.
    flake-utils.lib.eachSystem [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          pi = pkgs.callPackage ./pkgs/pi.nix { };
          default = self.packages.${system}.pi;
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.pi}/bin/pi";
        };
      });
}
