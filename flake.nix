{
  description = "Flake for fotkaholic.eu development";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    hugo-theme-gallery = {
      url = "github:nicokaiser/hugo-theme-gallery";
      flake = false;
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , hugo-theme-gallery
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      in
      {
        packages = {
          default = pkgs.stdenv.mkDerivation {
            name = "fotkaholic.eu";
            src = ./.;

            nativeBuildInputs = with pkgs; [
              git
              go
              hugo
              just
            ];

            buildPhase = ''
              if [ ! -d themes/github.com/nicokaiser/hugo-theme-gallery]; then
                mkdir -p themes/github.com/nicokaiser/hugo-theme-gallery
                ln -s ${hugo-theme-gallery} themes/github.com/nicokaiser/hugo-theme-gallery/v4
              else
                echo Hugo theme is already installed
              fi
              ${pkgs.just}/bin/just build
            '';

            installPhase = "cp -r public $out";
          };
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            go
            hugo
            vscode
            claude-code
            just
            jdk17 # for SQ:IDE
            imagemagick # for image resizing
            awscli2 # for image upload
            exiftool # for EXIF metadata manipulation
            parallel

            nodejs_24

            awscli2 # for Cloudflare R2 uploads
          ];
          
          shellHook = ''
            echo "Setting up development environment..."
            mkdir -p themes/github.com/nicokaiser/hugo-theme-gallery
            ln -s ${hugo-theme-gallery} themes/github.com/nicokaiser/hugo-theme-gallery/v4
          '';
        };
      }
    );
}
