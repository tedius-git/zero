{
  description = "Development Shell";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          shellHook = ''
            echo "Development environment loaded"
            alias zero-dev='find src -name '*.elm' | entr -c elm make src/Main.elm --output=main.js'
          '';
          packages = with pkgs; [
            (haskell.lib.compose.overrideSrc {
                src = fetchFromGitHub {
                  owner = "bmillwood";
                  repo = "elm-compiler";
                  rev = "c8ca5e14650a77446a6577eb356ddd09c3928bac";
                  sha256 = "sha256-H9+dOILnszejlylsV7Dd7TFuXuKGc/+7kYeNhN4SVXg=";
                };
              }
              elmPackages.elm)
            entr
          ];
        };
      }
    );
}
