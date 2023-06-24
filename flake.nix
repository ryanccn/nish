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
        buildInputs = [prev.gum prev.jq];

        installPhase = ''
          runHook preInstall

          mkdir -p $out/{bin,lib}

          for bin in bin/*; do
            install -Dm755 "$bin" $out/bin
          done

          install -Dm755 lib/package_manager.sh $out/lib

          for bin in $(find $out/bin $out/lib -type f); do
          	wrapProgram "$bin" \
          		--prefix PATH : ${makeBinPath buildInputs}
          done

          # dumb hack so script is sourced instead of exec'd
          sed -i '$d' $out/lib/package_manager.sh
          echo "source $out/lib/.package_manager.sh-wrapped" >> $out/lib/package_manager.sh

          runHook postInstall
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
