-- Read-only community invariant validation with explicit index-only repair.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.CommunityValidation = PNC.CommunityValidation or {}

local Validation = PNC.CommunityValidation
local Communities = PNC.Communities
local Constants = PNC.CommunityConstants
local Types = PNC.CommunityTypes
local CommunityMath = PNC.CommunityMath

local function result()
    return {
        ok = true,
        scope = "community_registry",
        errors = {},
        warnings = {},
        checks = 0,
    }
end

local function issue(output, severity, code, detail)
    local item = {
        severity = severity,
        code = code,
        detail = tostring(detail or ""),
    }
    if severity == "error" then
        output.ok = false
        output.errors[#output.errors + 1] = item
    else
        output.warnings[#output.warnings + 1] = item
    end
end

local function safePersistent(value, path, output, seen)
    local kind = type(value)
    output.checks = output.checks + 1
    if kind == "function" or kind == "userdata"
        or kind == "thread"
    then
        issue(
            output,
            "error",
            "unsafe_persistent_value",
            path .. ":" .. kind
        )
        return
    end
    if kind == "number"
        and not CommunityMath.IsFinite(value)
    then
        issue(output, "error", "non_finite_number", path)
        return
    end
    if kind ~= "table" then return end
    if getmetatable and getmetatable(value) ~= nil then
        issue(output, "error", "persistent_metatable", path)
    end
    if seen[value] then
        issue(output, "error", "persistent_cycle", path)
        return
    end
    seen[value] = true
    for key, child in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            issue(
                output,
                "error",
                "unsafe_persistent_key",
                path
            )
        end
        safePersistent(
            child,
            path .. "." .. tostring(key),
            output,
            seen
        )
    end
    seen[value] = nil
end

local function checkRange(
    output,
    value,
    minimum,
    maximum,
    code,
    detail
)
    output.checks = output.checks + 1
    if not CommunityMath.IsFinite(value)
        or value < minimum or value > maximum
    then
        issue(output, "error", code, detail)
    end
end

function Validation.ValidateRegistry()
    local output = result()
    local seenNPCs = {}
    Communities.EnsureLoaded()
    for communityID, community in pairs(
        Communities.Registry.byID
    ) do
        output.checks = output.checks + 1
        if community.id ~= communityID then
            issue(
                output,
                "error",
                "community_id_mismatch",
                communityID
            )
        end
        local faction = PNC.Factions
            and PNC.Factions.Get
            and PNC.Factions.Get(community.factionID) or nil
        if not faction then
            issue(
                output,
                "error",
                "community_faction_missing",
                communityID
            )
        end
        if not Communities.Registry.byFaction[
            community.factionID
        ] or Communities.Registry.byFaction[
            community.factionID
        ][communityID] ~= true then
            issue(
                output,
                "error",
                "by_faction_index_mismatch",
                communityID
            )
        end
        if not Types.NormalizeHome(
            community.home,
            community.mode
        ) then
            issue(
                output,
                "error",
                "invalid_home",
                communityID
            )
        end
        if community.siteID then
            local site = Communities.Registry.sitesByID[
                community.siteID
            ]
            if not site then
                issue(
                    output,
                    "error",
                    "missing_site_reference",
                    communityID .. ":" .. community.siteID
                )
            elseif community.status == "active"
                and site.occupantCommunityID ~= communityID
            then
                issue(
                    output,
                    "error",
                    "site_occupancy_mismatch",
                    communityID .. ":" .. community.siteID
                )
            end
        end
        checkRange(
            output,
            community.home and community.home.radius,
            Constants.RADIUS_MIN,
            Constants.RADIUS_MAX,
            "radius_out_of_range",
            communityID
        )
        checkRange(
            output,
            community.security,
            Constants.SECURITY_MIN,
            Constants.SECURITY_MAX,
            "security_out_of_range",
            communityID
        )
        checkRange(
            output,
            community.morale,
            Constants.MORALE_MIN,
            Constants.MORALE_MAX,
            "morale_out_of_range",
            communityID
        )
        local capacities = {
            population = Constants.POPULATION_CAPACITY_MAX,
            beds = Constants.BEDS_MAX,
            storage = Constants.STORAGE_MAX,
        }
        for name, maximum in pairs(capacities) do
            checkRange(
                output,
                community.capacity[name],
                0,
                maximum,
                "capacity_out_of_range",
                communityID .. ":" .. name
            )
        end
        for _, category in ipairs(
            Constants.SUPPLY_CATEGORIES
        ) do
            checkRange(
                output,
                community.supplies[category],
                Constants.SUPPLY_MIN,
                Constants.SUPPLY_MAX,
                "supply_out_of_range",
                communityID .. ":" .. category
            )
        end
        if (community.status == "archived"
            or community.status == "destroyed")
            and community.leaderNPCID ~= nil
        then
            issue(
                output,
                "error",
                "retired_community_has_leader",
                communityID
            )
        end
        for npcID, present in pairs(
            community.memberIDs or {}
        ) do
            if present == true then
                local record = PNC.Registry.Get(npcID)
                if seenNPCs[npcID] then
                    issue(
                        output,
                        "error",
                        "npc_in_multiple_communities",
                        npcID
                    )
                end
                seenNPCs[npcID] = communityID
                if not record
                    or record.alive == false
                    or not record.affiliation
                    or record.affiliation.communityID
                        ~= communityID
                then
                    issue(
                        output,
                        "error",
                        "member_index_mismatch",
                        communityID .. ":" .. npcID
                    )
                elseif record.affiliation.factionID
                    ~= community.factionID
                then
                    issue(
                        output,
                        "error",
                        "member_faction_mismatch",
                        communityID .. ":" .. npcID
                    )
                end
            end
        end
        if community.leaderNPCID then
            local leader = PNC.Registry.Get(
                community.leaderNPCID
            )
            if not leader
                or leader.alive == false
                or community.memberIDs[
                    community.leaderNPCID
                ] ~= true
            then
                issue(
                    output,
                    "error",
                    "invalid_community_leader",
                    communityID
                )
            end
        end
    end
    for factionID, communityIDs in pairs(
        Communities.Registry.byFaction
    ) do
        for communityID, present in pairs(communityIDs) do
            local community =
                Communities.Registry.byID[communityID]
            if present ~= true or not community
                or community.factionID ~= factionID
            then
                issue(
                    output,
                    "error",
                    "stale_by_faction_index",
                    factionID .. ":" .. communityID
                )
            end
        end
    end
    for siteID, site in pairs(
        Communities.Registry.sitesByID or {}
    ) do
        output.checks = output.checks + 1
        if site.id ~= siteID
            or not Types.IsValidSiteID(siteID)
        then
            issue(
                output,
                "error",
                "site_id_mismatch",
                siteID
            )
        end
        if not Constants.VALID_SITE_KINDS[site.kind]
            or not Constants.VALID_SITE_STATUSES[
                site.status
            ]
        then
            issue(
                output,
                "error",
                "invalid_site_classification",
                siteID
            )
        end
        if not Types.NormalizeSite(site, siteID) then
            issue(
                output,
                "error",
                "invalid_site",
                siteID
            )
        end
        if site.occupantCommunityID then
            local community = Communities.Registry.byID[
                site.occupantCommunityID
            ]
            if not community
                or community.status ~= "active"
                or community.siteID ~= siteID
                or site.claimantKey ~= nil
                or site.status ~= "occupied"
            then
                issue(
                    output,
                    "error",
                    "invalid_site_occupant",
                    siteID
                )
            end
        elseif site.claimantKey then
            if not PNC.EntityRef
                or not PNC.EntityRef.IsPlayer
                or not PNC.EntityRef.IsPlayer(
                    site.claimantKey
                )
                or site.status ~= "claimed"
            then
                issue(
                    output,
                    "error",
                    "invalid_site_claim",
                    siteID
                )
            end
        elseif site.status ~= "vacant" then
            issue(
                output,
                "error",
                "vacant_site_status_mismatch",
                siteID
            )
        end
    end
    for npcID, record in pairs(
        PNC.Registry and PNC.Registry.Data or {}
    ) do
        local communityID = record.affiliation
            and record.affiliation.communityID or nil
        if communityID then
            local community =
                Communities.Registry.byID[communityID]
            if not community then
                issue(
                    output,
                    "error",
                    "missing_community_reference",
                    npcID .. ":" .. communityID
                )
            elseif community.memberIDs[npcID] ~= true then
                issue(
                    output,
                    "error",
                    "affiliation_index_mismatch",
                    npcID .. ":" .. communityID
                )
            end
        end
    end
    safePersistent(
        Communities.Registry,
        "PNC_Communities",
        output,
        {}
    )
    return output
end

function Validation.RepairIndexes()
    return Communities.RebuildIndexes()
end

return Validation
