extends Node

const SAVE_PATH = "user://config.cfg"

var _config_file = ConfigFile.new()
var _settings = {
	"audio": {
		"music": Globals.music,
		"sfx": Globals.sfx
	}
}
var _default = {
	"audio": {
		"music": Globals.music,
		"sfx": Globals.sfx
	}
}

func _ready():
	load_settings()

func save_settings():
	for section in _settings.keys():
		for key in _settings[section]:
			_config_file.set_value(section, key, _settings[section][key])
	
	_config_file.save(SAVE_PATH)


func load_settings():
	# Open file
	var error = _config_file.load(SAVE_PATH)
	# Check if it opened correctly
	if error != OK:
		print("Failed loading the settings file. Error code %s" % error)
		return null
	# Retrieve the values and store them
	for section in _settings.keys():
		for key in _settings[section]:
			_settings[section][key] = _config_file.get_value(section, key, _default[section][key])
			
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _settings["audio"]["music"])
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), _settings["audio"]["sfx"])
