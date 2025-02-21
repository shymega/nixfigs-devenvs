{
  description = "Repository with different development shells for @shymega";

  nixConfig = {
    extra-trusted-substituters = [
      "https://cache.dataaturservice.se/spectrum/"
      "https://cache.nixos.org/"
      "https://deploy-rs.cachix.org/"
      "https://devenv.cachix.org"
      "https://nix-community.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://nix-on-droid.cachix.org"
      "https://numtide.cachix.org"
      "https://pre-commit-hooks.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "deploy-rs.cachix.org-1:xfNobmiwF/vzvK1gpfediPwpdIP0rpDV2rYqx40zdSI="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
      "spectrum-os.org-2:foQk3r7t2VpRx92CaXb5ROyy/NBdRJQG2uX2XJMYZfU="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
    nixfigs-helpers.url = "github:shymega/nixfigs-helpers";
    the-nix-way.url = "github:the-nix-way/dev-templates";
  };

  outputs =
    { self, ... }@inputs:
    let
      genPkgs = system: import inputs.nixpkgs { inherit system; };

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      treeFmtEachSystem =
        f: inputs.nixpkgs.lib.genAttrs systems (system: f inputs.nixpkgs.legacyPackages.${system});
      treeFmtEval = treeFmtEachSystem (
        pkgs:
        inputs.nixfigs-helpers.inputs.treefmt-nix.lib.evalModule pkgs "${inputs.nixfigs-helpers.helpers.formatter
        }"
      );

      forEachSystem = inputs.nixpkgs.lib.genAttrs systems;
    in
    {
      # for `nix fmt`
      formatter = treeFmtEachSystem (pkgs: treeFmtEval.${pkgs.system}.config.build.wrapper);
      # for `nix flake check`
      checks =
        treeFmtEachSystem (pkgs: {
          formatting = treeFmtEval.${pkgs}.config.build.wrapper;
        })
        // forEachSystem (system: {
          pre-commit-check = import "${inputs.nixfigs-helpers.helpers.checks}" {
            inherit self system;
            inherit (inputs.nixfigs-helpers) inputs;
            inherit (inputs.nixpkgs) lib;
          };
        });
      devShells = forEachSystem (
        system:
        let
          pkgs = genPkgs system;
        in
        import inputs.nixfigs-helpers.helpers.devShells { inherit pkgs self system; }
      );

      templates-srcs = rec {
        shymega = {
          default = inputs.the-nix-way.templates.empty;
        };
        all-templates = shymega // inputs.the-nix-way.templates;
      };
      templates = self.templates-srcs.all-templates;
    };
}
