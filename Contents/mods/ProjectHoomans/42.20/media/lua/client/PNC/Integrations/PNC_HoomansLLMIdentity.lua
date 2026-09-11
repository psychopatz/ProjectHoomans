-- Canonical save identity adapter shared by interactive LLM requests and the
-- client-side conversation-memory outbox.
--
-- Project Hoomans does not own the save filesystem.  It only reports the
-- active world selected by the game, while PBrainZ decides where the client
-- memory is stored.

PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Identity = PNC.HoomansLLM.Identity or {}

local Identity = PNC.HoomansLLM.Identity

local function text(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function normalizedSavePath()
    if not getCurrentSaveName then return nil end
    local raw = text(getCurrentSaveName())
    if raw == "" then return nil end
    raw = string.gsub(raw, "\\", "/")

    -- Build 42 returns the absolute current-save directory. Keep only the
    -- path below <Zomboid>/Saves so it is portable across machines.
    local lowered = string.lower(raw)
    local marker = "/saves/"
    local markerStart = string.find(lowered, marker, 1, true)
    if markerStart then
        raw = string.sub(raw, markerStart + #marker)
    elseif string.sub(lowered, 1, #"saves/") == "saves/" then
        raw = string.sub(raw, #"saves/" + 1)
    end

    raw = text(raw)
    if raw == "" or string.sub(raw, 1, 1) == "/"
        or (#raw >= 2 and string.sub(raw, 2, 2) == ":")
    then
        return nil
    end
    return raw
end

local function gameMode()
    local world = getWorld and getWorld() or nil
    local mode = world and world.getGameMode and world:getGameMode() or nil
    mode = string.lower(text(mode))
    if mode == "multiplayer" then return "multiplayer" end

    -- A missing world object can occur during a short transition. Client Lua
    -- is multiplayer only when the engine explicitly reports a client world.
    if mode == "" and isClient and isClient() == true then
        return "multiplayer"
    end
    return "singleplayer"
end

local function serverInstanceID(savePath)
    local parts = {
        text(getServerName and getServerName()),
        text(getServerIP and getServerIP()),
        text(getServerPort and getServerPort()),
    }
    local present = {}
    for _, value in ipairs(parts) do
        if value ~= "" then present[#present + 1] = value end
    end
    if #present > 0 then return table.concat(present, "|") end
    return savePath or "unknown-server"
end

function Identity.Current()
    local mode = gameMode()
    local savePath = normalizedSavePath()
    if mode == "singleplayer" then
        -- Test doubles and older wrappers may expose only the leaf name.
        -- Apocalypse/SaveName is the standard Build 42 relative layout.
        if savePath and not string.find(savePath, "/", 1, true)
            and getWorld and getWorld()
        then
            local world = getWorld()
            local gameModeName = world and world.getGameMode
                and text(world:getGameMode()) or ""
            if gameModeName ~= "" then
                savePath = gameModeName .. "/" .. savePath
            end
        end
        return {
            world_mode = mode,
            save_relative_path = savePath,
        }
    end

    local world = getWorld and getWorld() or nil
    local generation = savePath
        or text(world and world.getWorld and world:getWorld())
        or text(getServerName and getServerName())
        or "unknown-generation"
    return {
        world_mode = mode,
        server_instance_id = serverInstanceID(savePath),
        server_world_generation = generation,
    }
end

return Identity
