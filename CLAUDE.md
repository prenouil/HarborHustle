# Harbor Hustle

Jeu de gestion de port en 3D, vue isométrique (Godot 4.7, GDScript, Forward Plus).
On ne dirige aucun personnage : tout se joue à la souris, en donnant des ordres de construction.
Direction artistique : celle de Globozone (blocs low-poly, couleurs franches, ambiance bleue) ; l'auteur en détient les droits.

## Lancer

Godot : `C:\Users\user\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`

- Importer (après ajout de fichiers) : `Godot --headless --path . --import`
- Capture d'écran : `Godot --path . --script res://tests/screenshot.gd -- <fichier.png> [secondes]`
  (variables `SHOT_ZOOM` = taille de la caméra, `SHOT_FOCUS` = "x,z" du point visé sur le quai,
  `SHOT_UNLOAD` = lance le déchargement dès le départ)
- Scénario complet (console, Oui/Non, déchargement, camions) : `Godot --headless --path . --script res://tests/test_unloading.gd`

## Organisation

- `scenes/main.tscn` : scène principale, construite par `scripts/main.gd` (clics, console, interface).
- `scripts/blocks.gd` : briques low-poly (boîtes, prismes, troncs de pyramide, matériaux unis partagés).
- `scripts/harbor.gd` : eau, quai (bord en z = 0, eau côté +z, dessus à y = 1.5), hangars, mobilier, obstacles au sol.
- `scripts/ship.gd` : bateau amarré ; `containers` liste les containers dans l'ordre où on peut les décharger.
- `scripts/crane.gd` : grue portique (rails en z = -4 et -12) ; `transfer()` déplace un container du bateau au camion.
- `scripts/truck.gd` : camion de 4 containers, voie en z = -8 sous la grue, arrive par +x et repart par -x.
- `scripts/unloading.gd` : déroulé du déchargement (camions successifs jusqu'à bateau vide).
- `scripts/console.gd` / `scripts/console_dialog.gd` : console de la grue sur le quai et sa fenêtre Oui / Non.
- `scripts/walk_map.gd` : zone praticable du quai et chemins (AStarGrid2D + lissage en lignes droites).
- `scripts/hero.gd` : le héros (barbu à cravate), marche le long d'un chemin, animations de marche et d'attente.
- `scripts/camera_rig.gd` : caméra orthographique isométrique, zoom vers le curseur, déplacement clic droit / ZQSD.
- `tests/` : scripts `extends SceneTree` lancés en ligne de commande.

## Conventions

- Commentaires et textes en français.
- Pas de `class_name` : les scripts se référencent par `preload` (fonctionne sans cache d'import).
- Tant qu'il n'y a pas d'assets Globozone importés, les modèles sont générés par code avec `blocks.gd`.
- Fichiers en UTF-8, fins de ligne LF.
