{
  description = "FM";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-26.05";
    nixpkgs-racket.url = "github:NixOS/nixpkgs/master"; # Racket broken on 25.11

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils";
    revealjs = {
      url = "github:hakimel/reveal.js";
      flake = false;
    };
    mathjax = {
      url = "github:mathjax/mathjax/4.1.3";
      flake = false;
    };
    plantumlC4 = {
      url = "github:plantuml-stdlib/c4-plantuml";
      flake = false;
    };
    plantumlEIP = {
      url = "github:plantuml-stdlib/EIP-PlantUML";
      flake = false;
    };
    decktape = {
      url = "github:astefanutti/decktape";
      flake = false;
    };
    isar-mode = {
      url = "github:m-fleury/isar-mode";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      flake-utils,
      nixpkgs,
      nixpkgs-racket,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        "aarch64-linux"
      ];
      perSystem =
        { config, system, self', ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          ciPkgs = import pkgs.path {
            inherit system;
            config = pkgs.config // {
              allowUnfreePredicate = pkg:
                pkgs.lib.getName pkg == "corefonts";
            };
          };

          # Pin GHC version for easier, explicit upgrades later
          ghcVersion = "9123";

          haskellOverlay = final: prev:
            let
              hlib = final.haskell.lib.compose;
            in
              {
                haskellPackages =
                  prev.haskell.packages."ghc${ghcVersion}".override (old: {
                    overrides = final.lib.composeExtensions
                      (old.overrides or (_: _: { }))
                      (hfinal: hprev: {
                        store = hlib.dontCheck hprev.store;
                        #ghcide = hlib.disableOptimization hprev.ghcide;
                        liquidhaskell-boot = hprev.liquidhaskell-boot_0_9_12_2_1;
                        liquid-fixpoint =
                          hlib.dontCheck hprev.liquid-fixpoint_0_9_6_3_5;
                        liquidhaskell =
                          hlib.overrideCabal
                            (drv: { doHaddock = false; })
                            hprev.liquidhaskell_0_9_12_2_1;
                      });
                  });
              };

          z3Overlay = final: prev: {
            z3 = prev.z3.overrideAttrs (_: {
              doCheck = false;
            });
          };

          haskellPkgs = pkgs.extend (
            pkgs.lib.composeManyExtensions [
              haskellOverlay
              z3Overlay
            ]
          );

          verifastPkgs =
            let
              basePkgs = nixpkgs.legacyPackages.${system};
              patchedNixpkgs = pkgs.applyPatches {
                name = "verifast-on-macos";
                src = nixpkgs;
                patches = basePkgs.fetchpatch {
                  url = "https://github.com/NixOS/nixpkgs/commit/1fbad9f3afcdd4621b84120c22404ea4e310485d.patch";
                  hash = "sha256-5SDVX8ASkDPTTBER924+7niP4mzq0vwHUpgA0yllCyU=";
                };
              };
            in
              import patchedNixpkgs {
                inherit system;
                overlays = [ z3Overlay ];
              };

          unfreePkgs = import pkgs.path {
            inherit system;
            config = pkgs.config // {
              allowUnfree = true;
            };
          };

          isar-mode = pkgs.emacs30.pkgs.trivialBuild {
            pname = "isar-mode";
            version = "unstable";
            src = inputs.isar-mode;
          };
          emacs = pkgs.emacs30.pkgs.withPackages (p: [
            p.org-re-reveal
            p.haskell-mode
            isar-mode
          ]);

          texlive = pkgs.texlive.combine {
            inherit (pkgs.texlive)
              scheme-small
              fontspec
              unicode-math
              lualatex-math
              tex-gyre
              tex-gyre-math
              dejavu
              tcolorbox
              titlesec
              enumitem
              fancyhdr
              parskip
            ;
          };

          unionShell = shells: pkgs.mkShell {
            inputsFrom = shells;
          };
        in
        {
          formatter = pkgs.nixfmt;
          devShells = {
            haskell =
              let
                liquid-haskell-project =
                  (haskellPkgs.haskellPackages.callCabal2nix "liquid-haskell"
                    (haskellPkgs.lib.cleanSource ./liquid-haskell) { })
                    .overrideAttrs
                    (old: {
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ haskellPkgs.z3 ];
                    });
                haskell-code =
                  haskellPkgs.haskellPackages.callCabal2nix "haskell-code"
                    (haskellPkgs.lib.cleanSource ./haskell-code) { };
                vscode = unfreePkgs.vscode-with-extensions.override {
                  vscodeExtensions = with unfreePkgs.vscode-extensions; [
                    bbenoist.nix
                    haskell.haskell
                    justusadam.language-haskell
                  ];
                };
              in
                haskellPkgs.haskellPackages.shellFor {
                  packages = _: [
                    liquid-haskell-project
                    haskell-code
                  ];
                  nativeBuildInputs = [ haskellPkgs.haskellPackages.doctest ];
                  buildInputs = [
                    haskellPkgs.cabal-install
                    self'.packages.hls
                    haskellPkgs.z3
                    vscode
                  ];
                  shellHook = ''
                    export PS1="\n\[\033[1;32m\][nix-shell:\W \[\033[1;31m\]FM\[\033[1;32m\]]\$\[\033[0m\] "
                    echo -e "\n\033[1;31m ♣ ♠ Welcome to FM - Haskell! ♥ ♦ \033[0m\n"
                    echo -e "   Use the following command to open VSCode in this directory:\n"
                    echo -e "       code ."
                    echo -e "\n   All required extensions should be pre-installed and ready."
                '';
                };

            verifast =
              let
                verifast-vscode = unfreePkgs.vscode-utils.extensionFromVscodeMarketplace {
                  publisher = "VeriFast";
                  name = "verifast";
                  version = "0.9.9";
                  sha256 = "sha256-0FVxjuWjCeuiUoRtJXW2L73WcA5tNfJ/zHQ12/tu2Jk="; # pkgs.lib.fakeSha256;
                };
                vscode = unfreePkgs.vscode-with-extensions.override {
                  vscodeExtensions = with unfreePkgs.vscode-extensions; [
                    bbenoist.nix
                    ms-vscode.cpptools-extension-pack
                    verifast-vscode
                  ];
                };
              in
                verifastPkgs.mkShell {
                  packages = [
                    verifastPkgs.verifast
                    verifastPkgs.z3
                    vscode
                  ];

                  shellHook = ''
                    export PS1="\n\[\033[1;32m\][nix-shell:\W \[\033[1;31m\]FM\[\033[1;32m\]]\$\[\033[0m\] "
                    echo -e "\n\033[1;31m ♣ ♠ Welcome to FM - Verifast! ♥ ♦ \033[0m\n"
                    mkdir -p .vscode
                    echo '{ "verifast.verifastCommandPath": "${verifastPkgs.verifast}/bin/verifast" }' \
                      > .vscode/settings.json
                    echo -e "   All required extensions should be pre-installed and ready."
                  '';
                };

            agda =
              assert pkgs.agda.version == "2.8.0";
              assert pkgs.agdaPackages.standard-library.version == "2.3";
              pkgs.mkShell {
                packages = [
                  (pkgs.agda.withPackages (ps: [ ps.standard-library ]))
                ];
                shellHook = ''
                  export PS1="\n\[\033[1;32m\][nix-shell:\W \[\033[1;31m\]FM\[\033[1;32m\]]\$\[\033[0m\] "
                  echo -e "\n\033[1;31m ♣ ♠ Welcome to FM - Agda! ♥ ♦ \033[0m\n"
                '';
              };

            isabelle =
              assert pkgs.isabelle.version == "2025-2";
              pkgs.mkShell {
                packages = [ pkgs.isabelle ];
                shellHook = ''
                  export PS1="\n\[\033[1;32m\][nix-shell:\W \[\033[1;31m\]FM\[\033[1;32m\]]\$\[\033[0m\] "
                  echo -e "\n\033[1;31m ♣ ♠ Welcome to FM - Isabelle! ♥ ♦ \033[0m\n"
                '';
              };

            acl2 =
              pkgs.mkShell {
                packages = [ unfreePkgs.acl2 ];
                shellHook = ''
                  export PS1="\n\[\033[1;32m\][nix-shell:\W \[\033[1;31m\]FM\[\033[1;32m\]]\$\[\033[0m\] "
                  echo -e "\n\033[1;31m ♣ ♠ Welcome to FM - ACL2! ♥ ♦ \033[0m\n"
                '';
              };

            ${if ciPkgs.stdenv.hostPlatform.isLinux then "ci" else null} =
              ciPkgs.mkShell {
                packages = with ciPkgs; [
                  gnumake
                  chromium
                  which
                  fontconfig
                  corefonts
              ];
              shellHook = ''
                export FONTCONFIG_FILE="${ciPkgs.makeFontsConf { fontDirectories = [ ciPkgs.corefonts ]; }}"
              '';
            };

            forge =
              let
                pkgs-for-racket = import nixpkgs-racket {
                  inherit system;
                  config = {
                    allowBroken = true;
                    allowUnsupportedSystem = true;
                  };
                };
                racket-pkgs = import nixpkgs {
                  inherit system;
                  config.allowUnfree = true;
                  overlays = [
                    (final: prev: {
                      racket-minimal = pkgs-for-racket.racket-minimal;
                    })
                  ];
                };
                forge-fm-vscode = unfreePkgs.vscode-utils.extensionFromVscodeMarketplace {
                  publisher = "SiddharthaPrasad";
                  name = "forge-fm";
                  version = "0.2.9";
                  sha256 = "sha256-Ogx/MByLHXFQvrMSorIt3RbdfDqOTTL7Bif0QSbCmGA="; # pkgs.lib.fakeSha256;
                };
                vscode = unfreePkgs.vscode-with-extensions.override {
                  vscodeExtensions = with unfreePkgs.vscode-extensions; [
                    bbenoist.nix
                    forge-fm-vscode
                  ];
                };
              in
                pkgs.mkShell {
                  packages = [ racket-pkgs.racket-minimal vscode ];
                  shellHook = ''
                    export PS1="\n\[\033[1;32m\][nix-shell:\W \[\033[1;31m\]FM\[\033[1;32m\]]\$\[\033[0m\] "
                    echo -e "\n\033[1;31m ♣ ♠ Welcome to FM - Forge! ♥ ♦ \033[0m\n"
                  '';
                };

            latex = pkgs.mkShell {
              packages = [ texlive ];
              shellHook = ''
                export PS1="\n\[\033[1;32m\][nix-shell:\W \[\033[1;31m\]FM\[\033[1;32m\]]\$\[\033[0m\] "
                echo -e "\n\033[1;31m ♣ ♠ Welcome to FM - LaTeX! ♥ ♦ \033[0m\n"
              '';
            };

            default = unionShell (with config.devShells; [ haskell verifast agda isabelle ]);
          };

          checks = {
            isabelle-isar-cheat-sheet =
              pkgs.runCommand "isabelle-isar-cheat-sheet-check"
                {
                  nativeBuildInputs = [ texlive ];
                }
                ''
                  cp ${./slides/isabelle-isar-cheat-sheet.tex} cheat-sheet.tex
                  lualatex \
                    -interaction=nonstopmode \
                    -halt-on-error \
                    cheat-sheet.tex
                  mkdir -p $out
                  cp cheat-sheet.pdf $out/
                '';
          };

          legacyPackages = pkgs;

          packages = {
            hls = haskellPkgs.haskell-language-server.override {
              supportedGhcVersions = [ ghcVersion ];
            };

            # To be able to specifically build decktape without the Nix sandbox,
            # we need to make it a package instead of an app.
            decktapeWithDependencies = pkgs.stdenv.mkDerivation {
              name = "decktape-with-dependencies";
              src = inputs.decktape;
              buildInputs = [
                pkgs.nodejs
                pkgs.cacert
              ];
              buildPhase = "HOME=$TMP npm install";
              installPhase = "cp -r . $out";
            };

            # Provide the Emacs that is used to build the slides; might be useful
            # for debugging.
            emacs = pkgs.writeShellScriptBin "reveal-emacs" ''
              ${emacs}/bin/emacs -Q
            '';

            watch = pkgs.writeShellScriptBin "watch-and-commit" ''
              ${pkgs.lib.getExe pkgs.watch} -n 10 "git add . && git commit -m update && git push"
            '';
          };

          apps = {
            # The default target for `nix run`. This builds the reveal.js slides.
            slides =
              let
                app = pkgs.writeShellScript "org-re-reveal" ''
                  if [ ! -e slides/plantuml/plugins ]; then
                    mkdir -p slides/plantuml/plugins
                    ln -snf ${inputs.plantumlC4}/*.puml slides/plantuml/plugins/.
                    echo Symlinked PlantUML C4 to ./slides/plantuml/plugins
                    ln -snf ${inputs.plantumlEIP}/dist/*.puml slides/plantuml/plugins/.
                    echo Symlinked PlantUML EIP to ./slides/plantuml/plugins
                  fi

                  export REVEAL_ROOT="${inputs.revealjs}"
                  export REVEAL_MATHJAX_URL=
                  export PATH=${pkgs.plantuml}/bin:$PATH
                  echo $@
                  ${emacs}/bin/emacs --batch -q -l slides/export.el \
                      --eval="(org-re-reveal-export-file \"$@\" \"${inputs.revealjs}\" \"${inputs.mathjax}/tex-chtml.js\")"
                '';
              in
              {
                type = "app";
                program = "${app}";
              };

            # May be used to create the PDF version of the talk. See the Makefile
            # for an actual invocation.
            decktape =
              let
                app = pkgs.writeShellScript "run-decktape" "${pkgs.nodejs}/bin/node ${
                  self.packages.${system}.decktapeWithDependencies
                }/decktape.js $@";
              in
              {
                type = "app";
                program = "${app}";
              };
            pdfunite =
              let
                poppler = pkgs.poppler-utils;
              in
              {
                type = "app";
                program = "${poppler}/bin/pdfunite";
              };
          };
        };
    };
}
