extends Node


var MVolume = {
	"value":1,
	"range":[0,1]
	}
var SVolume = {
	"value":1,
	"range":[0,1]
	}
var MouseSens={
	"value":1,
	"range":[0.1,10]
}
var MotionShake={
	"value":1.0,
	"range":[0.0,1.0]
}
# Called when the node enters the scene tree for the first time.
func _init() -> void:
	var configfile = ConfigFile.new()
	if configfile.load("user://config.cfg") == OK:
		MouseSens["value"]=configfile.get_value("SETTINGS","MouseSens",1.0)
		MVolume["value"]=configfile.get_value("SETTINGS","MVolume",1.0)
		SVolume["value"]=configfile.get_value("SETTINGS","SVolume",1.0)
		MotionShake["value"]=configfile.get_value("SETTINGS","MotionShake",1.0)
	else:
		configfile.set_value("SETTINGS","MouseSens",MouseSens["value"])
		configfile.set_value("SETTINGS","MVolume",MVolume["value"])
		configfile.set_value("SETTINGS","SVolume",SVolume["value"])
		configfile.set_value("SETTINGS","MotionShake",MotionShake["value"])
		configfile.save("user://config.cfg")

func save_settings():
	var configfile = ConfigFile.new()
	configfile.set_value("SETTINGS","MouseSens",MouseSens["value"])
	configfile.set_value("SETTINGS","MVolume",MVolume["value"])
	configfile.set_value("SETTINGS","SVolume",SVolume["value"])
	configfile.set_value("SETTINGS","SVolume",MotionShake["value"])
	var saved=configfile.save("user://config.cfg")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	AudioServer.set_bus_volume_db(0,linear_to_db(MVolume["value"]))
	pass
