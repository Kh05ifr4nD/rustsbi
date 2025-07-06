riscv_target := "riscv64imac-unknown-none-elf"
main_packages := "sbi-spec sbi-rt rustsbi rustsbi-macros sbi-testing"

# Show available commands
default:
    @just --list
# === Core Cargo Commands ===
# Build for RISC-V target
b:
    @for pkg in {{main_packages}}; do cargo build -p $pkg --target {{riscv_target}}; done
    cargo xtask prototyper
    cargo xtask prototyper --jump
    cargo xtask bench
    cargo xtask test
# Check RISC-V target
c:
    pre-commit run clippy --all-files
# Format code
f:
    cargo fmt --all
# Clean build artifacts
cl:
    cargo clean
# === Nix Commands ===
# Enter nix development shell
nd:
    nix develop
# Build nix flake
nb:
    nix build
# Check nix flake
nfc:
    nix flake check
# Update nix flake
nfu:
    nix flake update
# === Pre-commit Commands ===
# Run all pre-commit hooks
pr:
    pre-commit run --all-files
# Install pre-commit hooks
pi:
    pre-commit install
# === Documentation ===
# Build and open docs
d:
    cargo doc
