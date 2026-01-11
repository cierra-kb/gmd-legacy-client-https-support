let
    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/d351d0653aeb7877273920cd3e823994e7579b0b.tar.gz";
    pkgs = import nixpkgs { config = {}; overlays = []; };
in

pkgs.mkShellNoCC {
    packages = with pkgs; [
        gnumake
        autoconf
        automake
        libtool
        gnum4
        perl
        cmake
        xxd
        wget
        ncurses5
    ];
}
