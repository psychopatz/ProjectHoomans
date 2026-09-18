-- Persistent real-Lua semantic worker for the Python harness.
--
-- This file deliberately loads the production semantic modules. The objects
-- below mock only the Project Zomboid/runtime boundaries used by that path.

local repository = arg[1] or os.getenv("PNC_HARNESS_REPOSITORY") or "."
local coreRepository = arg[2]
    or os.getenv("PNC_HARNESS_CORE_REPOSITORY")
    or repository .. "/../psychopatzCore"
local hoomansRuntime = os.getenv("PZ_TEST_HOOMANS_RUNTIME") or "42.20"
local coreRuntime = os.getenv("PZ_TEST_CORE_RUNTIME") or "42.20"

local function path(root, relative)
    return root .. "/" .. relative
end

local packagePaths = {
    path(repository, "tools/semantic_harness/lua/?.lua"),
    path(repository, "Contents/mods/ProjectHoomans/" .. hoomansRuntime .. "/media/lua/shared/?.lua"),
    path(repository, "Contents/mods/ProjectHoomans/" .. hoomansRuntime .. "/media/lua/server/?.lua"),
    path(repository, "Contents/mods/ProjectHoomans/" .. hoomansRuntime .. "/media/lua/client/?.lua"),
    path(repository, "Contents/mods/ProjectHoomans/common/media/lua/shared/?.lua"),
    path(coreRepository, "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua"),
    path(coreRepository, "Contents/mods/PsychopatzCore/" .. coreRuntime .. "/media/lua/shared/?.lua"),
    path(coreRepository, "Contents/mods/PsychopatzCore/common/media/lua/client/?.lua"),
    path(coreRepository, "Contents/mods/PsychopatzCore/" .. coreRuntime .. "/media/lua/client/?.lua"),
    package.path,
}
package.path = table.concat(packagePaths, ";")

local Protocol = require "worker/Protocol"
local RuntimeState = require "worker/RuntimeState"
local Runtime = RuntimeState.new()

local PROTOCOL_VERSION = Protocol.VERSION

local function copy(value, depth, seen)
    if type(value) ~= "table" then return value end
    depth = depth or 0
    if depth > 8 then return "<depth_limit>" end
    seen = seen or {}
    if seen[value] then return "<cycle>" end
    seen[value] = true
    local output = {}
    local count = 0
    for key, item in pairs(value) do
        count = count + 1
        if count > 128 then break end
        if type(key) == "string" or type(key) == "number" then
            local itemType = type(item)
            if itemType == "table" then
                output[key] = copy(item, depth + 1, seen)
            elseif itemType ~= "function"
                and itemType ~= "userdata"
                and itemType ~= "thread"
            then
                output[key] = item
            end
        end
    end
    seen[value] = nil
    return output
end

local function clearTable(value)
    for key in pairs(value) do value[key] = nil end
    return value
end

local function emit(value, requestID)
    return Protocol.emit(value, requestID)
end

local function fail(requestID, message)
    return Protocol.fail(requestID, message)
end

local function readRequest(source)
    return Protocol.readRequest(source)
end

local function safeString(value, fallback)
    value = tostring(value or fallback or "")
    return value
end

local function number(value, fallback)
    value = tonumber(value)
    return value ~= nil and value or fallback
end

local function language(value)
    value = string.upper(tostring(value or "EN"))
    if value == "" or string.find(value, "..", 1, true)
        or string.match(value, "^[%w_%-]+$") == nil
    then
        return "EN"
    end
    return value
end

local function scenarioLanguage()
    local scenario = Runtime.scenario or {}
    local runtime = scenario.runtime or {}
    return language(runtime.language or "EN")
end

local function nativeText(key, ...)
    local scenario = Runtime.scenario or {}
    local runtime = scenario.runtime or {}
    local catalog = runtime.nativeTranslations or {}
    local value = catalog[key]
    if type(value) ~= "string" or value == "" then return key end
    local args = { ... }
    for index = 1, #args do
        value = string.gsub(value, "%%" .. tostring(index), function()
            return tostring(args[index])
        end)
    end
    return value
end

local function packagedRoot(modID)
    if tostring(modID) == "ProjectHoomans" then
        return repository .. "/Contents/mods/ProjectHoomans/common"
    end
    if tostring(modID) == "PsychopatzCore" then
        return coreRepository .. "/Contents/mods/PsychopatzCore/common"
    end
    return nil
end

local function packagedReader(modID, relativePath)
    relativePath = tostring(relativePath or "")
    if relativePath == "" or string.sub(relativePath, 1, 1) == "/"
        or string.find(relativePath, "..", 1, true)
        or string.find(relativePath, "\\", 1, true)
    then
        return nil
    end
    local root = packagedRoot(modID)
    if not root then return nil end
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

local function translationManager()
    return type(CustomTranslationManager) == "table"
        and CustomTranslationManager or nil
end

local function currentLanguage()
    local manager = translationManager()
    if manager and type(manager.getLanguage) == "function" then
        local ok, value = pcall(manager.getLanguage)
        if ok and value then return language(value) end
    end
    return scenarioLanguage()
end

local function recordTranslation(kind, key, fallback, value, args)
    local keyText = tostring(key or "")
    if keyText == "" then return end
    local fallbackText = fallback ~= nil and tostring(fallback) or nil
    local resolved = value ~= nil and tostring(value) or ""
    Runtime.translationLookups[#Runtime.translationLookups + 1] = {
        kind = kind,
        key = keyText,
        fallback = fallbackText,
        value = resolved,
        args = copy(args),
        language = currentLanguage(),
        fallbackUsed = fallbackText ~= nil
            and resolved == fallbackText
            and currentLanguage() ~= "EN",
        turn = Runtime.turn,
    }
    if #Runtime.translationLookups > 128 then
        table.remove(Runtime.translationLookups, 1)
    end
end

local function installTranslationInstrumentation()
    local translation = PNC and PNC.Translation
    if type(translation) ~= "table" or translation._harnessWrapped then
        return
    end
    local originalGetKey = translation.GetKey
    local originalGet = translation.Get
    local originalTr = translation.Tr
    local originalTrFormat = translation.TrFormat
    if type(originalGetKey) == "function" then
        translation.GetKey = function(key, fallback, source)
            local value = originalGetKey(key, fallback, source)
            recordTranslation("getKey", key, fallback, value, nil)
            return value
        end
    end
    if type(originalGet) == "function" then
        translation.Get = function(systemName, key, fallback)
            local value = originalGet(systemName, key, fallback)
            recordTranslation("get", key, fallback, value, nil)
            return value
        end
    end
    if type(originalTr) == "function" then
        translation.Tr = function(first, second, third)
            local value = originalTr(first, second, third)
            recordTranslation("tr", third ~= nil and second or first,
                third ~= nil and third or second, value, nil)
            return value
        end
    end
    if type(originalTrFormat) == "function" then
        translation.TrFormat = function(key, fallback, ...)
            local args = { ... }
            local value = originalTrFormat(key, fallback, ...)
            recordTranslation("trFormat", key, fallback, value, args)
            return value
        end
    end
    translation._harnessWrapped = true
