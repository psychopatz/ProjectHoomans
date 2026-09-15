local Test = {}

local repository = os.getenv("PZ_TEST_REPOSITORY") or "."
local config = dofile(repository .. "/tests/test_config.lua")
local hoomansRuntime = os.getenv("PZ_TEST_HOOMANS_RUNTIME")
    or config.projectHoomansRuntime
local coreRuntime = os.getenv("PZ_TEST_CORE_RUNTIME")
    or config.psychopatzCoreRuntime
local coreRepository = os.getenv("PZ_TEST_CORE_REPOSITORY")
    or config.psychopatzCoreRepository

local roots = {
    ProjectHoomans = repository .. "/Contents/mods/ProjectHoomans/"
        .. hoomansRuntime .. "/media/lua/",
    ProjectHoomansMod = repository .. "/Contents/mods/ProjectHoomans/"
        .. hoomansRuntime .. "/",
    ProjectHoomansCommonMod = repository .. "/Contents/mods/ProjectHoomans/common/",
    ProjectHoomansCommon = repository .. "/Contents/mods/ProjectHoomans/common/media/",
    PsychopatzCore = coreRepository .. "/Contents/mods/PsychopatzCore/",
}
local defaultPackagePathsAdded = false

-- Isolated smoke tests load individual Hoomans modules instead of the normal
-- shared composition root. Preserve the old getText-shaped test behavior for
-- those modules without changing the production runtime or monkey-patching
-- the game translation API.
local function installTranslationFallback()
    local existing = getmetatable(_G)
    if existing and existing.__pncTranslationFallback then return end

    local previousNewIndex = existing and existing.__newindex
    local previousIndex = existing and existing.__index
    local fallbackPNC = {}
    local metatable = {}
    if existing then
        for key, value in pairs(existing) do metatable[key] = value end
    end
    metatable.__pncTranslationFallback = true
    metatable.__index = function(table, key)
        if key == "PNC" and rawget(table, key) == nil then
            return fallbackPNC
        end
        if type(previousIndex) == "function" then
            return previousIndex(table, key)
        end
        if type(previousIndex) == "table" then return previousIndex[key] end
        return nil
    end
    metatable.__newindex = function(table, key, value)
        if key == "PNC" and type(value) == "table" then
            if value ~= fallbackPNC then
                for field in pairs(fallbackPNC) do
                    if field ~= "Translation" then fallbackPNC[field] = nil end
                end
                if not value.Translation then
                    value.Translation = fallbackPNC.Translation
                end
                for field, fieldValue in pairs(value) do
                    fallbackPNC[field] = fieldValue
                end
            end
            return
        end
        if type(previousNewIndex) == "function" then
            return previousNewIndex(table, key, value)
        end
        if type(previousNewIndex) == "table" then
            previousNewIndex[key] = value
        else
            rawset(table, key, value)
        end
    end
    setmetatable(_G, metatable)
    fallbackPNC.Translation = {
        GetKey = function(translationKey, fallback)
            if type(getText) == "function" then
                local ok, translated = pcall(getText, translationKey)
                if ok and type(translated) == "string"
                    and translated ~= ""
                    and translated ~= translationKey
                then
                    return translated
                end
            end
            return fallback or translationKey or ""
        end,
    }
    fallbackPNC.Translation.TrFormat = function(translationKey, fallback, ...)
        local direct
        if type(getText) == "function" then
            local args = { ... }
            local ok, translated = pcall(getText, translationKey,
                args[1], args[2], args[3], args[4])
            if ok and type(translated) == "string"
                and translated ~= "" and translated ~= translationKey
            then
                direct = translated
            end
        end
        local translated = fallbackPNC.Translation.GetKey(
            translationKey, fallback)
        if direct then translated = direct end
        local args = { ... }
        translated = string.gsub(translated, "%%(%d+)", function(index)
            local replacement = args[tonumber(index)]
            return replacement ~= nil and tostring(replacement)
                or "%%" .. index
        end)
        local ok, formatted = pcall(string.format, translated,
            args[1], args[2], args[3], args[4])
        return ok and formatted or translated
    end
    local currentPNC = rawget(_G, "PNC")
    if type(currentPNC) == "table" then
        if currentPNC.Translation then
            fallbackPNC.Translation = currentPNC.Translation
        else
            currentPNC.Translation = fallbackPNC.Translation
        end
        for field, fieldValue in pairs(currentPNC) do
            fallbackPNC[field] = fieldValue
        end
        rawset(_G, "PNC", nil)
    end
