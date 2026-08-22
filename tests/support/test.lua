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
    return package.path
end

function Test.load(mod, layer, relative)
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
