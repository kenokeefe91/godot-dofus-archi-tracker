extends Control

const CHEMIN_BASE := "res://archimonstre.db.sqlite"
const SCENE_LISTE := "res://scenes/liste_archimonstres.tscn"

var base: SQLite

var _personnages: Array[Dictionary] = []

@onready var liste_personnages: ItemList = %ListePersonnages
@onready var champ_nom: LineEdit = %ChampNom
@onready var champ_serveur: LineEdit = %ChampServeur
@onready var champ_classe: LineEdit = %ChampClasse
@onready var bouton_ajouter: Button = %BoutonAjouter
@onready var etiquette_statut: Label = %EtiquetteStatut


func _ready() -> void:
	base = SQLite.new()
	base.path = _chemin_base()
	if not base.open_db():
		etiquette_statut.text = "Impossible d'ouvrir la base archimonstre.db.sqlite."
		return
	bouton_ajouter.pressed.connect(_on_bouton_ajouter_pressed)
	liste_personnages.item_activated.connect(_on_liste_personnages_active)
	_rafraichir_liste()


func _chemin_base() -> String:
	if OS.has_feature("editor"):
		return CHEMIN_BASE
	var chemin: String = "user://archimonstre.db.sqlite"
	if FileAccess.file_exists(chemin):
		return chemin
	var source: PackedByteArray = FileAccess.get_file_as_bytes(CHEMIN_BASE)
	var fichier: FileAccess = FileAccess.open(chemin, FileAccess.WRITE)
	fichier.store_buffer(source)
	fichier.close()
	return chemin


func _rafraichir_liste() -> void:
	liste_personnages.clear()
	_personnages.clear()
	if not base.query("SELECT id, nom, serveur, classe FROM personnage ORDER BY nom"):
		etiquette_statut.text = "Erreur lors de la lecture de la table personnage."
		return
	for entree: Dictionary in base.query_result:
		_personnages.append(entree)
		liste_personnages.add_item("%s — %s (%s)" % [entree["nom"], entree["classe"], entree["serveur"]])


func _on_bouton_ajouter_pressed() -> void:
	var nom: String = champ_nom.text.strip_edges()
	var serveur: String = champ_serveur.text.strip_edges()
	var classe: String = champ_classe.text.strip_edges()
	if nom.is_empty() or serveur.is_empty() or classe.is_empty():
		etiquette_statut.text = "Nom, serveur et classe sont obligatoires."
		return
	var requete := "INSERT INTO personnage (nom, serveur, classe) VALUES (?, ?, ?)"
	if not base.query_with_bindings(requete, [nom, serveur, classe]):
		etiquette_statut.text = "Ce personnage existe déjà sur ce serveur."
		return
	etiquette_statut.text = "Personnage ajouté."
	champ_nom.text = ""
	champ_serveur.text = ""
	champ_classe.text = ""
	_rafraichir_liste()


func _on_liste_personnages_active(index: int) -> void:
	var scene: PackedScene = load(SCENE_LISTE)
	var instance: Node = scene.instantiate()
	instance.set("personnage", _personnages[index])
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(instance)
	get_tree().current_scene = instance
