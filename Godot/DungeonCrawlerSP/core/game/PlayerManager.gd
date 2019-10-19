extends Node

const PlayerAgentGd          = preload("res://core/agent/PlayerAgent.gd")

onready var playerAgent : PlayerAgentGd = $"PlayerAgent"
var _currentLevel : LevelBase          setget setCurrentLevel


func deleted(_a):
	assert(false)


func setPlayerUnits( playerUnits : Array ):
	for unit in playerUnits:
		assert( unit is UnitBase )

	var unitsToRemove := []
	for unit in playerAgent.getUnits():
		if not unit in playerUnits:
			unitsToRemove.append( unit )

	Utility.freeIfNotInTree( unitsToRemove )

	addPlayerUnits( playerUnits )


func addPlayerUnits( playerUnits : Array ):
	for unit in playerUnits:
		assert( unit is UnitBase )
		playerAgent.addUnit( unit )

	if _currentLevel:
		_currentLevel.update()


func removePlayerUnits( playerUnits : Array ):
	for unit in playerUnits:
		assert( unit is UnitBase )
		playerAgent.removeUnit( unit )

	Utility.freeIfNotInTree( playerUnits )


func getPlayerUnits():
	return playerAgent.getUnits()


func unparentUnits():
	for unit in playerAgent.getUnits():
		assert( unit is UnitBase )
		unit.get_parent().remove_child( unit )


func setCurrentLevel( level : LevelBase ):
	_currentLevel = level


func _onCurrentLevelChanged( level : LevelBase ):
	setCurrentLevel( level )


func _updatePlayerAgentProcessing():
	playerAgent.setProcessing( !Console._consoleBox.visible )
