-- GUI members view rows.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

function Internal.AppendMembersRows(rows, snapshot, dashboard)
    local source = dashboard.source
        rows[#rows + 1] = Internal.Row("Faction", source.name, "success")
        rows[#rows + 1] = Internal.Row(
            "Member total", source.memberCount
        )
        for _, member in ipairs(snapshot.members or {}) do
            local affiliation = member.affiliation or {}
            rows[#rows + 1] = Internal.Row(
                tostring(member.name), member.npcID
            )
            rows[#rows + 1] = Internal.Row(
                "  affiliation",
                tostring(affiliation.membershipStatus)
                    .. " / " .. tostring(affiliation.role)
                    .. " / " .. tostring(affiliation.rank)
            )
        end
        if dashboard.npc then
            rows[#rows + 1] = Internal.Row(
                "Selected record revision",
                dashboard.npc.recordRevision
            )
            rows[#rows + 1] = Internal.Row(
                "Selected presence revision",
                dashboard.npc.presenceRevision
            )
        end
end

return Model

