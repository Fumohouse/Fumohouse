extends Node


var menus := {}
var default_menu: DebugMenu
var current_menu: DebugMenu


func _unhandled_input(event: InputEvent):
	var menu_arr: Array[DebugMenu] = menus.values()

	for menu in menu_arr:
		if menu.action == "":
			continue

		if event.is_action_pressed(menu.action):
			if current_menu and menu.menu_name == current_menu.menu_name:
				close_menu()
			else:
				switch_menu(menu)


func register_menu(menu: DebugMenu):
	if menus.has(menu.menu_name):
		push_error("Menu %s is already registered." % menu.menu_name)
		return

	menus[menu.menu_name] = menu


func set_default_menu(menu: DebugMenu):
	default_menu = menu
	if not current_menu:
		switch_menu(menu)


func deregister_menu(m_name: StringName):
	if not menus.has(m_name):
		push_error("Menu %s is not registered." % m_name)
		return

	menus.erase(m_name)


func switch_menu(menu: DebugMenu):
	if current_menu:
		current_menu.update_visibility(false)

	current_menu = menu
	current_menu.update_visibility(true)


func close_menu():
	if not current_menu:
		return

	if default_menu:
		switch_menu(default_menu)
	else:
		current_menu.update_visibility(false)
		current_menu = null
