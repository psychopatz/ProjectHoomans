local T = require "tests/support/test"

T.addPackagePaths()

local function list(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
        remove = function(_, index) table.remove(values, index + 1) end,
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
corpse.current = source
local setCurrentCalls = 0
function corpse:getSquare() return self.current or self.square end
function corpse:getCurrentSquare() return self.current end
function corpse:getX() return self.x end
function corpse:getY() return self.y end
function corpse:getZ() return self.z end
function corpse:setX(value) self.x = value end
function corpse:setY(value) self.y = value end
function corpse:setZ(value) self.z = value end
function corpse:setCurrent(square)
    setCurrentCalls = setCurrentCalls + 1
    self.current = square
end
function corpse:setSquare(square) self.square = square end
function corpse:removeFromWorld() end
function corpse:removeFromSquare()
    if self.square then
        for index = #self.square.bodies, 1, -1 do
            if self.square.bodies[index] == self then
                table.remove(self.square.bodies, index)
            end
        end
    end
    self.current = nil
end
function corpse:getModData() return self.data end

function source:getDeadBodys() return list(self.bodies) end
function source:getStaticMovingObjects() return list(self.bodies) end
function destination:getDeadBodys() return list(self.bodies) end
function destination:getStaticMovingObjects() return list(self.bodies) end
function source:removeCorpse(item)
    item:removeFromSquare()
end
function source:addCorpse(item)
    local present = false
    for index = 1, #self.bodies do
        if self.bodies[index] == item then present = true end
    end
    if not present then self.bodies[#self.bodies + 1] = item end
end
function destination:removeCorpse(item)
    item:removeFromSquare()
end
function destination:addCorpse(item)
    local present = false
    for index = 1, #self.bodies do
        if self.bodies[index] == item then present = true end
    end
    if not present then self.bodies[#self.bodies + 1] = item end
end
function carryDestination:getDeadBodys() return list(self.bodies) end
function carryDestination:getStaticMovingObjects() return list(self.bodies) end
function carryDestination:removeCorpse(item)
    item:removeFromSquare()
end
function carryDestination:addCorpse(item)
    local present = false
    for index = 1, #self.bodies do
        if self.bodies[index] == item then present = true end
    end
    if not present then self.bodies[#self.bodies + 1] = item end
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
            if (x == carryDestination.x or x == 13)
                and y == carryDestination.y
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
T.equal(corpse.current, destination,
    "corpse transfer synchronizes the moving square")
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
T.equal(corpse.current, carryDestination,
    "visible carry synchronizes the moving square")
T.equal(corpse.x, 12.25, "visible carry preserves fractional x position")
T.equal(corpse.y, 20.75, "visible carry preserves fractional y position")
T.equal(#source.bodies, 0, "visible carry removes old tile membership")
T.equal(#destination.bodies, 0, "visible carry leaves the prior tile")
T.equal(#carryDestination.bodies, 1,
    "visible carry creates one new tile membership")

local followedInTile, inTileReason = Internal.followCorpse(
    corpse, 12.75, 20.25, 0)
T.truthy(followedInTile, "visible carry follows within the current tile: "
    .. tostring(inTileReason))
T.equal(corpse.square, carryDestination,
    "within-tile carry keeps the existing square membership")
T.equal(corpse.current, carryDestination,
    "within-tile carry keeps moving square ownership synchronized")
T.equal(corpse.x, 12.75, "within-tile carry updates fractional x")
T.equal(corpse.y, 20.25, "within-tile carry updates fractional y")
T.equal(#carryDestination.bodies, 1,
    "within-tile carry does not duplicate the corpse membership")

local movedAgain, movedAgainReason = Internal.followCorpse(
    corpse, 13.25, 20.25, 0)
T.truthy(movedAgain, "repeated visible carry remains attached: "
    .. tostring(movedAgainReason))
T.equal(#source.bodies, 0, "repeated carry leaves the original tile empty")
T.equal(#destination.bodies, 0, "repeated carry leaves the first tile empty")
T.equal(#carryDestination.bodies, 1,
    "repeated visible carry keeps exactly one membership")

T.finish("pnc_body_lifecycle_corpse_transfer_smoke")
