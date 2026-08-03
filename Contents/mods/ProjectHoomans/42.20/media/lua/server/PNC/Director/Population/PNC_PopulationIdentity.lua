-- Shared metadata/presence policy for automatic population creation.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.PopulationIdentity = PNC.PopulationIdentity or {}

local Identity = PNC.PopulationIdentity

function Identity.FactionName(archetypeID, seed)
    local generator = PNC.FactionNameGenerator
    if not generator or not generator.GenerateFactionName then
        return "Survivor " .. tostring(archetypeID)
    end
    local used = {}
    for _, faction in ipairs(PNC.Factions.List()) do used[faction.name] = true end
    for attempt = 1, 32 do
        local name = generator.GenerateFactionName(archetypeID,
            tostring(seed) .. ":POPULATION:" .. tostring(attempt))
        if not used[name] then return name end
    end
    return "New " .. generator.GenerateFactionName(archetypeID,
        tostring(seed) .. ":POPULATION:FALLBACK")
end

function Identity.FactionTags(archetypeID, creationKind)
    local tags = { populationGenerated = true }
    if creationKind == "MOBILE_GROUP" then
        tags.mobileGroup = true
        tags.mobilePathMode = "random"
    elseif archetypeID == "settler" then
        tags.settlementType = "friendly"
    elseif archetypeID == "looter" then
        tags.settlementType = "looter_toll"
        tags.territorialToll = true
    end
    return tags
end

function Identity.PresenceSpec()
    -- The canonical Directors decide whether the site is loaded. Offscreen
    -- records start abstract, but remain eligible for normal range-enter
    -- materialization instead of being permanently force-abstracted.
    return { presenceMode = "auto", allowLive = true }
end

function Identity.MigrateLegacyMetadata()
    local migrated = 0
    for _, faction in ipairs(PNC.Factions.List()) do
        if faction.tags and faction.tags.populationGenerated == true then
            local kind = faction.mobile and faction.mobile.active == true
                and "MOBILE_GROUP" or "SETTLEMENT"
            if PNC.Factions.MergeTags then
                PNC.Factions.MergeTags(faction.id,
                    Identity.FactionTags(faction.archetypeID, kind))
            end
            local current = PNC.Factions.Get(faction.id) or faction
            if string.find(current.name or "", "Population ", 1, true) == 1 then
                local newName = Identity.FactionName(current.archetypeID,
                    tostring(current.id) .. ":LEGACY_METADATA")
                if PNC.Factions.SetName then
                    local renamed, _, updated = PNC.Factions.SetName(
                        current.id, newName)
                    if renamed and updated then
                        current, migrated = updated, migrated + 1
                    end
                end
            end
            for _, community in ipairs(PNC.Communities.GetForFaction(
                current.id) or {}) do
                if string.find(community.name or "", "Population ", 1, true) == 1
                then
                    local generated = PNC.FactionNameGenerator
                        .GenerateCommunityName(current.archetypeID,
                            current.name, tostring(current.id) .. ":"
                                .. tostring(community.siteID or community.id))
                    if PNC.Communities.SetName
                        and PNC.Communities.SetName(community.id, generated)
                    then
                        migrated = migrated + 1
                    end
                end
            end
        end
    end
    return migrated
end

return Identity
