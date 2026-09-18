-- Animation target rows and assignable scene-target resolution.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local State = Internal.State or Model.State
local actorDefinition = Internal.actorDefinition
local actorDiscoveryRadius = Internal.actorDiscoveryRadius
local findLiveActorRow = Internal.findLiveActorRow
local liveActorName = Internal.liveActorName
local LIVE_PLAYER_ID = Internal.LIVE_PLAYER_ID
local translatedLabel = Internal.translatedLabel

function Model.GetActorForCatalog(catalogName)
    local wanted = catalogName == "player"
        and "local_player" or "nearby_live_npc"
    local selected = State.selectedActorID
    if actorDefinition(selected)
        and Model.GetActorKind(selected) == wanted
    then
        return selected
    end
    local target = Model.GetAnimationTarget(catalogName)
    if target and target.previewOnly ~= true then
        local targetDefinition = actorDefinition(target.actorID)
        if targetDefinition and Model.GetActorKind(target.actorID) == wanted then
            return target.actorID
        end
    end
    return nil
end

-- Animation browsing has two kinds of target. A scene target can receive an
-- assignment; a live preview target only supplies a concrete local body.
-- They deliberately use different keys so a live NPC ID can never be
-- mistaken for a blueprint actor slot ID.
function Model.GetAnimationTargetRows(catalogName)
    local wanted = catalogName == "player"
        and "local_player" or "nearby_live_npc"
    local liveRows = Model.GetLiveActorRows(actorDiscoveryRadius())
    local sceneRows = Model.GetActorRows(Model.GetSnapshot())
    local result = {}
    local bound = {}
    for _, scene in ipairs(sceneRows) do
        if scene.kind == wanted then
            local liveID = scene.liveID
            if not liveID
                and tostring(scene.id) == tostring(State.selectedActorID or "")
                and State.pendingLiveActorID
            then
                local pending = findLiveActorRow(
                    State.pendingLiveActorID,
                    liveRows
                )
                if pending and pending.kind == wanted then
                    liveID = pending.id
                end
            end
            local live = findLiveActorRow(liveID, liveRows)
            local fallbackName = scene.liveName or (
                liveID and ("Unavailable [" .. tostring(liveID) .. "]")
                or "unbound")
            local name = liveActorName(live, fallbackName)
            result[#result + 1] = {
                key = "scene:" .. tostring(scene.id),
                actorID = tostring(scene.id),
                liveID = liveID,
                name = name,
                label = tostring(scene.label) .. " -> " .. name,
                previewOnly = false,
                body = live and live.body or nil,
                record = live and live.record or nil,
            }
            if liveID then bound[tostring(liveID)] = true end
        end
    end

    -- Keep the local player available for isolated player-animation preview,
    -- even when the draft has no player slot. If a slot exists, the explicit
    -- scene row above remains the assignable target.
    if catalogName == "player" then
        local player = findLiveActorRow(LIVE_PLAYER_ID, liveRows)
        if player then
            result[#result + 1] = {
                key = "live:" .. LIVE_PLAYER_ID,
                liveID = LIVE_PLAYER_ID,
                name = liveActorName(player, translatedLabel(
                    "UI_PNC_PuppetOpera_LocalPlayer", "Local player")),
                label = liveActorName(player, translatedLabel(
                    "UI_PNC_PuppetOpera_LocalPlayer", "Local player"))
                    .. " (preview only)",
                previewOnly = true,
                body = player.body,
                record = player.record,
            }
        end
    else
        -- Unbound live NPCs are preview targets. Bound NPCs are represented by
        -- their named scene rows, avoiding an ambiguous duplicate entry.
        for _, live in ipairs(liveRows) do
            if live.kind == wanted and not bound[tostring(live.id)] then
                result[#result + 1] = {
                    key = "live:" .. tostring(live.id),
                    liveID = tostring(live.id),
                    name = liveActorName(live, live.id),
                    label = liveActorName(live, live.id)
                        .. " [" .. tostring(live.id) .. "] (preview only)",
                    previewOnly = true,
                    body = live.body,
                    record = live.record,
                }
            end
        end
    end
    return result
end

return Model
