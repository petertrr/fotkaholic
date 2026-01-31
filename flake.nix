{
  description = "Flake for fotkaholic.eu development";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    ,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = {
          default = pkgs.stdenv.mkDerivation {
            name = "fotkaholic.eu";
            src = ./.;

            nativeBuildInputs = with pkgs; [
              git
              hugo
            ];

            buildPhase = ''
              ${pkgs.hugo}/bin/hugo
            '';

            installPhase = "cp -r public $out";
          };
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            go
            hugo
            vscode
            
            just
            nodePackages.nodejs
            nodePackages.npm
          ];
        };
      }
    );
}
