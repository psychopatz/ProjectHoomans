-- Unified low-level NPC animation playback driver shared by AnimationScenes,
-- AnimationPacks, and Choreography.
--
-- Owns a single per-body ownership token (`PNC_AnimDriverOwner`) alongside
-- BumpType and AnimVars playback so single-actor AI scenes and multi-actor
-- Choreography choreography share one engine contract and never stomp each other.
PNC = PNC or {}
PNC.AnimationDriver = PNC.AnimationDriver or {}

local Driver = PNC.AnimationDriver

Driver.VERSION = 1

local OWNER_KEY = "PNC_AnimDriverOwner"
local ROUTE_KEY = "PNC_AnimDriverRoute"
local BUMP_KEY = "PNC_AnimDriverBump"

local function modDataOf(body)
    return body and type(body.getModData) == "function"
        and body:getModData() or nil
end

local function animService()
    return PNC.Animation
end

local function animVarAdapter()
    return PNC.Choreography and PNC.Choreography.AnimVarAdapter or nil
end

local function nowMs()
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function bumpFinished(body)
    if body and type(body.getVariableBoolean) == "function"
        and body:getVariableBoolean("BumpAnimFinished") == true
    then
        return true
    end
    if body and type(body.getVariableString) == "function" then
        local value = string.lower(tostring(
            body:getVariableString("BumpAnimFinished") or ""
        ))
        return value == "true" or value == "1"
    end
    return false
end

function Driver.GetOwner(body)
    local modData = modDataOf(body)
    return modData and modData[OWNER_KEY] or nil
end

function Driver.IsOwnedBy(body, ownerToken)
    if not ownerToken or tostring(ownerToken) == "" then return false end
    local modData = modDataOf(body)
    if not modData or tostring(modData[OWNER_KEY] or "") ~= tostring(ownerToken) then
        return false
    end
    if modData[ROUTE_KEY] == "anim_vars" then return true end
    local expected = tostring(modData[BUMP_KEY] or "")
    if expected == "" then return true end
    local requested = modData.PNC_BumpRequestedType
    if requested == nil then return true end
    return tostring(requested) == expected
end

-- Resolves a sceneId from AnimationScenes / AnimationPacks if the caller
-- passed a scene reference instead of a raw bumpType.
function Driver.ResolveSceneTrack(sceneId)
    sceneId = tostring(sceneId or "")
    if sceneId == "" then return nil end
    local scenes = PNC.AnimationScenes
    local def = scenes and type(scenes.Get) == "function"
        and scenes.Get(sceneId) or nil
    if type(def) ~= "table" then return nil end
    local step = type(def.steps) == "table" and def.steps[1] or nil
    return {
        route = "bump",
        bump = (step and step.bump) or def.bump,
        props = (step and step.props) or def.props,
        durationMs = (step and step.durationMs) or def.durationMs,
        sceneId = def.id,
        stepId = step and step.id or nil,
    }
end

function Driver.Start(body, record, request)
    if not body or not record or type(request) ~= "table" then
        return false, "anim_driver_arguments_invalid"
    end
    local ownerToken = tostring(request.ownerToken or "")
    local modData = modDataOf(body)
    if ownerToken ~= "" and modData and modData[OWNER_KEY] ~= nil
        and tostring(modData[OWNER_KEY]) ~= ownerToken
        and request.forceTakeover ~= true
    then
        return false, "anim_driver_owned_by_other"
    end

    local route = tostring(request.route or "bump")
    if route == "anim_vars" then
        local vars = animVarAdapter()
        if not vars or type(vars.Apply) ~= "function" then
            return false, "anim_vars_adapter_unavailable"
        end
        local ok, reason = vars.Apply(body, request.track or request, {
            phase = request.phase or "play",
            moving = request.moving == true,
            progress = tonumber(request.progress) or 0,
        })
        if not ok then return false, reason or "anim_vars_apply_failed" end
        if modData and ownerToken ~= "" then
            modData[OWNER_KEY] = ownerToken
            modData[ROUTE_KEY] = "anim_vars"
            modData[BUMP_KEY] = nil
        end
        return true, "anim_vars_started"
    end

    local bump = tostring(request.bump or request.bumpType or "")
    local resolvedProps = request.props
    if bump == "" and request.sceneId then
        local sceneTrack = Driver.ResolveSceneTrack(request.sceneId)
        if sceneTrack then
            bump = tostring(sceneTrack.bump or "")
            resolvedProps = resolvedProps or sceneTrack.props
        end
    end
    if bump == "" then return false, "anim_driver_bump_missing" end

    local anim = animService()
    if not anim or type(anim.PlayBump) ~= "function" then
        return false, "anim_driver_service_unavailable"
    end
    local accepted, reason = anim.PlayBump(body, record, bump, {
        sceneId = request.sceneId,
        sceneRevision = request.sceneRevision,
        playbackRevision = request.playbackRevision,
        leaseUntil = request.leaseUntil,
        keepManagedUseless = request.keepManagedUseless,
        nonCombat = request.nonCombat,
    })
    if accepted == false then
        return false, reason or "anim_driver_bump_rejected"
    end
    if modData and ownerToken ~= "" then
        modData[OWNER_KEY] = ownerToken
        modData[ROUTE_KEY] = "bump"
        modData[BUMP_KEY] = anim.ResolveBumpType
            and anim.ResolveBumpType(bump) or bump
    end
    return true, "bump_started", resolvedProps
