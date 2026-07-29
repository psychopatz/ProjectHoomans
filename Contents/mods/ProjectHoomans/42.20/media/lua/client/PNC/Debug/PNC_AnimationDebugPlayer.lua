require "PNC/Debug/PNC_AnimationDebugCatalog"

PNC = PNC or {}
PNC.AnimationDebugPlayer = PNC.AnimationDebugPlayer or {}

local Player = PNC.AnimationDebugPlayer
local Catalog = PNC.AnimationDebugCatalog
local Core = PNC.Core
local Animation = PNC.Animation
local staleActiveAtLoad = Player.active

local SELECTOR_ADAPTERS = {
    targetseentime = {
        get = function(body)
            return body.getTargetSeenTime
                and body:getTargetSeenTime()
                or 0
        end,
        set = function(body, value)
            if body.setTargetSeenTime then
                body:setTargetSeenTime(tonumber(value) or 0)
            end
        end,
    },
    playerattackposition = {
        get = function(body)
            return body.getPlayerAttackPosition
                and tostring(body:getPlayerAttackPosition() or "")
                or ""
        end,
        set = function(body, value)
            if body.setPlayerAttackPosition then
                body:setPlayerAttackPosition(tostring(value or ""))
            end
        end,
    },
    hitforce = {
        get = function(body)
            return body.getHitForce
                and body:getHitForce()
                or 0
        end,
        set = function(body, value)
            if body.setHitForce then
                body:setHitForce(tonumber(value) or 0)
            end
        end,
    },
    hitreaction = {
        get = function(body)
            return body.getHitReaction
                and tostring(body:getHitReaction() or "")
                or ""
        end,
        set = function(body, value)
            if body.setHitReaction then
                body:setHitReaction(tostring(value or ""))
            end
        end,
    },
    sitonground = {
        get = function(body)
            return body.isSitOnGround
                and body:isSitOnGround() == true
                or false
        end,
        set = function(body, value)
            if body.setSitOnGround then
                body:setSitOnGround(value == true)
            end
        end,
    },
    frombehind = {
        get = function(body)
            return body.isHitFromBehind
                and body:isHitFromBehind() == true
                or false
        end,
        set = function(body, value)
            if body.setHitFromBehind then
                body:setHitFromBehind(value == true)
            end
        end,
    },
    fallonfront = {
        get = function(body)
            return body.isFallOnFront
                and body:isFallOnFront() == true
                or false
        end,
        set = function(body, value)
            if body.setFallOnFront then
                body:setFallOnFront(value == true)
            end
        end,
    },
}

-- These selectors are computed from engine state and have no safe public
-- setter. Writing them through setVariable produces warning spam and still
-- cannot make the corresponding XML branch true.
local READ_ONLY_SELECTORS = {
    bclient = true,
    bhastarget = true,
    bistargetissmallvehicle = true,
    bpassengerexposed = true,
    intrees = true,
    issitting = true,
    previousstate = true,
    waseating = true,
}

local function nowMillis()
    return Core and Core.Now and Core.Now() or 0
end

local function topologyName()
    if isClient and isClient() == true then return "multiplayer client" end
    if isServer and isServer() == true then return "dedicated server" end
    return "singleplayer"
end

local function bodyID(body)
    local modData = body
        and body.getModData
        and body:getModData()
        or nil
    return tostring(modData and modData.PNC_UUID or "")
end

local function getBodyFromPresence(npcId)
    local sync = PNC.ClientPresenceSync
    local id = tostring(npcId or "")
    if id == "" or not sync then return nil end
    if sync.BodyByID and sync.BodyByID[id] then
        return sync.BodyByID[id]
    end
    if sync.BodyByLease then
        for _, body in pairs(sync.BodyByLease) do
            if bodyID(body) == id then return body end
        end
    end
    return nil
end

function Player.ResolveBody(npcId, fallback)
    local requestedID = tostring(npcId or "")
    local fallbackID = bodyID(fallback)
    if fallback
        and (not fallback.isDead or fallback:isDead() ~= true)
        and (
            requestedID == ""
            or fallbackID == ""
            or fallbackID == requestedID
        )
    then
        return fallback
    end
    return getBodyFromPresence(npcId)
end

