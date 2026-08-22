local T = require "tests/support/test"

local ROOT =
    T.path("ProjectHoomans", "client", "PNC/")
local MODEL = ROOT .. "UI/Factions/PNC_FactionDebugModel.lua"
local OVERLAY = ROOT .. "UI/Factions/PNC_FactionDebugOverlay.lua"

ISUIElement = {}
function ISUIElement:derive()
    local class = {}
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end
function ISUIElement:initialise() end
function ISUIElement:render() end
function ISUIElement:new(x, y, width, height)
    return setmetatable({
        x = x,
        y = y,
        width = width,
        height = height,
        visible = true,
    }, { __index = self })
end
function ISUIElement:setCapture() end
function ISUIElement:addToUIManager() self.added = true end
function ISUIElement:removeFromUIManager() self.added = false end
function ISUIElement:setVisible(value) self.visible = value end
function ISUIElement:getIsVisible() return self.visible end
function ISUIElement:bringToTop() end
function ISUIElement:setX(value) self.x = value end
function ISUIElement:setY(value) self.y = value end
function ISUIElement:drawRect() end
function ISUIElement:drawRectBorder() end
function ISUIElement:drawText() end
function ISUIElement:drawTextRight() end
function ISUIElement:drawTextCentre() end

package.preload["ISUI/ISUIElement"] =
    function() return ISUIElement end

local factionOverlayEnabled = false

PNC = {
    Core = {
        Now = function() return 5000 end,
    },
    Network = {
        ClientState = {
            factionDebugAuthorized = true,
            factionDebug = {
                registryRevision = 9,
                generatedAt = 24,
                selectedFactionID = "faction_source",
                selectedTargetFactionID = "faction_target",
                selectedNPCID = "npc_one",
                factions = {
                    {
                        id = "faction_source",
                        name = "Source",
                    },
                    {
                        id = "faction_target",
                        name = "Target",
                    },
                },
                selectedFaction = {
                    id = "faction_source",
                    name = "Source",
                    archetypeID = "looter",
                    archetypeLabel = "Looter Gang",
                    status = "active",
                    revision = 3,
                    memberCount = 1,
                    playerMemberCount = 0,
                },
                selectedTargetFaction = {
                    id = "faction_target",
                    name = "Target",
                    archetypeID = "settler",
                    archetypeLabel = "Settlement",
                    status = "active",
                    revision = 2,
                },
                relationForward = {
                    state = "war",
                    previousState = "hostile",
                    standing = -60,
                    trust = -40,
                    fear = 20,
                    grievance = 80,
                    atWar = true,
                    revision = 4,
                    incidents = {},
                },
                relationReverse = {
                    state = "war",
                    atWar = true,
                    incidents = {},
                },
                intentPreview = {
                    intent = "attack",
                    reason = "factions_at_war",
                    attackAllowed = true,
                    pursueAllowed = true,
                    commandable = false,
                },
                intentTrace = {
                    selectedRule = "at_war",
                    fallback = false,
                },
                roster = {
                    {
                        id = "npc_one",
                        name = "Raider",
                        recordRevision = 8,
                        presenceRevision = 2,
                        affiliation = {
                            factionID = "faction_source",
                            role = "raider",
                            rank = "member",
                        },
                    },
                },
                npcDiagnostics = {
                    {
                        npcID = "npc_one",
                        factionID = "faction_source",
                        factionName = "Source",
                        archetypeID = "looter",
                        intent = "attack",
                        intentReason = "factions_at_war",
                        attackAllowed = true,
                        atWarWithPlayer = true,
                        relationship = {
                            exists = true,
                            approval = 12,
                            respect = 8,
                            familiarity = 6,
                            state = "neutral",
                            previousState = "unknown",
                            revision = 2,
                        },
                        morale = 3,
                        relationshipChanges = {
                            {
                                sequence = 4,
                                targetKey =
                                    "player:Patrick:char_player",
                                kind = "social_event",
                                eventID = "social:test:1",
                                memoryType = "treated_wound",
                                knowledgeSource = "experienced",
                                approvalDelta = 4,
                                respectDelta = 2,
                                familiarityDelta = 1,
                                moraleDelta = 1,
                                stateBefore = "unknown",
                                stateAfter = "neutral",
                            },
                        },
                    },
                },
                activeAggregationEpisodes = {},
                reconciliationJobs = {},
                telemetry = {
                    enabled = true,
                    count = 1,
                    maximum = 128,
                    entries = {
                        {
                            sequence = 1,
                            category = "intent",
                            result = "attack",
                        },
                    },
                },
                validationResult = {
                    ok = true,
                    checks = 5,
                    errors = {},
                    warnings = {},
                },
            },
        },
    },
    Nameplates = {
        IsFactionDebugEnabled = function()
            return factionOverlayEnabled
        end,
        SetFactionDebugEnabled = function(value)
            factionOverlayEnabled = value == true
            return factionOverlayEnabled
        end,
        ToggleFactionDebug = function()
            factionOverlayEnabled = not factionOverlayEnabled
            return factionOverlayEnabled
        end,
    },
}

