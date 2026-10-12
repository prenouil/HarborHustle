# Harbor Hustle

Jeu de gestion de port en 3D, vue isométrique (Godot 4.7, GDScript, Forward Plus).
On ne dirige aucun personnage : tout se joue à la souris, en donnant des ordres de construction.
Direction artistique : celle de Globozone (blocs low-poly, couleurs franches, ambiance bleue) ; l'auteur en détient les droits.

## Lancer

Godot : `C:\Users\user\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`

- Importer (après ajout de fichiers) : `Godot --headless --path . --import`
- Capture d'écran : `Godot --path . --script res://tests/screenshot.gd -- <fichier.png> [secondes]`
  (variables `SHOT_ZOOM` = taille de la caméra, `SHOT_FOCUS` = "x,z" du point visé sur le quai)

## Organisation

- `scenes/main.tscn` : scène principale, construite par `scripts/main.gd`.
- `scripts/blocks.gd` : briques low-poly (boîtes, prismes, troncs de pyramide, matériaux unis partagés).
- `scripts/harbor.gd` : eau, quai (bord en z = 0, eau côté +z, dessus à y = 1.5), hangars, mobilier.
- `scripts/ship.gd` : bateau amarré ; `containers` liste les containers dans l'ordre où on peut les décharger.
- `scripts/hero.gd` : le héros (barbu à cravate), animation d'attente.
- `scripts/camera_rig.gd` : caméra orthographique isométrique, zoom vers le curseur, déplacement clic droit / ZQSD.
- `tests/` : scripts `extends SceneTree` lancés en ligne de commande.

## Conventions

- Commentaires et textes en français.
- Pas de `class_name` : les scripts se référencent par `preload` (fonctionne sans cache d'import).
- Tant qu'il n'y a pas d'assets Globozone importés, les modèles sont générés par code avec `blocks.gd`.
- Fichiers en UTF-8, fins de ligne LF.
