if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Handler = PNC.ServerDebugCommandHandler
local Const = PNC.Const
local H = Handler.Internal

local CompanionInitialization = require "PNC/Core/Companions/PNC_DebugCompanionInitialization"

function Handler.ConfigureTeleport(value)
    H.Teleport = value
end

function H.ResolveDebugArchetype(args, tacticalClass, fallbackID)
    local explicit = args and args.archetypeID or nil
    local defaults
    local archetypes = PNC.Archetypes
    if explicit and archetypes and archetypes.Get then
        return archetypes.Get(explicit).id
    end
    if archetypes then
        defaults = tacticalClass == "hostile"
            and archetypes.GetHostileDefaults
            and archetypes.GetHostileDefaults()
            or archetypes.GetColonistDefaults
                and archetypes.GetColonistDefaults()
        if type(defaults) == "table" and defaults[1] then
            return tostring(defaults[1])
        end
    end
    return fallbackID
end

function H.HandleUniqueNPCTestSpawn(player, args)
    local definitionID = args and (args.definitionId or args.id) or nil
    local API = PNC.API and PNC.API.UniqueNPCs
    local record
    local reason
    if not API or not API.SpawnTest then
        return nil, "unique_test_spawn_unavailable"
    end
    if not definitionID or tostring(definitionID) == "" then
        return nil, "unique_definition_id_required"
    end
    record, reason = API.SpawnTest(tostring(definitionID), player)
    if not record then
        PNC.Core.LogWarn("PNC unique test spawn failed definition="
            .. tostring(definitionID) .. " reason=" .. tostring(reason))
        return nil, reason or "unique_test_spawn_failed"
    end
    PNC.Core.LogInfo("PNC unique test spawn definition="
        .. tostring(definitionID) .. " runtime=" .. tostring(record.id))
    return record, "spawned"
end

function Handler.Spawn(player, args)
    local x = tonumber(args and args.x) or (player and player:getX()) or 0
    local y = tonumber(args and args.y) or (player and player:getY()) or 0
    local z = tonumber(args and args.z) or (player and player:getZ()) or 0
    local variant = tostring(args and args.variant or "companion")
    local tacticalClass = tostring(args and args.tacticalClass or "")
    local equipmentSpawnMode = PNC.Inventory.GetDebugEquipmentSpawnMode(
        variant,
        args and args.equipmentSpawnMode
    )
    local colonist = tacticalClass == "colonist"
    local hostile = tacticalClass == "hostile"
    local gameTime = getGameTime and getGameTime() or nil
    local worldAgeHours = gameTime
        and gameTime.getWorldAgeHours
        and gameTime:getWorldAgeHours() or 0
    if tacticalClass ~= "colonist" and tacticalClass ~= "neutral"
        and tacticalClass ~= "hostile"
    then
        PNC.Core.LogWarn(
            "PNC debug spawn rejected invalid tactical class=" .. tacticalClass
        )
        return nil, "invalid_tactical_class"
    end
    local orderSpec = hostile
        and { kind = Const.ORDER_HOSTILE_HUNT, x = x, y = y, z = z }
        or {
            kind = Const.ORDER_ROAM,
            roamMode = Const.ROAM_MODE_AREA,
            x = x,
            y = y,
            z = z,
            radius = Const.ROAM_DEFAULT_RADIUS,
        }
    local prepare
    if colonist then
        local recruitment = PNC.Recruitment
        if not recruitment or not recruitment.Assign then
            return nil, "recruitment_unavailable"
        end
        prepare = function(created)
            return recruitment.Assign(player, created, {
                source = "debug_companion_spawn",
                endConversation = false,
            })
        end
    end
    local record, reason = PNC.API.Spawn({
        tacticalClass = colonist and "neutral" or tacticalClass,
        archetypeID = H.ResolveDebugArchetype(
            args,
            tacticalClass,
            hostile and "Scavenger" or "General"
        ),
        x = x,
        y = y,
        z = z,
        orderSpec = orderSpec,
        forceLive = true,
        equipmentSpawnMode = equipmentSpawnMode,
        debug = true,
    }, prepare)
    if colonist and record then
        local initialized, initializationResult =
            CompanionInitialization.ApplyKnownCompanion(
                player, record.id, worldAgeHours
            )
        if initialized and type(initializationResult) == "table"
            and initializationResult.relationshipApplied ~= true
        then
            PNC.Core.LogWarn(
                "PNC debug companion relationship initialization failed npc="
                    .. tostring(record.id)
                    .. " reason="
                    .. tostring(initializationResult.relationshipReason)
            )
        end
        if initialized and type(initializationResult) == "table"
            and initializationResult.knowledgeApplied ~= true
        then
            PNC.Core.LogWarn(
                "PNC debug companion knowledge initialization failed npc="
                    .. tostring(record.id)
            )
        elseif not initialized then
            PNC.Core.LogWarn(
                "PNC debug companion initialization failed npc="
                    .. tostring(record.id)
                    .. " reason=" .. tostring(initializationResult)
            )
        end
    end
    PNC.Core.LogInfo("PNC debug spawn variant=" .. variant
        .. " tacticalClass=" .. tacticalClass
        .. " equipment=" .. tostring(equipmentSpawnMode or "sandbox_chances")
        .. " id=" .. tostring(record and record.id or "failed")
        .. (reason and " reason=" .. tostring(reason) or ""))
    return record, reason
