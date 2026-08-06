{
  description = "OpenTofu Development Environment";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    pkgs =
      let
        overlays = [ ];

        pkgs = import nixpkgs {
          inherit overlays;
          system = "x86_64-linux";
        };
      in
      pkgs;

    devShell.x86_64-linux =
      let
        overlays = [ ];

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
        ];

        shellHook = ''
          # export PATH="$PATH:...";
        '';

        # ENV_VAR = "${pkgs. ...}/...";
      };
  };
}
