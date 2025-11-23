{
  description = "OpenTofu Development Environment";

  # https://github.com/nix-community/nix-vscode-extensions/blob/50c4bce16b/README.md#extensions
  #
  # Adds the following attrsets (and lambda).
  #
  # pkgs.vscode-marketplace
  # pkgs.vscode-marketplace-release
  # pkgs.open-vsx
  # pkgs.open-vsx-release
  # pkgs.forVSCodeVersion
  inputs.nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, nix-vscode-extensions }: {
    pkgs =
      let
        overlays = [ nix-vscode-extensions.overlays.default ];

        pkgs = import nixpkgs {
          inherit overlays;
          system = "x86_64-linux";
        };
      in
      pkgs;

    devShell.x86_64-linux =
      let
        overlays = [ nix-vscode-extensions.overlays.default ];

        pkgs = import nixpkgs {
          inherit overlays;
          system = "x86_64-linux";
        };
      in
      with pkgs;
      mkShell {
        buildInputs = [
          amazon-ecr-credential-helper
          awscli2
          bashInteractive
          graphviz
          hcl2json
          magic-wormhole-rs
          ssm-session-manager-plugin
          tenv
          (
            vscode-with-extensions.override {
              vscode = vscodium;
              vscodeExtensions = [
                vscode-marketplace.tuttieee.emacs-mcx
                vscode-marketplace.opentofu.vscode-opentofu
              ];
            }
          )
        ];

        shellHook = ''
          # export PATH="$PATH:...";
        '';

        # ENV_VAR = "${pkgs. ...}/...";
      };
  };
}
