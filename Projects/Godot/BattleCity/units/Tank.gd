extends Node2D

const BulletScn = preload("res://units/Bullet.tscn")
const BoomBigScn = preload("res://effects/BoomBig.tscn")

#frame offsets
const ColorOffset = { GOLD = 0, SILVER = 8, GREEN = 200, PURPLE = 208 }
const TypeOffset = { MK1 = 0, MK2 = 25, MK3 = 50, MK4 = 75, MK5 = 100, MK6 = 125, MK7 = 150, MK8 = 175 }
const RotationOffset = { UP = 0, LEFT = 2, DOWN = 4, RIGHT = 6 }
const Direction = { 
	UP = Vector2(0, -1),
	DOWN = Vector2(0, 1),
	LEFT = Vector2(-1, 0),
	RIGHT = Vector2(1, 0),
	NONE = Vector2(0, 0)
}
const Direction2Frame = {
	Direction.DOWN  : RotationOffset.DOWN,
	Direction.LEFT  : RotationOffset.LEFT,
	Direction.RIGHT : RotationOffset.RIGHT,
	Direction.UP    : RotationOffset.UP
}
enum State { DEFAULT, FORCED_MOVEMENT }

export var m_speed = 40              setget setSpeed
export var m_maxActiveBullets = 1
export var m_bulletImpulse = 200            
var m_motion                         setget deleted, deleted
var m_stage                          setget setStage
var m_typeFrame = TypeOffset.MK1     setget deleted
var m_direction = Direction.NONE     setget setDirection
var m_rotation = Direction.UP        setget deleted, deleted
var m_colorFrame                     setget setColor, deleted
var m_frameToAnimationName = {}      setget deleted, deleted
var m_currrentAnimationName = ""     setget deleted, deleted
var m_cannonEndDistance = 0          setget deleted, deleted
var m_team                           setget setTeam
var m_isOnIce = false                setget deleted, deleted
var m_state = DefaultState.new(self) setget deleted, deleted
var m_stateEnum = State.DEFAULT      setget deleted, deleted
var m_activeBullets = 0              setget deleted, deleted


func deleted():
	assert(false)


func _ready():
	set_process( true )
	set_fixed_process( true )
	m_cannonEndDistance = abs( self.get_node("CannonEnd").get_pos().y )
	
	var spriteFrame = get_node("Sprite").get_frame()
	if   ( spriteFrame % 200 >= TypeOffset.MK8 ):  m_typeFrame = TypeOffset.MK8
	elif ( spriteFrame % 200 >= TypeOffset.MK7 ):  m_typeFrame = TypeOffset.MK7
	elif ( spriteFrame % 200 >= TypeOffset.MK6 ):  m_typeFrame = TypeOffset.MK6
	elif ( spriteFrame % 200 >= TypeOffset.MK5 ):  m_typeFrame = TypeOffset.MK5
	elif ( spriteFrame % 200 >= TypeOffset.MK4 ):  m_typeFrame = TypeOffset.MK4
	elif ( spriteFrame % 200 >= TypeOffset.MK3 ):  m_typeFrame = TypeOffset.MK3
	elif ( spriteFrame % 200 >= TypeOffset.MK2 ):  m_typeFrame = TypeOffset.MK2
	else:                                          m_typeFrame = TypeOffset.MK1

	if   ( spriteFrame >= ColorOffset.PURPLE ):  setColor( ColorOffset.PURPLE )
	elif ( spriteFrame >= ColorOffset.GREEN ):   setColor( ColorOffset.GREEN )
	elif ( spriteFrame >= ColorOffset.SILVER ):  setColor( ColorOffset.SILVER )
	else:                                        setColor( ColorOffset.GOLD )

	self.rotateTo( Direction.UP )
	setStage( get_parent() )


func _process(delta):
	processMovement( delta )
	processRotation()
	processAnimation()


func _fixed_process(delta):
	processMovement( delta )


func setType( type ):
	assert( type in TypeOffset )
	m_typeFrame = type
	resetAnimations( m_colorFrame, m_typeFrame )
	updateSpriteFrame()


func setTeam(team):
	if m_team:
		self.remove_from_group(m_team)

	m_team = team
	self.add_to_group(team)


func setDirection( direction ):
	m_state.setDirection(direction)
	
	
func setDirection_state( state, direction ):
	assert( state extends DefaultState )
	m_direction = direction
	m_motion = m_speed * direction


func setSpeed(speed):
	m_speed = speed
	m_motion = speed * m_direction


func setColor( color ):
	assert ( color in ColorOffset.values() )
	m_colorFrame = color
	resetAnimations( m_colorFrame, m_typeFrame )
	updateSpriteFrame()


func setRotation( rotation ):
	assert( rotation in Direction.values() and rotation != Direction.NONE )
	m_rotation = rotation
	updateSpriteFrame()
	
	
func setStage(stage):
	m_stage = weakref( stage )


