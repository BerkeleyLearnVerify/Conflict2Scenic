#################################
# MAP AND MODEL                 #
#################################

param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(8, 10)
param EGO_THROTTLE = VerifaiRange(0.25, 0.45)
param DEPARTURE_DISTANCE = VerifaiRange(30, 40)

#################################
# SPATIAL RELATIONS             #
#################################

intersection = Uniform(*filter(lambda i: i.is4Way, network.intersections))
egoInitLane = Uniform(*intersection.incomingLanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
intendedManeuver = Uniform(*filter(lambda m: m.type is ManeuverType.LEFT_TURN, egoInitLane.maneuvers))
trafficwayProbe = new OrientedPoint at egoSpawnPt offset along egoSpawnPt.heading by (0, 6, 0)
departureProbe = new OrientedPoint at egoSpawnPt offset along egoSpawnPt.heading by (0, globalParameters.DEPARTURE_DISTANCE, 0)

#################################
# AGENT BEHAVIORS               #
#################################

# Ego fails to execute the available left turn and continues straight under throttle.
behavior EgoBehavior():
    while True:
        take SetThrottleAction(globalParameters.EGO_THROTTLE)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with speed globalParameters.EGO_SPEED,
    with behavior EgoBehavior()

#################################
# REQUIREMENTS                  #
#################################

require intendedManeuver.startLane is egoInitLane
require trafficwayProbe.position in road
require departureProbe.position not in road
