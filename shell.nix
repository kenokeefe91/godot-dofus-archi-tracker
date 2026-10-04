{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    # Python 3 : le module sqlite3 est inclus dans la bibliothèque standard
    pkgs.python3
    # CLI sqlite3 pour inspecter archimonstre.db.sqlite directement
    pkgs.sqlite
  ];

  shellHook = ''
    echo "[shell.nix] python3 + sqlite3 prêts pour le tracker d'archimonstres"
  '';
}
