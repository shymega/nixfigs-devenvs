{
  description = "An empty flake template that you can adapt to your own environment";

  # Flake inputs
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  # Flake outputs
  outputs = inputs: let
    forEachSystem = let
      # The systems supported for this flake
      supportedSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      genPkgs = let
        inherit (inputs) nixpkgs;
      in
        system: nixpkgs.legacyPackages.${system};

      inherit (inputs.nixpkgs.lib) genAttrs;
    in
      f: genAttrs supportedSystems (system: f (genPkgs system));
  in {
    devShells = forEachSystem (
      pkgs: {
        default = pkgs.mkShell {
          # The Nix packages provided in the environment
          # Add any you need here
          packages = with pkgs; [];

          # Set any environment variables for your dev shell
          env = {};

          # Add any shell logic you want executed any time the environment is activated
          shellHook = '''';
        };
      }
    );
  };
}
