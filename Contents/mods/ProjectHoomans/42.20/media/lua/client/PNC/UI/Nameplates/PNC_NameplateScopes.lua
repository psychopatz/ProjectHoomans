require "PNC/Knowledge/PNC_NPCIdentityPresentation"
require "PNC/UI/Nameplates/PNC_NameplatePresentation"
require "PNC/UI/Nameplates/PNC_NameplateRelationshipFeedback"

PNC = PNC or {}
PNC.NameplateScopes = PNC.NameplateScopes or {}

local Scopes = PNC.NameplateScopes
local Identity = PNC.NPCIdentityPresentation
local Presentation = PNC.NameplatePresentation
local RelationshipFeedback = PNC.NameplateRelationshipFeedback

Scopes.IDENTITY = "identity"
Scopes.DEBUG = "debug"
Scopes.CONVERSATION = "conversation"
Scopes.RELATIONSHIP_FEEDBACK = "relationship_feedback"

local function debugEnabled(settings)
    return settings and (
        settings.showAIDebug == true
            or settings.showPathDebug == true
            or settings.showCombatDebug == true
            or settings.showAnimationDebug == true
            or settings.showAnimationSceneDebug == true
            or settings.showFactionDebug == true
            or settings.showCommunityDebug == true
    ) or false
end

function Scopes.IsDebugActive(settings)
    return debugEnabled(settings)
end

function Scopes.IsLiveVisible(player, zombie)
    if not player or not zombie then return false end
    local layout = Presentation.Layout
    return math.abs(player:getZ() - zombie:getZ()) <= layout.floorTolerance
        and Presentation.Distance(player, zombie) <= layout.maxDrawDistance
end

function Scopes.IsSnapshotVisible(player, snapshot)
    if not player or not snapshot then return false end
    local layout = Presentation.Layout
    local playerX = player:getX()
    local playerY = player:getY()
    local snapshotX = tonumber(snapshot.x) or 0
    local snapshotY = tonumber(snapshot.y) or 0
    local distance = PNC.Core and PNC.Core.Distance
    local planarDistance = distance
        and distance(playerX, playerY, snapshotX, snapshotY)
        or math.sqrt(
            ((playerX - snapshotX) * (playerX - snapshotX))
                + ((playerY - snapshotY) * (playerY - snapshotY))
        )
    return math.abs(player:getZ() - (tonumber(snapshot.z) or 0)) <= layout.floorTolerance
        and planarDistance <= layout.maxDrawDistance
end

function Scopes.Build(player, snapshot, zombie, settings, speech)
    local alive = snapshot and snapshot.alive ~= false
        and snapshot.presenceState == PNC.Const.PRESENCE_LIVE
    local liveVisible = alive and Scopes.IsLiveVisible(player, zombie)
    local snapshotVisible = alive
        and Scopes.IsSnapshotVisible(player, snapshot)
    local feedbackVisible = RelationshipFeedback
        and RelationshipFeedback.IsActive
        and RelationshipFeedback.IsActive(snapshot and snapshot.id)
        or false

    return {
        [Scopes.IDENTITY] = liveVisible
            and Identity.IsNameKnown(snapshot) == true or false,
        [Scopes.DEBUG] = Scopes.IsDebugActive(settings)
            and snapshotVisible or false,
        [Scopes.CONVERSATION] = speech ~= nil and snapshotVisible or false,
        [Scopes.RELATIONSHIP_FEEDBACK] = feedbackVisible,
    }
end

function Scopes.HasRenderableScope(scopes)
    return type(scopes) == "table"
        and (
            scopes[Scopes.IDENTITY] == true
                or scopes[Scopes.DEBUG] == true
                or scopes[Scopes.CONVERSATION] == true
                or scopes[Scopes.RELATIONSHIP_FEEDBACK] == true
        )
end

return Scopes