end

function H.FindTeleportPosition(record)
    local body = record and PNC.Registry.GetLiveZombie(record.id) or nil
    local x = body and body:getX() or tonumber(record and record.x) or 0
    local y = body and body:getY() or tonumber(record and record.y) or 0
    local z = body and body:getZ() or tonumber(record and record.z) or 0
    local cell = getCell and getCell() or nil
    local offsets = {
        { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 },
        { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 },
    }
    local i
    if cell then
        for i = 1, #offsets do
            local square = cell:getGridSquare(
                math.floor(x) + offsets[i][1],
                math.floor(y) + offsets[i][2],
                math.floor(z)
            )
            if square and (not square.isFree or square:isFree(false)) then
                return square:getX() + 0.5,
                    square:getY() + 0.5,
                    square:getZ()
            end
        end
    end
    return x + 1.5, y + 1.5, z
end

function H.TeleportPlayerToRecord(player, npcId)
    local record = npcId and PNC.Registry.Get(npcId) or nil
    local x
    local y
    local z
    if not player or not record then
        return false
    end
    x, y, z = H.FindTeleportPosition(record)
    if H.Teleport.ToCoordinates(player, x, y, z) then
        PNC.Core.LogInfo("PNC debug queued teleport for "
            .. tostring(player:getUsername())
            .. " near NPC " .. tostring(record.id))
        return true
    end
    PNC.Core.LogWarn("PNC debug teleport unavailable for NPC "
        .. tostring(record.id))
    return false
end

