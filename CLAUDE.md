# Harbor Hustle

Jeu de gestion de port en 3D, vue isométrique (Godot 4.7, GDScript, Forward Plus).
Tout se joue à la souris : on construit (hangars, grue), on achète (camions, dockers) et on envoie le héros
utiliser la console de la grue pour décharger les bateaux.
Direction artistique : celle de Globozone (blocs low-poly, couleurs franches, ambiance bleue) ; l'auteur en détient les droits.

## Boucle de jeu

- Départ : quai vide, 100 000 €. Un premier bateau arrive et s'amarre.
- Bâtiment (bouton à gauche) : hangar 2 000 € (rangée du fond), grue 1 000 € (à côté du bateau, une seule) ;
  placement avec fantôme et carré vert/rouge, puis le héros construit pendant 10 s (il n'est plus contrôlable).
- Véhicule / Personnel (boutons à droite) : camion 1 000 €, docker 100 €.
- Console de la grue (il faut au moins un hangar, un camion et un docker) : Oui lance le déchargement.
  Au plus 2 camions circulent et 2 dockers travaillent en même temps. Bateau vide : il repart, un autre arrive.

## Lancer

Godot : `C:\Users\user\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`

- Importer (après ajout de fichiers) : `Godot --headless --path . --import`
- Partie complète automatisée : `Godot --headless --path . --script res://tests/test_game.gd`
- Capture d'écran : `Godot --path . --script res://tests/screenshot.gd -- <fichier.png> [secondes de jeu]`
  (variables décrites en tête du script : `SHOT_ZOOM`, `SHOT_FOCUS`, `SHOT_SETUP`, `SHOT_UNLOAD`, `SHOT_SPEED`,
  `SHOT_PLACE` / `SHOT_BUILD` avec `SHOT_PLACE_AT`)

## Organisation

- `scenes/main.tscn` : scène principale, construite par `scripts/main.gd` (argent, achats, placement, chantier, clics).
- `scripts/harbor.gd` : eau, quai vide et mobilier ; constantes du plan du quai (voies, rangée des hangars, limites).
- `scripts/logistics.gd` : bateaux (arrivée, départ), circuit des camions, travail des dockers.
- `scripts/hangar.gd`, `scripts/crane.gd`, `scripts/console.gd` : bâtiments ; `crane.transfer()` passe un container du bateau au camion.
- `scripts/truck.gd` : camion de 4 containers. Voie A (z = -8, sous la grue, vers -x), voie B (z = -17, vers +x),
  stationnement devant les hangars (z = -20.5). Hors de l'écran, il passe d'une voie à l'autre.
- `scripts/ship.gd` : porte-containers ; `containers` liste les containers dans l'ordre où on peut les décharger.
- `scripts/character.gd` : héros ou docker (avec transpalette), marche le long d'un chemin, gestes de chantier.
- `scripts/placement.gd` : fantôme du bâtiment à placer et validité de l'emplacement.
- `scripts/construction.gd` + `shaders/build_reveal.gdshader` : bâtiment qui apparaît du bas vers le haut.
- `scripts/walk_map.gd` : zone praticable du quai et chemins (AStarGrid2D + lissage), reconstruite à chaque bâtiment.
- `scripts/hud.gd`, `scripts/dialog.gd` : interface et fenêtre modale à boutons.
- `scripts/blocks.gd` : briques low-poly (boîtes, prismes, troncs de pyramide, matériaux unis partagés).
- `scripts/camera_rig.gd` : caméra orthographique isométrique, zoom vers le curseur, déplacement clic droit / ZQSD.
- `tests/` : scripts `extends SceneTree` lancés en ligne de commande.

## Conventions

- Commentaires et textes en français.
- Pas de `class_name` : les scripts se référencent par `preload` (fonctionne sans cache d'import).
- Tant qu'il n'y a pas d'assets Globozone importés, les modèles sont générés par code avec `blocks.gd`.
- Fichiers en UTF-8, fins de ligne LF. Attention avec PowerShell : `Get-Content -Raw` lit en ANSI et casse les accents.