local function conditionValue(condition)
    local kind = tostring(condition and condition.kind or "")
    local raw = condition and condition.value or nil
    if kind == "BOOL" then
        return tostring(raw) == "true"
    end
    if kind == "GTR" then
        return (tonumber(raw) or 0) + 0.01
    end
    if kind == "LESS" then
        return (tonumber(raw) or 0) - 0.01
    end
    if kind == "STRNEQ" then
        return tostring(raw or "") .. "__PNC_DEBUG_NOT_EQUAL__"
    end
    return tostring(raw or "")
end

local function readVariable(body, condition)
    local kind = tostring(condition and condition.kind or "")
    local name = condition and condition.name or nil
    local adapter = name
        and SELECTOR_ADAPTERS[string.lower(tostring(name))]
        or nil
    if not name or name == "" then return nil end
    if adapter then return adapter.get(body) end
    if kind == "BOOL" and body.getVariableBoolean then
        return body:getVariableBoolean(name) == true
    end
    if (kind == "GTR" or kind == "LESS")
        and body.getVariableFloat
    then
        return body:getVariableFloat(name, 0.0)
    end
    if body.getVariableString then
        return tostring(body:getVariableString(name) or "")
    end
    return nil
end

local function saveAndApplyConditions(active)
    local body = active.body
    if not body.setVariable then return end
    for _, condition in ipairs(active.entry.conditions or {}) do
        local name = condition.name
        if name and name ~= "" then
            local normalized = string.lower(tostring(name))
            local adapter = SELECTOR_ADAPTERS[normalized]
            if READ_ONLY_SELECTORS[normalized] then
                active.skippedSelectors[#active.skippedSelectors + 1] =
                    tostring(name)
            elseif active.previousVariables[name] == nil then
                active.previousVariables[name] = {
                    condition = condition,
                    value = readVariable(body, condition),
                    adapter = adapter,
                }
                if adapter then
                    adapter.set(body, conditionValue(condition))
                else
                    body:setVariable(name, conditionValue(condition))
                end
            elseif adapter then
                adapter.set(body, conditionValue(condition))
            else
                body:setVariable(name, conditionValue(condition))
            end
        end
    end
    -- Every PNC node depends on the human-shell discriminator, either
    -- directly or through its inherited base node.
    body:setVariable("PNCActor", true)
end

local function restoreConditions(active)
    local body = active and active.body or nil
    if not body or not body.setVariable then return end
    for name, previous in pairs(active.previousVariables or {}) do
        if previous.adapter then
            previous.adapter.set(body, previous.value)
        elseif previous.value ~= nil then
            body:setVariable(name, previous.value)
        elseif body.clearVariable then
            body:clearVariable(name)
        end
    end
    body:setVariable("PNCActor", true)
end

local function markPreview(active)
    local modData = active.body.getModData
        and active.body:getModData()
        or nil
    if not modData then return end
    modData.PNC_AnimationDebugPreview = true
    modData.PNC_AnimationDebugMode = active.mode
    modData.PNC_AnimationDebugState = active.entry.state
    modData.PNC_AnimationDebugNode = active.entry.node
    modData.PNC_AnimationDebugClip = active.entry.anim
    modData.PNC_AnimationDebugStartedAt = active.startedAt
end

local function clearPreview(active)
    local modData = active
        and active.body
        and active.body.getModData
        and active.body:getModData()
        or nil
    if not modData then return end
    modData.PNC_AnimationDebugPreview = nil
    modData.PNC_AnimationDebugMode = nil
    modData.PNC_AnimationDebugState = nil
    modData.PNC_AnimationDebugNode = nil
    modData.PNC_AnimationDebugClip = nil
    modData.PNC_AnimationDebugStartedAt = nil
end

local function findBumpType(entry)
    if not entry or entry.state ~= "bumped" then return nil end
    for _, condition in ipairs(entry.conditions or {}) do
        if condition.name == "BumpType"
            and condition.kind == "STRING"
            and condition.value
            and condition.value ~= ""
        then
            return tostring(condition.value)
        end
    end
    return nil
end

function Player.CanPipeline(entry)
    return findBumpType(entry) ~= nil
end

function Player.GetPlaybackRoute(entry)
    if Player.CanPipeline(entry) then
        return "PNC BumpType → XML node"
    end
    if entry and entry.playable then
        return "resolved selectors + exposed body clip"
    end
    return "selectors only (no direct clip)"
end

function Player.GetEntryNote(entry)
    local state = tostring(entry and entry.state or "")
    if state == "attack" or state == "attack-network" then
        return "Zombie bite-graph guard; this PNC node intentionally uses an idle/aim clip. NPC weapon swings are under bumped."
    end
    if Player.CanPipeline(entry) then
        return "Engine XML playback through the same BumpType route used by live NPC actions."
    end
    return "Preview applies writable selectors, then uses the Lua-exposed body clip player because AdvancedAnimator state setters are not exposed."
end

local function isPipelineMode(mode)
    return mode == "pipeline" or mode == "xml_pipeline"
end

function Player.Stop(reason)
    local active = Player.active
    if not active then return false end
    if isPipelineMode(active.mode)
        and Animation
        and Animation.FinishBump
    then
        Animation.FinishBump(active.body, true)
    end
    restoreConditions(active)
    clearPreview(active)
    if active.body
        and active.body.setUseless
        and active.uselessBefore ~= nil
    then
        active.body:setUseless(active.uselessBefore)
    end
    Player.lastResult = {
        ok = true,
        reason = tostring(reason or "stopped"),
        at = nowMillis(),
        mode = active.mode,
        node = active.entry and active.entry.node or nil,
    }
    Player.active = nil
    return true
end

local function begin(
    entry,
    npcId,
    body,
    mode,
    record,
    applySelectors
)
    Player.Stop("replaced")
    body = Player.ResolveBody(npcId, body)
    if not body then
        Player.lastResult = {
            ok = false,
            reason = "selected NPC has no local live body",
            at = nowMillis(),
        }
        return nil, "no_local_body"
    end
    if not entry then
        Player.lastResult = {
            ok = false,
            reason = "no animation node selected",
            at = nowMillis(),
        }
        return nil, "no_entry"
    end
    local active = {
        body = body,
        npcId = tostring(npcId or bodyID(body)),
        entry = entry,
        mode = mode,
        record = record or {
            id = tostring(npcId or bodyID(body)),
            runtime = { debug = true },
        },
        startedAt = nowMillis(),
        previousVariables = {},
        skippedSelectors = {},
        uselessBefore = body.isUseless
            and body:isUseless() == true
            or false,
    }
    Player.active = active
    if applySelectors ~= false then
        saveAndApplyConditions(active)
    end
    markPreview(active)
    return active
end

local function completeStart(active, ok, reason)
    local result = {
        ok = ok == true,
        reason = tostring(reason or (ok and "playing" or "failed")),
        at = nowMillis(),
        mode = active and active.mode or nil,
        node = active and active.entry and active.entry.node or nil,
    }
    if ok ~= true then
        Player.Stop(reason or "play_failed")
    end
    Player.lastResult = result
    print("[PNC][ANIMPLAYER] start"
        .. " ok=" .. tostring(result.ok)
        .. " npc=" .. tostring(active and active.npcId or "-")
        .. " mode=" .. tostring(result.mode or "-")
        .. " state=" .. tostring(
            active and active.entry and active.entry.state or "-"
        )
        .. " node=" .. tostring(result.node or "-")
        .. " clip=" .. tostring(
            active and active.entry and active.entry.anim or "-"
        )
        .. " reason=" .. tostring(result.reason)
        .. " skipped=" .. table.concat(
            active and active.skippedSelectors or {},
            ","
        ))
    return ok == true, reason
end

function Player.PlayXML(entry, npcId, body, record)
    local active, reason = begin(
        entry,
        npcId,
        body,
        "xml",
        record,
        true
    )
    if not active then return false, reason end
    local bumpType = findBumpType(entry)
    if bumpType and Animation and Animation.PlayBump then
        active.mode = "xml_pipeline"
        markPreview(active)
        local ok, playReason = Animation.PlayBump(
            body,
            active.record,
            bumpType
        )
        return completeStart(
            active,
            ok,
            ok and "xml_pipeline_started"
                or playReason
        )
    end
    if not entry.playable or not entry.anim or entry.anim == "" then
        return completeStart(active, false, "node_has_no_clip")
    end
    if body.setUseless then body:setUseless(false) end
    if entry.looped and body.PlayAnimWithSpeed then
        body:PlayAnimWithSpeed(
            tostring(entry.anim),
            tonumber(entry.speed) or 1.0
        )
    elseif body.PlayAnimUnlooped then
        body:PlayAnimUnlooped(tostring(entry.anim))
    elseif body.PlayAnim then
        body:PlayAnim(tostring(entry.anim))
    else
        return completeStart(active, false, "body_clip_player_unavailable")
    end
    if PNC.AnimationTrace and PNC.AnimationTrace.Sample then
        PNC.AnimationTrace.Sample(body, "debug_xml_play", nil, true)
    end
    return completeStart(active, true, "xml_selectors_clip_started")
end

function Player.PlayPipeline(entry, npcId, body, record)
    local bumpType = findBumpType(entry)
    if not bumpType then return false, "node_has_no_bump_type" end
    local active, reason = begin(
        entry,
        npcId,
        body,
        "pipeline",
        record,
        true
    )
    if not active then return false, reason end
    if not Animation or not Animation.PlayBump then
        return completeStart(active, false, "pnc_pipeline_unavailable")
    end
    local ok, playReason = Animation.PlayBump(
        body,
        active.record,
        bumpType
    )
    return completeStart(active, ok, playReason)
end

function Player.PlayRaw(entry, npcId, body, record)
    local active, reason = begin(
        entry,
        npcId,
        body,
        "raw",
        record,
        false
    )
    if not active then return false, reason end
    if not entry.playable or not entry.anim or entry.anim == "" then
        return completeStart(active, false, "node_has_no_clip")
    end
    if body.setUseless then body:setUseless(false) end
    if entry.looped and body.PlayAnimWithSpeed then
        body:PlayAnimWithSpeed(
            tostring(entry.anim),
            tonumber(entry.speed) or 1.0
        )
    elseif body.PlayAnimUnlooped then
        body:PlayAnimUnlooped(tostring(entry.anim))
    elseif body.PlayAnim then
        body:PlayAnim(tostring(entry.anim))
    else
        return completeStart(active, false, "raw_player_unavailable")
    end
    if PNC.AnimationTrace and PNC.AnimationTrace.Sample then
        PNC.AnimationTrace.Sample(body, "debug_raw_play", nil, true)
    end
    return completeStart(active, true, "raw_clip_started")
end

function Player.Replay()
    local active = Player.active
    if not active then return false, "nothing_to_replay" end
    local entry = active.entry
    local npcId = active.npcId
    local body = active.body
    local record = active.record
    if isPipelineMode(active.mode) then
        return Player.PlayPipeline(entry, npcId, body, record)
    end
    if active.mode == "raw" then
        return Player.PlayRaw(entry, npcId, body, record)
    end
    return Player.PlayXML(entry, npcId, body, record)
end

function Player.Finish()
    local active = Player.active
    if not active then return false, "nothing_playing" end
    if isPipelineMode(active.mode)
        and Animation
        and Animation.FinishBump
    then
        Animation.FinishBump(active.body, true)
        Player.lastResult = {
            ok = true,
            reason = "finish_signalled",
            at = nowMillis(),
            mode = active.mode,
            node = active.entry.node,
        }
        return true, "finish_signalled"
    end
    if active.body.reportEvent then
        active.body:reportEvent("ActiveAnimFinishing")
        Player.lastResult = {
            ok = true,
            reason = "active_anim_finishing_reported",
            at = nowMillis(),
            mode = active.mode,
            node = active.entry.node,
        }
        return true, "active_anim_finishing_reported"
    end
    return false, "finish_event_unavailable"
end

function Player.IsPreviewing(bodyOrId)
    local active = Player.active
    if not active then return false end
    if type(bodyOrId) == "string"
        or type(bodyOrId) == "number"
    then
        return active.npcId == tostring(bodyOrId)
    end
    return active.body == bodyOrId
end

function Player.Maintain(body, now)
    local active = Player.active
    if not active or active.body ~= body then return false end
    if body.isDead and body:isDead() then
        Player.Stop("body_dead")
        return false
    end
    -- Pipeline previews use the same topology contract as Bandits: useless in
    -- SP, useful in MP while ActionContext advances. Direct/raw clip playback
    -- has no bump lease and therefore keeps the body useful explicitly.
    if not isPipelineMode(active.mode) and body.setUseless then
        body:setUseless(false)
    end
    markPreview(active)
    if isPipelineMode(active.mode)
        and Animation
        and Animation.PumpBumpRelease
    then
        Animation.PumpBumpRelease(body, now or nowMillis())
    end
    Player.Observe(now)
    return true
end

function Player.Observe(now)
    local active = Player.active
    if not active then return false end
    now = tonumber(now) or nowMillis()
    local age = now - (tonumber(active.startedAt) or now)
    local stage = tonumber(active.observationStage) or 0
    local threshold = stage == 0 and 100
        or stage == 1 and 450
        or nil
    if not threshold or age < threshold then return false end
    active.observationStage = stage + 1
    local runtime = Player.Runtime()
    print("[PNC][ANIMPLAYER] observe"
        .. tostring(active.observationStage)
        .. " age=" .. tostring(math.max(0, age)) .. "ms"
        .. " npc=" .. tostring(active.npcId)
        .. " mode=" .. tostring(active.mode)
        .. " requested=" .. tostring(active.entry.anim or "-")
        .. " action=" .. tostring(runtime.actionState or "-")
        .. " animState=" .. tostring(runtime.animationState or "-")
        .. " bump=" .. tostring(runtime.bumpType or "-")
        .. " track=" .. tostring(runtime.track or "-")
        .. " time=" .. tostring(runtime.trackTime or "-")
        .. " weight=" .. tostring(runtime.trackWeight or "-"))
    return true
end

function Player.Runtime()
    local active = Player.active
    local body = active and active.body or nil
    return {
        topology = topologyName(),
        active = active ~= nil,
        npcId = active and active.npcId or nil,
        mode = active and active.mode or nil,
        node = active and active.entry and active.entry.node or nil,
        requestedState = active
            and active.entry
            and active.entry.state
            or nil,
        requestedClip = active
            and active.entry
            and active.entry.anim
            or nil,
        actionState = body
            and body.getCurrentActionContextStateName
            and tostring(
                body:getCurrentActionContextStateName() or ""
            )
            or "",
        previousActionState = body
            and body.getPreviousActionContextStateName
            and tostring(
                body:getPreviousActionContextStateName() or ""
            )
            or "",
        animationState = body
            and body.getAnimationStateName
            and tostring(body:getAnimationStateName() or "")
            or "",
        -- AdvancedAnimator is a non-table Java userdata in Build 42.19.
        -- Its public Java methods are intentionally not indexed from Lua.
        advancedState = "not Lua-exposed",
        bumpType = body
            and body.getBumpType
            and tostring(body:getBumpType() or "")
            or "",
        track = body
            and body.dbgGetAnimTrackName
            and tostring(body:dbgGetAnimTrackName(0, 0) or "")
            or "",
        trackTime = body
            and body.dbgGetAnimTrackTime
            and tonumber(body:dbgGetAnimTrackTime(0, 0))
            or nil,
        trackWeight = body
            and body.dbgGetAnimTrackWeight
            and tonumber(body:dbgGetAnimTrackWeight(0, 0))
            or nil,
        trackFrame = body
            and body.dbgGetAnimTrackTime
            and math.max(
                0,
                math.floor(
                    (
                        tonumber(
                            body:dbgGetAnimTrackTime(0, 0)
                        ) or 0
                    ) * 30 + 0.0001
                )
            )
            or nil,
        useless = body
            and body.isUseless
            and body:isUseless() == true
            or false,
        result = Player.lastResult,
        skippedSelectors = active
            and active.skippedSelectors
            or {},
    }
end

function Player.Dump()
    local active = Player.active
    local runtime = Player.Runtime()
    print("[PNC][ANIMPLAYER] topology="
        .. tostring(runtime.topology)
        .. " npc=" .. tostring(runtime.npcId or "-")
        .. " mode=" .. tostring(runtime.mode or "-")
        .. " node=" .. tostring(runtime.node or "-")
        .. " state=" .. tostring(runtime.requestedState or "-")
        .. "/" .. tostring(runtime.actionState or "-")
        .. "/" .. tostring(runtime.advancedState or "-")
        .. " clip=" .. tostring(runtime.requestedClip or "-")
        .. " track=" .. tostring(runtime.track or "-")
        .. " bump=" .. tostring(runtime.bumpType or "-")
        .. " useless=" .. tostring(runtime.useless))
    if active
        and PNC.AnimationTrace
        and PNC.AnimationTrace.DumpBody
    then
        PNC.AnimationTrace.DumpBody(active.body)
    end
    return runtime
end

function Player.GetCatalog()
    return Catalog
end

-- Lua reloads retain the PNC namespace. Recover a preview interrupted by an
-- earlier debugger break so it cannot keep snapshot animation ownership.
if staleActiveAtLoad and Player.active == staleActiveAtLoad then
    Player.Stop("module_reload")
end

return Player
