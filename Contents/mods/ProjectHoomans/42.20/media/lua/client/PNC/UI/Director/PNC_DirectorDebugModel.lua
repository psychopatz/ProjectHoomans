PNC = PNC or {}
PNC.DirectorDebugModel = PNC.DirectorDebugModel or {}

local Model = PNC.DirectorDebugModel

local function row(label, value, tone)
    return { label = tostring(label or ""),
        value = tostring(value == nil and "" or value), tone = tone }
end

function Model.GroupItems(snapshot)
    local output = {}
    for _, group in ipairs(snapshot and snapshot.groups or {}) do
        output[#output + 1] = { id = group.id, value = group,
            label = group.groupType .. " / " .. group.id,
            detail = group.mission .. " + " .. group.state }
    end
    return output
end

function Model.LocationItems(snapshot)
    local output = {}
    for _, location in ipairs(snapshot and snapshot.locations or {}) do
        output[#output + 1] = { id = location.id, value = location,
            label = location.type .. " / " .. location.id,
            detail = string.format("%.0f, %.0f | groups %d",
                location.x or 0, location.y or 0,
                #(location.occupantGroupIds or {})) }
    end
    return output
end


function Model.DetailRows(snapshot, group, location, authorized, reason)
    local rows, metrics = {}, snapshot and snapshot.metrics or {}
    if authorized ~= true then return { row("Authorization", reason, "danger") } end
    rows[#rows + 1] = row("Director", metrics.paused and "PAUSED" or "RUNNING",
        metrics.paused and "warning" or "success")
    rows[#rows + 1] = row("Registry", "revision " .. tostring(metrics.registryRevision or 0)
        .. (metrics.dirty and " / dirty" or " / saved"))
    rows[#rows + 1] = row("Population", string.format(
        "groups=%d traveling=%d active=%d", metrics.groups or 0,
        metrics.traveling or 0, metrics.materialized or 0))
    rows[#rows + 1] = row("World", string.format(
        "locations=%d encounters=%d jobs=%d", metrics.locations or 0,
        metrics.encounters or 0, metrics.scheduledJobs or 0))
    if snapshot and snapshot.action then
        rows[#rows + 1] = row("Last action",
            tostring(snapshot.action.action) .. ": " .. tostring(snapshot.action.reason),
            snapshot.action.ok and "success" or "danger")
    end
    if group then
        rows[#rows + 1] = row("GROUP", group.id)
        rows[#rows + 1] = row("Faction / home", tostring(group.factionId)
            .. " / " .. tostring(group.homeCommunityId or "independent"))
        rows[#rows + 1] = row("Type", group.groupType)
        rows[#rows + 1] = row("Members / leader", tostring(#(group.memberIds or {}))
            .. " / " .. tostring(group.leaderId or "none"))
        rows[#rows + 1] = row("Mission + state", group.mission .. " + " .. group.state)
        rows[#rows + 1] = row("Current location", group.location and group.location.id or "none")
        rows[#rows + 1] = row("Target", group.targetLocation and group.targetLocation.id or "none")
        rows[#rows + 1] = row("State time", string.format("%.3f -> %.3f",
            group.stateStartedAt or 0, group.stateEndsAt or 0))
        local needs = group.needs or {}
        rows[#rows + 1] = row("Needs H/W/R", string.format("%.1f / %.1f / %.1f",
            needs.hunger or 0, needs.hydration or 0, needs.fatigue or 0))
        local resources = group.resources or {}
        rows[#rows + 1] = row("Resources F/W/A/M", string.format("%.0f / %.0f / %.0f / %.0f",
            resources.food or 0, resources.water or 0, resources.ammo or 0,
            resources.medical or 0))
        rows[#rows + 1] = row("Combat cache",
            (group.combatProfileDirty and "DIRTY" or "CACHED") .. " / "
                .. tostring(group.combatProfileCacheState or group.combatProfileReason or "none"),
            group.combatProfileDirty and "warning" or "success")
        local profile = group.combatProfile
        if profile then
            for _, field in ipairs({ "memberCount", "combatantCount", "manpower",
                "meleePower", "rangedPower", "defense", "mobility", "morale",
                "experience", "medical", "ammoState", "condition", "overallPower" }) do
                rows[#rows + 1] = row("Combat " .. field,
                    string.format("%.2f", tonumber(profile[field]) or 0))
            end
        end
        for _, evaluation in ipairs(group.destinationEvaluations or {}) do
            local c = evaluation.components or {}
            rows[#rows + 1] = row("SCORE " .. evaluation.locationId,
                string.format("%.1f = res %.1f tag %.1f mission %.1f unvisited %.1f distance %.1f danger %.1f scavenged %.1f",
                    c.final or 0, c.resources or 0, c.tags or 0, c.mission or 0,
                    c.unvisited or 0, c.distance or 0, c.danger or 0,
                    c.scavenged or 0))
        end
    end
    if location then
        rows[#rows + 1] = row("LOCATION", location.id)
        rows[#rows + 1] = row("Type / position", location.type .. " / "
            .. string.format("%.0f, %.0f, %.0f", location.x or 0,
                location.y or 0, location.z or 0))
        rows[#rows + 1] = row("Danger / scavenged",
            tostring(location.danger) .. " / " .. tostring(location.scavengedLevel))
        rows[#rows + 1] = row("Occupants",
            table.concat(location.occupantGroupIds or {}, ", "))
    end
    for _, job in ipairs(snapshot and snapshot.jobs or {}) do
        rows[#rows + 1] = row("JOB " .. job.name,
            string.format("every %.3fh / next %.3f / runs %d / errors %d",
                job.interval or 0, job.nextRun or 0, job.runs or 0, job.errors or 0),
            (job.errors or 0) > 0 and "danger" or "textMuted")
    end
    local encounters = snapshot and snapshot.recentEncounters or {}
    local first = math.max(1, #encounters - 7)
    for index = first, #encounters do
        local report = encounters[index]
        rows[#rows + 1] = row("ENCOUNTER " .. tostring(report.id),
            tostring(report.outcome) .. " / " .. tostring(report.locationId)
                .. " / seed " .. tostring(report.seed)
                .. " / " .. table.concat(report.participants or {}, " vs "),
            report.outcome == "MATERIALIZATION_REQUIRED"
                and "warning" or "textMuted")
    end
    return rows
end

return Model
