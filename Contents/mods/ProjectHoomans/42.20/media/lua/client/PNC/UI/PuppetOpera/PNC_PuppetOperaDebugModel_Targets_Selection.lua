-- Animation target selection and preview validation.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local State = Internal.State or Model.State
local touch = Internal.touch
local actorDefinition = Internal.actorDefinition

function Model.GetAnimationTarget(catalogName)
    catalogName = catalogName == "player" and "player" or "npc"
    local requested = State.animationTargets[catalogName]
    local rows = Model.GetAnimationTargetRows(catalogName)
    if requested then
        for _, row in ipairs(rows) do
            if row.key == requested then return row end
        end
        -- A disappeared live body must not silently fall back to a different
        -- NPC or scene slot with a similar label.
        return nil
    end
    local selected = State.selectedActorID
    local definition = actorDefinition(selected)
    local wanted = catalogName == "player"
        and "local_player" or "nearby_live_npc"
    if definition and Model.GetActorKind(selected) == wanted then
        for _, row in ipairs(rows) do
            if row.actorID == tostring(selected) then return row end
        end
    end
    return nil
end

function Model.SetAnimationTarget(catalogName, key)
    catalogName = catalogName == "player" and "player" or "npc"
    key = key and tostring(key) or nil
    if not key or key == "" then
        State.animationTargets[catalogName] = nil
        touch()
        return true
    end
    local target
    for _, row in ipairs(Model.GetAnimationTargetRows(catalogName)) do
        if row.key == key then target = row break end
    end
    if not target then return false, "animation_target_not_found" end
    State.animationTargets[catalogName] = key
    if target.previewOnly == true then
        State.selectedActorID = nil
        State.pendingLiveActorID = target.liveID
        if catalogName == "npc" then
            State.selectedNPCID = target.liveID
        else
            State.selectedNPCID = nil
        end
    else
        State.selectedActorID = target.actorID
        State.pendingLiveActorID = nil
        if catalogName == "npc" then State.selectedNPCID = target.liveID end
    end
    touch()
    return true, key
end

function Model.GetPreviewTarget(catalogName)
    local target = Model.GetAnimationTarget(catalogName)
    if not target then return nil, "animation_target_required" end
    if catalogName == "npc" and (not target.body or not target.record) then
        return nil, "animation_target_npc_not_local"
    end
    return target
end

return Model