end

function Driver.Maintain(body, record, ownerToken, spec)
    if not body or type(spec) ~= "table" then
        return false, "anim_driver_arguments_invalid"
    end
    if ownerToken and not Driver.IsOwnedBy(body, ownerToken) then
        return false, "anim_driver_ownership_lost"
    end
    if spec.route == "anim_vars" then
        return true, "anim_vars_maintained"
    end
    local bump = tostring(spec.bump or spec.bumpType or "")
    if bump == "" then return false, "anim_driver_bump_missing" end
    local anim = animService()
    if not anim or type(anim.MaintainBump) ~= "function" then
        return false, "anim_driver_service_unavailable"
    end
    return anim.MaintainBump(body, record, bump, spec.leaseUntil, spec.options)
end

function Driver.Observe(body, ownerToken, spec)
    spec = type(spec) == "table" and spec or {}
    if ownerToken and not Driver.IsOwnedBy(body, ownerToken) then
        return false, "anim_driver_ownership_lost"
    end
    local modData = modDataOf(body)
    local startedAt = tonumber(spec.startedAt) or 0
    local current = tonumber(spec.now) or nowMs()
    local duration = tonumber(spec.durationMs) or 900
    if modData and modData[ROUTE_KEY] == "anim_vars" then
        local vars = animVarAdapter()
        if vars and type(vars.UpdateProgress) == "function" then
            local progress = duration > 0
                and ((current - startedAt) / duration) % 1 or 0
            vars.UpdateProgress(body, progress, spec.isMoving == true)
        end
        if current - startedAt >= duration then
            return true, "finished"
        end
        return true, "playing"
    end
    local anim = animService()
    local active = anim and type(anim.IsBumpActionActive) == "function"
        and anim.IsBumpActionActive(body, current) or false
    if active then return true, "playing" end
    if bumpFinished(body) then return true, "finished" end
    if current - startedAt >= duration then return true, "finished" end
    return false, "anim_driver_interrupted"
end

function Driver.Stop(body, record, ownerToken, options)
    options = type(options) == "table" and options or {}
    local modData = modDataOf(body)
    if ownerToken and modData and modData[OWNER_KEY] ~= nil
        and tostring(modData[OWNER_KEY]) ~= tostring(ownerToken)
        and options.force ~= true
    then
        return false, "anim_driver_owned_by_other"
    end
    local route = modData and modData[ROUTE_KEY] or options.route
    if route == "anim_vars" then
        local vars = animVarAdapter()
        if vars and type(vars.Clear) == "function" then
            pcall(vars.Clear, body)
        end
    else
        local anim = animService()
        if anim and type(anim.FinishBump) == "function" then
            pcall(anim.FinishBump, body, options.immediate ~= false)
        end
    end
    if modData then
        modData[OWNER_KEY] = nil
        modData[ROUTE_KEY] = nil
        modData[BUMP_KEY] = nil
    end
    return true, "anim_driver_stopped"
end

return Driver
