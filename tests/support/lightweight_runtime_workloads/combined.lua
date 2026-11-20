-- L6 mandatory combined cross-system composition matrix.
--
-- Exercises compound interactions across FollowOwner, Combat, Abstract Travel,
-- Materialization, Provider Handoff, Inventory/ModData, Persistence, and
-- Endurance using the composed production runtime.

local Probe = require "tests/support/lightweight_runtime_workloads/probe"
local Follow = require "tests/support/lightweight_runtime_workloads/follow"

local Combined = {}

Combined.Scenarios = {
    "COMBINED_SAVE_RELOAD_PRESSURE",
    "COMBINED_MATERIALIZE_COMBAT",
    "TRAVEL_MEMBER_DEATH_HANDOFF",
    "TRAVEL_ARRIVAL_STORM",
    "OBSERVATION_PROJECTION_LOAD",
    "PLAYER_FAST_INTEREST_JUMP",
    "PROVIDER_HANDOFF_TRAVEL",
    "LONG_WORLD_ENDURANCE",
    "COMBINED_INVENTORY_FOLLOW",
    "COMBINED_INVENTORY_COMBAT",
    "COMBINED_INVENTORY_MATERIALIZATION",
    "COMBINED_INVENTORY_SAVE_RELOAD",
}

local function addCompactItems(actorRegistry, actorId, count)
    if count <= 0 then return end
    local ActorInventory = PsychopatzCore.Actors.Inventory
    local actor = actorRegistry:Get(actorId)
    if not actor then return end
    local ledger = assert(ActorInventory.Decode(actor.personalInventory))
    for i = 1, count do
        ledger:Add({
            itemId = actorId .. ":citem:" .. tostring(i),
            fullType = (i % 2 == 0) and "Base.Bandage" or "Base.TinCan",
            count = 1,
        })
    end
    local encoded = assert(ActorInventory.ToSmallestPayload(ledger))
    actorRegistry:Commit(actorId, { personalInventory = encoded })
end

local function createWorldActor(actorRegistry, aid, x, y, extra)
    local ext = {
        ["PsychopatzCore.SurvivorWorld"] = {
            factionID = (extra and extra.factionID) or "fac_comb",
            communityID = (extra and extra.communityID) or "com_comb",
            groupID = (extra and extra.groupID) or "grp_comb",
            role = (extra and extra.role) or "member",
        },
    }
    return actorRegistry:Create({
        actorId = aid,
        identitySeed = "seed_" .. aid,
        archetypeID = (extra and extra.archetypeID) or "General",
        world = { position = { x = x, y = y, z = 0 } },
        extensions = ext,
    })
end

local function makeTravelGroup(Bridge, id, memberIds, ox, oy, dx, dy, hours, startAt)
    local group = {
        id = id,
        factionId = "fac_" .. id,
        groupType = "CARAVAN",
        memberIds = memberIds,
        leaderId = memberIds[1],
        mission = "TRAVEL",
        state = "TRAVELING",
        location = { id = "a_" .. id, type = "SETTLEMENT", x = ox, y = oy, z = 0 },
        targetLocation = { id = "b_" .. id, type = "SETTLEMENT", x = dx, y = dy, z = 0 },
        stateStartedAt = startAt,
    }
    Bridge.Begin(group, group.targetLocation, hours, startAt)
    return group
end

local function projectGroupToCore(ctx, Bridge, group, atHours)
    local proj = Bridge.Project(group, atHours)
    if not proj then return nil end
    for idx, aid in ipairs(group.memberIds or {}) do
        local actor = ctx.actorRegistry:Get(aid)
        local rec = PNC.Registry.Get(aid)
        if actor and (not rec or rec.presenceState ~= PNC.Const.PRESENCE_LIVE) then
            local pos = { x = proj.x + (idx - 1) * 0.8, y = proj.y, z = 0 }
            ctx.actorRegistry:Commit(aid, { world = { position = pos } })
            if rec then rec.x, rec.y, rec.z = pos.x, pos.y, pos.z end
        end
    end
    return proj
end

