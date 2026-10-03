local Model = require "PNC/UI/Relationships/PNC_RelationshipDebugModel_Core"
local Internal = Model.Internal or {}
local row = Internal.row
local number = Internal.number
local signed = Internal.signed
local mapValue = Internal.mapValue
local appendFaction = Internal.appendFaction
local signedBand = Internal.signedBand
local grievanceBand = Internal.grievanceBand
local personalityBand = Internal.personalityBand

local function appendIdentityRows(rows, snapshot, observer, target)
    rows[#rows + 1] = row("Observer", observer.label)
    rows[#rows + 1] = row("Observer key", observer.key)
    rows[#rows + 1] = row("Target", target.label)
    rows[#rows + 1] = row("Target key", target.key)
    appendFaction(rows, "Observer faction", observer.faction)
    appendFaction(rows, "Target faction", target.faction)
    local factionRelation = snapshot.factionRelation
    if factionRelation then
        rows[#rows + 1] = row(
            "Faction relation",
            tostring(factionRelation.state)
                .. " / standing "
                .. tostring(factionRelation.standing)
                .. " / trust "
                .. tostring(factionRelation.trust),
            factionRelation.atWar and "danger" or "text"
        )
        rows[#rows + 1] = row(
            "Faction fear / grievance",
            tostring(factionRelation.fear)
                .. " / " .. tostring(factionRelation.grievance)
        )
        rows[#rows + 1] = row(
            "Faction metric bands",
            "standing=" .. signedBand(factionRelation.standing)
                .. " / trust=" .. signedBand(factionRelation.trust)
                .. " / grievance="
                .. grievanceBand(factionRelation.grievance)
        )
        rows[#rows + 1] = row(
            "Faction treaty",
            "war=" .. tostring(factionRelation.atWar)
                .. " allied=" .. tostring(factionRelation.allied)
                .. " truceUntil="
                .. tostring(factionRelation.truceUntil)
        )
    end
    if snapshot.factionIntent then
        rows[#rows + 1] = row(
            "Faction intent",
            tostring(snapshot.factionIntent.intent)
                .. " / " .. tostring(snapshot.factionIntent.reason)
                .. " / attack="
                .. tostring(snapshot.factionIntent.attackAllowed),
            snapshot.factionIntent.attackAllowed
                and "danger" or "success"
        )
    end
    if snapshot.playerPacification then
        rows[#rows + 1] = row(
            "Player pacification",
            tostring(snapshot.playerPacification.reason)
                .. " / until "
                .. number(
                    snapshot.playerPacification
                        .untilWorldAgeHours,
                    3
                ) .. " h",
            "success"
        )
    elseif target.kind == "player" then
        rows[#rows + 1] = row(
            "Player pacification",
            "inactive",
            "textMuted"
        )
    end
    if snapshot.pacificationAction then
        rows[#rows + 1] = row(
            "Pacification action",
            tostring(snapshot.pacificationAction.reason),
            snapshot.pacificationAction.ok
                and "success" or "warning"
        )
    end
end

local function appendGraphRows(rows, snapshot, graphEvaluation)
    graphEvaluation = graphEvaluation
        or Model.BuildGraph(snapshot, "inspect")
    if graphEvaluation then
        rows[#rows + 1] = row(
            "Derived attitude",
            tostring(graphEvaluation.attitude)
        )
        rows[#rows + 1] = row(
            "Selected interaction",
            tostring(graphEvaluation.requirement.label)
        )
        if graphEvaluation.requirement.enabled then
            rows[#rows + 1] = row(
                "Interaction score",
                number(graphEvaluation.finalScore)
                    .. " / threshold "
                    .. number(graphEvaluation.threshold)
            )
            rows[#rows + 1] = row(
                "Inside green region",
                tostring(
                    graphEvaluation.insideSuccessRegion
                ),
                graphEvaluation.insideSuccessRegion
                    and "success" or "warning"
            )
            rows[#rows + 1] = row(
                "Score components",
                "base=" .. number(graphEvaluation.baseScore)
                    .. " context="
                    .. signed(graphEvaluation.contextBonus)
            )
        end
    end
    return graphEvaluation
end

local function appendRelationshipStateRows(
    rows, snapshot, observer, relationship, conversationDelta
)
    rows[#rows + 1] = row(
        "Snapshot world age",
        number(snapshot.generatedAt, 3) .. " h"
    )
    rows[#rows + 1] = row("Stored record",
        relationship.exists and "yes" or "no (preview defaults)",
        relationship.exists and "success" or "warning")
    rows[#rows + 1] = row("Approval", number(relationship.approval))
    rows[#rows + 1] = row("Respect", number(relationship.respect))
    rows[#rows + 1] = row("Familiarity", number(relationship.familiarity))
    if type(conversationDelta) == "table"
        and tostring(conversationDelta.npcID or "") == tostring(
            observer.npcID or observer.id or observer.key or ""
        )
    then
        local delta = conversationDelta.delta or {}
        rows[#rows + 1] = row(
            "Last conversation",
            tostring(conversationDelta.source or "conversation")
                .. " / " .. tostring(conversationDelta.blockID or "gift"),
            "success"
        )
        rows[#rows + 1] = row(
            "  changed",
            "Approval " .. signed(delta.approval)
                .. " / Respect " .. signed(delta.respect)
                .. " / Familiarity " .. signed(delta.familiarity),
            "success"
        )
        if conversationDelta.effects then
            rows[#rows + 1] = row(
                "  effects",
                mapValue(conversationDelta.effects)
            )
        end
        if conversationDelta.itemTypes then
            rows[#rows + 1] = row(
                "  gift items",
                table.concat(conversationDelta.itemTypes, ", ")
            )
        end
    end
    rows[#rows + 1] = row("State", relationship.state)
    rows[#rows + 1] = row("Previous state", relationship.previousState)
    rows[#rows + 1] = row(
        "Baseline approval",
        number(relationship.baselineApproval)
    )
    rows[#rows + 1] = row(
        "Baseline respect",
        number(relationship.baselineRespect)
    )
    rows[#rows + 1] = row("Morale", number(observer.morale))
    rows[#rows + 1] = row(
        "Morale baseline",
        number(observer.moraleBaseline)
    )
    rows[#rows + 1] = row(
        "Revisions",
        string.format(
            "relationship %s / social %s / record %s / presence %s",
            relationship.revision or 0,
            observer.socialRevision or 0,
            observer.recordRevision or 0,
            observer.presenceRevision or 0
        )
    )
    rows[#rows + 1] = row(
        "Last interaction",
        number(relationship.lastInteractionAt, 3) .. " h"
    )
    rows[#rows + 1] = row(
        "Last evaluated",
        number(relationship.lastEvaluatedAt, 3) .. " h"
    )
end

local function appendPersonalityRows(rows, observer, profile)
    rows[#rows + 1] = row(
        "Personality",
        tostring(profile.socialStyle or "unknown")
    )
    rows[#rows + 1] = row("  orientation", profile.orientation)
    rows[#rows + 1] = row(
        "  food preference", profile.foodPreference
    )
    rows[#rows + 1] = row("  romance style", profile.romanceStyle)
    rows[#rows + 1] = row("  jealousy style", profile.jealousyStyle)
    rows[#rows + 1] = row("  social style", profile.socialStyle)
    rows[#rows + 1] = row(
        "  identity seed", observer.identitySeed or "(unavailable)"
    )
    rows[#rows + 1] = row(
        "  archetype", observer.archetypeID or "(unavailable)"
    )
    for _, dimension in ipairs({
        "compassion", "sociability", "forgiveness", "bravery",
        "materialism", "aggression", "loyalty",
    }) do
        rows[#rows + 1] = row(
            "  " .. dimension,
            number(profile[dimension])
                .. " (" .. personalityBand(profile[dimension]) .. ")"
        )
    end
end


Internal.appendIdentityRows = appendIdentityRows
Internal.appendGraphRows = appendGraphRows
Internal.appendRelationshipStateRows = appendRelationshipStateRows
Internal.appendPersonalityRows = appendPersonalityRows

return Model
