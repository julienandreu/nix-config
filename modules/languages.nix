{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Node.js LTS (defaults to latest LTS version in nixpkgs)
    # Note: npm comes with nodejs, but pnpm, yarn, typescript, ts-node
    # should be installed per-project via package.json
    nodejs
    
    # Rust (latest stable - Rust releases stable versions every 6 weeks)
    # rustc and cargo are the core tools
    # rustfmt and clippy are included in the Rust toolchain
    # rust-analyzer is the language server (separate package)
    rustc
    cargo
    rustfmt
    rust-analyzer
    clippy
    
    # Python (latest stable - Python doesn't have official LTS versions)
    # Note: pip comes with python3, but packages should be installed
    # per-project via requirements.txt, pyproject.toml, or pipx
    python3
    ruff  # Python linter and formatter (replaces flake8, black, isort, etc.)
  ];

  # Rust environment via home-manager
  home.sessionVariables = {
    CARGO_HOME = "${config.home.homeDirectory}/.cargo";
    RUSTUP_HOME = "${config.home.homeDirectory}/.rustup";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.cargo/bin"
  ];
}

