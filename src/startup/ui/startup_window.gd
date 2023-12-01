extends Control

var explorer : FileDialog


###############################################################
#region Basic stuff  ##########################################
###############################################################

# Setting up the Startup Screen
func _ready() -> void:
	%VersionLabel.text = ProjectSettings.get_setting("application/config/version")
	load_recent_projects()


# Function to open the editor, also closes the startup menu
func open_editor(arg: PackedStringArray) -> void:
	# Editor check
	if Engine.is_editor_hint():
		print("Running from editor, can't start GoZen Editor")
		get_tree().quit()
	
	# Getting executable path for editor
	var path : String = OS.get_executable_path().get_base_dir()+  "/gozen_editor.%s"
	match OS.get_name():
		"Windows": path = path % "exe"
		"Linux":   path = path % "x86_64"
		_: 
			printerr("On this moment '%s' is not supported!" % OS.get_name())
			get_tree().quit()
	
	# Opens a new thread else startup menu can't close
	var thread := Thread.new()
	var x := func(): 
		OS.execute(path, [arg])
	thread.start(x)
	get_tree().quit()


# Loading the 5 most recently worked on projects
func load_recent_projects() -> void:
	const path: String = "user://recent_projects.dat"
	if !FileAccess.file_exists(path):
		print("No recent projects yet")
		return
	
	# Updating the recent projects file and adding buttons
	var file_access := FileAccess.open(path, FileAccess.READ)
	var old_recent_projects: Array = file_access.get_as_text().split('\n')
	var new_recent_projects: String = ""
	for entry: String in old_recent_projects:
		var project_data: PackedStringArray = entry.split('||')
		if project_data.size() != 2: # End of file reached!
			break 
		if FileAccess.file_exists(entry):
			# Adding existing files to the new_recent_projects for saving later
			new_recent_projects += "%s\n" % entry
		else: # If file does not exist, we do not need to go further
			continue
		if %RecentProjectsVBox.get_child_count() == 5:
			# We only need the first 5 existing project files, so we
			# skip the next part of adding a button			# can be "" = empty so we need to check for this
			continue
		
		# Adding the recent projects button
		var button := Button.new()
		button.text = project_data[0]
		button.tooltip_text = project_data[1]
		button.icon = preload("res://assets/icons/video_file.png")
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.connect("pressed", open_editor.bind([project_data[1]]))
		%RecentProjectsVBox.add_child(button)
	file_access.open(path, FileAccess.WRITE)
	file_access.store_string(new_recent_projects)
	old_recent_projects = []

#endregion
###############################################################
#region Upper area  ###########################################
###############################################################

# Make link to image clickable
func _on_image_credit_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)


# Open the github page when editor button is pressed
func _on_editor_button_pressed() -> void:
	OS.shell_open("https://github.com/voylin/GoZen")


# Close startup when exit is pressed
func _on_exit_button_pressed() -> void:
	get_tree().quit()


# Play show animation
func _on_exit_button_mouse_entered() -> void:
	$AnimationPlayer.play("show_exit_button")


# Play hide animation for exit button
func _on_exit_button_mouse_exited() -> void:
	$AnimationPlayer.play("hide_exit_button")

#endregion
###############################################################
#region Bottom area  ##########################################
###############################################################

func _on_new_fhd_button_pressed(horizontal: bool) -> void:
	if horizontal: open_editor(["new", tr("UNTITLED_PROJECT_TITLE"), "1920x1080"])
	else:          open_editor(["new", tr("UNTITLED_PROJECT_TITLE"), "1080x1920"])


func _on_new_4k_button_pressed(horizontal: bool) -> void:
	if horizontal: open_editor(["new", tr("UNTITLED_PROJECT_TITLE"), "1920x1080"])
	else:          open_editor(["new", tr("UNTITLED_PROJECT_TITLE"), "1080x1920"])


func _on_new_custom_button_pressed() -> void:
	$NewCustomWindow.visible = true


func _on_open_project_button_pressed() -> void:
	# TODO: Change this with native file manager or custom one
	explorer = FileDialog.new()
	explorer.title = tr("EXPLORER_OPEN_PROJECT")
	explorer.add_filter("*.gozen")
	explorer.show_hidden_files = true
	explorer.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	explorer.file_selected.connect(_on_open_project_file_selected)
	explorer.canceled.connect(_on_open_project_cancel)
	add_child(explorer)
	explorer.popup_centered(Vector2i(600,500))


func _on_support_project_button_pressed() -> void:
	OS.shell_open("https://ko-fi.com/voylin")

#endregion
###############################################################
#region Custom project  #######################################
###############################################################

func _on_new_custom_cancel_button_pressed() -> void:
	%NewProjectTitleLineEdit.text = ""
	%XSpinBox.value = 1920
	%YSpinBox.value = 1080
	$NewCustomWindow.visible = false


func _on_new_custom_confirm_button_pressed() -> void:
	var title: String = %NewProjectTitleLineEdit.text
	if title == "":
		title = tr("UNTITLED_PROJECT_TITLE")
	open_editor(["new", title, "%sx%s" % [%XSpinBox.value, %YSpinBox.value]])

#endregion
###############################################################
# region Open project explorer  ###############################
###############################################################

func _on_open_project_cancel() -> void:
	explorer.queue_free()


func _on_open_project_file_selected(path: String) -> void:
	open_editor([path])

#endregion
###############################################################
