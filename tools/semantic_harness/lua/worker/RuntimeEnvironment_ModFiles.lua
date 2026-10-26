-- Packaged mod files and compatibility globals exposed to production code.

local ModFiles = {}

local function packagedRoot(context, modID)
    if tostring(modID) == "ProjectHoomans" then
        return context.repository .. "/Contents/mods/ProjectHoomans/common"
    end
    if tostring(modID) == "PsychopatzCore" then
        return context.coreRepository .. "/Contents/mods/PsychopatzCore/common"
    end
    if tostring(modID) == "DTHoomans" then
        if not context.dynamicTradingRuntime then return nil end
        return context.dynamicTradingRepository
            .. "/Contents/mods/DTHoomans/" .. context.dynamicTradingRuntime
    end
    if tostring(modID) == "DTCommon" then
        return context.dynamicTradingRepository
            .. "/Contents/mods/DTCommon/common"
    end
    return nil
end

local function packagedReader(context, modID, relativePath)
    relativePath = tostring(relativePath or "")
    if relativePath == "" or string.sub(relativePath, 1, 1) == "/"
        or string.find(relativePath, "..", 1, true)
        or string.find(relativePath, "\\", 1, true)
    then
        return nil
    end
    local root = packagedRoot(context, modID)
    if not root then return nil end
    local overlay = os.getenv("PNC_HARNESS_CANDIDATE_OVERLAY_ROOT")
    if overlay and overlay ~= "" and modID == "ProjectHoomans"
        and string.match(relativePath,
            "^media/translation/[A-Z][A-Z]/Conversation/Semantic/[%w_]+%.json$")
    then
        local candidate = io.open(overlay .. "/" .. relativePath, "rb")
        if candidate then
            local closed = false
            return {
                readLine = function()
                    if closed then return nil end
                    return candidate:read("*l")
                end,
                close = function()
                    if not closed then closed = true; candidate:close() end
                end,
            }
        end
    end
    local handle = io.open(root .. "/" .. relativePath, "rb")
    if not handle then return nil end
    local closed = false
    return {
        readLine = function()
            if closed then return nil end
            return handle:read("*l")
        end,
        close = function()
            if not closed then
                closed = true
                handle:close()
            end
        end,
    }
end

function ModFiles.configure(context)
    local Runtime = context.Runtime
    Translator = {
        getLanguage = function()
            return { toString = function()
                return context.Translations.scenarioLanguage(context)
            end }
        end,
    }
    Events = Events or {}
    Events.OnGameBoot = Events.OnGameBoot or { listeners = {} }
    Events.OnGameBoot.listeners = Events.OnGameBoot.listeners or {}
    Events.OnGameBoot.Add = Events.OnGameBoot.Add or function(callback)
        Events.OnGameBoot.listeners[#Events.OnGameBoot.listeners + 1] = callback
    end
    getText = function(key, ...)
        return context.Translations.nativeText(context, key, ...)
    end
    getModFileReader = function(modID, relativePath)
        return packagedReader(context, modID, relativePath)
    end
    -- Native compatibility queries remain the production API surface. The
    -- worker supplies only the engine-backed activated-mod observation from
    -- the current scenario runtime projection.
    getModInfoByID = function()
        return nil
    end
    getActivatedMods = function()
        return {
            contains = function(_, modID)
                local available = context.runtime
                    and context.runtime.availableMods or {}
                return available[tostring(modID or "")] == true
            end,
        }
    end
    PNC = PNC or {}
    PNC.Compatibility = PNC.Compatibility or {}
    PNC.Compatibility.ModCache = {}
end

return ModFiles
