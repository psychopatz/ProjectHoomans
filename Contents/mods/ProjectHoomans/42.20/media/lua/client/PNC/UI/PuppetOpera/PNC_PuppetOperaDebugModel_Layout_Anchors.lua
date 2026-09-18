-- Relative anchor validation and mutation for the Puppet Opera layout model.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

local currentDraft = Internal.currentDraft
local markChanged = Internal.markChanged

local function validateAnchorOffset(actorID, right, forward, z)
    local draft = currentDraft()
    local actorKey = tostring(actorID)
    local actor = draft and draft.actors and draft.actors[actorKey]
    local anchors = draft and draft.anchorFrame
        and draft.anchorFrame.anchors or nil
    local anchor = actor and anchors and anchors[actor.anchor]
    right = tonumber(right)
    forward = tonumber(forward)
    z = tonumber(z)
    if not anchor or not right or not forward or not z then
        return false, "anchor_not_found"
    end
    if right ~= math.floor(right) or forward ~= math.floor(forward)
        or z ~= math.floor(z)
        or right < -8 or right > 8
        or forward < -8 or forward > 8
        or z < -1 or z > 1
    then
        return false, "anchor_offset_out_of_range"
    end
    for _, other in ipairs(Model.GetGridActors()) do
        if other.id ~= actorKey
            and other.right == right
            and other.forward == forward
            and other.z == z
        then
            return false, "anchor_tile_occupied_by:" .. tostring(other.id)
        end
    end
    return true, anchor, right, forward, z
end

local function commitAnchorOffset(anchor, right, forward, z)
    if anchor.right == right and anchor.forward == forward
        and anchor.z == z
    then
        return true
    end
    anchor.right = right
    anchor.forward = forward
    anchor.z = z
    markChanged()
    return true
end

Internal.validateAnchorOffset = validateAnchorOffset
Internal.commitAnchorOffset = commitAnchorOffset

function Model.SetActorAnchorOffset(actorID, right, forward, z)
    local valid, anchorOrReason, normalizedRight, normalizedForward,
        normalizedZ = validateAnchorOffset(actorID, right, forward, z)
    if not valid then return false, anchorOrReason end
    return commitAnchorOffset(
        anchorOrReason,
        normalizedRight,
        normalizedForward,
        normalizedZ
    )
end

return Model
