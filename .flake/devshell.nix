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
        env = {
          RUST_BACKTRACE = "1";
          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
        };
        inputsFrom = [
          config.pre-commit.devShell
        ];
        name = "rustsbi";
        packages = with pkgs; [
          cargo-binutils
          cargo-cache
          git
          gnupg
          just
          nixd
          nixfmt-rfc-style
          rustToolchain
        ];
        shellHook = '''';
      };
    };
}
