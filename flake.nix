{
  description = "ni, implemented in bash";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    version = builtins.substring 0 8 self.lastModifiedDate;

    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      });

    forEachSystem = fn:
      forAllSystems (system:
        fn {
          inherit system;
          pkgs = nixpkgsFor.${system};
        });
  in {
    devShells = forEachSystem ({pkgs, ...}: let
      inherit (pkgs) mkShell;
    in {
      default = mkShell {
        packages = with pkgs; [
          beautysh
          gum
          shellcheck
        ];
      };
    });

    formatter = forEachSystem ({pkgs, ...}: pkgs.alejandra);

    packages = forEachSystem ({pkgs, ...}: {
      inherit (pkgs) nish;
      default = pkgs.nish;
    });

    overlays.default = _: prev: let
      inherit (prev) stdenv;
      inherit (prev.lib) licenses maintainers makeBinPath platforms;
    in {
      nish = stdenv.mkDerivation rec {
        pname = "nish";
        inherit version;

        src = builtins.path {
          name = "${pname}-src";
          path = ./.;
        };

        nativeBuildInputs = [prev.makeWrapper];
        buildInputs = [prev.gum];

        installPhase = ''
          mkdir -p $out/bin/lib
          install -Dm755 n{i,r} $out/bin
          install -Dm755 lib/package_manager.sh $out/bin/lib

          for bin in $out/bin/{n{i,r},lib/package_manager.sh}; do
          	wrapProgram "$bin" \
          		--prefix PATH : ${makeBinPath buildInputs}
          done
        '';

        meta = {
          description = "ni, implemented in bash";
          homepage = "https://github.com/ryanccn/nish";
          license = licenses.mit;
          maintainers = [maintainers.getchoo];
          platforms = with platforms; linux ++ darwin;
        };
      };
    };
  };
}
