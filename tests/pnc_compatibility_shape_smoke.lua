-- Shape contract for every third-party compatibility provider.
--
-- This is a source-level guard, not a runtime test: it keeps the provider
-- module shape described in PNC_Compatibility_API.lua from drifting as new
-- integrations are added. It deliberately reads the files instead of loading
-- them, so it needs no game or provider stubs.

local T = require "tests/support/test"

local MODS = "PNC/Core/Compatibility/Mods/"
local MAX_HUB_LINES = 120

-- provider folder name == the PascalCase segment used in every filename
local PROVIDERS = {
    {
        folder = "Bandits",
        class = "foreign_actor",
        adapterID = "Bandits",
        version = "Bandits2-B42.20",
        spokes = {
            "Access", "Targeting", "Relationships", "Combat", "Flavor",
        },
        -- Loaded from PNC/00_PNC_Init.lua so it patches PZ's animation file map
        -- before any other shared module reads it.
        unrooted = {
            AnimPathCompat = "loaded from PNC/00_PNC_Init.lua",
        },
    },
    {
        folder = "CompanionDogs",
        class = "feature_integration",
        spokes = { "Access", "Presentation", "Feed", "Interaction", "Runtime" },
    },
    {
        folder = "Necroa",
        class = "policy_hook",
        adapterID = "Necroa",
        version = "Necroa2-B42.20",
        spokes = { "Mask", "Policy" },
    },
    {
        folder = "ProjectALife",
        class = "foreign_actor",
        adapterID = "ProjectALifeNPCs",
        version = "ProjectALifeNPCs-B42.20",
        spokes = {
            "Access", "Policy", "Targeting", "Combat",
            "DamageBridge", "ReverseBridge",
        },
    },
}

local function source(folder, role)
    return T.read(
        "ProjectHoomans",
        "shared",
        MODS .. folder .. "/PNC_" .. folder .. "_" .. role .. ".lua"
    )
end

local function lineCount(text)
    local count = 0
    for _ in text:gmatch("\n") do count = count + 1 end
    return count + 1
end

-- Occurrences of `require "…/Mods/<folder>/…"` that are not part of an
-- `or require` guarded fallback.
local function unguardedSiblingRequires(text, folder)
    local pattern = 'require%s*"PNC/Core/Compatibility/Mods/'
        .. folder .. '/[^"]+"'
    local found = {}
    local cursor = 1
    while true do
        local startAt, endAt = text:find(pattern, cursor)
        if not startAt then break end
        local prefix = text:sub(math.max(1, startAt - 24), startAt - 1)
        if not prefix:match("or%s*$") then
            found[#found + 1] = text:sub(startAt, endAt)
        end
        cursor = endAt + 1
    end
    return found
end

for _, provider in ipairs(PROVIDERS) do
    local label = provider.folder
    local hub = source(provider.folder, "Adapter")

    T.truthy(lineCount(hub) <= MAX_HUB_LINES,
        label .. " adapter hub is no longer thin ("
            .. tostring(lineCount(hub)) .. " lines)")

    for _, speak in ipairs(provider.spokes) do
        local text = source(provider.folder, speak)
        T.contains(hub,
            "PNC/Core/Compatibility/Mods/" .. label .. "/PNC_"
                .. label .. "_" .. speak,
            label .. " hub does not load its " .. speak .. " spoke")
        local unguarded = unguardedSiblingRequires(text, label)
        T.equal(#unguarded, 0,
            label .. " spoke " .. speak
                .. " requires a sibling outside an `or require` fallback")
    end

    for role, reason in pairs(provider.unrooted or {}) do
        source(provider.folder, role)
        T.falsy(hub:find(
            'require "PNC/Core/Compatibility/Mods/' .. label .. "/PNC_"
                .. label .. "_" .. role .. '"', 1, true),
            label .. " hub must not require " .. role
                .. ": it is " .. reason)
    end

    -- The hub is a hub: no dynamic require, and it returns its namespace.
    T.equal(select(2, hub:gsub("require%s*%(", "")), 0,
        label .. " adapter hub uses a dynamic require")
    T.contains(hub, "return Bridge",
        label .. " adapter hub does not return its namespace")
    if provider.class == "feature_integration" then
        T.falsy(hub:find("RegisterAdapter", 1, true),
            label .. " is a feature integration and must not register")
    else
        T.contains(hub, 'id = "' .. provider.adapterID .. '"',
            label .. " adapter id was not declared")
        T.contains(hub, 'version = "' .. provider.version .. '"',
            label .. " adapter version was not declared")
        T.contains(hub, "apiVersion = 1",
            label .. " adapter apiVersion was not declared")
        T.contains(hub, "capabilities = {",
            label .. " adapter capabilities were not declared")
        if provider.class == "foreign_actor" then
            T.contains(hub, "detect = ",
                label .. " foreign-actor adapter declares no detect predicate")
        else
            T.falsy(hub:find("detect = ", 1, true),
                label .. " policy-hook adapter must not declare detect")
        end
    end
end

T.finish("pnc_compatibility_shape_smoke")