func resetAnimations(colorFrame, tankTypeFrame):
	var animationPlayer = get_node("Sprite/AnimationPlayer")

	for frame2Animation in m_frameToAnimationName.values():
		animationPlayer.remove_animation(frame2Animation)
	m_frameToAnimationName = {}
	
	for directionFrame in RotationOffset.values():
		var firstFrame = m_colorFrame + m_typeFrame + directionFrame
		var animationToAdd = animationPlayer.get_animation("Drive").duplicate()
		var trackIdx = animationToAdd.find_track(".:frame")

		for keyIdx in range(0, animationToAdd.track_get_key_count( trackIdx ) ):
			animationToAdd.track_set_key_value( \
				trackIdx, keyIdx, firstFrame + keyIdx)

		animationPlayer.add_animation("Drive"+str(firstFrame), animationToAdd)
		var list = animationPlayer.get_animation_list()
		m_frameToAnimationName[firstFrame] = "Drive"+str(firstFrame)


func processMovement( delta ):
	var body = get_node("Body2D")
	var wasStopped = body.move( m_motion * delta ) != Vector2(0,0)
	
	self.set_pos( get_pos() + body.get_pos() ) # move root node of a tank to where physics body is
	body.set_pos( Vector2(0,0) ) # previous line has moved body as well so we need to revert that
	
	if m_motion == Vector2(0,0):
		return
	elif m_isOnIce and !wasStopped:
		changeState( State.FORCED_MOVEMENT )
	else:
		changeState( State.DEFAULT )


func processRotation():
	if m_rotation != m_direction and m_direction != Direction.NONE:
		rotateTo(m_direction)


func rotateTo( direction ):
	assert( direction != Direction.NONE )

	setRotation(direction)
	m_currrentAnimationName = m_frameToAnimationName[get_node("Sprite").get_frame()]

	if ( m_rotation == Direction.DOWN ):
		self.get_node("CannonEnd").set_pos( Vector2( 0, m_cannonEndDistance ) )
	elif ( m_rotation == Direction.LEFT ):
		self.get_node("CannonEnd").set_pos( Vector2( -m_cannonEndDistance, 0 ) )
	elif ( m_rotation == Direction.RIGHT ):
		self.get_node("CannonEnd").set_pos( Vector2( m_cannonEndDistance, 0 ) )
	elif ( m_rotation == Direction.UP ):
		self.get_node("CannonEnd").set_pos( Vector2( 0, -m_cannonEndDistance ) )


func processAnimation():
	if ( m_direction == Direction.NONE):
		get_node("Sprite/AnimationPlayer").stop()
	elif ( get_node("Sprite/AnimationPlayer").get_current_animation() != m_currrentAnimationName ):
		get_node("Sprite/AnimationPlayer").play( m_currrentAnimationName )


func fireCannon():
	if m_activeBullets > 0:
		return

	var bullet = BulletScn.instance()
	bullet.rotateToDirection(m_rotation)
	PS2D.body_add_collision_exception(bullet.get_node("Body2D").get_rid(), self.get_node("Body2D").get_rid())

	for existingBullet in get_tree().get_nodes_in_group( bullet.BulletsGroup ):
		if ( existingBullet.setTeam( self.m_team ) ):
			PS2D.body_add_collision_exception( bullet.get_node("Body2D").get_rid(), existingBullet.get_node("Body2D").get_rid() )

	bullet.add_to_group( bullet.BulletsGroup )
	assert( m_team != null )
	bullet.setTeam(m_team)
	bullet.setImpulse(m_bulletImpulse)

	m_stage.get_ref().add_child(bullet)
	bullet.set_global_pos( self.get_node("CannonEnd").get_global_pos() )

	m_activeBullets += 1
	bullet.connect("exit_tree", self, "decreaseActiveBullets")


func destroy():
	self.queue_free()
	var boom = BoomBigScn.instance()
	m_stage.get_ref().add_child( boom )
	boom.set_pos( self.get_pos() )
	boom.get_node("Sprite/AnimationPlayer").connect("finished", boom, "queue_free")
	boom.get_node("Sprite/AnimationPlayer").play("Explode")


func handleBulletCollision(bullet):
	if self.m_team != bullet.m_team:
		self.destroy()


func updateSpriteFrame():
	get_node("Sprite").set_frame( m_colorFrame + m_typeFrame + Direction2Frame[m_rotation] )
	pass
	
	
func decreaseActiveBullets():
	m_activeBullets -= 1
	assert( m_activeBullets >= 0 )


func _on_IceDetector_body_enter( body ):
	m_isOnIce = true


func _on_IceDetector_body_exit( body ):
	m_isOnIce = false
	
	
func changeState( stateEnum ):
	if (m_stateEnum == stateEnum):
		return

	if stateEnum == State.DEFAULT:
		m_state = DefaultState.new(self)
	elif stateEnum == State.FORCED_MOVEMENT:
		m_state = ForcedMovementState.new(self)
	else:
		assert(false)

	m_stateEnum = stateEnum


class DefaultState:
	var m_tank


	func _init(tank):
		m_tank = tank


	func setDirection(direction):
		m_tank.setDirection_state( self, direction )


class ForcedMovementState extends DefaultState:
	
	func _init(tank).(tank):
		pass
		
		
	func setDirection(direction):
		assert(m_tank.m_direction != Direction.NONE)
		pass

