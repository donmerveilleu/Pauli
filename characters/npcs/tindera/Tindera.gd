extends NPC


func _init() -> void:
	npc_name = "Tindera"
	prompt_text = "Talk to the Tindera"

	first_lines = [
		DialogueLine.new("Paulina", "(Nag-text si Mama: \"Pag palit ug corned beef para panihapon nimo.\")"),
		DialogueLine.new("Paulina", "Manang, palit ko'g corned beef."),
		DialogueLine.new("Tindera", "Sige, iha. Eto na, sukli ni nimo."),
		DialogueLine.new("Tindera", "Diba taga-likod ka? Pagbantay pauli kay naa'y mga tawo sa kilid-kilid nga manghilabot o manyak."),
	]
	repeat_lines = [
		DialogueLine.new("Tindera", "Pag-amping, iha. Diretso na dayon pauli."),
	]
