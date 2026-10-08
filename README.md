# therock-sdk-nix

[TheRock ROCm Core SDK](https://github.com/ROCm/TheRock) (stable channel) packaged for
NixOS from the relocatable per-family dist tarballs published at
`https://stable.repo.amd.com/rocm/core/tarball/therock-dist-linux-<family>-<version>.tar.gz`.

These are the "system ROCm" tarballs the strix-halo / llama.cpp install flows use:
`$ORIGIN` runpaths, bundled sysdeps. The derivation keeps the libraries byte-for-byte
untouched (patchelf mangles the lld-linked ones and the loader segfaults), symlinks
`libstdc++`/`libgcc_s` into the runpath dirs the dist already searches, and only points
executable `PT_INTERP` at the Nix loader.

`rocm-sdk-cc.nix` wraps the SDK clang/hipcc for nix builds: the SDK clang cannot find
NixOS libstdc++/glibc headers (no `/usr/include`), so every host-side or `-x hip`
compile fails on `<cstdlib>` without the gcc-toolchain flags.

## Usage

As a flake input (the intended path — pass your `pkgs` so there is one nixpkgs):

```nix
inputs.therock-sdk.url = "github:ewtodd/therock-sdk-nix";

rocmSdk = inputs.therock-sdk.lib.${system}.mkRocmSdk { inherit pkgs; family = "gfx120X-all"; };
rocmSdkCc = inputs.therock-sdk.lib.${system}.mkRocmSdkCc { inherit pkgs rocmSdk; };
```

Standalone (the SDK is marked unfree):

```console
$ NIXPKGS_ALLOW_UNFREE=1 nix build github:ewtodd/therock-sdk-nix              # gfx120X-all
$ NIXPKGS_ALLOW_UNFREE=1 nix build github:ewtodd/therock-sdk-nix#rocmSdk-gfx1151
```

Families with published hashes: `gfx1151`, `gfx120X-all` (add to the `hashes` attrset
in `nix/rocm-sdk-therock.nix` for others).

## Bumping the ROCm version

1. `version` in `nix/rocm-sdk-therock.nix`.
2. Recompute every hash:
   `nix-prefetch-url https://stable.repo.amd.com/rocm/core/tarball/therock-dist-linux-<family>-<version>.tar.gz`
3. The LLVM-major-named binary in the load check (`lib/llvm/bin/clang-NN`) changes with
   each LLVM major: ROCm 10.0 is LLVM 23, ROCm 10.1 is LLVM 24. Same name in the
   `clangWrapper` in `nix/rocm-sdk-cc.nix`.
