
extends Control

const SavingModuleGd         = preload("res://core/SavingModule.gd")

const ModuleExtensions       = ["gd"]
const NoModuleString    = "..."

var m_params : Dictionary              setget deleted
var m_previousSceneFile                setget deleted
var m_module : SavingModuleGd          setget setModule
var m_rpcTargets = []                  # setRpcTargets


signal readyForGame( module, playerUnitCreationData )
signal finished()


func deleted(_a):
	assert(false)


func _ready():
	m_params = SceneSwitcher.getParams()

	Connector.connectNewGameScene( self )

	moduleSelected( get_node("ModuleSelection/FileName").text )
	get_node("Lobby").connect("unitNumberChanged", self, "onUnitNumberChanged")

	if m_params.has("isHost") and m_params["isHost"] == true:
		get_node("ModuleSelection/SelectModule").disabled = false

	Network.connect("nodeRegisteredClientsChanged", self, "onNodeRegisteredClientsChanged")
	if not Network.isServer():
		Network.rpc( "registerNodeForClient", get_path() )


func _exit_tree():
		if Network.isClient():
			Network.rpc( "unregisterNodeForClient", get_path() )


func _notification( what ):
	if what == NOTIFICATION_PREDELETE:
		pass


func _input( event ):
	if event.is_action_pressed("ui_cancel"):
		emit_signal("finished")
		accept_event()


func onNodeRegisteredClientsChanged( nodePath : NodePath, nodesWithClients ):
	if nodePath == get_path():
		setRpcTargets( nodesWithClients[nodePath] )


func onLeaveGamePressed():
	emit_signal("finished")


func onNetworkError( _what ):
	emit_signal("finished")


puppet func moduleSelected( moduleDataPath : String ):
	clear()
	if moduleDataPath == NoModuleString:
		return

	assert( moduleDataPath.get_extension() in ModuleExtensions )
	if File.new().open( moduleDataPath, File.READ ) != OK:
		Debug.err( self, "Module file %s can't be opened for reading" % moduleDataPath )
		return

	var module = null
	var dataResource = load( moduleDataPath )
	if SavingModuleGd.verify( dataResource ):
		var moduleData = dataResource.new()
		module = SavingModuleGd.new( moduleData, dataResource.resource_path )

	if not module:
		Debug.err( self, "Incorrect module data file %s" % moduleDataPath )
		if Network.isServer():
			for id in m_rpcTargets:
				Network.RPCid( self, id, ["moduleSelected", get_node("ModuleSelection/FileName").text] )
		return


	setModule( module )
	get_node("ModuleSelection/FileName").text = moduleDataPath
	get_node("Lobby").setMaxUnits( m_module.getPlayerUnitMax() )

	if Network.isServer():
		for id in m_rpcTargets:
			Network.RPCid( self, id, ["moduleSelected", get_node("ModuleSelection/FileName").text] )


func onUnitNumberChanged( number : int ):
	assert( number >= 0 )
	get_node("Buttons/StartGame").disabled = ( number == 0 or !Network.isServer() )


func clear():
	get_node("ModuleSelection/FileName").text = NoModuleString
	setModule( null )
	get_node("Lobby").clearUnits()


func onStartGamePressed():
	emit_signal("readyForGame", m_module , $"Lobby".m_unitsCreationData)


func setModule( module : SavingModuleGd ):
	m_module = module
	get_node("Lobby").setModule( module )


func setRpcTargets( clientIds : Array ):
	Network.setRpcTargets( self, clientIds )
	$"Lobby".setRpcTargets( clientIds )


