extends Control

signal return_pressed

func _on_ReturnButton_mouse_entered():
	play_menu_move()

func _on_ReturnButton_focus_entered():
	play_menu_move()

func _on_ReturnButton_pressed():
	emit_signal("return_pressed")
	play_menu_select()

func play_menu_move():
	SoundFx.play_menu("Menu Move", rand_range(0.8, 1.2), -30)

func play_menu_select():
	SoundFx.play_menu("Menu Select", rand_range(0.8, 1.2), -30)
