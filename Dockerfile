FROM nixos/nix:latest

COPY config.nix /root/.config/nixpkgs/

RUN  nix-env -iA nixpkgs.python2

RUN  nix-env -iA nixpkgs.busybox
RUN  nix-env -iA nixpkgs.gawk
RUN  nix-env -iA nixpkgs.gnused
RUN  nix-env -iA nixpkgs.gnumake

# See this tool for old versions of nix packages
#   https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=emscripten
RUN  nix-env -iA emscripten -f https://github.com/NixOS/nixpkgs/archive/25b53f32236b308172673c958f570b5b488c7b73.tar.gz
RUN  nix-env -iA nixpkgs.micro
