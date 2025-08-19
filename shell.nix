{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    nodePackages.svgo
    mdbook

    gdtoolkit_4

    python312

    # Ordered dithering
    python312Packages.pillow
    python312Packages.numpy
  ];
}
