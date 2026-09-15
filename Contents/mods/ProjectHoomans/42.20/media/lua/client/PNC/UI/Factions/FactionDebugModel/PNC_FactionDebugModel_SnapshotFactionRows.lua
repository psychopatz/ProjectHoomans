-- Snapshot rows for registry identity and selected faction state.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal
require "PNC/UI/Mobile/PNC_MobileGroupDebugModel"

local MobileModel = PNC.MobileGroupDebugModel

local function appendFactionIdentityRows(rows, faction)
    rows[#rows + 1] = Internal.Row("Faction", faction.name, "success")
    rows[#rows + 1] = Internal.Row("Faction ID", faction.id)
    rows[#rows + 1] = Internal.Row(
        "Archetype",
        tostring(faction.archetypeLabel)
            .. " (" .. tostring(faction.archetypeID) .. ")"
    )
    rows[#rows + 1] = Internal.Row("Status", faction.status)
    rows[#rows + 1] = Internal.Row(
        "Leader", faction.leaderNPCID or "(none)"
    )
    rows[#rows + 1] = Internal.Row(
        "Player owner",
        faction.ownerPlayerKey or "(none)"
    )
    rows[#rows + 1] = Internal.Row(
        "Members",
        tostring(faction.memberCount or 0)
            .. " NPC / "
            .. tostring(faction.playerMemberCount or 0)
            .. " player"
    )
    rows[#rows + 1] = Internal.Row("Revision", faction.revision)
    rows[#rows + 1] = Internal.Row(
        "Emblem",
        Internal.EmblemText(faction.emblem)
    )
    rows[#rows + 1] = Internal.Row(
        "Created", tostring(faction.createdAt) .. " h"
    )
    rows[#rows + 1] = Internal.Row(
        "Archived", tostring(faction.archivedAt) .. " h"
    )
    rows[#rows + 1] = Internal.Row(
        "Tags", Internal.EnabledKeys(faction.tags)
    )
end

local function appendMobileFactionRows(rows, faction)
    local mobile = faction.mobile
    if not mobile or mobile.active ~= true then return end
    local site = mobile.site or {}
    local home = site.home or {}
    local ambient = mobile.ambient or {}
    local target = mobile.controlMode == "strategic"
        and mobile.strategicTarget or ambient.target
    rows[#rows + 1] = Internal.Row(
        "Group type", "mobile / "
            .. tostring(faction.archetypeID)
            .. " / control="
            .. tostring(mobile.controlMode or "ambient")
            .. " / path="
            .. tostring(mobile.pathMode or "random"),
        "warning"
    )
    rows[#rows + 1] = Internal.Row(
        "Mobile state",
        MobileModel.StateText(mobile),
        MobileModel.State(mobile) == "en_route"
            and "danger" or "warning"
    )
    rows[#rows + 1] = Internal.Row(
        "Mobile objective",
        mobile.controlMode == "strategic"
            and ("player base / "
                .. tostring(target and target.baseID or "pending"))
            or (tostring(ambient.phase or "pending")
                .. " / "
                .. tostring(ambient.objective or "pending")),
        mobile.controlMode == "strategic"
            and "danger" or "warning"
    )
    if target or mobile.travel then
        rows[#rows + 1] = Internal.Row(
            "Mobile target",
            MobileModel.TargetText(mobile)
        )
    end
    if mobile.travel then
        rows[#rows + 1] = Internal.Row(
            "Settlement travel",
            "started " .. tostring(mobile.travel.startedAt or 0)
                .. " h / day "
                .. tostring(mobile.travel.departureDay or 0),
            "danger"
        )
    end
    rows[#rows + 1] = Internal.Row(
        "Last departure",
        tostring(mobile.lastDepartureAt or -1) .. " h"
    )
    rows[#rows + 1] = Internal.Row(
        "Mobile staging site",
        tostring(site.id or "unknown")
            .. " @ " .. string.format(
                "%.1f, %.1f, %.0f",
                tonumber(home.x) or 0,
                tonumber(home.y) or 0,
                tonumber(home.z) or 0
            )
    )
    rows[#rows + 1] = Internal.Row(
        "Next relocation",
        tostring(mobile.nextMoveAt or 0)
            .. " h / count "
            .. tostring(mobile.relocationCount or 0)
    )
end

local function appendPolicyRows(rows, faction)
    local policy = faction.policy or {}
    rows[#rows + 1] = Internal.Row(
        "Policy",
        tostring(policy.outsiderPolicy or "neutral")
            .. " / war " .. tostring(policy.warThreshold)
            .. " / peace " .. tostring(policy.peaceThreshold)
    )
    rows[#rows + 1] = Internal.Row(
        "Policy dimensions",
        string.format(
            "agg %.2f / ret %.2f / caution %.2f / hosp %.2f / opp %.2f",
            tonumber(policy.aggression) or 0,
            tonumber(policy.retaliation) or 0,
            tonumber(policy.caution) or 0,
            tonumber(policy.hospitality) or 0,
            tonumber(policy.opportunism) or 0
        )
    )
end

function Internal.AppendSnapshotFactionRows(rows, snapshot)
    rows[#rows + 1] = Internal.Row(
        "Registry",
        "schema " .. tostring(snapshot.registrySchemaVersion)
            .. " / revision "
            .. tostring(snapshot.registryRevision)
    )
    rows[#rows + 1] = Internal.Row(
        "Faction count", #(snapshot.factions or {})
    )
    rows[#rows + 1] = Internal.Row(
        "Your faction",
        snapshot.currentPlayerFactionID or "(none)",
        snapshot.currentPlayerFactionID
            and "success" or "warning"
    )
    if snapshot.currentPlayerDiplomacyFactionID
        and snapshot.currentPlayerDiplomacyFactionID
            ~= snapshot.currentPlayerFactionID
    then
        rows[#rows + 1] = Internal.Row(
            "Diplomacy identity",
            snapshot.currentPlayerDiplomacyFactionID,
            "textMuted"
        )
    end
    local faction = snapshot.selectedFaction
    if not faction then
        rows[#rows + 1] = Internal.Row(
            "Selection",
            "Create or select a faction",
            "textMuted"
        )
        return
    end
    appendFactionIdentityRows(rows, faction)
    appendMobileFactionRows(rows, faction)
    appendPolicyRows(rows, faction)
end

return Model
