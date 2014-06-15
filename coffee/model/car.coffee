'use strict'

require '../helpers.coffee'
_ = require 'underscore'
Trajectory = require './trajectory.coffee'

module.exports =
  class Car
    constructor: (lane, position) ->
      @id = Object.genId()
      @color = (300 + 240 * Math.random() | 0) % 360
      @_speed = 0
      @width = 0.1
      @length = 0.2
      @safeDistance = 1.5 * @length
      @maxSpeed = (4 + Math.random()) / 5
      @acceleration = 0.25
      @trajectory = new Trajectory @, lane, position
      @alive = true
      @preferedLane = null
      @turnNumber = null

    @property 'coords',
      get: -> @trajectory.coords

    @property 'speed',
      get: -> @_speed
      set: (speed) ->
        speed = 0 if speed < 0
        speed = @maxSpeed if speed > @maxSpeed
        @_speed = speed

    @property 'direction',
      get: -> @trajectory.direction

    release: ->
      @trajectory.release()

    move: (delta) ->
      if @trajectory.distanceToNextCar - @safeDistance > @speed * delta
        k = 1 - Math.pow @speed/@maxSpeed, 4
        @speed += @acceleration * delta * k
      else
        @speed = 0
      if @preferedLane? and @preferedLane isnt @trajectory.current.lane and
      not @trajectory.isChangingLanes
        switch @turnNumber
          when 0 then @trajectory.changeLaneToLeft()
          when 2 then @trajectory.changeLaneToRight()
      step = @speed * delta
      # TODO: hacks, should have changed speed
      step = 0 if @trajectory.distanceToNextCar - @safeDistance < step
      if @trajectory.timeToMakeTurn(step)
        return @alive = false if not @nextLane?
        if not @trajectory.canEnterIntersection @nextLane
          if step > @trajectory.getDistanceToIntersection()
            step = @trajectory.getDistanceToIntersection()
            @speed = 0
      @trajectory.moveForward step

    pickNextLane: ->
      throw Error 'next lane is already chosen' if @nextLane
      @nextLane = null
      intersection = @trajectory.nextIntersection
      currentLane = @trajectory.current.lane
      possibleRoads = intersection.roads.filter (x) ->
        x.target isnt currentLane.road.source
      return null if possibleRoads.length is 0
      nextRoad = _.sample possibleRoads
      laneNumber = _.random 0, nextRoad.lanesNumber-1
      @nextLane = nextRoad.lanes[laneNumber]
      throw Error 'can not pick next lane' if not @nextLane
      @turnNumber = currentLane.getTurnDirection @nextLane
      @preferedLane = switch @turnNumber
        when 0 then currentLane.leftmostAdjacent
        when 2 then currentLane.rightmostAdjacent
        else null
      @nextLane
