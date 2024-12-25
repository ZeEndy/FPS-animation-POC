#@tool
extends Node

signal Resumed()
signal MenuStatusChanged()

@onready var ViewpTexture : ViewportTexture = get_node("SubViewport").get_texture()
@onready var TimeText : Label = get_node("SubViewport/DefaultScreen/Label")

@onready var MenuItems = get_node("SubViewport/MenuScreen/MenuItems")
@onready var DefaultScreen : Control = get_node("SubViewport/DefaultScreen")
@onready var MenuScreen : Control = get_node("SubViewport/MenuScreen")
@onready var SettingsScreen : Control = get_node("SubViewport/Settings")
@onready var SettingsItems : VBoxContainer = get_node("SubViewport/Settings/Items")
@export var SelectedItem=0
enum MStates{
	Main,
	Settings,
}

var MenuState = MStates.Main
var MenuEnabled=false
var FontSize=60

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var time = Time.get_time_dict_from_system()
	var MenuItemCount = MenuItems.get_child_count()
	
	var SettingsCount = SettingsItems.get_child_count()
	if MenuEnabled:
		TimeText.visible=false
		match (MenuState):
			MStates.Main:
				if Input.is_action_just_pressed("Menu"):
					Resume()
					
				DealWithVisibilty()
				SelectedItem+=int(Input.is_action_just_pressed("DOWN"))-int(Input.is_action_just_pressed("UP"))
				if SelectedItem==-1:
					SelectedItem=MenuItemCount
				SelectedItem=SelectedItem%MenuItemCount
				for i in MenuItemCount:
					var ItemNode : Label = MenuItems.get_child(i)
					if i == SelectedItem:
						if Input.is_action_just_pressed("ACTION1"):
							match ItemNode.text:
								"RESUME":
									Resume()
									break
								"SETTINGS":
									MenuState=MStates.Settings
									SelectedItem=0
									SettingsItems.position.y=125
									break
								"QUIT":
									get_tree().quit()
						
						ItemNode["theme_override_font_sizes/font_size"]=ExpDecay(ItemNode["theme_override_font_sizes/font_size"],FontSize*1.8,20,delta)
					else:
						ItemNode["theme_override_font_sizes/font_size"]=ExpDecay(ItemNode["theme_override_font_sizes/font_size"],FontSize,5,delta)
				pass
			MStates.Settings:
				if Input.is_action_just_pressed("Menu"):
					MenuState=MStates.Main
					SelectedItem=1
					SettingsItems.position.y=125
					Settings.save_settings()
				DealWithVisibilty()
				
				SelectedItem+=int(Input.is_action_just_pressed("DOWN"))-int(Input.is_action_just_pressed("UP"))
				if SelectedItem==-1:
					SelectedItem=MenuItemCount
				SelectedItem=SelectedItem%SettingsCount
				
				for i in SettingsCount:
					var item : VBoxContainer = SettingsItems.get_child(SelectedItem)
					if i==SelectedItem:
						SettingsItems.position.y=ExpDecay(SettingsItems.position.y,125-item.position.y,20,delta)
						item.grab_focus()
				pass
	else:
		TimeText.visible=true
		MenuScreen.visible=false
		TimeText.text="%02d:%02d"%[time.hour,time.minute]
		if Input.is_action_just_pressed("Menu"):
			MenuStatusChanged.emit()
			MenuEnabled=true

func DealWithVisibilty():
	if MenuState==MStates.Main:
		MenuScreen.visible=true
		SettingsScreen.visible=false
	elif MenuState==MStates.Settings:
		MenuScreen.visible=false
		SettingsScreen.visible=true




func Resume():
	MenuStatusChanged.emit()
	MenuEnabled=false

static func ExpDecay(a,b,decay,dt):
	if typeof(a)==TYPE_BASIS:
		var result = Basis.IDENTITY
		result.x = ExpDecay(a.x,b.x,decay,dt)
		result.y = ExpDecay(a.y,b.y,decay,dt)
		result.z = ExpDecay(a.z,b.z,decay,dt)
		return result.orthonormalized()
	return b+(a-b)*exp(-decay*dt)
