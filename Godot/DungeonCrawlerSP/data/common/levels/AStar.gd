extends Node

const NodeGuard = preload("res://addons/TypeWrappers/NodeGuard.gd")

const ShapeName := "Shape"
const Epsilon := 0.00001

class PointsData:
	var topLeftPoint : Vector2
	var xCount : int
	var yCount : int


var _step : Vector2
var _offsets := []
var _boundingRect : Rect2
var _pointsData : PointsData
var _astar := AStar.new()
var _testerShape := NodeGuard.new()

var create : bool = false


func _physics_process(delta):
	if !create:
		return

	createGraph()
	create = false


func initialize( step : Vector2, boundingRect : Rect2 ):
	_setStep(step)
	_boundingRect = boundingRect
	_pointsData = _pointsDataFromRect( step, boundingRect )


func setCollisionShape( shape2d : CollisionShape2D ):
	_testerShape.setNode( shape2d.duplicate() )


func createGraph():
	assert(_testerShape.node != null)
	assert(is_inside_tree())

	var testerBody := KinematicBody2D.new()
	testerBody.add_child(_testerShape.release())
	add_child(testerBody)

	var testPoints = []
	testPoints += [Vector2(0,1),Vector2(0,4),]
	testPoints += [Vector2(6,1),Vector2(6,4),]
	testPoints += [Vector2(1,1), Vector2(1,2), Vector2(1,3)]
	testPoints += [Vector2(3,2), Vector2(3,3), Vector2(3,1), Vector2(3,0), Vector2(3,4)]
	testPoints += [Vector2(3,5), Vector2(3,6), Vector2(3,7)]

	for x in _pointsData.xCount:
		for y in _pointsData.yCount:

#	for pt in testPoints:
#		var x = pt.x
#		var y = pt.y

			var originPoint := Vector2(_pointsData.topLeftPoint.x + x*_step.x \
				, _pointsData.topLeftPoint.y + y*_step.y)

			testerBody.position = originPoint

			var allow : Array = _testMovementFrom(originPoint, _step, testerBody)

			if allow.size() == 0:
				continue

			_astar.add_point( _calculateId(originPoint, _boundingRect) \
				, Vector3(originPoint.x, originPoint.y, 0.0) )

			for point in allow:
				_astar.add_point( _calculateId(point, _boundingRect) \
					, Vector3(point.x, point.y, 0.0) )


	remove_child(testerBody)
	testerBody.queue_free()
	pass


func getBoundingRect() -> Rect2:
	return _boundingRect


func getPointsData() -> PointsData:
	return _pointsData


func getAStarPoints2D() -> Array:
	var pointArray := []
	for id in _astar.get_points():
		var point3d : Vector3 = _astar.get_point_position(id)
		pointArray.append(Vector2(point3d.x, point3d.y))

	return pointArray


func _setStep(step : Vector2):
	_step = step
	_offsets = [
	  Vector2(_step.x, -_step.y)
	, Vector2(_step.x, 0)
	, Vector2(_step.x, _step.y)
	, Vector2(0, _step.y)
	]


func _pointsDataFromRect( step : Vector2, rect : Rect2 ) -> PointsData:
	var data = PointsData.new()

	data.topLeftPoint.x = stepify(rect.position.x + step.x/2, step.x)
	var xLastPoint : int = int((rect.position.x + rect.size.x -1) / step.x) * int(step.x)
	data.xCount = int((xLastPoint - data.topLeftPoint.x) / 16) + 1

	data.topLeftPoint.y = stepify(rect.position.y + step.y/2, step.y)
	var yLastPoint : int = int((rect.position.y + rect.size.y -1) / step.y) * int(step.y)
	data.yCount = int((yLastPoint - data.topLeftPoint.y) / 16) + 1

	return data


func _calculateId(point : Vector2, boundingRect : Rect2) -> int:
	var id : float = (point.x - boundingRect.position.x) * boundingRect.size.x \
	               + point.y - boundingRect.position.y
	assert(id >= 0)
	return int(id)


func _testMovementFrom( origin : Vector2, step : Vector2, tester : KinematicBody2D) -> Array:
	tester.position = origin
	tester.move_and_slide(Vector2())

	var isValidPlace = abs(tester.position.x + tester.position.y - origin.x - origin.y) < Epsilon
	var allowed := []
	var transform := Transform2D(0.0, origin)

	if isValidPlace:
		for offset in _offsets:
			if _boundingRect.has_point(origin+offset) and !tester.test_move(transform, offset):
				allowed.append(origin+offset)

	return allowed
