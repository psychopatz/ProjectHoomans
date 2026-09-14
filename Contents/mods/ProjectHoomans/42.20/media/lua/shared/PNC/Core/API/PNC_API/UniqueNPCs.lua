-- Public unique NPC definition and inventory-template registration API.

PNC = PNC or {}
PNC.API = PNC.API or {}
PNC.API.UniqueNPCs = PNC.API.UniqueNPCs or {}

local API = PNC.API.UniqueNPCs
local Catalog = PNC.UniqueNPCs
local Core = PNC.Core

local function playerPosition(player)
    if not player then return 0, 0, 0 end
    return tonumber(player.getX and player:getX()) or 0,
        tonumber(player.getY and player:getY()) or 0,
        tonumber(player.getZ and player:getZ()) or 0
end

function API.Register(definition, options)
    return Catalog.Register(definition, options)
end

function API.Get(id)
    return Catalog.Get(id)
end

function API.List()
    return Catalog.List()
end

function API.ListRegistrationErrors()
    return Catalog.ListRegistrationErrors()
end

function API.RegisterInventoryTemplate(template, options)
    return Catalog.RegisterInventoryTemplate(template, options)
end

function API.GetInventoryTemplate(id)
    return Catalog.GetInventoryTemplate(id)
end

-- Spawn a temporary, live copy for debug validation.  This intentionally
-- resolves the authored definition first, then strips the unique lifecycle
-- identity before calling the ordinary NPC API.  It can therefore exercise
-- the real appearance/inventory pipeline without reserving or consuming the
-- one-time unique NPC slot.
function API.SpawnTest(id, player, options)
    local definition
    local resolved
    local reason
    local x
    local y
    local z
    local testID
    local record
    options = type(options) == "table" and options or {}
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return nil, "not_authority"
    end
    definition = Catalog.Get(id)
    if not definition then return nil, "unique_definition_not_found" end
    resolved, reason = Catalog.Resolve(definition, {
        identitySeed = options.identitySeed
            or (PNC.Identity and PNC.Identity.RollSeed
                and PNC.Identity.RollSeed())
            or nil,
        archetypeID = definition.archetypeID,
    })
    if not resolved then return nil, reason or "unique_resolve_failed" end
    x, y, z = playerPosition(player)
    testID = Core and Core.GenerateID
        and Core.GenerateID("unique_test") or "unique_test"
    resolved.id = testID
    resolved.uniqueDefinitionId = nil
    resolved.uniqueDefinitionVersion = nil
    resolved.x = x + 1.5
    resolved.y = y + 1.5
    resolved.z = z
    resolved.anchorX = resolved.x
    resolved.anchorY = resolved.y
    resolved.anchorZ = resolved.z
    resolved.orderSpec = {
        kind = PNC.Const and PNC.Const.ORDER_ROAM or "roam",
        roamMode = PNC.Const and PNC.Const.ROAM_MODE_AREA or "area",
        x = resolved.x,
        y = resolved.y,
        z = resolved.z,
        radius = PNC.Const and PNC.Const.ROAM_DEFAULT_RADIUS or 20,
    }
    resolved.forceLive = true
    resolved.persist = false
    resolved.debug = true
    resolved.generation = nil
    record = PNC.API.Spawn(resolved)
    if not record then return nil, "test_spawn_failed" end
    return record, "spawned"
end

return API
