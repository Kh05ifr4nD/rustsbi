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
              settings = {
                denyWarnings = true;
                allFeatures = false; # We'll handle features manually
                offline = false;
              };
            };

            cargo-check-riscv = {
              enable = true;
              name = "cargo-check-riscv";
              description = "Check Rust packages for RISC-V target";
              entry = "${pkgs.writeShellScript "cargo-check-riscv" ''
                set -e
                export PATH="${rustToolchain}/bin:$PATH"

                echo "🔍 Running cargo check for RISC-V targets..."

                # Get only RustSBI library packages (no_std compatible)
                packages="sbi-spec sbi-rt rustsbi rustsbi-macros sbi-testing"

                # Check each package
                for package in $packages; do
                  echo "📦 Checking package: $package"
                  if ! cargo check -p "$package" --target riscv64imac-unknown-none-elf; then
                    echo "❌ Package $package check failed!"
                    exit 1
                  fi
                done

                echo "✅ All packages checked successfully for RISC-V target"
              ''}";
              files = "\\.rs$";
              pass_filenames = false;
              language = "system";
            };

            # Custom clippy for RISC-V targets
            clippy-riscv = {
              enable = true;
              name = "clippy-riscv";
              description = "Lint Rust packages for RISC-V target";
              entry = "${pkgs.writeShellScript "clippy-riscv" ''
                set -e
                export PATH="${rustToolchain}/bin:$PATH"

                echo "📎 Running clippy for RISC-V targets..."

                # Get only RustSBI library packages (no_std compatible)
                packages="sbi-spec sbi-rt rustsbi rustsbi-macros sbi-testing"

                # Lint each package
                for package in $packages; do
                  echo "📦 Linting package: $package"
                  if ! cargo clippy -p "$package" --target riscv64imac-unknown-none-elf -- -D warnings; then
                    echo "❌ Package $package clippy check failed!"
                    exit 1
                  fi
                done

                echo "✅ All packages linted successfully for RISC-V target"
              ''}";
              files = "\\.rs$";
              pass_filenames = false;
              language = "system";
              after = [ "rustfmt" ];
            };
          };
        };
      };
    };
}
