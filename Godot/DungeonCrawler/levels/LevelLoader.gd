extends Reference

const GlobalGd               = preload("res://GlobalNames.gd")
const UtilityGd              = preload("res://Utility.gd")

signal levelLoaded( nodeName )
signal levelUnloaded( nodeName )

enum State { Ready, Adding, Removing }

var m_game : Node                      setget deleted
var m_levelFilename : String           setget deleted
var m_state : int = State.Ready        setget deleted


func deleted(_a):
	assert(false)


func _init( game : Node ):
	m_game = game


func loadLevel( levelFilename : String, levelParent : Node ):
	if m_state != State.Ready:
		Debug.warn(self, "LevelLoader not ready to load %s" % levelFilename)
		return

	var level = load( levelFilename )
	if not level:
		Debug.err( self, "Could not load level file: " + levelFilename )
		return

	var revertState = UtilityGd.scopeExit( self, "_changeState", [m_state] )
	_changeState( State.Adding, levelFilename )

	level = level.instance()

	if m_game.m_currentLevel == null:
		assert( not m_game.has_node( level.name ) )
		assert( m_game.is_a_parent_of( levelParent ) )
		levelParent.add_child( level )
		m_game.setCurrentLevel( level )
	else:
		unloadLevel()
		yield( self, "levelUnloaded" )
		assert( not m_game.has_node( level.name ) )
		m_game.add_child( level )
		m_game.setCurrentLevel( level )

	assert( level.is_inside_tree() )
	assert( m_game.m_currentLevel == level )

	call_deferred( "emit_signal", "levelLoaded", level.name )


func unloadLevel():
	assert( m_game.m_currentLevel )
	# take player units from level
	for playerUnit in m_game.getPlayerUnits():
		m_game.m_currentLevel.removeChildUnit( playerUnit )

	if m_game.m_module:
		m_game.m_module.saveLevel( m_game.m_currentLevel )

	m_game.m_currentLevel.queue_free()
	var levelName = m_game.m_currentLevel.name
	yield( m_game.m_currentLevel, "predelete" )
	assert( not m_game.m_currentLevel ) #TODO: current level can exist if m_game is loaded
	emit_signal( "levelUnloaded", levelName )


func insertPlayerUnits( playerUnits, level, entranceName ):
	var spawns = getSpawnsFromEntrance( level, entranceName )

	for unit in playerUnits:

		var freeSpawn = findFreePlayerSpawn( spawns )
		if freeSpawn == null:
			continue

		spawns.erase(freeSpawn)
		level.get_node("Units").add_child( unit, true )
		unit.set_position( freeSpawn.global_position )


func getSpawnsFromEntrance( level, entranceName ):
	var spawns = []
	var entranceNode

	if entranceName == null:
		Debug.info(self, "Level entrance name unspecified. Using first entrance found.")
		entranceNode = level.get_node("Entrances").get_child(0)
	else:
		entranceNode = level.get_node("Entrances/" + entranceName)
		if entranceNode == null:
			Debug.warn(self, "Level entrance name not found. Using first entrance found.")
			entranceNode = level.get_node("Entrances").get_child(0)

	assert( entranceNode != null )
	for child in entranceNode.get_children():
		if child.is_in_group( GlobalGd.Groups.SpawnPoints ):
			spawns.append( child )

	return spawns


func findFreePlayerSpawn( spawns ):
	for spawn in spawns:
		if spawn.spawnAllowed():
			return spawn

	return null


func _changeState( state : int, levelFilename : String = "" ):
	match( state ):
		m_state:
			Debug.warn(self, "changing to same state")
			return
		State.Ready:
			assert( levelFilename.empty() )
		State.Adding:
			assert( not levelFilename.empty() )
		State.Removing:
			assert( not levelFilename.empty() )

	m_levelFilename = levelFilename
	m_state = state