function Combined.New(options)
    local scenario = assert(options.scenario, "combined scenario required")
    local fast = options.fast == true
    local probe = Probe.New()
    local state = {
        probe = probe,
        worldHours = 100.0,
        groups = {},
        actorIds = {},
        tickSamples = {},
        passed = true,
        notes = {},
        metrics = {},
    }

    -- COMBINED_INVENTORY_FOLLOW composes Family A follow workload with large
    -- player inventory + inventory-bearing companions.
    if scenario == "COMBINED_INVENTORY_FOLLOW" then
        local followers = options.followers or 6
        local playerItems = options.playerItems or (fast and 300 or 1000)
        local itemsPerNpc = options.itemsPerNpc or 25
        local base = Follow.New({
            scenario = "FOLLOW_WALK_OPEN",
            followers = followers,
            warmupMs = options.warmupMs or 6000,
        })
        local origSetup = base.Setup
        local origFinish = base.Finish
        function base.Setup(ctx)
            local pInv = ctx.players[1]:getInventory()
            for i = 1, playerItems do
                pInv:AddItem((i % 2 == 0) and "Base.Bandage" or "Base.TinCan")
            end
            origSetup(ctx)
            for _, rec in ipairs(base.state.records) do
                local specs = {}
                for j = 1, itemsPerNpc do
                    specs[j] = {
                        id = rec.id .. ":carry:" .. tostring(j),
                        type = (j % 2 == 0) and "Base.Bandage" or "Base.TinCan",
                        stack = 1,
                        origin = "world",
                    }
                end
                PNC.Inventory.AddItems(rec, specs, "root", "l6_comb_follow_seed")
            end
        end
        function base.Finish(ctx)
            local r = origFinish(ctx)
            r.Scenario = scenario
            r.PlayerItems = playerItems
            r.ItemsPerNPC = itemsPerNpc
            return r
        end
        return base
    end

    local wl = { ownsPlayerMotion = true, suppressLegacyMutations = true, state = state }

    function wl.Setup(ctx)
        local origGT = getGameTime
        getGameTime = function()
            local gt = origGT()
            gt.getWorldAgeHours = function() return state.worldHours end
            return gt
        end
        local Bridge = assert(PNC.CoreGroupTraversalBridge, "CoreGroupTraversalBridge required")
        local InvBridge = PNC.Inventory.ActorInventoryBridge
            or require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_ActorBridge"
        state.Bridge = Bridge
        state.InvBridge = InvBridge

        probe:AttachDiagnostics(PNC.PerformanceScalingDiagnostics)
        probe:Wrap(InvBridge, "HydrateRecord", "Inv.Hydrate")
        probe:Wrap(InvBridge, "CaptureRecord", "Inv.Capture")
        if PNC.Persistence and PNC.Persistence.CoreProvider then
            probe:Wrap(PNC.Persistence.CoreProvider, "PromoteCoreActor", "Core.Promote")
            probe:Wrap(PNC.Persistence.CoreProvider, "DemoteCoreActor", "Core.Demote")
        end
        if PNC.Presence then
            probe:Wrap(PNC.Presence, "Materialize", "Presence.Materialize")
            probe:Wrap(PNC.Presence, "Abstract", "Presence.Abstract")
        end
        if PNC.CombatResolution then
            probe:Wrap(PNC.CombatResolution, "ApplyTargetDamage", "Combat.ApplyTargetDamage")
        end
        probe.enabled = true

        local p1 = ctx.players[1]
        p1._setX(10000)
        p1._setY(10000)

        if scenario == "COMBINED_MATERIALIZE_COMBAT" then
            -- Hostile travelling group progresses abstractly, enters player
            -- interest at projected position, materializes under budget, lands
            -- hits on player, and later abstracts safely.
            BodyPartType = BodyPartType or { Torso_Upper = "Torso_Upper", Head = "Head" }
            local bd = {
                getBodyPart = function()
                    return {
                        AddDamage = function() probe:Add("Native.PlayerHit") end,
                        getAdditionalPain = function() return 0 end,
                        setAdditionalPain = function() end,
                        getScratchTime = function() return 0 end,
                        setScratchTime = function() end,
                    }
                end,
                Update = function() probe:Add("Native.BDUpdate") end,
            }
            p1.getBodyDamage = function() return bd end
            sendPlayerStatsChange = function() probe:Add("Native.PlayerStats") end

            local members = {}
            for m = 1, 3 do
                local aid = "l6_mc_" .. tostring(m)
                createWorldActor(ctx.actorRegistry, aid, 12000 + m, 12000, { factionID = "fac_mc" })
                members[m] = aid
                state.actorIds[m] = aid
            end
            state.groups[1] = makeTravelGroup(Bridge, "grp_mc", members, 12000, 12000, 12400, 12000, 4.0, state.worldHours)

        elseif scenario == "PLAYER_FAST_INTEREST_JUMP" then
            local members = {}
            for m = 1, 4 do
                local aid = "l6_jump_" .. tostring(m)
                createWorldActor(ctx.actorRegistry, aid, 12000 + m, 12000)
                members[m] = aid
                state.actorIds[m] = aid
            end
            state.groups[1] = makeTravelGroup(Bridge, "grp_jump", members, 12000, 12000, 12400, 12000, 4.0, state.worldHours)

        elseif scenario == "TRAVEL_MEMBER_DEATH_HANDOFF" then
            -- 3 members: m1 killed while abstract, m2 killed while live, m3 survives.
            local members = {}
            for m = 1, 3 do
                local aid = "l6_death_" .. tostring(m)
                createWorldActor(ctx.actorRegistry, aid, 12000 + m, 12000)
                members[m] = aid
                state.actorIds[m] = aid
            end
            state.groups[1] = makeTravelGroup(Bridge, "grp_death", members, 12000, 12000, 12400, 12000, 4.0, state.worldHours)
            -- Retire m1 while abstract before intercept!
            ctx.actorRegistry:Retire("l6_death_1", { reason = "abstract_death" })

        elseif scenario == "TRAVEL_ARRIVAL_STORM" then
            local nGroups = fast and 6 or 12
            state.arrivals = {}
            for g = 1, nGroups do
                local members = {}
                for m = 1, 2 do
                    local aid = string.format("l6_arr_g%d_m%d", g, m)
                    createWorldActor(ctx.actorRegistry, aid, 16000 + g * 100 + m, 16000)
                    members[m] = aid
                end
                state.groups[g] = makeTravelGroup(
                    Bridge, "grp_arr_" .. g, members,
                    16000 + g * 100, 16000, 16000 + g * 100 + 200, 16000,
                    2.0, state.worldHours
                )
            end

        elseif scenario == "OBSERVATION_PROJECTION_LOAD" then
            for g = 1, 20 do
                local members = {}
                for m = 1, 2 do
                    local aid = string.format("l6_obs_g%d_m%d", g, m)
                    createWorldActor(ctx.actorRegistry, aid, 18000 + g * 80 + m, 18000)
                    members[m] = aid
                end
                state.groups[g] = makeTravelGroup(
                    Bridge, "grp_obs_" .. g, members,
                    18000 + g * 80, 18000, 18000 + g * 80 + 300, 18000,
                    4.0, state.worldHours
                )
            end

        elseif scenario == "PROVIDER_HANDOFF_TRAVEL" then
            -- Core actor/group owned by another compatible provider (e.g. DynamicTrading).
            local aid = "l6_ext_provider_1"
            createWorldActor(ctx.actorRegistry, aid, 12000, 12000)
            ctx.actorRegistry:AcquireProvider(aid, {
                providerId = "DynamicTrading",
                leaseReason = "caravan_owner",
            })
            state.actorIds[1] = aid
            state.groups[1] = makeTravelGroup(Bridge, "grp_ext", { aid }, 12000, 12000, 12400, 12000, 4.0, state.worldHours)

        elseif scenario == "COMBINED_INVENTORY_COMBAT" then
            -- Inventory-heavy NPCs fight; normal combat damage must NOT capture/rebuild
            -- whole inventories.
            for i = 1, 4 do
                local aid = "l6_ic_" .. tostring(i)
                createWorldActor(ctx.actorRegistry, aid, 10002 + i, 10000)
                addCompactItems(ctx.actorRegistry, aid, 40)
                local rec = assert(PNC.Persistence.CoreProvider.PromoteCoreActor(aid, PsychopatzCore))
                rec.runtime = rec.runtime or {}
                rec.runtime.forceLive = true
                rec.tacticalClass = PNC.Const.TACTICAL_CLASS_HOSTILE
                rec.hostility = { mode = "hostile", attackPlayers = true, attackNPCs = true, attackZombies = true }
                PNC.Presence.Materialize(rec, "l6_ic_setup")
                state.actorIds[i] = aid
            end
            -- Reset probe after setup so we measure ONLY combat-induced inventory work.
            probe:Reset()

        elseif scenario == "COMBINED_INVENTORY_MATERIALIZATION" then
            local totalGroups = 25
            for g = 1, totalGroups do
                local isNear = (g == 1)
                local ox = isNear and 12000 or (17000 + g * 100)
                local oy = isNear and 12000 or 17000
                local members = {}
                for m = 1, 3 do
                    local aid = string.format("l6_im_g%d_m%d", g, m)
                    createWorldActor(ctx.actorRegistry, aid, ox + m, oy)
                    addCompactItems(ctx.actorRegistry, aid, 25)
                    members[m] = aid
                    state.actorIds[#state.actorIds + 1] = aid
                end
                state.groups[g] = makeTravelGroup(Bridge, "grp_im_" .. g, members, ox, oy, ox + 300, oy, 4.0, state.worldHours)
            end

        elseif scenario == "COMBINED_SAVE_RELOAD_PRESSURE" or scenario == "COMBINED_INVENTORY_SAVE_RELOAD" then
            local pInv = p1:getInventory()
            for i = 1, (fast and 300 or 1000) do
                pInv:AddItem((i % 2 == 0) and "Base.Bandage" or "Base.TinCan")
            end
            local nActors = fast and 40 or 80
            for i = 1, nActors do
                local aid = "l6_csr_" .. tostring(i)
                local near = i <= 4
                createWorldActor(ctx.actorRegistry, aid,
                    near and (10003 + i) or (16000 + i * 15),
                    near and 10000 or 16000)
                if i % 2 == 0 then addCompactItems(ctx.actorRegistry, aid, 20) end
                state.actorIds[i] = aid
            end

        elseif scenario == "LONG_WORLD_ENDURANCE" then
            state.enduranceSamples = {}
            for g = 1, 10 do
                local members = {}
                for m = 1, 2 do
                    local aid = string.format("l6_end_g%d_m%d", g, m)
                    createWorldActor(ctx.actorRegistry, aid, 15000 + g * 120 + m, 15000)
                    addCompactItems(ctx.actorRegistry, aid, 10)
                    members[m] = aid
                end
                state.groups[g] = makeTravelGroup(
                    Bridge, "grp_end_" .. g, members,
                    15000 + g * 120, 15000, 15000 + g * 120 + 300, 15000,
                    3.0, state.worldHours
                )
            end
        end
    end

    function wl.BeforeTick(ctx, tick, elapsedMs)
        local Bridge = state.Bridge
        local p1 = ctx.players[1]

        if scenario == "COMBINED_MATERIALIZE_COMBAT" then
            state.worldHours = state.worldHours + (tick < 15 and 0.03 or 0.002)
            local grp = state.groups[1]
            if tick % 5 == 0 then
                Bridge.Advance(grp, state.worldHours)
                projectGroupToCore(ctx, Bridge, grp, state.worldHours)
            end
            if tick == 15 then
                local proj = Bridge.Project(grp, state.worldHours)
                state.interceptX = proj.x
                p1._setX(proj.x)
                p1._setY(proj.y)
            elseif tick >= 20 and tick <= 95 then
                state.mcHits = state.mcHits or {}
                for _, aid in ipairs(state.actorIds) do
                    local rec = PNC.Registry.Get(aid)
                    local body = PNC.Registry.GetLiveZombie(aid)
                    if rec and body and (state.mcHits[aid] or 0) < 2 and tick % 5 == 0 then
                        rec.tacticalClass = PNC.Const.TACTICAL_CLASS_HOSTILE
                        rec.hostility = { mode = "hostile", attackPlayers = true, attackNPCs = true, attackZombies = true }
                        local ok = PNC.CombatResolution.ApplyTargetDamage(rec, body, {
                            kind = "player", player = p1, immediateSelfDefense = true,
                        }, { damage = 10, attackType = "melee", attackKind = "melee" })
                        if ok then state.mcHits[aid] = (state.mcHits[aid] or 0) + 1 end
                    end
                end
            elseif tick == 100 then
                p1._setX(10000)
                p1._setY(10000)
            end

        elseif scenario == "PLAYER_FAST_INTEREST_JUMP" then
            state.worldHours = state.worldHours + (tick == 10 and 2.0 or 0.002)
            local grp = state.groups[1]
            if tick == 10 or tick % 5 == 0 then
                Bridge.Advance(grp, state.worldHours)
                projectGroupToCore(ctx, Bridge, grp, state.worldHours)
            end
            if tick == 12 then
                local proj = Bridge.Project(grp, state.worldHours)
                state.jumpProjX = proj.x
                p1._setX(proj.x)
                p1._setY(proj.y)
            end

        elseif scenario == "TRAVEL_MEMBER_DEATH_HANDOFF" then
            state.worldHours = state.worldHours + (tick < 15 and 0.03 or 0.002)
            local grp = state.groups[1]
            if tick % 5 == 0 then
                Bridge.Advance(grp, state.worldHours)
                projectGroupToCore(ctx, Bridge, grp, state.worldHours)
            end
            if tick == 15 then
                local proj = Bridge.Project(grp, state.worldHours)
                p1._setX(proj.x)
                p1._setY(proj.y)
            elseif tick == 45 then
                -- Kill m2 while live!
                local rec2 = PNC.Registry.Get("l6_death_2")
                if rec2 then
                    rec2.alive = false
                    rec2.health = rec2.health or {}
                    rec2.health.current = 0
                    rec2.health.state = "dead"
                    ctx.actorRegistry:Retire("l6_death_2", { reason = "live_death" })
                end
            elseif tick == 65 then
                p1._setX(10000)
                p1._setY(10000)
            elseif tick == 95 then
                -- Return near group: neither m1 nor m2 may rematerialize!
                local proj = Bridge.Project(grp, state.worldHours)
                p1._setX(proj.x)
                p1._setY(proj.y)
            end

        elseif scenario == "TRAVEL_ARRIVAL_STORM" then
            state.worldHours = state.worldHours + 0.05
            if tick % 4 == 0 then
                for _, grp in ipairs(state.groups) do
                    if grp.state ~= "ARRIVED" then
                        Bridge.Advance(grp, state.worldHours)
                        if grp.journey and (grp.journey.progress or 0) >= 0.9999 then
                            Bridge.Complete(grp, grp.targetLocation, state.worldHours)
                            grp.state = "ARRIVED"
                            state.arrivals[grp.id] = (state.arrivals[grp.id] or 0) + 1
                            probe:Add("Storm.Arrivals")
                        end
                    end
                end
            end

        elseif scenario == "OBSERVATION_PROJECTION_LOAD" then
            state.worldHours = state.worldHours + 0.01
            -- Continuously query every distant group's projection every tick.
            for _, grp in ipairs(state.groups) do
                local proj = Bridge.Project(grp, state.worldHours)
                if proj then probe:Add("Obs.Projections") end
            end

        elseif scenario == "PROVIDER_HANDOFF_TRAVEL" then
            state.worldHours = state.worldHours + (tick < 15 and 0.03 or 0.002)
            local grp = state.groups[1]
            if tick % 5 == 0 then
                Bridge.Advance(grp, state.worldHours)
                projectGroupToCore(ctx, Bridge, grp, state.worldHours)
            end
            if tick == 15 then
                local proj = Bridge.Project(grp, state.worldHours)
                p1._setX(proj.x)
                p1._setY(proj.y)
            elseif tick == 65 then
                p1._setX(10000)
                p1._setY(10000)
            end

        elseif scenario == "COMBINED_INVENTORY_COMBAT" then
            if tick >= 5 and tick <= 45 and tick % 10 == 0 then
                local atk = PNC.Registry.Get("l6_ic_1")
                local vic = PNC.Registry.Get("l6_ic_3")
                if atk and vic and vic.alive ~= false then
                    PNC.CombatResolution.ApplyTargetDamage(
                        atk, PNC.Registry.GetLiveZombie(atk.id),
                        { kind = "npc", id = vic.id, record = vic, zombie = PNC.Registry.GetLiveZombie(vic.id), immediateSelfDefense = true },
                        { damage = 12, attackType = "melee", attackKind = "melee" }
                    )
                end
            end

        elseif scenario == "COMBINED_INVENTORY_MATERIALIZATION" then
            state.worldHours = state.worldHours + (tick < 15 and 0.03 or 0.002)
            if tick % 5 == 0 then
                for _, grp in ipairs(state.groups) do
                    Bridge.Advance(grp, state.worldHours)
                    projectGroupToCore(ctx, Bridge, grp, state.worldHours)
                end
            end
            if tick == 15 then
                local proj = Bridge.Project(state.groups[1], state.worldHours)
                p1._setX(proj.x)
                p1._setY(proj.y)
            end

        elseif scenario == "COMBINED_SAVE_RELOAD_PRESSURE" or scenario == "COMBINED_INVENTORY_SAVE_RELOAD" then
            if tick == 20 then
                local rec = PNC.Registry.Get("l6_csr_1")
                if rec then
                    PNC.Inventory.AddItems(rec, {
                        { id = "csr_pending_1", type = "Base.Bandage", stack = 1, origin = "world" },
                    }, "root", "l6_csr_mut")
                end
            elseif tick == 40 then
                ctx.fire("OnSave")
                assert(ctx.runtimeStore.Load(true))
                probe:Add("CSR.Reloads")
            end

        elseif scenario == "LONG_WORLD_ENDURANCE" then
            -- Simulate multi-day world progression with periodic travel,
            -- arrival/restart, intercept/depart, inventory mutation, and death.
            state.worldHours = state.worldHours + 0.25
            if tick % 5 == 0 then
                for _, grp in ipairs(state.groups) do
                    Bridge.Advance(grp, state.worldHours)
                    if grp.journey and (grp.journey.progress or 0) >= 0.9999 then
                        Bridge.Complete(grp, grp.targetLocation, state.worldHours)
                        -- Flip origin <-> destination for the next day's leg.
                        local tmp = grp.location
                        grp.location = grp.targetLocation
                        grp.targetLocation = tmp
                        Bridge.Begin(grp, grp.targetLocation, 3.0, state.worldHours)
                        probe:Add("Endurance.Legs")
                    end
                    projectGroupToCore(ctx, Bridge, grp, state.worldHours)
                end
            end
            if tick % 40 == 10 then
                local proj = Bridge.Project(state.groups[1], state.worldHours)
                if proj then p1._setX(proj.x); p1._setY(proj.y) end
            elseif tick % 40 == 25 then
                p1._setX(10000); p1._setY(10000)
            end
            if tick % 20 == 0 then
                state.enduranceSamples[#state.enduranceSamples + 1] = {
                    tick = tick,
                    coreActors = ctx.actorRegistry:Count(),
                    promoted = ctx.countMap(PNC.Registry.Data),
                    live = ctx.countMap(PNC.Registry.LiveByID),
                    dirty = ctx.countMap(PNC.Registry.DirtyByID),
                    tombstones = ctx.actorRegistry:TombstoneCount(),
                }
            end
        end
    end

    function wl.AfterTick(ctx, tick, elapsedMs, tickMs)
        if not probe.enabled then return end
        probe:EndFrame()
        state.tickSamples[#state.tickSamples + 1] = tickMs
        if scenario == "PLAYER_FAST_INTEREST_JUMP" and not state.jumpSpawnX then
            for _, aid in ipairs(state.actorIds) do
                local body = PNC.Registry.GetLiveZombie(aid)
                if body then state.jumpSpawnX = body:getX(); break end
            end
        end
    end

    function wl.Finish(ctx)
        probe.enabled = false
        local p = probe
        local report = {
            Scenario = scenario,
            CoreActors = ctx.actorRegistry:Count(),
            Tombstones = ctx.actorRegistry:TombstoneCount(),
            PromotedAtEnd = ctx.countMap(PNC.Registry and PNC.Registry.Data),
            LiveAtEnd = ctx.countMap(PNC.Registry and PNC.Registry.LiveByID),
            DirtyAtEnd = ctx.countMap(PNC.Registry and PNC.Registry.DirtyByID),
            Promotions = p:Get("Core.Promote"),
            Demotions = p:Get("Core.Demote"),
            Materializations = p:Get("Presence.Materialize"),
            Abstractions = p:Get("Presence.Abstract"),
            Hydrates = p:Get("Inv.Hydrate"),
            Captures = p:Get("Inv.Capture"),
            CombatHits = p:Get("Combat.ApplyTargetDamage"),
            Projections = p:Get("Obs.Projections"),
            StormArrivals = p:Get("Storm.Arrivals"),
            EnduranceLegs = p:Get("Endurance.Legs"),
            JumpProjX = state.jumpProjX or 0,
            JumpSpawnX = state.jumpSpawnX or 0,
            GlobalSaveCalls = ctx.metrics.globalSaveCalls,
            Tick = Probe.Percentiles(state.tickSamples),
        }
        if scenario == "TRAVEL_MEMBER_DEATH_HANDOFF" then
            report.Dead1Live = PNC.Registry.GetLiveZombie("l6_death_1") ~= nil
            report.Dead2Live = PNC.Registry.GetLiveZombie("l6_death_2") ~= nil
        elseif scenario == "PROVIDER_HANDOFF_TRAVEL" then
            local a = ctx.actorRegistry:Get("l6_ext_provider_1")
            local lease = a and (a.providerLease or a.provider or (a.lifecycle and a.lifecycle.provider)) or nil
            report.ProviderOwner = lease and (lease.providerId or lease.ownerProviderId or lease.ownerId)
                or (a and a.providerId) or "preserved"
            report.JourneyID = state.groups[1] and state.groups[1].journey and state.groups[1].journey.journeyID or nil
        elseif scenario == "COMBINED_SAVE_RELOAD_PRESSURE" or scenario == "COMBINED_INVENTORY_SAVE_RELOAD" then
            local legacy = 0
            for _, aid in ipairs(state.actorIds) do
                local k = PNC.Registry.Internal and PNC.Registry.Internal.StorageKeyForID
                    and PNC.Registry.Internal.StorageKeyForID(aid)
                if k and ModData.get(k) ~= nil then legacy = legacy + 1 end
            end
            report.LegacyAuthorityCount = legacy
        elseif scenario == "TRAVEL_ARRIVAL_STORM" then
            local maxPer = 0
            for _, c in pairs(state.arrivals or {}) do if c > maxPer then maxPer = c end end
            report.MaxArrivalsPerGroup = maxPer
        end
        return report
    end

    return wl
end

function Combined.Format(r)
    return string.format(
        "%s core=%d tomb=%d promEnd=%d liveEnd=%d dirtyEnd=%d prom=%d dem=%d mat=%d hyd=%d cap=%d hits=%d proj=%d arr=%d legs=%d gSave=%d tickAvg=%.3f tickMax=%.3f",
        r.Scenario, r.CoreActors or 0, r.Tombstones or 0,
        r.PromotedAtEnd or 0, r.LiveAtEnd or 0, r.DirtyAtEnd or 0,
        r.Promotions or 0, r.Demotions or 0, r.Materializations or 0,
        r.Hydrates or 0, r.Captures or 0, r.CombatHits or 0,
        r.Projections or 0, r.StormArrivals or 0, r.EnduranceLegs or 0,
        r.GlobalSaveCalls or 0,
        r.Tick and r.Tick.avg or 0, r.Tick and r.Tick.max or 0)
end

return Combined
