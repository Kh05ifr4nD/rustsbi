{ inputs, ... }:
{
  perSystem =
    { config, system, ... }:
    let
      overlays = [ (import inputs.rust-overlay) ];
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
      };
      rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ../rust-toolchain.toml;
    in
    {
      devShells.default = pkgs.mkShell {
        name = "rustsbi";

        inputsFrom = [
          config.pre-commit.devShell
        ];

        packages = with pkgs; [
          cargo-binutils
          git
          jq
          just
          nixd
          rustToolchain
          typos
        ];

        env = {
          RUST_BACKTRACE = "1";
          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
        };

        shellHook = ''
        '';
      };
    };
}
