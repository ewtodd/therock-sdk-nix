{
  description = "therock-sdk-nix: TheRock ROCm Core SDK (relocatable per-family dist tarballs) plus a clang/hipcc wrapper for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Consume the caller's `pkgs` so a NixOS host does not evaluate a second nixpkgs.
      mkRocmSdk =
        {
          pkgs,
          family ? "gfx1151",
        }:
        pkgs.callPackage ./nix/rocm-sdk-therock.nix { inherit family; };

      mkRocmSdkCc = { pkgs, rocmSdk }: pkgs.callPackage ./nix/rocm-sdk-cc.nix { inherit rocmSdk; };
    in
    {
      lib = forAllSystems (system: {
        inherit
          mkRocmSdk
          mkRocmSdkCc
          ;
      });

      # Standalone: `nix build .#rocmSdk`, `nix build .#rocmSdk-gfx1151`, ...
      # The SDK is unfree (AMD license), so the standalone instance allows it.
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          sdk120 = mkRocmSdk {
            inherit pkgs;
            family = "gfx120X-all";
          };
          sdk115 = mkRocmSdk {
            inherit pkgs;
            family = "gfx1151";
          };
        in
        {
          default = sdk120;
          rocmSdk = sdk120;
          rocmSdkCc = mkRocmSdkCc {
            pkgs = pkgs;
            rocmSdk = sdk120;
          };
          rocmSdk-gfx1151 = sdk115;
          rocmSdkCc-gfx1151 = mkRocmSdkCc {
            pkgs = pkgs;
            rocmSdk = sdk115;
          };
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
