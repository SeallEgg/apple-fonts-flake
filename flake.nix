{
  description = "Flake providing package for Apple fonts.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    sf-pro.url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
    sf-pro.flake = false;

    sf-compact.url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
    sf-compact.flake = false;

    sf-mono.url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
    sf-mono.flake = false;

    sf-arabic.url = "https://devimages-cdn.apple.com/design/resources/download/SF-Arabic.dmg";
    sf-arabic.flake = false;

    sf-armenian.url = "https://devimages-cdn.apple.com/design/resources/download/SF-Armenian.dmg";
    sf-armenian.flake = false;

    sf-georgian.url = "https://devimages-cdn.apple.com/design/resources/download/SF-Georgian.dmg";
    sf-georgian.flake = false;

    sf-hebrew.url = "https://devimages-cdn.apple.com/design/resources/download/SF-Hebrew.dmg";
    sf-hebrew.flake = false;

    ny-serif.url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
    ny-serif.flake = false;

    apple-color-emoji.url = "https://github.com/samuelngs/apple-emoji-linux/releases/latest/download/AppleColorEmoji.ttf";
    apple-color-emoji.flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs systems;

    mkFontPackage = pkgs: name: src:
      if name == "apple-color-emoji"
      then
        pkgs.stdenvNoCC.mkDerivation {
          inherit name src;
          dontUnpack = true;
          installPhase = ''
            runHook preInstall
            mkdir -p $out/share/fonts/truetype
            cp "$src" $out/share/fonts/truetype/AppleColorEmoji.ttf
            runHook postInstall
          '';
          meta = with pkgs.lib; {
            description = "Apple Color Emoji font";
          };
        }
      else
        pkgs.stdenvNoCC.mkDerivation {
          inherit name src;
          nativeBuildInputs = [pkgs.p7zip pkgs.undmg];
          unpackPhase = ''
            runHook preUnpack
            undmg $src
            7z x *.pkg
            7z x Payload~
            runHook postUnpack
          '';
          installPhase = ''
            runHook preInstall
            mkdir -p $out/share/fonts/truetype $out/share/fonts/opentype
            find -name \*.otf -exec mv {} "$out/share/fonts/opentype/" \;
            find -name \*.ttf -exec mv {} "$out/share/fonts/truetype/" \;
            runHook postInstall
          '';
          meta = with pkgs.lib; {
            description = "Apple ${name} font";
          };
        };

    fontInputs = nixpkgs.lib.filterAttrs (n: _: n != "nixpkgs") inputs;

    makeFontPackageSet = pkgs: let
      fontPackages = nixpkgs.lib.mapAttrs (name: src: mkFontPackage pkgs name src) fontInputs;
    in
      fontPackages
      // {
        apple-fonts = pkgs.symlinkJoin {
          name = "apple-fonts";
          paths = nixpkgs.lib.attrValues fontPackages;
        };
      };
  in {
    packages = forAllSystems (
      system:
        makeFontPackageSet nixpkgs.legacyPackages.${system}
    );

    overlays.default = final: prev: makeFontPackageSet final;

    nixosModules.default = {
      config,
      pkgs,
      lib,
      ...
    }: {
      options.fonts.apple-fonts = {
        enable = lib.mkEnableOption "Apple fonts";
      };

      config = lib.mkIf config.fonts.apple-fonts.enable {
        fonts.packages = [(makeFontPackageSet pkgs).apple-fonts];
      };
    };
  };
}
