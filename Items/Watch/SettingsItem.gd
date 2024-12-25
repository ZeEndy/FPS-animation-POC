extends VBoxContainer

enum SettingsType{
	SSlider,
	SSliderStepped,
	SBool
}
@export var Step=0.01 #only used for slider
@export var Type : SettingsType
@export var AffectedSetting=""
@export var Formatting = "%2.01f"
var ValueView
var ValueView2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_focus_mode(Control.FOCUS_ALL)
	if Type==SettingsType.SSlider || Type==SettingsType.SSliderStepped:
		ValueView=get_node("ProgressBar")
		ValueView2=ValueView.get_node("Label")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if has_focus() && is_visible_in_tree():
		match Type:
			SettingsType.SSlider:
				var SInput=int(Input.is_action_pressed("RIGHT"))-int(Input.is_action_pressed("LEFT"))
				var SettingDict=Settings.get(AffectedSetting)
				#print(SettingDict["value"])
				SettingDict["value"]+=SInput*Step
				if SettingDict["range"][0]!=null:
					SettingDict["value"]=max(SettingDict["value"],SettingDict["range"][0])
				if SettingDict["range"][1]!=null:
					SettingDict["value"]=min(SettingDict["value"],SettingDict["range"][1])
				ValueView.value=SettingDict["value"]
				ValueView2.text = Formatting % SettingDict["value"]
				Settings.set(AffectedSetting,SettingDict)
				
	pass
