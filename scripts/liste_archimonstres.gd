extends Control

const CHEMIN_BASE := "res://archimonstre.db.sqlite"
const SCENE_SELECTION := "res://scenes/selection_personnage.tscn"

const REQUETE_DEBUT := """
	SELECT a.id AS id, a.monstre AS monstre, a.nom AS nom, a.lvl_min AS lvl_min, a.lvl_max AS lvl_max,
		p.nom AS pierre, GROUP_CONCAT(z.nom) AS zones,
		IIF(c.personnage_id IS NULL, 0, 1) AS capture
	FROM archimonstre a
	JOIN pierre_dame p ON p.id = a.pierre_dame_id
	LEFT JOIN archimonstre_zone az ON az.archimonstre_id = a.id
	LEFT JOIN zone_de_monstre z ON z.id = az.zone_id
	LEFT JOIN capture c ON c.archimonstre_id = a.id AND c.personnage_id = ?
	WHERE a.lvl_max >= ? AND a.lvl_min <= ?
		AND a.nom LIKE ? AND a.monstre LIKE ?
"""

const REQUETE_FIN := """
	GROUP BY a.id
	ORDER BY a.monstre, a.nom
"""

const REQUETE_PIERRES := """
	SELECT p.nom AS pierre, COUNT(*) AS total
	FROM archimonstre a
	JOIN pierre_dame p ON p.id = a.pierre_dame_id
	LEFT JOIN capture c ON c.archimonstre_id = a.id AND c.personnage_id = ?
	WHERE c.personnage_id IS NULL
	GROUP BY p.id
	ORDER BY p.id
"""

var personnage: Dictionary = {}

var base: SQLite

@onready var bouton_retour: Button = %BoutonRetour
@onready var titre: Label = %Titre
@onready var etiquette_compteur: Label = %EtiquetteCompteur
@onready var etiquette_pierres: Label = %EtiquettePierres
@onready var tableau: Tree = %TableauArchimonstres
@onready var filtre_lvl_min: SpinBox = %FiltreLvlMin
@onready var filtre_lvl_max: SpinBox = %FiltreLvlMax
@onready var filtre_recherche: LineEdit = %FiltreRecherche
@onready var filtre_monstre: LineEdit = %FiltreMonstre
@onready var filtre_captures: CheckBox = %FiltreCaptures
@onready var filtre_non_captures: CheckBox = %FiltreNonCaptures
@onready var bouton_reset: Button = %BoutonReset


func _ready() -> void:
	base = SQLite.new()
	base.path = CHEMIN_BASE
	if not base.open_db():
		titre.text = "Impossible d'ouvrir la base archimonstre.db.sqlite."
		return
	titre.text = "Personnage : %s (%s)" % [personnage.get("nom", "?"), personnage.get("serveur", "?")]
	_configurer_tableau()
	bouton_retour.pressed.connect(_on_retour_pressed)
	filtre_lvl_min.value_changed.connect(_on_filtre_modifie)
	filtre_lvl_max.value_changed.connect(_on_filtre_modifie)
	filtre_recherche.text_changed.connect(_on_filtre_modifie)
	filtre_monstre.text_changed.connect(_on_filtre_modifie)
	filtre_captures.toggled.connect(_on_filtre_modifie)
	filtre_non_captures.toggled.connect(_on_filtre_modifie)
	bouton_reset.pressed.connect(_on_reset_pressed)
	tableau.item_edited.connect(_on_item_edite)
	_rafraichir()


func _configurer_tableau() -> void:
	tableau.columns = 6
	tableau.hide_root = true
	tableau.column_titles_visible = true
	tableau.set_column_title(0, "Capture")
	tableau.set_column_title(1, "Monstre")
	tableau.set_column_title(2, "Archimonstre")
	tableau.set_column_title(3, "Niveau")
	tableau.set_column_title(4, "Zones")
	tableau.set_column_title(5, "Pierre")
	tableau.set_column_custom_minimum_width(0, 60)
	tableau.set_column_custom_minimum_width(1, 140)
	tableau.set_column_custom_minimum_width(2, 200)
	tableau.set_column_custom_minimum_width(3, 70)
	tableau.set_column_custom_minimum_width(4, 260)
	tableau.set_column_custom_minimum_width(5, 70)
	for colonne: int in tableau.columns:
		tableau.set_column_expand(colonne, true)