function Handler.SpawnMobileGroup(player, args)
    local Factions = PNC.Factions
    local Director = PNC.MobileGroupDirector
    local Archetypes = PNC.FactionArchetypes
    if not Factions or type(Factions.Create) ~= "function"
        or not Director or type(Director.GenerateForFaction) ~= "function"
    then
        return nil, "mobile_group_pipeline_unavailable"
    end
    local archetypeID = tostring(args and args.archetypeID or "refugee")
    if Archetypes and type(Archetypes.Get) == "function"
        and not Archetypes.Get(archetypeID)
    then
        return nil, "unknown_archetype"
    end
    local x = tonumber(args and args.x) or (player and player:getX()) or 0
    local y = tonumber(args and args.y) or (player and player:getY()) or 0
    local z = tonumber(args and args.z) or (player and player:getZ()) or 0
    local controlMode = tostring(args and args.mobileControlMode or "ambient")
    local pathMode = tostring(args and args.mobilePathMode or "random")
    local groupSize = math.max(2, math.min(6, math.floor(tonumber(args and args.groupSize) or 3)))
    local gameTime = getGameTime and getGameTime() or nil
    local worldAgeHours = gameTime and gameTime.getWorldAgeHours
        and tonumber(gameTime:getWorldAgeHours()) or 0

    -- Unified Core-first pipeline: create debug groups through PsychopatzCore
    -- SurvivorWorld (identical to Starter Bootstrap & Population Director), then
    -- promote immediately at the cursor so there is no split creation system.
    local CoreAdapter = PNC.CoreSurvivorWorldAdapter
    if CoreAdapter and type(CoreAdapter.CreateUnifiedGroup) == "function"
        and CoreAdapter.CanCommitGeneratedPlans and CoreAdapter.CanCommitGeneratedPlans()
    then
        local gType = archetypeID == "looter" and "LOOTER"
            or (archetypeID == "scavenger" and "SCAVENGER" or "REFUGEE")
        local viewGroup, canonical, plan = CoreAdapter.CreateUnifiedGroup({
            archetypeID = archetypeID,
            groupType = gType,
            location = { x = x, y = y, z = z },
            memberCount = groupSize,
            source = "DEBUG_UNIFIED_SPAWN",
            createdAt = worldAgeHours,
            materializeImmediate = tostring(args and args.presenceMode or "live") == "live",
        }, "debug_unified_mobile_group")
        if viewGroup then
            if PNC.AbstractTraversal
                and type(PNC.AbstractTraversal.ChooseDestination) == "function"
                and type(PNC.AbstractTraversal.Begin) == "function"
            then
                local dest = PNC.AbstractTraversal.ChooseDestination(viewGroup)
                if dest then
                    PNC.AbstractTraversal.Begin(viewGroup, dest, worldAgeHours)
                end
            end
            return viewGroup, "unified_core_group_created", {
                group = viewGroup,
                canonical = canonical,
                plan = plan,
            }
        end
    end

    local ok, reason, faction = Factions.Create({
        name = "Debug " .. archetypeID .. " " .. tostring(math.floor(worldAgeHours * 10)),
        archetypeID = archetypeID,
        createdAt = worldAgeHours,
        tags = {
            debugCreated = true,
            mobileGroup = true,
            mobileControlMode = controlMode,
            mobilePathMode = pathMode,
        },
    })
    if not ok or type(faction) ~= "table" then
        return nil, reason or "faction_create_failed"
    end

    local ix = math.floor(x)
    local iy = math.floor(y)
    local iz = math.floor(z)
    local siteRadius = 6
    local genOk, genReason, groupResult = Director.GenerateForFaction(faction.id, {
        x = x,
        y = y,
        z = z,
        groupSize = groupSize,
        presenceMode = tostring(args and args.presenceMode or "live"),
        allowLive = true,
        useExisting = false,
        mobileControlMode = controlMode,
        mobilePathMode = pathMode,
        siteSpec = {
            id = "debug_mobile:" .. tostring(faction.id),
            kind = "camp",
            home = { x = x, y = y, z = z, radius = siteRadius },
            bounds = {
                minX = ix - siteRadius,
                maxX = ix + siteRadius,
                minY = iy - siteRadius,
                maxY = iy + siteRadius,
                minZ = iz,
                maxZ = iz,
            },
            createdAt = worldAgeHours,
        },
        debug = true,
    })
    if not genOk then
        return nil, genReason or "mobile_group_generate_failed"
    end

    if type(Director.RefreshFactionObjective) == "function" then
        Director.RefreshFactionObjective(faction.id, worldAgeHours)
    end
    if args and args.startSettlementTravel == true
        and type(Director.StartSettlementTravel) == "function"
    then
        Director.StartSettlementTravel(faction.id, nil, worldAgeHours)
    end

    if PNC.Core and type(PNC.Core.LogInfo) == "function" then
        PNC.Core.LogInfo("PNC debug spawned mobile group faction="
            .. tostring(faction.id) .. " archetype=" .. archetypeID
            .. " size=" .. tostring(groupSize) .. " control=" .. controlMode)
    end
    return faction, "spawned", groupResult
end

return Handler