end

local function identityName(npc)
    local first = safeString(npc and npc.forename)
    local last = safeString(npc and npc.surname)
    if first ~= "" and last ~= "" then return first .. " " .. last end
    return first ~= "" and first or last
end

local function playerName(player)
    local first = safeString(player and player.forename)
    local last = safeString(player and player.surname)
    if first ~= "" and last ~= "" then return first .. " " .. last end
    return first ~= "" and first or last
end

local function relationshipFor(npcID)
    local scenario = Runtime.scenario or {}
    local npc = scenario.npc or {}
    local relationship = npc.relationship or {}
    Runtime.relationships = Runtime.relationships or {}
    Runtime.relationships[npcID] = Runtime.relationships[npcID]
        or copy(relationship)
    return Runtime.relationships[npcID]
end

local function relationshipSnapshotFor(npcID)
    return copy(relationshipFor(npcID))
end

local function resetContainers()
    RuntimeState.resetContainers(Runtime)
end

-- Scenario inventory is intentionally JSON-friendly: authors may use either
-- an array of item specs or the production compact map keyed by item ID. The
-- worker normalizes both shapes to the compact authoritative form while the
-- player side also receives native-like item/container methods for the real
-- gift selector.
local function normalizeInventory(inventory)
    inventory = type(inventory) == "table" and inventory or {}
    local source = type(inventory.items) == "table" and inventory.items or {}
    local items = {}
    for key, item in pairs(source) do
        if type(item) == "table" then
            local itemID = tostring(item.itemID or item.id or key or "")
            if itemID ~= "" then
                item.id = itemID
                item.itemID = item.itemID or itemID
                item.type = item.type or item.fullType or ""
                item.fullType = item.fullType or item.type
                item.stack = math.max(1, math.floor(number(item.stack, 1)))
                items[itemID] = item
            end
        end
    end
    inventory.items = items
    inventory.containers = type(inventory.containers) == "table"
        and inventory.containers or {}
    inventory.revision = math.max(0, math.floor(number(inventory.revision, 1)))
    return inventory
end

