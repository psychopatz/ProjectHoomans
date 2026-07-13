require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.NPCMonitorSupport = PNC.NPCMonitorSupport or {}

local Support = PNC.NPCMonitorSupport

function Support.Tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == "" or value == key then return fallback end
    return value
end

function Support.HasProblem(item)
    if not item then return false end
    if item.lastError then return true end
    if item.presenceState == "live" then return item.bodyState ~= "bound" end
    if item.bodyState == "duplicate" or item.bodyState == "stale_cleaned" then return true end
    if item.lastCleanupState == "duplicate" or item.lastCleanupState == "stale_cleaned" then return true end
    return item.presenceState == "corpse"
        and item.corpseState ~= "inert_loaded"
        and item.corpseState ~= "unloaded"
end

function Support.MatchesFilter(item, filter)
    if filter == "Live" then return item.presenceState == "live" end
    if filter == "Abstract" then return item.presenceState == "abstract" end
    if filter == "Corpse" then return item.presenceState == "corpse" end
    if filter == "Problems" then return Support.HasProblem(item) end
    return true
end

function Support.FindBody(item)
    local sync = PNC.ClientPresenceSync
    if not item or not sync then return nil end
    local body
    if item.bodyLease and sync.BodyByLease then
        body = sync.BodyByLease[tostring(item.id) .. ":" .. tostring(item.bodyLease)]
    end
    return body or (sync.BodyByID and sync.BodyByID[tostring(item.id)] or nil)
end

function Support.SetOutlined(body, enabled)
    if not body then return end
    if body.setOutlineHighlightCol then
        pcall(body.setOutlineHighlightCol, body, 0.15, 0.85, 1, 1)
    end
    if body.setOutlineHighlight then
        pcall(body.setOutlineHighlight, body, enabled == true)
    end
end

function Support.PresenceColor(item)
    if Support.HasProblem(item) then return "danger" end
    if item.presenceState == "live" then return "success" end
    if item.presenceState == "corpse" then return "warning" end
    return "accent"
end

local function addDetail(list, label, value, tone)
    list:addItem(tostring(label), {
        label = tostring(label),
        value = tostring(value == nil and "-" or value),
        tone = tone,
    })
end

function Support.PopulateDetails(list, item, authorized, audit)
    list:clear()
    if not authorized then
        addDetail(list, "Status", Support.Tr("UI_PNC_MonitorUnauthorized", "Debug roster unavailable or not authorized."), "danger")
        return
    end
    if not item then
        addDetail(list, "Selection", Support.Tr("UI_PNC_MonitorSelectNPC", "Select an NPC to inspect its lifecycle."), "textMuted")
        return
    end

    audit = audit or {}
    local bite = item.bite or {}
    addDetail(list, "Name", item.name)
    addDetail(list, "UUID", item.id)
    addDetail(list, "Faction", item.faction)
    addDetail(list, "Presence", tostring(item.presenceState or "-") .. " / " .. tostring(item.phase or "-"), Support.PresenceColor(item))
    addDetail(list, "Body", tostring(item.bodyState or "-") .. " / corpse " .. tostring(item.corpseState or "-"))
    addDetail(list, "Last cleanup", tostring(item.lastCleanupState or "-") .. " / " .. tostring(item.lastCleanupReason or "-"))
    addDetail(list, "Lease", item.bodyLease)
    addDetail(list, "Online / outfit", tostring(item.liveBodyOnlineID or "-") .. " / " .. tostring(item.liveBodyInstanceID or "-"))
    addDetail(list, "Position", string.format("%.2f, %.2f, %.0f", tonumber(item.x) or 0, tonumber(item.y) or 0, tonumber(item.z) or 0))
    addDetail(list, "AI", item.activeBehavior or item.activeJob or "Idle")
    addDetail(list, "Health", tostring(item.healthState or "-") .. "  " .. tostring(item.hpCurrent or 0) .. "/" .. tostring(item.hpMax or 0))
    addDetail(list, "Target", item.targetKind or "none")
    addDetail(list, "Combat block", item.combatBlockReason)
    addDetail(list, "Body action", item.bodyActionState)
    addDetail(list, "Last transition", item.lastReason)
    addDetail(list, "Error", item.lastError, item.lastError and "danger" or nil)
    addDetail(list, "Bite", tostring(bite.phase or "-") .. " / " .. tostring(bite.actionState or "-"))
    addDetail(list, "Bite reason", bite.reason)
    addDetail(list, "Bite timing", tostring(bite.startedAt or "-") .. " / " .. tostring(bite.impactAt or "-") .. " / " .. tostring(bite.releaseAt or "-"))
    addDetail(list, "Last audit", "scanned " .. tostring(audit.scanned or 0)
        .. "  removed " .. tostring(audit.removed or 0)
        .. "  rebound " .. tostring(audit.rebound or 0)
        .. "  duplicates " .. tostring(audit.duplicates or 0))
end

return Support
