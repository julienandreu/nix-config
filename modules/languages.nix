{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Node.js version manager (replaces nvm)
    # fnm is ~150x faster than nvm (~2ms vs ~300ms init time)
    # Usage: fnm install 20, fnm use 20, fnm default 20
    # Supports .nvmrc and .node-version files
    fnm

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