local function inventoryIDs(inventory)
    local output = {}
    for itemID in pairs(inventory and inventory.items or {}) do
        output[#output + 1] = tostring(itemID)
    end
    table.sort(output)
    return output
end

local function nativeList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local function nativeItem(spec)
    local item = {}
    item.getID = function() return spec.id end
    item.getFullType = function() return spec.fullType or spec.type end
    item.getType = function() return spec.fullType or spec.type end
    item.getDisplayName = function()
        return spec.displayName or spec.customName or spec.fullType or spec.type
    end
    item.getName = function() return spec.customName end
    item.isFavorite = function() return spec.favorite == true or spec.fav == true end
    item.isEquipped = function()
        return spec.equipped == true or spec.equipSlot ~= nil
    end
    item.getCondition = function() return spec.condition or spec.cond end
    item.getUsedDelta = function() return spec.usedDelta or spec.uses end
    item.getItemContainer = function()
        local contents = spec.contents or spec.items
        if type(contents) ~= "table" then return nil end
        local children = {}
        for key, child in pairs(contents) do
            if type(child) == "table" then
                child.id = child.id or child.itemID or tostring(key)
                child.fullType = child.fullType or child.type
                children[#children + 1] = nativeItem(child)
            end
        end
        table.sort(children, function(left, right)
            return tostring(left:getID()) < tostring(right:getID())
        end)
        return { getItems = function() return nativeList(children) end }
    end
    item.getInventory = item.getItemContainer
    return item
end

local function nativeInventory(inventory)
    return {
        getItems = function()
            local output = {}
            for _, itemID in ipairs(inventoryIDs(inventory)) do
                output[#output + 1] = nativeItem(inventory.items[itemID])
            end
            return nativeList(output)
        end,
    }
end

local function scenarioItemByType(fullType)
    local scenario = Runtime.scenario or {}
    for _, ownerName in ipairs({ "player", "npc" }) do
        local owner = scenario[ownerName] or {}
        local inventory = owner.inventory or {}
        for _, item in pairs(inventory.items or {}) do
            if tostring(item.fullType or item.type or "") == tostring(fullType or "") then
                return item
            end
        end
    end
    return nil
end

local function marketSenseFor(fullType)
    local item = scenarioItemByType(fullType)
    local definition = item and (item.marketSense or item.classification) or nil
    return type(definition) == "table" and definition or nil
end

local function configureGlobals()
    local scenario = Runtime.scenario or {}
    local playerData = scenario.player or {}
    local npcData = scenario.npc or {}
    local world = scenario.world or {}
    local runtime = scenario.runtime or {}
    local conversation = scenario.conversation or {}
    local playerInventory = normalizeInventory(playerData.inventory)
    local npcInventory = normalizeInventory(npcData.inventory)

    -- This is the harness's explicit MarketSense seam. The production
    -- adapters, selectors, and gift scorer remain real; scenario item specs
    -- provide the same bounded taxonomy data that the optional game service
    -- supplies at runtime.
    MarketSense = {
        GetTags = function(fullType)
            local details = marketSenseFor(fullType) or {}
            return {
                primary = details.primary,
                category = details.category,
                tags = copy(details.tags),
                expandedTags = copy(details.expandedTags),
                themes = copy(details.themes),
            }
        end,
        GetPriceDetails = function(fullType)
            local details = marketSenseFor(fullType)
            return details and copy(details) or nil
        end,
        GetPriceDetailsForInstance = function(fullType)
            local details = marketSenseFor(fullType)
            return details and copy(details) or nil
        end,
        GetItemCapabilities = function(fullType)
            local details = marketSenseFor(fullType) or {}
            return { capabilities = copy(details.capabilities) or {} }
        end,
    }

    Translator = {
        getLanguage = function()
            return { toString = function() return scenarioLanguage() end }
        end,
    }
    Events = Events or {}
    Events.OnGameBoot = Events.OnGameBoot or { listeners = {} }
    Events.OnGameBoot.listeners = Events.OnGameBoot.listeners or {}
    Events.OnGameBoot.Add = Events.OnGameBoot.Add or function(callback)
        Events.OnGameBoot.listeners[#Events.OnGameBoot.listeners + 1] = callback
    end
    getText = nativeText
    getModFileReader = packagedReader

    local descriptor = {
        getForename = function() return playerData.forename end,
        getSurname = function() return playerData.surname end,
    }
    local player = {
        getDescriptor = function() return descriptor end,
        getDisplayName = function()
            return playerData.displayName or playerName(playerData)
        end,
        getX = function() return 0 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
        getHoursSurvived = function()
            return number(world.worldAgeHours, 0)
        end,
        getInventory = function() return nativeInventory(playerInventory) end,
    }
    local gameTime = {
        getWorldAgeHours = function()
            return number(world.worldAgeHours, 0)
        end,
        getTimeOfDay = function() return number(world.timeOfDay, 12) end,
        getHour = function()
            return math.floor(number(world.timeOfDay, 12))
        end,
        getMinutes = function()
            local time = number(world.timeOfDay, 12)
            return math.floor((time - math.floor(time)) * 60 + 0.5)
        end,
        getDayPlusOne = function()
            return math.floor(number(world.worldAgeHours, 0) / 24) + 1
        end,
        getMonth = function() return 0 end,
        getYear = function() return 1993 end,
    }
    local climate = {
        getPrecipitationIntensity = function()
            return world.weather == "rain" and 0.8 or 0
        end,
        isRaining = function() return world.weather == "rain" end,
        getFogIntensity = function() return world.weather == "fog" and 0.8 or 0 end,
        isFoggy = function() return world.weather == "fog" end,
        getTemperature = function() return 20 end,
    }

    getGameTime = function() return gameTime end
    getClimateManager = function() return climate end
    getTimeInMillis = function() return Runtime.now end
    getTimestampMs = function() return Runtime.now end
    getSpecificPlayer = function(index) return index == 0 and player or nil end
    getPlayer = function() return player end
    instanceof = function(value, className)
        return value == player and className == "IsoGameCharacter"
    end
    isServer = function() return runtime.mode == "multiplayer" end
    isClient = function() return runtime.mode == "multiplayer" end

    PsychopatzCore = PsychopatzCore or {}
    PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}
    PsychopatzCore.Conversation.Text = PsychopatzCore.Conversation.Text or {}
    if type(PsychopatzCore.Conversation.Text.Resolve) ~= "function" then
        PsychopatzCore.Conversation.Text.Resolve = function(value)
            return value and (value.fallback or value.text) or ""
        end
    end
    if type(PsychopatzCore.Conversation.Text.RegisterFallback) ~= "function" then
        PsychopatzCore.Conversation.Text.RegisterFallback = function(key, value)
            Runtime.fallbacks = Runtime.fallbacks or {}
            Runtime.fallbacks[key] = value
            return value
        end
    end
    PsychopatzCore.RuntimeRole = {
        AllowsServerCode = function() return true end,
    }
    PsychopatzCore.DebugTrace = {
        IsEnabled = function() return true end,
        Record = function(definition)
            Runtime.trace[#Runtime.trace + 1] = copy(definition)
            return true
        end,
    }

    -- Preserve loaded production namespaces across scenario resets. Replacing
    -- PNC or PsychopatzCore here would silently discard the actual parser and
    -- router modules after the first conversation.
    PNC = PNC or {}
    PNC.Core = PNC.Core or {}
    PNC.Core.Now = function() return Runtime.now end
    PNC.Core.DeepCopy = function(value) return copy(value) end
    PNC.Inventory = PNC.Inventory or {}
    PNC.Inventory.EnsureRecordInventory = function(record)
        return normalizeInventory(record and record.inventory)
    end
    PNC.Const = PNC.Const or {}
    PNC.Const.MODULE = "ProjectHoomans"
    PNC.Const.CMD_SEMANTIC_IDENTITY_RESULT = "SemanticIdentityResult"
    PNC.Network = PNC.Network or {}
    PNC.Network.ClientState = PNC.Network.ClientState or {}
    clearTable(PNC.Network.ClientState)
    PNC.Network.ClientState.conversationRelationships = {}
    PNC.Network.ClientState.pendingSemanticIdentity = {}
    PNC.Network.ClientState.characterPayloads = {}
    PNC.Network.Internal = PNC.Network.Internal or {}
    PNC.Semantics = PNC.Semantics or {}
    PNC.Conversation = PNC.Conversation or {}
    PNC.Conversation.Relationship = {
        ReceivePresentation = function() return true end,
    }
    PNC.Registry = PNC.Registry or {}
    PNC.Registry.Get = function(id)
        return tostring(id) == tostring(npcData.npcID) and npcData or nil
    end
    PNC.PlayerCharacters = PNC.PlayerCharacters or {}
    PNC.PlayerCharacters.GetRegistryRecord = function(characterUUID)
            if tostring(characterUUID) ~= tostring(playerData.characterUUID) then
                return nil
            end
            return {
                displayName = playerData.displayName,
                forename = playerData.forename,
                surname = playerData.surname,
            }
    end
    PNC.PlayerContext = PNC.PlayerContext or {}
    PNC.PlayerContext.Resolve = function()
        return {
            characterUUID = playerData.characterUUID,
            playerEntityKey = "player:" .. tostring(playerData.characterUUID),
        }, "harness_resolved"
    end
    PNC.PlayerContext.Peek = PNC.PlayerContext.Resolve
    PNC.Relationships = PNC.Relationships or {}
    PNC.Relationships.Get = function(npcID)
        return relationshipSnapshotFor(npcID)
    end
    PNC.Relationships.ApplyConversationEffect = function(npcID, _, effect, context)
            local relationship = relationshipFor(npcID)
            relationship.approval = number(relationship.approval, 0)
                + number(effect.approval, 0)
            relationship.respect = number(relationship.respect, 0)
                + number(effect.respect, 0)
            relationship.familiarity = number(relationship.familiarity, 0)
                + number(effect.familiarity, 0)
            relationship.revision = number(relationship.revision, 0) + 1
            if effect.tags and effect.tags.untrustworthy then
                relationship.identityTrust = "untrustworthy"
            elseif effect.tags and effect.tags.truthful then
                relationship.identityTrust = "trusted"
            end
            return true, "applied", {
                eventID = context and context.eventID,
                memoryID = context and context.eventID,
                memoryType = effect.memoryType,
            }
    end
    PNC.RelationshipPresentation = PNC.RelationshipPresentation or {}
    PNC.RelationshipPresentation.Summarize = function(value)
        return copy(value)
    end
    PNC.NPCKnowledgeAPI = PNC.NPCKnowledgeAPI or {}
    PNC.NPCKnowledgeAPI.DiscloseForPlayer = function(_, options)
            npcData.identityState = "known"
            PNC.Network.ClientState.npcPresentations =
                PNC.Network.ClientState.npcPresentations or {}
            PNC.Network.ClientState.npcPresentations[npcData.npcID] = {
                state = "known",
                displayName = identityName(npcData),
            }
            if Runtime.view and Runtime.view.spec
                and Runtime.view.spec.context
            then
                Runtime.view.spec.context.identityState = "known"
            end
            Runtime.disclosures = number(Runtime.disclosures, 0) + 1
            Runtime.knowledge = options
            return { revealed = { "identity.name" } }
    end
    PNC.PlayerKnowledgeCommands = PNC.PlayerKnowledgeCommands or {}
    PNC.PlayerKnowledgeCommands.Internal = PNC.PlayerKnowledgeCommands.Internal or {}
    PNC.PlayerKnowledgeCommands.Internal.SafeID = function(value)
            value = tostring(value or "")
            return value ~= "" and value or nil
    end
    PNC.PlayerKnowledgeCommands.Internal.ContextFor = function()
            return {
                characterUUID = playerData.characterUUID,
                playerEntityKey = "player:" .. tostring(playerData.characterUUID),
            }
    end
    PNC.PlayerKnowledgeCommands.Internal.IntroductionText = function()
            return "I'm " .. identityName(npcData) .. "."
    end

    local function serverResult(payload)
        local mode = runtime.mode or "singleplayer"
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "server_to_client",
            mode = mode,
            command = "SemanticIdentityResult",
            payload = copy(payload),
        }
        if mode == "multiplayer" then
            sendServerCommand(player, "ProjectHoomans", "SemanticIdentityResult", payload)
        else
            triggerEvent("OnServerCommand", "ProjectHoomans", "SemanticIdentityResult", payload)
        end
        return true
    end

    triggerEvent = function(eventName, module, command, payload)
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "event",
            eventName = eventName,
            module = module,
            command = command,
            payload = copy(payload),
        }
        if eventName == "OnServerCommand"
            and PNC.Client and PNC.Client.HandleServerCommand
        then
            PNC.Client.HandleServerCommand(command, payload)
        end
    end
    sendServerCommand = function(_, module, command, payload)
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "server_command",
            module = module,
            command = command,
            payload = copy(payload),
        }
        if PNC.Client and PNC.Client.HandleServerCommand then
            PNC.Client.HandleServerCommand(command, payload)
        end
    end
    sendClientCommand = function(_, module, command, payload)
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "client_command",
            module = module,
            command = command,
            payload = copy(payload),
        }
        return true
    end

    PNC.Network.Internal.SendIdentityPayload = function(_, command, payload)
        return serverResult(payload)
    end

    PNC.PBrainZ = {
        IsProviderAvailable = function()
            return runtime.llmEnabled == true and runtime.providerAvailable == true
        end,
        IsBridgeEnabled = function() return runtime.llmEnabled == true end,
        GetProviderStatus = function()
            return {
                ready = runtime.llmEnabled == true and runtime.providerAvailable == true,
                status = runtime.providerAvailable == true and "ready" or "unavailable",
            }
        end,
        Submit = function()
            Runtime.llmCalls = Runtime.llmCalls + 1
            return false, "harness_llm_disabled"
        end,
    }

    -- These are the production client request boundary's semantic contracts.
    -- The server-side validator and client result router remain real Lua.
    PNC.Client = PNC.Client or {}
    PNC.Client.Internal = PNC.Client.Internal or {}
    PNC.Client.RequestNPCKnowledgeTopic = function(npcID, topicID, options)
            Runtime.transport[#Runtime.transport + 1] = {
                direction = "client_to_server",
                mode = runtime.mode,
                command = "KnowledgeDisclosureRequest",
                payload = {
                    npcID = npcID,
                    topicID = topicID,
                    options = copy(options),
                },
            }
            return true
    end
    PNC.Client.RequestSemanticInventoryQuery = function(request, context)
            request = type(request) == "table" and request or {}
            Runtime.transport[#Runtime.transport + 1] = {
                direction = "client_to_server",
                mode = runtime.mode,
                command = "SemanticInventoryQuery",
                payload = copy(request),
            }
            local service = PNC.Semantics
                and PNC.Semantics.InventoryQueryService or nil
            local result = service and type(service.HandleRequest) == "function"
                and service.HandleRequest(request, {
                    internal = true,
                    npcID = request.npcID,
                    player = player,
                }) or {
                    accepted = false,
                    status = "failed",
                    reason = "inventory_service_unavailable",
                    requestID = request.requestID,
                    npcID = request.npcID,
                    query = copy(request.query),
                    items = {},
                    totalCount = 0,
                    distinctItems = 0,
                }
            Runtime.transport[#Runtime.transport + 1] = {
                direction = "server_to_client",
                mode = runtime.mode,
                command = "SemanticInventoryQueryResult",
                payload = copy(result),
            }
            return result.accepted == true, result.reason, result
    end
    PNC.Client.SubmitSemanticIdentity = function(npcID, options)
            local requestID = "identity_exchange:" .. tostring(Runtime.turn)
            local args = {
                requestID = requestID,
                npcID = npcID,
                kind = options and options.kind,
                claimedName = options and options.claimedName,
                conversationToken = options and options.conversationToken,
                origin = options and options.origin,
            }
            Runtime.transport[#Runtime.transport + 1] = {
                direction = "client_to_server",
                mode = runtime.mode,
                command = "SemanticIdentityRequest",
                payload = copy(args),
            }
            local Commands = PNC.PlayerKnowledgeCommands
            if not Commands or type(Commands.HandleSemanticIdentity) ~= "function" then
                return false, "identity_authority_unavailable"
            end
            return Commands.HandleSemanticIdentity(player, args)
    end

    local function itemDisplayName(item)
        return tostring(item and (item.displayName or item.customName
            or item.fullType or item.type) or "item")
    end

    local function queueGiftResult(result, itemTypes)
        local first = itemTypes and itemTypes[1] or "item"
        local display = tostring(first or "item")
        local source = npcInventory.items
        for _, item in pairs(source or {}) do
            if tostring(item.fullType or item.type or "") == display then
                display = itemDisplayName(item)
                break
            end
        end
        local payload = {
            key = "semantic.gift.received",
            text = "Thank you for the " .. display .. ".",
            fallback = "Thank you for the " .. display .. ".",
            args = { giftItemName = display },
        }
        Runtime.queued[#Runtime.queued + 1] = {
            speaker = "npc",
            payload = payload,
            metadata = {
                source = { kind = "semantic", channel = "gift_result" },
                provenance = {
                    provider = "mock_authoritative_inventory",
                    parser = "production_gift_selection",
                },
            },
        }
        Runtime.transcript[#Runtime.transcript + 1] = Runtime.queued[#Runtime.queued]
        return result
    end

    PNC.Client.SendInventoryTransfer = function(args)
            args = type(args) == "table" and args or {}
            local itemIDs = type(args.itemIDs) == "table" and args.itemIDs or {}
            local requested = args.quantity ~= nil
                and math.max(1, math.floor(number(args.quantity, 1))) or nil
            Runtime.transport[#Runtime.transport + 1] = {
                direction = "client_to_server",
                mode = runtime.mode,
                command = "InventoryTransfer",
                payload = copy(args),
            }
            if tostring(args.direction or "") ~= "player_to_npc"
                or tostring(args.id or "") ~= tostring(npcData.npcID or "")
            then
                return false, "invalid_direction"
            end
            local moved = 0
            local remaining = requested
            local itemTypes = {}
            local newItemIDs = {}
            for index = 1, #itemIDs do
                local sourceID = tostring(itemIDs[index] or "")
                local sourceItem = playerInventory.items[sourceID]
                if not sourceItem then return false, "item_not_found" end
                local available = math.max(1, math.floor(number(sourceItem.stack, 1)))
                local amount = remaining and math.min(available, remaining) or available
                if amount > 0 then
                    local newID = "npc_gift_" .. tostring(Runtime.turn)
                        .. "_" .. tostring(index)
                    local gifted = copy(sourceItem)
                    gifted.id = newID
                    gifted.itemID = newID
                    gifted.stack = amount
                    gifted.container = args.npcContainer or "root"
                    npcInventory.items[newID] = gifted
                    itemTypes[#itemTypes + 1] = gifted.fullType or gifted.type
                    newItemIDs[#newItemIDs + 1] = newID
                    moved = moved + amount
                    available = available - amount
                    if available > 0 then
                        sourceItem.stack = available
                    else
                        playerInventory.items[sourceID] = nil
                    end
                    if remaining then
                        remaining = remaining - amount
                        if remaining <= 0 then break end
                    end
                end
            end
            if moved < 1 or (remaining and remaining > 0) then
                return false, "quantity_unavailable"
            end
            playerInventory.revision = playerInventory.revision + 1
            npcInventory.revision = npcInventory.revision + 1
            local effect = PNC.Gifts and PNC.Gifts.EvaluateEffect
                and PNC.Gifts.EvaluateEffect(itemTypes) or {
                    approval = 0, respect = 0, familiarity = 0,
                }
            local before = relationshipSnapshotFor(npcData.npcID)
            local applied, applyReason, relationshipResult =
                PNC.Relationships.ApplyConversationEffect(
                    npcData.npcID,
                    "player:" .. tostring(playerData.characterUUID),
                    effect,
                    { eventID = "gift:" .. tostring(Runtime.turn) }
                )
            local after = relationshipSnapshotFor(npcData.npcID)
            local details = {
                itemTypes = itemTypes,
                itemIDs = newItemIDs,
                itemCount = moved,
                giftEffect = effect,
                relationshipBefore = before,
                relationshipAfter = after,
                relationshipDelta = {
                    approval = after.approval - before.approval,
                    respect = after.respect - before.respect,
                    familiarity = after.familiarity - before.familiarity,
                },
                eventID = relationshipResult and relationshipResult.eventID
                    or "gift:" .. tostring(Runtime.turn),
                applied = applied == true,
                applyReason = applyReason,
                giftReplyKey = "gift.received." .. tostring(effect.kind or "general"),
            }
            local result = {
                success = true,
                reason = "transferred_to_npc",
                npcId = npcData.npcID,
                requestId = args.requestId,
                gift = args.gift == true,
            }
            for key, value in pairs(details) do result[key] = copy(value) end
            Runtime.transport[#Runtime.transport + 1] = {
                direction = "server_to_client",
                mode = runtime.mode,
                command = "InventoryResult",
                payload = copy(result),
            }
            local payload = args.gift == true and queueGiftResult(result, itemTypes)
                or result
            if PNC.Network.ClientState.characterPayloads then
                PNC.Network.ClientState.characterPayloads[npcData.npcID] = {
                    inventory = { revision = npcInventory.revision },
                }
            end
            return true, "transferred_to_npc", payload
    end

    -- The production command adapter stops at Client.SendCompanionCommand;
    -- the native implementation owns Java/world validation and authoritative
    -- server execution. Keep that seam configurable so the harness can show
    -- the real action dispatch without pretending to mutate the world.
    PNC.Client.SendCompanionCommand = function(commandID, npcID, scope, context)
        local responses = runtime.commandResponses or {}
        local configured = responses[tostring(commandID)]
        local accepted = true
        local reason = "network_queued"
        local targets = { tostring(npcID or "") }
        local details = {}
        if configured == false then
            accepted = false
            reason = "mock_command_rejected"
        elseif type(configured) == "table" then
            if configured.accepted ~= nil then
                accepted = configured.accepted == true
            end
            reason = tostring(configured.reason
                or (accepted and "network_queued" or "mock_command_rejected"))
            targets = copy(configured.targets or targets)
            details = copy(configured.details or {})
        end
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "client_to_server",
            mode = runtime.mode,
            command = "CompanionCommand",
            payload = {
                commandID = tostring(commandID or ""),
                id = tostring(npcID or ""),
                scope = tostring(scope or ""),
                requestID = context and context.requestID,
                commandSource = context and context.commandSource,
                campSiteHint = context and copy(context.campSiteHint),
            },
        }
        return accepted, reason, targets, details
    end
end

local function loadProductionModules()
    local testSource = repository .. "/tests/support/test.lua"
    local Test = dofile(testSource)
    Test.addPackagePaths()

    local originalRequire = require
    local originalInputClass = PsychopatzConversationLLMInput
    local headlessModules = {
        ["ISUI/ISButton"] = "native_ui",
        ["ISUI/ISPanel"] = "native_ui",
        ["PsychopatzCore/UI/PsychopatzUI"] = "native_ui",
        ["PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"] = "native_ui",
        ["PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"] = "native_ui",
    }

    Runtime.moduleManifest = {}
    Runtime.loadedModules = {}
    local function load(mod, layer, relative, role)
        local value = Test.load(mod, layer, relative)
        Runtime.moduleManifest[#Runtime.moduleManifest + 1] = {
            path = mod .. ":" .. layer .. ":" .. relative,
            role = role or "production",
            status = "loaded",
        }
        Runtime.loadedModules[#Runtime.loadedModules + 1] = relative
        return value
    end

    PsychopatzConversationLLMInput = {
        new = function(_, x, y, width, height, options)
            return { x = x, y = y, width = width, height = height, options = options }
        end,
    }

    local Semantic = load(
        "PsychopatzCore", "common",
        "PsychopatzCore/Semantics/PsychopatzSemantic.lua", "semantic"
    )
    load("PsychopatzCore", "common", "PsychopatzCore/Translation/PsychopatzCustomTranslationManager.lua", "translation")
    load("PsychopatzCore", "common", "PsychopatzCore/Translation/PsychopatzCoreTranslation.lua", "translation")
    load("ProjectHoomans", "shared", "PNC/Translation/PNC_TranslationBootstrap.lua", "translation")
    load("PsychopatzCore", "common_client", "PsychopatzCore/UI/Conversation/PsychopatzConversationText.lua", "conversation_text")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticMarketSenseAdapter.lua", "inventory")
    load("ProjectHoomans", "shared", "PNC/Gifts/PNC_GiftMarketSenseAdapter.lua", "inventory")
    load("ProjectHoomans", "shared", "PNC/Conversation/PNC_ConversationGifts.lua", "inventory")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticInventoryQuery.lua", "inventory")
    load("ProjectHoomans", "server", "PNC/Semantics/Inventory/PNC_SemanticItemSelector.lua", "inventory")
    load("ProjectHoomans", "server", "PNC/Semantics/Inventory/PNC_SemanticInventoryQueryService.lua", "inventory")
    load("ProjectHoomans", "shared", "PNC/Conversation/PNC_ConversationToolReplyCatalog.lua", "tool_catalog")
    load("ProjectHoomans", "shared", "PNC/Conversation/PNC_ConversationToolReplies.lua", "tool_replies")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticCatalog.lua", "semantic")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticDialoguePolicy.lua", "semantic")
    load("ProjectHoomans", "client", "PNC/Semantics/PNC_SemanticDialogueInput_Context.lua", "semantic")
    load("ProjectHoomans", "client", "PNC/Semantics/PNC_SemanticDialogueInput_Presentation.lua", "semantic")
    load("ProjectHoomans", "client", "PNC/Semantics/PNC_SemanticDialogueInput_Actions.lua", "semantic")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticIdentityExchange.lua", "semantic")
    load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticIdentityNetwork.lua", "semantic")
    load(
        "ProjectHoomans", "server",
        "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_Core.lua",
        "authority"
    )
    load("ProjectHoomans", "server", "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_Identity.lua", "authority")

    -- The production root references a small native UI dependency closure.
    -- Only those named edges may be replaced in headless mode. Any unexpected
    -- missing module or runtime error must fail startup instead of becoming a
    -- false-green semantic test.
    require = function(name)
        local ok, value = pcall(originalRequire, name)
        if ok then return value end
        local reason = tostring(value or "require_failed")
        local role = headlessModules[name]
        if role then
            Runtime.headlessRequires[name] = {
                role = role,
                reason = reason,
            }
            return true
        end
        error("unexpected production require failure for " .. tostring(name)
            .. ": " .. reason)
    end
    load("ProjectHoomans", "client", "PNC/Semantics/PNC_SemanticDialogueInput.lua", "semantic_entry")
    require = originalRequire

    load("ProjectHoomans", "client", "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Registry.lua", "network")
    load("ProjectHoomans", "client", "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_SemanticIdentity.lua", "network")

    PsychopatzConversationLLMInput = originalInputClass
    installTranslationInstrumentation()
    if type(Semantic) ~= "table" then error("semantic core failed to load") end
end

local function buildContext()
    local scenario = Runtime.scenario or {}
    local npc = scenario.npc or {}
    local world = scenario.world or {}
    local conversation = scenario.conversation or {}
    local player = scenario.player or {}
    local relationship = relationshipFor(npc.npcID)
    return {
        identityState = npc.identityState or "unknown",
        npcName = identityName(npc),
        npcFullName = identityName(npc),
        npcFirstName = npc.forename,
        npcState = {
            traits = copy(npc.traits or {}),
            identityState = npc.identityState or "unknown",
            needs = {
                hunger = number(world.hunger, 0),
                thirst = number(world.thirst, 0),
                fatigue = number(world.fatigue, 0),
            },
        },
        relationshipState = relationship.relationshipState
            or npc.relationshipState or "unknown",
        identityTrust = relationship.identityTrust,
        relationship = copy(relationship),
        npcTraits = copy(npc.traits or {}),
        npcPersonality = copy(npc.personality or {}),
        player = nil,
        playerNameKnown = true,
        playerName = playerName(player),
        characterUUID = player.characterUUID,
        conversationTopic = conversation.topic or "greeting",
        conversationLifecycleState = { token = conversation.token or "harness-lease" },
        entry = {
            snapshot = {
                activeBehavior = "idle",
                healthState = "healthy",
                needs = {
                    hunger = number(world.hunger, 0),
                    thirst = number(world.thirst, 0),
                    fatigue = number(world.fatigue, 0),
                    stress = number(world.stress, 0),
                    boredom = number(world.boredom, 0),
                    panic = number(world.panic, 0),
                },
            },
        },
    }
end

local function buildView()
    local scenario = Runtime.scenario or {}
    local npc = scenario.npc or {}
    local player = scenario.player or {}
    local session = {
        characterUUID = player.characterUUID,
        conversationID = "harness-conversation",
        append = function(self, speaker, value, metadata)
            local message = {
                speaker = speaker,
                value = value,
                metadata = copy(metadata),
            }
            self.lastAppend = message
            Runtime.transcript[#Runtime.transcript + 1] = message
            if speaker == "npc" then
                Runtime.queued[#Runtime.queued + 1] = {
                    speaker = speaker,
                    payload = copy(value),
                    metadata = copy(metadata),
                }
            end
            return { messageID = "harness-message-" .. tostring(#Runtime.transcript) }
        end,
        queueMessage = function(self, speaker, payload, metadata)
            local message = {
                speaker = speaker,
                payload = copy(payload),
                metadata = copy(metadata),
            }
            self.lastQueued = message
            Runtime.queued[#Runtime.queued + 1] = message
            Runtime.transcript[#Runtime.transcript + 1] = message
        end,
    }
    local view = {
        headless = true,
        lifecycleFinished = false,
        spec = {
            npcID = npc.npcID,
            context = buildContext(),
        },
        session = session,
    }
    return view
end

local function relationshipSnapshot()
    local scenario = Runtime.scenario or {}
    local npc = scenario.npc or {}
    return copy(relationshipFor(npc.npcID))
end

local function contextSnapshot(view)
    local session = view and view.session
    local context = session and session.semanticDialogueContext
    local semanticState = session and session.semanticDialogueState
    return {
        dialogue = context and context.ToContext and context:ToContext() or nil,
        state = semanticState and semanticState.Snapshot and semanticState:Snapshot() or nil,
    }
end

local function normalizedToolCalls(trace, transport, result, actionResult)
    local calls = {}
    local labels = {
        KnowledgeDisclosureRequest = "ask_name",
        SemanticIdentityRequest = "validate_identity",
        SemanticInventoryQuery = "query_inventory",
        InventoryTransfer = "transfer_item",
        CompanionCommand = "companion_command",
        AdjustRelationship = "adjust_relationship",
    }
    local function add(kind, name, values)
        name = tostring(name or "")
        if name == "" then return end
        values = type(values) == "table" and values or {}
        calls[#calls + 1] = {
            kind = kind,
            name = name,
            label = labels[name] or name,
            callID = values.callID or values.call_id or values.id,
            requestID = values.requestID or values.request_id
                or result and result.sequence,
            arguments = copy(values.arguments or values.args),
            status = values.status
                or (values.accepted == true and "accepted" or nil),
            accepted = values.accepted,
            reason = values.reason,
            authority = values.authority or values.mode or "mock",
            source = values.source or "production_trace",
        }
    end

    for _, event in ipairs(trace or {}) do
        local eventName = tostring(event and event.event or "")
        local data = event and event.data or {}
        if string.find(eventName, "tool", 1, true)
            or string.find(eventName, "command.dispatch", 1, true)
            or string.find(eventName, "task.dispatch", 1, true)
        then
            add(string.find(eventName, "tool", 1, true)
                    and "tool_call" or "action_dispatch",
                data.name or data.toolName or data.tool
                    or data.action or data.commandID or data.command,
                data)
        end
    end

    if type(actionResult) == "table" then
        add("action_dispatch", actionResult.action or actionResult.commandID
            or actionResult.taskID, actionResult)
    end

    for _, event in ipairs(transport or {}) do
        local command = event and event.command
        if command == "SemanticIdentityRequest"
            or command == "KnowledgeDisclosureRequest"
            or command == "SemanticInventoryQuery"
            or command == "InventoryTransfer"
        then
            add("authority_request", command, {
                arguments = event.payload,
                authority = event.mode or "mock",
                source = "transport",
                status = "sent",
            })
        elseif event.direction == "server_to_client"
            and type(event.payload) == "table"
            and type(event.payload.relationshipDelta) == "table"
        then
            add("relationship_adjustment", "AdjustRelationship", {
                arguments = event.payload,
                authority = "server",
                source = "transport",
                status = "applied",
                accepted = true,
            })
        end
    end
    return calls
end

local function translationSnapshot()
    local manager = translationManager()
    local diagnostics
    if manager and type(manager.GetTranslationAuditSnapshot) == "function" then
        local ok, value = pcall(manager.GetTranslationAuditSnapshot)
        if ok then diagnostics = value end
    end
    return {
        language = currentLanguage(),
        lookupCount = #Runtime.translationLookups,
        lookups = copy(Runtime.translationLookups),
        audit = diagnostics,
    }
end

local function toolReply(payload)
    payload = type(payload) == "table" and payload or {}
    local results = type(payload.results) == "table"
        and payload.results or {}
    local replies = PNC.Conversation
        and PNC.Conversation.ToolReplies or nil
    if not replies or type(replies.Build) ~= "function" then
        return { ok = false, error = "tool_reply_catalog_unavailable" }
    end
    local before = #Runtime.translationLookups
    local value = replies.Build(results, payload.context or {})
    local toolName = ""
    for _, result in ipairs(results) do
        local name = tostring(result and result.name or "")
        if name == "ask_name" then
            toolName = name
            break
        end
        if toolName == "" and name == "social_react" then
            toolName = name
        elseif toolName == "" and string.sub(name, 1, 6) == "order_" then
            toolName = name
        end
    end
    local lookups = {}
    for index = before + 1, #Runtime.translationLookups do
        lookups[#lookups + 1] = copy(Runtime.translationLookups[index])
    end
    return {
        ok = true,
        type = "tool_reply",
        language = currentLanguage(),
        text = value,
        results = copy(results),
        toolCalls = {
            {
                kind = "tool_call",
                name = toolName,
                label = toolName,
                status = "resolved",
                source = "production_tool_reply_catalog",
            },
        },
        translationLookups = lookups,
        loadedModules = Runtime.loadedModules,
    }
end

local function setLanguage(value)
    local selected = language(value)
    local scenario = Runtime.scenario or {}
    scenario.runtime = scenario.runtime or {}
    scenario.runtime.language = selected
    local manager = translationManager()
    if manager and type(manager.setLanguageOverride) == "function" then
        manager.setLanguageOverride(selected)
    end
    Runtime.translationLanguage = currentLanguage()
    return {
        ok = true,
        type = "language",
        language = Runtime.translationLanguage,
        translation = translationSnapshot(),
    }
end

local function turn(text)
    Runtime.turn = Runtime.turn + 1
    Runtime.now = Runtime.now + 1
    local view = Runtime.view
    local queuedBefore = #Runtime.queued
    local transcriptBefore = #Runtime.transcript
    local traceBefore = #Runtime.trace
    local transportBefore = #Runtime.transport
    local translationBefore = #Runtime.translationLookups
    local relationshipBefore = relationshipSnapshot()
    local contextBefore = contextSnapshot(view)
    local accepted, reason = PNC.Semantics.DialogueInput.Submit(view, text)
    local result = view.lastSemanticDialogueResult
    local newMessages = {}
    local newTrace = {}
    local newTransport = {}
    local newTranslations = {}
    local index
    for index = queuedBefore + 1, #Runtime.queued do
        newMessages[#newMessages + 1] = copy(Runtime.queued[index])
    end
    for index = transcriptBefore + 1, #Runtime.transcript do
        -- Transcript includes player input and queued NPC lines; preserve both.
    end
    for index = traceBefore + 1, #Runtime.trace do
        newTrace[#newTrace + 1] = copy(Runtime.trace[index])
    end
    for index = transportBefore + 1, #Runtime.transport do
        newTransport[#newTransport + 1] = copy(Runtime.transport[index])
    end
    for index = translationBefore + 1, #Runtime.translationLookups do
        newTranslations[#newTranslations + 1] = copy(Runtime.translationLookups[index])
    end
    local actionResult = view.lastSemanticActionResult
    local toolCalls = normalizedToolCalls(
        newTrace, newTransport, result, actionResult)
    return {
        ok = true,
        type = "turn",
        input = text,
        accepted = accepted == true,
        reason = reason,
        result = result and {
            accepted = result.accepted == true,
            reason = result.reason,
            sequence = result.sequence,
            ir = copy(result.ir),
            decision = copy(result.decision),
            actionResult = copy(actionResult),
        } or nil,
        messages = newMessages,
        trace = newTrace,
        transport = newTransport,
        toolCalls = toolCalls,
        translation = {
            language = currentLanguage(),
            lookups = newTranslations,
        },
        relationshipBefore = relationshipBefore,
        relationshipAfter = relationshipSnapshot(),
        contextBefore = contextBefore,
        contextAfter = contextSnapshot(view),
        llmCalls = Runtime.llmCalls,
        loadedModules = Runtime.loadedModules,
    }
end

local function resetScenario(scenario)
    Runtime.scenario = scenario
    resetContainers()
    configureGlobals()
    setLanguage(scenarioLanguage())
    Runtime.view = buildView()
    PNC.Network.ClientState.conversationRelationships = {}
    PNC.Network.ClientState.pendingSemanticIdentity = {}
    PNC.Network.ClientState.identityTrust = {}
    PNC.Network.ClientState.semanticIdentityResults = {}
    PNC.Network.ClientState.npcPresentations = {}
    local npc = scenario.npc or {}
    PNC.Network.ClientState.conversationRelationships[npc.npcID] = relationshipSnapshot()
    PNC.Network.ClientState.characterPayloads[npc.npcID] = {
        inventory = {
            revision = number(npc.inventory and npc.inventory.revision, 1),
        },
    }
    return {
        ok = true,
        type = "configured",
        scenario = copy(scenario),
        loadedModules = Runtime.loadedModules,
        moduleManifest = copy(Runtime.moduleManifest),
        headlessRequires = copy(Runtime.headlessRequires),
        translation = translationSnapshot(),
    }
end

local function snapshot()
    return {
        ok = true,
        type = "snapshot",
        scenario = copy(Runtime.scenario),
        transcript = copy(Runtime.transcript),
        queued = copy(Runtime.queued),
        relationship = relationshipSnapshot(),
        context = contextSnapshot(Runtime.view),
        transport = copy(Runtime.transport),
        trace = copy(Runtime.trace),
        translation = translationSnapshot(),
        llmCalls = Runtime.llmCalls,
        loadedModules = Runtime.loadedModules,
        moduleManifest = copy(Runtime.moduleManifest),
        headlessRequires = copy(Runtime.headlessRequires),
    }
end

local initialScenario = {
    player = {
        characterUUID = "char_patrick",
        forename = "Patrick",
        surname = "Patz",
        displayName = "Patrick Patz",
    },
    npc = {
        npcID = "npc_mara",
        forename = "Mara",
        surname = "Vale",
        identityState = "unknown",
        traits = { "reserved" },
        relationship = { approval = 0, respect = 0, familiarity = 0, revision = 1 },
    },
    world = { hunger = 0.2, thirst = 0.4, fatigue = 0.1, timeOfDay = 13.5, worldAgeHours = 49.5 },
    conversation = { topic = "greeting", token = "harness-lease" },
    runtime = { mode = "singleplayer", language = "EN", llmEnabled = false, providerAvailable = false },
}

configureGlobals()
loadProductionModules()
resetScenario(initialScenario)

emit({
    ok = true,
    type = "hello",
    worker = "project_hoomans_semantic_harness",
    capabilities = { "CONFIG", "RESET", "INPUT", "LANGUAGE", "TOOL_REPLY", "SNAPSHOT", "PING", "CAPABILITIES", "QUIT" },
    loadedModules = Runtime.loadedModules,
    moduleManifest = Runtime.moduleManifest,
    headlessRequires = Runtime.headlessRequires,
    translation = translationSnapshot(),
}, "__hello__")

for line in io.lines() do
    local request, reason = readRequest(line)
    if not request then
        io.stderr:write("protocol error: " .. tostring(reason) .. "\n")
        break
    end
    local requestID = request.id
    local command = request.command
    local payload = request.payload
    if command == "CONFIG" then
        if type(payload) ~= "table" then
            fail(requestID, "scenario_must_be_object")
        else
            emit(resetScenario(payload), requestID)
        end
    elseif command == "RESET" then
        emit(resetScenario(copy(Runtime.scenario)), requestID)
    elseif command == "INPUT" then
        if payload == nil then
            fail(requestID, "input_required")
        else
            emit(turn(tostring(payload)), requestID)
        end
    elseif command == "LANGUAGE" then
        if payload == nil then
            fail(requestID, "language_required")
        else
            emit(setLanguage(type(payload) == "table" and payload.language or payload), requestID)
        end
    elseif command == "TOOL_REPLY" then
        emit(toolReply(payload), requestID)
    elseif command == "SNAPSHOT" then
        emit(snapshot(), requestID)
    elseif command == "PING" then
        emit({
            ok = true,
            type = "pong",
            worker = "project_hoomans_semantic_harness",
            state = "ready",
        }, requestID)
    elseif command == "CAPABILITIES" then
        emit({
            ok = true,
            type = "capabilities",
            protocolVersion = PROTOCOL_VERSION,
            capabilities = { "CONFIG", "RESET", "INPUT", "LANGUAGE", "TOOL_REPLY", "SNAPSHOT", "PING", "CAPABILITIES", "QUIT" },
            loadedModules = Runtime.loadedModules,
            moduleManifest = Runtime.moduleManifest,
            headlessRequires = Runtime.headlessRequires,
            translation = translationSnapshot(),
        }, requestID)
    elseif command == "QUIT" then
        emit({ ok = true, type = "closed" }, requestID)
        break
    elseif command ~= "" then
        fail(requestID, "unknown_command:" .. tostring(command))
    end
end
