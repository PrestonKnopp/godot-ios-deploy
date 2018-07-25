extends Control

func _ready():
	get_tree().connect('files_dropped', self, '_on_files_dropped')

func _on_files_dropped(files, screen):
	print('Can Drop Data?', files, screen)