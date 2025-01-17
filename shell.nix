{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    nodePackages.svgo
    mdbook

    python312

    # Ordered dithering
    python312Packages.pillow
    python312Packages.numpy
  ];
}
