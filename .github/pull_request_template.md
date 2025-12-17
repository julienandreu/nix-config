# Summary

<!-- What does this PR do? -->
- 

## Why

<!-- Why is this change needed? -->
- 

# What changed

<!-- Key files / areas touched -->
- 
- 

# How to test

<!-- Commands run + expected outcome -->
- [ ] `nix flake check --impure`
- [ ] `nix fmt --check` (or `nixfmt-tree` if available)
- [ ] `darwin-rebuild switch --flake .#mac --impure` (if applicable)
- [ ] Manual verification:
  - 

# Breaking changes

- [ ] No
- [ ] Yes (explain below)

<!-- If yes, include upgrade notes -->

# Migration notes

<!-- If users need to do anything after merging (e.g., update local.nix, run setup.sh again) -->
- 

# Notes for reviewer

<!-- Anything non-obvious, Nix gotchas, or things to double-check -->
- 

# Checklist

- [ ] Changes are focused and intentional
- [ ] Tested locally with `darwin-rebuild switch --flake .#mac --impure`
- [ ] No secrets committed (checked `.gitignore` and `secrets/`)
- [ ] `local.nix` changes are documented (if any)
- [ ] README/docs updated if behavior changed
- [ ] Flake inputs updated if needed (`nix flake update`)
- [ ] Catppuccin flavor changes tested (if applicable)
