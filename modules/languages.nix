{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs

    # Rust core
    rustc
    cargo
    rust-analyzer

    # Python
    python3
    ruff
  ];

  # Rust environment
  home.sessionVariables = {
    CARGO_HOME = "${config.home.homeDirectory}/.cargo";
    RUSTUP_HOME = "${config.home.homeDirectory}/.rustup";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.cargo/bin"
  ];
}
