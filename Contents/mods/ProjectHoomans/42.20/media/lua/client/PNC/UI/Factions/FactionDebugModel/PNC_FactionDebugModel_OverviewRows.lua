-- GUI overview view rows.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

require "PNC/UI/Mobile/PNC_MobileGroupDebugModel"

local MobileModel = PNC.MobileGroupDebugModel

local function appendMobileOverviewRows(rows, source)
    if not source.mobile or source.mobile.active ~= true then return end
    rows[#rows + 1] = Internal.Row(
        "Mobile lifecycle",
        MobileModel.StateText(source.mobile)
            .. " / " .. tostring(source.mobile.presence or "unknown"),
        MobileModel.State(source.mobile) == "en_route"
            and "danger" or "warning"
    )
    rows[#rows + 1] = Internal.Row(
        "Mobile destination",
        MobileModel.TargetText(source.mobile)
    )
    if source.mobile.travel then
        rows[#rows + 1] = Internal.Row(
            "Departure day",
            tostring(source.mobile.travel.departureDay or 0)
                .. " / started "
                .. tostring(source.mobile.travel.startedAt or 0)
                .. " h"
        )
    end
end

local function appendNPCOverviewRows(rows, dashboard)
    if not dashboard.npc then return end
    local affiliation = dashboard.npc.affiliation or {}
    rows[#rows + 1] = Internal.Row(
        "Selected NPC", dashboard.npc.name
    )
    rows[#rows + 1] = Internal.Row(
        "NPC affiliation",
        tostring(affiliation.membershipStatus or "none")
            .. " / "
            .. tostring(affiliation.role or "none")
            .. " / "
            .. tostring(affiliation.rank or "none")
    )
    rows[#rows + 1] = Internal.Row(
        "Tactical class",
        dashboard.npc.tacticalClass or "(none)"
    )
    rows[#rows + 1] = Internal.Row(
        "Identity authority",
        dashboard.npc.factionID or "(none)",
        dashboard.npc.factionID and "success" or "warning"
    )
    rows[#rows + 1] = Internal.Row(
        "Ownership",
        dashboard.npc.colonyOwned
            and "colony-owned" or "not colony-owned",
        dashboard.npc.colonyOwned and "success" or "textMuted"
    )
    local identityVerification = dashboard.npc.identityVerification
    if identityVerification then
        rows[#rows + 1] = Internal.Row(
            "Identity verifier",
            identityVerification.ok and "PASS" or "FAIL",
            identityVerification.ok and "success" or "danger"
        )
        rows[#rows + 1] = Internal.Row(
            "Verifier errors / warnings",
            tostring(#(identityVerification.errors or {}))
                .. " / "
                .. tostring(#(identityVerification.warnings or {}))
        )
    end
end

function Internal.AppendOverviewRows(rows, snapshot, dashboard)
    local source = dashboard.source
    local target = dashboard.target
        rows[#rows + 1] = Internal.Row(
            "Registry revision", dashboard.registryRevision
        )
        rows[#rows + 1] = Internal.Row("Source faction", source.name, "success")
        rows[#rows + 1] = Internal.Row("Source ID", source.id)
        rows[#rows + 1] = Internal.Row(
            "Archetype",
            tostring(source.archetypeLabel)
                .. " (" .. tostring(source.archetypeID) .. ")"
        )
        appendMobileOverviewRows(rows, source)
        rows[#rows + 1] = Internal.Row("Faction status", source.status)
        rows[#rows + 1] = Internal.Row(
            "Members",
            tostring(source.memberCount) .. " NPC / "
                .. tostring(source.playerMemberCount) .. " player"
        )
        rows[#rows + 1] = Internal.Row(
            "Communities",
            tostring(source.communityCount)
                .. " / active population "
                .. tostring(source.communityPopulation)
        )
        rows[#rows + 1] = Internal.Row(
            "Community names",
            #(source.communityNames or {}) > 0
                and table.concat(
                    source.communityNames,
                    ", "
                ) or "(none)"
        )
        local supplies = source.communitySupplies or {}
        rows[#rows + 1] = Internal.Row(
            "Community supplies",
            "food=" .. tostring(supplies.food or 0)
                .. " med=" .. tostring(
                    supplies.medicine or 0
                )
                .. " ammo=" .. tostring(
                    supplies.ammunition or 0
                )
                .. " tools=" .. tostring(
                    supplies.tools or 0
                )
                .. " materials=" .. tostring(
                    supplies.materials or 0
                )
        )
        rows[#rows + 1] = Internal.Row(
            "Target faction",
            target and target.name or "(select a target)",
            target and "warning" or "textMuted"
        )
        if target then
            rows[#rows + 1] = Internal.Row(
                "Diplomatic state",
                dashboard.forward.state,
                dashboard.forward.atWar and "danger"
                    or dashboard.forward.allied
                        and "success" or "text"
            )
            rows[#rows + 1] = Internal.Row(
                "Resolved intent",
                dashboard.intent.value .. " / "
                    .. dashboard.intent.reason,
                dashboard.intent.attackAllowed
                    and "danger" or "success"
            )
        end
        appendNPCOverviewRows(rows, dashboard)
        rows[#rows + 1] = Internal.Row(
            "Active episodes", dashboard.activeEpisodeCount,
            dashboard.activeEpisodeCount > 0
                and "warning" or "textMuted"
        )
        rows[#rows + 1] = Internal.Row(
            "Telemetry",
            tostring(dashboard.telemetry.count)
                .. "/" .. tostring(dashboard.telemetry.maximum),
            dashboard.telemetry.enabled
                and "success" or "textMuted"
        )
        if dashboard.validation then
            rows[#rows + 1] = Internal.Row(
                "Invariant check",
                dashboard.validation.ok and "PASS" or "FAIL",
                dashboard.validation.ok and "success" or "danger"
            )
        end
end

return Model