end

local function cleanRelative(path)
    path = tostring(path or "")
    assert(string.sub(path, 1, 1) ~= "/", "test path must be relative")
    assert(not string.find(path, "..", 1, true), "test path cannot traverse parents")
    return path
end

function Test.path(mod, layer, relative)
    relative = cleanRelative(relative)
    if mod == "ProjectHoomans" then
        if layer == "mod" then
            return roots.ProjectHoomansMod .. relative
        end
        if layer == "common_mod" then
            return roots.ProjectHoomansCommonMod .. relative
        end
        if layer == "root" then
            return roots.ProjectHoomans .. relative
        end
        if layer == "common" then
            return roots.ProjectHoomansCommon .. relative
        end
        if layer == "common_lua" then
            return roots.ProjectHoomansCommon .. "lua/shared/" .. relative
        end
        if layer == "common_client" then
            return roots.ProjectHoomansCommon .. "lua/client/" .. relative
        end
        return roots.ProjectHoomans .. tostring(layer) .. "/" .. relative
    end
    if mod == "PsychopatzCore" then
        if layer == "mod" then
            return roots.PsychopatzCore .. coreRuntime .. "/" .. relative
        end
        if layer == "common_mod" then
            return roots.PsychopatzCore .. "common/" .. relative
        end
        if layer == "root" then
            return roots.PsychopatzCore .. coreRuntime .. "/media/lua/" .. relative
        end
        if layer == "common" then
            return roots.PsychopatzCore .. "common/media/lua/shared/" .. relative
        end
        if layer == "common_client" then
            return roots.PsychopatzCore .. "common/media/lua/client/" .. relative
        end
        return roots.PsychopatzCore .. coreRuntime .. "/media/lua/"
            .. tostring(layer) .. "/" .. relative
    end
    error("unknown test mod: " .. tostring(mod))
end

function Test.addPackagePaths(specifications)
    installTranslationFallback()
    local usingDefaults = specifications == nil
    specifications = specifications or {
        { "ProjectHoomans", "shared" },
        { "ProjectHoomans", "server" },
        { "ProjectHoomans", "client" },
        { "ProjectHoomans", "common_lua" },
        { "PsychopatzCore", "common" },
        { "PsychopatzCore", "shared" },
    }
    local paths = {}
    for index = 1, #specifications do
        local specification = specifications[index]
        paths[#paths + 1] = Test.path(specification[1], specification[2], "?.lua")
    end
    paths[#paths + 1] = package.path
    package.path = table.concat(paths, ";")
    if usingDefaults then
        defaultPackagePathsAdded = true
    end
    return package.path
end

function Test.load(mod, layer, relative)
    if not defaultPackagePathsAdded then
        Test.addPackagePaths()
    end
    if relative == nil then
        return dofile(mod)
    end
    return dofile(Test.path(mod, layer, relative))
end

function Test.read(mod, layer, relative)
    local path = relative == nil and mod or Test.path(mod, layer, relative)
    local handle = assert(io.open(path, "rb"), "cannot open test source: " .. path)
    local source = handle:read("*a")
    handle:close()
    return source
end

function Test.equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

function Test.truthy(value, label)
    if not value then error((label or "truthy") .. ": expected truthy value", 2) end
    return value
end

function Test.falsy(value, label)
    if value then error((label or "falsy") .. ": expected falsy value", 2) end
end

function Test.near(actual, expected, tolerance, label)
    tolerance = tonumber(tolerance) or 0.000001
    if math.abs((tonumber(actual) or 0) - (tonumber(expected) or 0)) > tolerance then
        error((label or "near") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual) .. " tolerance=" .. tostring(tolerance), 2)
    end
end

function Test.contains(value, fragment, label)
    if not string.find(tostring(value or ""), tostring(fragment or ""), 1, true) then
        error((label or "contains") .. ": missing=" .. tostring(fragment), 2)
    end
end

function Test.finish(name)
    if os.getenv("PZ_TEST_VERBOSE") == "1" then
        print(tostring(name or "test") .. ": ok")
    end
    return true
end

Test.runtime = { ProjectHoomans = hoomansRuntime, PsychopatzCore = coreRuntime }
Test.repository = repository

return Test
