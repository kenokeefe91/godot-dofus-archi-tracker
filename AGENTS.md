# AGENTS.md — DofusArchiMonstreTracker

## Contexte projet

Tracker d'archimonstres Dofus (suivi de capture par monstre/zone). Application Godot, pas de code pour l'instant — le projet vient d'être scaffoldé.

- **Moteur :** Godot 4.7, renderer Forward Plus, physique Jolt
- **Langage :** GDScript typé (extensions `.gd`)
- **Données :** `liste_monstre.csv` — source de vérité des monstres (colonnes : Monstre, Nom Archimonstre, Image, Type, Etapes, Capturé, Nombre possédé, Zones, Lvl min, Lvl max, Pierre d'âme). Les colonnes `Lvl min`/`Lvl max` (tranche de niveau de l'archimonstre, extraite de DofusDB) et `Pierre d'âme` (Petite/Moyenne/Grande/Énorme, déduite de `Lvl max` : 50/100/150/190) sont vides quand la ligne n'a pas d'archimonstre. Encodage UTF-8, séparateur virgule, lignes CRLF, dernière ligne sans terminateur. Ne pas modifier ce fichier sans demande explicite.
- **Base :** `archimonstre.db.sqlite` — base sqlite régénérée via `nix-shell` (python3 + sqlite3). Tables : `zone_de_monstre` (id/nom/travel, remplie depuis `zones.csv`), `pierre_dame` (id/nom/lvl_max), `archimonstre` (id/nom/monstre/etapes/lvl_min/lvl_max/pierre_dame_id→pierre_dame/capture/nombre_possede, remplie depuis `liste_monstre.csv`) et `archimonstre_zone` (archimonstre_id/zone_id, relation n-n vers `zone_de_monstre`). Table `capture` (personnage_id/archimonstre_id, âmes capturées par personnage). Table `personnage` (id/nom/serveur/classe, nom unique par serveur) — vide pour l'instant, à remplir via l'application.
- **Binaire CLI :** `godot` disponible dans le PATH (`/usr/local/bin/godot`)

## Commandes

```bash
# Entrer dans l'environnement nix (python3 + sqlite3)
nix-shell

# Lancer le projet
godot --path /home/emmy/dofus-archi-monstre-tracker

# Vérifier qu'un script parse (à faire après chaque création/modification de .gd)
godot --path /home/emmy/dofus-archi-monstre-tracker --check-only --script <chemin_du_script.gd>

# Importer les ressources sans ouvrir l'éditeur (après ajout de fichiers)
godot --path /home/emmy/dofus-archi-monstre-tracker --headless --import

# Lancer une scène de test
godot --path /home/emmy/dofus-archi-monstre-tracker res://<scene>.tscn
```

Il n'y a pas encore de tests automatisés. Si des tests sont ajoutés, les lancer via `godot --headless` avec la scène de test dédiée.

## Structure

```
project.godot            # config moteur — éditer via l'éditeur si possible
icon.svg                 # icône du projet
liste_monstre.csv        # données des monstres (source de vérité)
zones.csv                # zones distinctes (id, nom, travel) — alimente zone_de_monstre
archimonstre.db.sqlite   # base sqlite (personnages, archimonstres, zones, pierres)
shell.nix                # environnement nix (python3 + sqlite3)
addons/godot-sqlite/     # GDExtension sqlite (dépendance autorisée)
scenes/                  # scènes .tscn
scripts/                 # scripts .gd
.godot/                  # cache import — ignoré par git, ne jamais commit
```

Scènes `.tscn` et scripts `.gd` : les ranger par fonctionnalité dans des dossiers dédiés (ex. `scenes/`, `scripts/`, `data/`) dès que le projet grandit.

## Règles de développement

- **GDScript typé** : typer les signatures de fonctions et les variables (`func foo(x: int) -> String:`, `var hp: int = 100`). Pas de `var` nu sans raison.
- **Style** : indentation par tabs (convention Godot), noms de fichiers en `snake_case.gd`, classes en `PascalCase`, signaux et fonctions en `snake_case`, constantes en `SCREAMING_SNAKE_CASE`.
- **Scènes** : préférer la composition (noeuds enfants explicites) à l'héritage de scènes.
- **Séparation données/logique** : le CSV est de la donnée ; le code qui le lit doit tolérer les lignes vides (la ligne 1 du CSV est vide, l'en-tête est en ligne 2) et les colonnes manquantes.
- **project.godot** : éviter les éditions manuelles quand le paramètre existe dans l'éditeur ; ne pas toucher aux sections `[rendering]` et `[physics]` sans raison.
- **Fichiers `.import`** : générés par Godot, mais commités (ne pas les ajouter au `.gitignore`).
- **Sauvegarde utilisateur** : utiliser `user://` (jamais `res://`) pour toute donnée modifiable à l'exécution (progression de capture, etc.).
- **Dépendances :** l'addon `godot-sqlite` (GDExtension, `addons/godot-sqlite/`) est installé et autorisé pour l'accès à la base sqlite (classe `SQLite`). Toute autre dépendance externe : demander d'abord.
