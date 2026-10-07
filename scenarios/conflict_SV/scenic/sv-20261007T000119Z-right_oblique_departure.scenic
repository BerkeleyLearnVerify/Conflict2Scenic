#################################
# MAP AND MODEL                 #
#################################

param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(7, 9)
param EGO_THROTTLE = VerifaiRange(0.15, 0.30)
param HEADING_ERROR = VerifaiRange(15, 25)
param DEPARTURE_DISTANCE = VerifaiRange(18, 24)

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
departureHeading = egoSpawnPt.heading - globalParameters.HEADING_ERROR * 1 deg
departureProbe = new OrientedPoint at egoSpawnPt offset along departureHeading by (0, globalParameters.DEPARTURE_DISTANCE, 0)

#################################
# AGENT BEHAVIORS               #
#################################

# Ego maintains the erroneous rightward heading without corrective steering.
behavior EgoBehavior():
    while True:
        take SetThrottleAction(globalParameters.EGO_THROTTLE)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    facing departureHeading,
    with blueprint MODEL,
    with speed globalParameters.EGO_SPEED,
    with behavior EgoBehavior()

#################################
# REQUIREMENTS                  #
#################################

require departureProbe.position not in road
