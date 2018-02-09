extends Node

const MainMenuScn = "res://gui/MainMenu.tscn"
const DebugWindowScn = "res://debug/DebugWindow.tscn"
const LoadingScreenScn = "res://gui/LoadingScreen.tscn"
const GameSceneScn = "res://game/GameScene.tscn"
const GameSceneGd = preload("res://game/GameScene.gd")

var m_mainMenu    setget deleted, deleted
var m_game        setget deleted, deleted
var m_debugWindow setget deleted, deleted


func deleted():
	assert(false)


func _init():
	set_pause_mode(PAUSE_MODE_PROCESS)


func _ready():
	Network.connect("networkError", Utility, "showAcceptDialog", ["Connection error"])
	Network.connect("connectionEnded", self, "onConnectionEnded")
	call_deferred("createDebugWindow")


func createDebugWindow():
	get_tree().get_root().add_child( preload(DebugWindowScn).instance() )


# called by MainMenu scene
func connectMainMenu( mainMenu ):
	m_mainMenu = mainMenu
	Network.connect("serverGameStatus", m_mainMenu, "getGameStatus")


func connectNewGameScene( newGameScene ):
	Network.connect("networkError",       newGameScene, "onNetworkError")
	Network.connect("playerListChanged",  newGameScene.get_node("Lobby"), "refreshLobby", [Network.m_players])
	Network.connect("playerJoined",       newGameScene.get_node("Lobby"), "sendToClient")
	newGameScene.connect("readyForGame",   self, "createGame")


func connectDebugWindow( debugWindow ):
	m_debugWindow = debugWindow
	Utility.connect("sendVariable", debugWindow, "updateVariable")


remote func createGame( module_, playerUnits ):
	SceneSwitcher.switchScene( LoadingScreenScn )

	if Network.isServer():
		rpc("createGame", null, null)

	SceneSwitcher.switchScene( \
		GameSceneScn, {GameSceneGd.Module : module_, GameSceneGd.PlayerUnitsData : playerUnits} )


func onGameEnded():
	assert( m_game )
	Utility.setFreeing( m_game )
	m_game = null
	SceneSwitcher.switchScene( MainMenuScn )


func onConnectionEnded():
	if m_game:
		Utility.setFreeing( m_game )
		m_game = null
	SceneSwitcher.switchScene( MainMenuScn )


# called by Game scene
func connectGame( game ):
	assert( m_game == null )
	m_game = game

	game.connect("gameEnded", self, "onGameEnded")
	game.connect("gameEnded", Network, "endConnection")
	Network.connect("allPlayersReady", game, "start")


func loadGame( filePath ):
	if not isGameInProgress():
		SceneSwitcher.switchScene( GameSceneScn, {GameSceneGd.SavedGame : filePath} )
	else:
		m_game.loadGame( filePath )


func isGameInProgress():
	return m_game != null
