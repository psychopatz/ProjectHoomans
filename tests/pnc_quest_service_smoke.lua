local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local now = 2000
local globalData = {}
local emitted = {}
local listeners = {}

local function deepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, entry in pairs(value) do
        output[deepCopy(key, seen)] = deepCopy(entry, seen)
    end
    return output
end

ModData = {
    get = function(key) return globalData[key] end,
    getOrCreate = function(key)
        globalData[key] = globalData[key] or {}
        return globalData[key]
    end,
}

local giver = { id = "doctor-1", alive = true }
local medicalTask = {
    id = "medical:clinic-1",
    status = "WAITING_FOR_SUPPLY",
    blockedReason = "missing_bandage",
    supplyRequesterId = giver.id,
    supplyRequestId = "medical-bandage:clinic-1:1",
}

PNC = {
    Core = {
        Now = function() return now end,
        DeepCopy = deepCopy,
        IsAuthority = function() return true end,
    },
    Registry = {
        Get = function(id)
            return tostring(id) == giver.id and giver or nil
        end,
    },
    MedicalCareService = {
        List = function() return { medicalTask } end,
    },
    Tasking = { Events = {
        Emit = function(eventType, details)
            local event = deepCopy(details or {})
            event.type = eventType
            event.id = event.id or ("event:" .. tostring(#emitted + 1))
            emitted[#emitted + 1] = {
                type = eventType,
                details = details,
            }
            for _, listener in ipairs(listeners[eventType] or {}) do
                listener({ npcId = event.npcId }, event)
            end
            return true, { type = eventType }
        end,
        Subscribe = function(eventType, listener)
            listeners[eventType] = listeners[eventType] or {}
            listeners[eventType][#listeners[eventType] + 1] = listener
            return true
        end,
    } },
}

local definitions = T.load("ProjectHoomans", "shared",
    "PNC/Quests/PNC_QuestDefinitions.lua")
local repository = T.load("ProjectHoomans", "server",
    "PNC/Quests/PNC_QuestRepository.lua")
local service = T.load("ProjectHoomans", "server",
    "PNC/Quests/PNC_QuestService.lua")
local player = { characterUUID = "character-1" }
local questID = "pnc.quest.clinic_supplies"

local offer, offerReason = service.OfferQuest(player, questID, giver.id)
T.truthy(offer, "clinic supplies quest offer exists")
T.equal(offerReason, "available", "medical supply task gates offer")
T.equal(offer.status, "AVAILABLE", "offer does not allocate state")
T.equal(offer.sourceTaskID, medicalTask.id,
    "offer binds the existing medical supply task")

local active, acceptReason = service.AcceptQuest(
    player, questID, giver.id, { expectedRevision = offer.revision })
T.truthy(active, "quest accepted by authoritative service")
T.equal(acceptReason, "accepted", "quest acceptance result")
T.equal(active.status, "ACTIVE", "accepted quest is active")
T.equal(active.ownerCharacterUUID, player.characterUUID,
    "quest is scoped to the accepting character")

local freeText = service.ApplyObjectiveEvent({
    type = "ConversationClaim",
    id = "claim:1",
    payload = {
        committed = true,
        direction = "player_to_npc",
        targetNPCID = giver.id,
        playerCharacterUUID = player.characterUUID,
        itemTypes = { "Base.Bandage" },
        medicalSupplyTaskID = medicalTask.id,
    },
})
T.falsy(freeText, "free-text claim cannot progress quest")
T.equal(service.GetInstance(player, questID, giver.id).status, "ACTIVE",
    "free-text claim leaves quest active")

local transferEvent = {
    type = service.INVENTORY_EVENT,
    id = "transfer:clinic-1",
    payload = {
        committed = true,
        direction = "player_to_npc",
        targetNPCID = giver.id,
        playerCharacterUUID = player.characterUUID,
        itemTypes = { "Base.Bandage" },
        itemIDs = { "npc-bandage-1" },
        itemCount = 1,
        requestID = "gift:clinic-1",
        medicalSupplyTaskID = medicalTask.id,
        medicalSupplyRequestID = medicalTask.supplyRequestId,
    },
}
local transferEmitted = PNC.Tasking.Events.Emit(
    service.INVENTORY_EVENT, {
        npcId = giver.id,
        entityId = transferEvent.id,
        payload = transferEvent.payload,
    })
T.truthy(transferEmitted, "inventory authority emits committed transfer event")
local ready, readyReason = service.GetInstance(player, questID, giver.id)
T.truthy(ready, "committed inventory transfer progresses quest")
T.equal(readyReason, nil, "quest lookup succeeds after transfer event")
T.equal(ready.status, "READY_TO_TURN_IN", "quest is ready after delivery")
T.equal(ready.objective.delivered, 1, "one bandage is credited")

local repeatedTransfer, repeatedTransferReason = service.ApplyObjectiveEvent(
    transferEvent)
T.truthy(repeatedTransfer, "repeated transfer event is idempotent")
T.equal(repeatedTransferReason, "already_ready",
    "repeated transfer does not credit a second bandage")
T.equal(repeatedTransfer.revision, ready.revision,
    "repeated transfer does not advance the quest revision")

local stale = service.ApplyObjectiveEvent({
    type = service.INVENTORY_EVENT,
    id = "transfer:wrong-character",
    payload = {
        committed = true,
        direction = "player_to_npc",
        targetNPCID = giver.id,
        playerCharacterUUID = "other-character",
        itemTypes = { "Base.Bandage" },
        requestID = "gift:wrong-character",
        medicalSupplyTaskID = medicalTask.id,
    },
})
T.falsy(stale, "transfer from another character cannot progress quest")

local rewarded, rewardReason = service.SubmitTurnIn(
    player, questID, giver.id, { expectedRevision = ready.revision })
T.truthy(rewarded, "ready quest can be turned in")
T.equal(rewardReason, "rewarded", "turn-in commits authored acknowledgement")
T.equal(rewarded.status, "REWARDED", "quest reaches rewarded terminal state")
T.truthy(rewarded.rewardClaimed, "reward claim is persisted")

local emittedBeforeDuplicate = #emitted
local duplicate, duplicateReason = service.SubmitTurnIn(
    player, questID, giver.id)
T.truthy(duplicate, "repeated turn-in is idempotent")
T.equal(duplicateReason, "already_rewarded", "repeated turn-in is not a second reward")
T.equal(#emitted, emittedBeforeDuplicate,
    "repeated turn-in emits no duplicate reward event")

T.truthy(repository.Save(), "quest state saves to ModData")
repository.Loaded = false
repository.Load(true)
local restored = service.GetInstance(player, questID, giver.id)
T.equal(restored.status, "REWARDED", "quest state survives reload")
T.equal(restored.rewardClaimed, true, "reward dedupe survives reload")

T.finish("pnc_quest_service_smoke")
