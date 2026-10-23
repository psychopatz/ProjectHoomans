-- Deterministic player aliases used by semantic identity choices.
--
-- This is a projection only. It is never persisted as player ModData and the
-- server recomputes it before accepting a generated-name claim.
PNC = PNC or {}
PNC.IdentityAlias = PNC.IdentityAlias or {}

local Alias = PNC.IdentityAlias
local Names = PNC.IdentityNames
if type(Names) ~= "table" then
    local ok, loaded = pcall(require, "PNC/Core/Identity/PNC_Identity_Names")
    Names = PNC.IdentityNames
    if type(Names) ~= "table" and ok and type(loaded) == "table" then
        Names = loaded
    end
end

local function clean(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.gsub(value, "%s+", " ")
    return value
end

local function normalized(value)
    return string.lower(clean(value))
end

local function claimMatchesName(claimed, canonical)
    local left = normalized(claimed)
    local right = normalized(canonical)
    if left == "" or right == "" then return false end
    if left == right then return true end
    if string.find(left, "%s") then return false end
    local forename, surname = string.match(right, "^([^%s]+)%s+(.+)$")
    return left == forename or left == surname
end

local function methodValue(target, name)
    local method = target and target[name]
    if type(method) ~= "function" then return nil end
    local ok, value = pcall(method, target)
    return ok and value or nil
end

function Alias.PlayerIdentitySeed(source)
    if type(source) == "table" then
        local value = source.identitySeed or source.characterUUID
            or source.entityKey or source.playerIdentitySeed
        if value ~= nil and clean(value) ~= "" then return tostring(value) end
        local player = source.player
        if player then
            value = player.characterUUID or methodValue(player, "getUsername")
                or methodValue(player, "getOnlineID")
            if value ~= nil and clean(value) ~= "" then
                return tostring(value)
            end
        end
    end
    return "player"
end

function Alias.PlayerIsFemale(source)
    if type(source) ~= "table" then return false end
    local gender = string.lower(tostring(source.gender or ""))
    if gender ~= "" then return gender == "female" end
    local value = source.isFemale
    if type(value) == "function" then value = methodValue(source, "isFemale") end
    if type(value) == "boolean" then return value end
    local player = source.player
    value = player and player.isFemale or nil
    if type(value) == "function" then value = methodValue(player, "isFemale") end
    if type(value) == "boolean" then return value end
    local descriptor = player and methodValue(player, "getDescriptor") or nil
    value = descriptor and descriptor.isFemale or nil
    if type(value) == "function" then value = methodValue(descriptor, "isFemale") end
    return value == true
end

function Alias.Generate(source, options)
    source = type(source) == "table" and source or {}
    options = type(options) == "table" and options or {}
    local seed = Alias.PlayerIdentitySeed(source)
    local actualName = source.playerName or source.displayName
    local saveSeed = options.saveSeed or source.saveSeed
    local archetypeID = options.archetypeID or "IdentityAlias"
    local attempt
    for attempt = 1, 8 do
        local value = Names.Generate(
            seed,
            Alias.PlayerIsFemale(source),
            archetypeID,
            {
                saveSeed = saveSeed,
                namespace = "projecthoomans.identity.alias." .. tostring(attempt),
            }
        )
        if not claimMatchesName(value, actualName) then return value end
    end
    return Names.Generate(
        seed .. ":fallback",
        Alias.PlayerIsFemale(source),
        archetypeID,
        {
            saveSeed = saveSeed,
            namespace = "projecthoomans.identity.alias.fallback",
        }
    )
end

function Alias.MatchesCanonical(value, canonical)
    return claimMatchesName(value, canonical)
end

return Alias