local requests = {}
PNC.Client = {
    CanUseDebug = function() return true end,
    RequestFactionDebug = function(sourceID, npcID, targetID)
        requests[#requests + 1] = {
            sourceID = sourceID,
            npcID = npcID,
            targetID = targetID,
        }
        return true
    end,
}

Events = {
    OnResetLua = {
        Add = function() end,
    },
}
UIFont = {
    Small = "Small",
    Medium = "Medium",
}
getCore = function()
    return {
        getScreenWidth = function() return 1280 end,
    }
end
getText = function(key) return key end

T.load(MODEL)
package.preload["PNC/UI/Factions/PNC_FactionDebugModel"] =
    function() return PNC.FactionDebugModel end
T.load(OVERLAY)

T.equal(
    PNC.FactionDebugOverlay.IsVisible(),
    false,
    "overlay defaults closed"
)
T.equal(
    PNC.FactionDebugOverlay.Toggle(),
    true,
    "overlay opens"
)
T.equal(
    PNC.FactionDebugOverlay.IsVisible(),
    true,
    "overlay visible"
)
T.equal(requests[1].sourceID, "faction_source",
    "selected source requested")
T.equal(requests[1].targetID, "faction_target",
    "selected target requested")
T.equal(requests[1].npcID, "npc_one",
    "selected NPC requested")

local dashboard = PNC.FactionDebugOverlay.NewDashboard(
    0, 0, 430, 492
)
dashboard:prerender()
dashboard:render()
T.equal(dashboard.embedded, true,
    "dashboard is embedded inspector presentation")
T.equal(
    PNC.FactionDebugOverlay.GetNPCDiagnostic("npc_one")
        .attackAllowed,
    true,
    "world overlay indexes authoritative NPC diagnostic"
)
local relationshipChange
local relationshipChangeCount
relationshipChange,
relationshipChangeCount =
    PNC.FactionDebugOverlay.GetRelationshipChange("npc_one")
T.equal(relationshipChange.memoryType, "treated_wound",
    "world overlay exposes social change type")
T.equal(relationshipChange.approvalDelta, 4,
    "world overlay exposes social score delta")
T.equal(relationshipChangeCount, 1,
    "world overlay counts unseen social changes")

PNC.FactionDebugOverlay.SetSelection(
    "faction_source",
    "faction_target",
    "npc_one"
)
PNC.FactionDebugOverlay.Update()
T.equal(#requests >= 2, true, "selection refresh requested")

T.equal(
    PNC.FactionDebugOverlay.Toggle(),
    false,
    "overlay closes"
)
T.equal(
    PNC.FactionDebugOverlay.IsVisible(),
    false,
    "overlay no longer visible"
)
T.finish("pnc_faction_debug_overlay_smoke")

T.finish("pnc_faction_debug_overlay_smoke")
