{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      overlays = [ (import inputs.rust-overlay) ];
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
      };
      rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ../rust-toolchain.toml;
    in
    {
      pre-commit = {
        check.enable = true;
        settings = {
          src = ../.;
          excludes = [
            "^target/"
            "\\.lock$"
            "\\.log$"
          ];
          hooks = {
            end-of-file-fixer.enable = true;
            trim-trailing-whitespace.enable = true;
            check-merge-conflicts.enable = true;
            check-yaml.enable = true;
            rustfmt = {
              enable = true;
              packageOverrides = {
                cargo = rustToolchain;
                rustfmt = rustToolchain;
              };
            };
            clippy = {
              enable = true;
              packageOverrides = {
                cargo = rustToolchain;
                clippy = rustToolchain;
              };
              entry = "${pkgs.writeShellScript "clippy-comprehensive" ''
                set -e
                export PATH="${rustToolchain}/bin:$PATH"

                echo "📎 Running comprehensive clippy checks..."

                # Main library packages with all targets and tests
                main_packages="sbi-spec sbi-rt rustsbi rustsbi-macros sbi-testing"
                for pkg in $main_packages; do
                  echo "📦 Checking $pkg (all targets + tests)..."
                  cargo clippy -p "$pkg" --all-targets --tests --fix --allow-dirty -- -D warnings
                done

                # Prototyper packages for RISC-V target
                echo "📦 Checking rustsbi-bench-kernel for RISC-V..."
                cargo clippy -p rustsbi-bench-kernel --target riscv64imac-unknown-none-elf -- -D warnings

                echo "📦 Checking rustsbi-test-kernel for RISC-V..."
                cargo clippy -p rustsbi-test-kernel --target riscv64imac-unknown-none-elf -- -D warnings

                # xtask with all targets
                echo "📦 Checking xtask (all targets)..."
                cargo clippy -p xtask --all-targets --fix --allow-dirty -- -D warnings

                echo "✅ All clippy checks passed!"
              ''}";
              files = "\\.rs$";
              pass_filenames = false;
              language = "system";
            };
          };
        };
      };
    };
}
