local T = require "tests/support/test"

T.addPackagePaths()

local function list(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local source = { bodies = {} }
local destination = { bodies = {} }
local carryDestination = { bodies = {} }
source.x, source.y, source.z = 10, 20, 0
destination.x, destination.y, destination.z = 11, 20, 0
carryDestination.x, carryDestination.y, carryDestination.z = 12, 20, 0
local corpse = {
    x = 10, y = 20, z = 0,
    data = { clothing = "preserved", PNC_CorpseHaulToken = "haul:one" },
}
corpse.square = source
local setCurrentCalls = 0
function corpse:getSquare() return self.square end
function corpse:getX() return self.x end
function corpse:getY() return self.y end
function corpse:getZ() return self.z end
function corpse:setX(value) self.x = value end
function corpse:setY(value) self.y = value end
function corpse:setZ(value) self.z = value end
function corpse:setCurrent(square)
    setCurrentCalls = setCurrentCalls + 1
    self.square = square
end
function corpse:getModData() return self.data end

function source:getDeadBodys() return list(self.bodies) end
function destination:getDeadBodys() return list(self.bodies) end
function source:removeCorpse(item)
    for index = #self.bodies, 1, -1 do
        if self.bodies[index] == item then table.remove(self.bodies, index) end
    end
    item.square = nil
end
function destination:removeCorpse(item)
    for index = #self.bodies, 1, -1 do
        if self.bodies[index] == item then table.remove(self.bodies, index) end
    end
    if item.square == self then item.square = nil end
end
function destination:addCorpse(item)
    self.bodies[#self.bodies + 1] = item
    item.square = self
end
function carryDestination:getDeadBodys() return list(self.bodies) end
function carryDestination:removeCorpse(item)
    for index = #self.bodies, 1, -1 do
        if self.bodies[index] == item then table.remove(self.bodies, index) end
    end
    if item.square == self then item.square = nil end
end
function carryDestination:addCorpse(item)
    self.bodies[#self.bodies + 1] = item
    item.square = self
end

source.bodies[1] = corpse

getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            if x == source.x and y == source.y and z == source.z then
                return source
            end
            if x == destination.x and y == destination.y
                and z == destination.z
            then
                return destination
            end
            if x == carryDestination.x and y == carryDestination.y
                and z == carryDestination.z
            then
                return carryDestination
            end
            return nil
        end,
    }
end

PNC = { BodyLifecycle = { Internal = {} } }
T.load("ProjectHoomans", "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_World.lua")
local Internal = PNC.BodyLifecycle.Internal

local original = corpse
local originalData = corpse.data
local moved, reason = Internal.moveCorpse(corpse, destination, 30, 40, 0)
T.truthy(moved, "corpse transfer succeeds through the world boundary: "
    .. tostring(reason))
T.equal(corpse, original, "corpse transfer preserves the engine object")
T.equal(corpse.data, originalData, "corpse transfer preserves corpse mod data")
T.equal(corpse.data.clothing, "preserved",
    "corpse transfer preserves corpse contents")
T.equal(corpse.square, destination,
    "corpse transfer attaches the object to the destination square")
T.equal(corpse.x, 30.5, "corpse transfer writes the destination x")
T.equal(corpse.y, 40.5, "corpse transfer writes the destination y")
T.equal(#source.bodies, 0, "corpse transfer removes the source membership")
T.equal(#destination.bodies, 1,
    "corpse transfer creates one destination membership")

local followed, followReason = Internal.followCorpse(
    corpse, 12.25, 20.75, 0)
T.truthy(followed, "visible carry follows the corpse across a tile: "
    .. tostring(followReason))
T.equal(corpse.square, carryDestination,
    "visible carry updates corpse square membership")
T.equal(corpse.x, 12.25, "visible carry preserves fractional x position")
T.equal(corpse.y, 20.75, "visible carry preserves fractional y position")
T.equal(#source.bodies, 0, "visible carry removes old tile membership")
T.equal(#destination.bodies, 0, "visible carry leaves the prior tile")
T.equal(#carryDestination.bodies, 1,
    "visible carry creates one new tile membership")

local currentCallsAfterCrossTile = setCurrentCalls
local followedInTile, inTileReason = Internal.followCorpse(
    corpse, 12.75, 20.25, 0)
T.truthy(followedInTile, "visible carry follows within the current tile: "
    .. tostring(inTileReason))
T.equal(corpse.square, carryDestination,
    "within-tile carry keeps the existing square membership")
T.equal(setCurrentCalls, currentCallsAfterCrossTile,
    "within-tile carry does not rewrite static corpse square ownership")
T.equal(corpse.x, 12.75, "within-tile carry updates fractional x")
T.equal(corpse.y, 20.25, "within-tile carry updates fractional y")

T.finish("pnc_body_lifecycle_corpse_transfer_smoke")