func _rafraichir() -> void:
	tableau.clear()
	var motif_nom: String = "%" + filtre_recherche.text.strip_edges() + "%"
	var motif_monstre: String = "%" + filtre_monstre.text.strip_edges() + "%"
	var bindings: Array = [personnage.get("id", 0), int(filtre_lvl_min.value), int(filtre_lvl_max.value), motif_nom, motif_monstre]
	var requete: String = REQUETE_DEBUT + _condition_capture() + REQUETE_FIN
	if not base.query_with_bindings(requete, bindings):
		etiquette_compteur.text = "Erreur lors de la lecture des archimonstres."
		return
	var racine: TreeItem = tableau.create_item()
	for entree: Dictionary in base.query_result:
		_ajouter_ligne(racine, entree)
	_maj_compteur()


func _ajouter_ligne(racine: TreeItem, entree: Dictionary) -> void:
	var ligne: TreeItem = tableau.create_item(racine)
	ligne.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	ligne.set_editable(0, true)
	ligne.set_checked(0, int(entree["capture"]) == 1)
	ligne.set_metadata(0, int(entree["id"]))
	ligne.set_text(1, String(entree["monstre"]))
	ligne.set_text(2, String(entree["nom"]))
	ligne.set_text(3, "%d à %d" % [int(entree["lvl_min"]), int(entree["lvl_max"])])
	ligne.set_text(4, String(entree["zones"]))
	ligne.set_text(5, String(entree["pierre"]).get_slice(" ", 0))


func _maj_compteur() -> void:
	base.query("SELECT COUNT(*) AS total FROM archimonstre")
	var total: int = int(base.query_result[0]["total"])
	base.query_with_bindings("SELECT COUNT(*) AS total FROM capture WHERE personnage_id = ?", [personnage.get("id", 0)])
	etiquette_compteur.text = "%d/%d archimonstres capturés" % [int(base.query_result[0]["total"]), total]
	_maj_pierres()


func _maj_pierres() -> void:
	if not base.query_with_bindings(REQUETE_PIERRES, [personnage.get("id", 0)]):
		return
	var morceaux: Array[String] = []
	for entree: Dictionary in base.query_result:
		morceaux.append("%s : %d" % [String(entree["pierre"]).get_slice(" ", 0), int(entree["total"])])
	etiquette_pierres.text = "Reste à capturer — " + " | ".join(morceaux)


func _condition_capture() -> String:
	if filtre_captures.button_pressed and not filtre_non_captures.button_pressed:
		return " AND c.personnage_id IS NOT NULL"
	if filtre_non_captures.button_pressed and not filtre_captures.button_pressed:
		return " AND c.personnage_id IS NULL"
	return ""


func _on_filtre_modifie(_valeur: Variant) -> void:
	_rafraichir()


func _on_reset_pressed() -> void:
	filtre_lvl_min.set_value_no_signal(0)
	filtre_lvl_max.set_value_no_signal(200)
	filtre_captures.button_pressed = false
	filtre_non_captures.button_pressed = false
	filtre_recherche.text = ""
	filtre_monstre.text = ""
	_rafraichir()


func _on_item_edite() -> void:
	var item: TreeItem = tableau.get_edited()
	if item == null:
		return
	_enregistrer_capture(item)


func _enregistrer_capture(item: TreeItem) -> void:
	var bindings: Array = [personnage.get("id", 0), int(item.get_metadata(0))]
	if item.is_checked(0):
		base.query_with_bindings("INSERT OR IGNORE INTO capture (personnage_id, archimonstre_id) VALUES (?, ?)", bindings)
		_maj_compteur()
		return
	base.query_with_bindings("DELETE FROM capture WHERE personnage_id = ? AND archimonstre_id = ?", bindings)
	_maj_compteur()


func _on_retour_pressed() -> void:
	var scene: PackedScene = load(SCENE_SELECTION)
	var instance: Node = scene.instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(instance)
	get_tree().current_scene = instance
