-- Dynamic Group Item Sharing / Gifting between teammates in need.
-- Reuses canonical PNC.Inventory, PNC.AnimationScenes + PNC.ActionProps (hand visuals),
-- PNC.Relationships (willingness + approval/respect gain + kinship address terms),
-- and DialogueBeats (Beats.BuildWorldThread / Beats.Emit).
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local SHARE_CHECK_INTERVAL_MS = 12000
local SHARE_PAIR_COOLDOWN_MS = 180000
local SHARE_RADIUS_SQ = 10 * 10
local MAX_TRACKED_KEYS = 32

local lastCheckAt = 0
local pairCooldowns, pairOrder = {}, {}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now()) or 0
end

local function lruPut(map, order, key, val)
    if map[key] == nil then
        while #order >= MAX_TRACKED_KEYS do
            local oldest = table.remove(order, 1)
            map[oldest] = nil
        end
        order[#order + 1] = key
    end
    map[key] = val
end

local function distSq(a, b)
    local dx = (tonumber(a.x) or 0) - (tonumber(b.x) or 0)
    local dy = (tonumber(a.y) or 0) - (tonumber(b.y) or 0)
    return dx * dx + dy * dy
end

local function isEligibleNPC(rec, now)
    if type(rec) ~= "table" or rec.id == nil or rec.alive == false then return false end
    local live = tostring(PNC.Const and PNC.Const.PRESENCE_LIVE or "live")
    if rec.presenceState ~= nil and tostring(rec.presenceState) ~= live then return false end
    local hState = rec.health and string.lower(tostring(rec.health.state or "normal")) or "normal"
    if hState == "downed" or hState == "unconscious" or hState == "dead" or hState == "incapacitated" then
        return false
    end
    local rt = type(rec.runtime) == "table" and rec.runtime or nil
    if rt and (rt.target ~= nil or rt.attackAction ~= nil or rt.combatTarget ~= nil
        or now < (tonumber(rt.inCombatUntil) or 0))
    then
        return false
    end
    return true
end

local function isSameGroup(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    if a.factionId ~= nil and b.factionId ~= nil and tostring(a.factionId) == tostring(b.factionId) then
        return true
    end
    if a.groupId ~= nil and b.groupId ~= nil and tostring(a.groupId) == tostring(b.groupId) then
        return true
    end
    if a.settlementId ~= nil and b.settlementId ~= nil and tostring(a.settlementId) == tostring(b.settlementId) then
        return true
    end
    if a.recruited == true and b.recruited == true then
        return true
    end
    return false
end

local function readNeed(rec, key)
    if type(rec) ~= "table" then return 0 end
    if PNC.IndividualNeeds and type(PNC.IndividualNeeds.Get) == "function" then
        local v = tonumber(PNC.IndividualNeeds.Get(rec, key))
        if v ~= nil then return v end
    end
    local needs = type(rec.needs) == "table" and rec.needs or nil
    return needs and tonumber(needs[key]) or 0
end

local function readAilment(rec, id)
    local ailments = rec and rec.health and rec.health.body and rec.health.body.wholeBodyAilments
        or (rec and rec.bodyHealth and rec.bodyHealth.wholeBodyAilments) or nil
    if type(ailments) ~= "table" then return 0 end
    local e = ailments[id]
    if type(e) == "table" then return tonumber(e.severity) or (e.active == true and 1 or 0) end
    return tonumber(e) or 0
end

local function detectShareableNeed(rec)
    local hunger = readNeed(rec, "hunger")
    local thirst = readNeed(rec, "thirst")
    local starv = readAilment(rec, "starvation")
    local dehyd = readAilment(rec, "dehydration")
    local health = type(rec.health) == "table" and rec.health or {}
    local bleeding = health.bleeding == true or (tonumber(health.bleedingRate) or 0) > 0

    local best = nil
    local function consider(kind, intensity, score)
        if not intensity then return end
        if not best or score > best.score then
            best = { kind = kind, intensity = intensity, score = score }
        end
    end
    if bleeding then
        local rate = tonumber(health.bleedingRate) or 0.5
        consider("bleed", rate >= 0.65 and "critical" or "medium", rate >= 0.65 and 4.0 or 2.8)
    end
    if thirst >= 0.55 or dehyd >= 0.01 then
        local tier = (thirst >= 0.84 or dehyd >= 0.01) and "critical" or "medium"
        consider("drink", tier, (tier == "critical" and 3.6 or 2.4) + thirst)
    end
    if hunger >= 0.45 or starv >= 0.01 then
        local tier = (hunger >= 0.70 or starv >= 0.01) and "critical" or "medium"
        consider("eat", tier, (tier == "critical" and 3.5 or 2.3) + hunger)
    end
    return best
end

local function inventoryItems(rec)
    if type(rec) ~= "table" then return {} end
    local inv = type(rec.inventory) == "table" and rec.inventory or nil
    if not inv and PNC.Inventory and type(PNC.Inventory.EnsureRecordInventory) == "function" then
        inv = PNC.Inventory.EnsureRecordInventory(rec, { reconcileWaterContainer = false })
    end
    if type(inv) ~= "table" then return {} end
    local list = type(inv.items) == "table" and inv.items or inv
    local out = {}
    for key, item in pairs(list) do
        if type(item) == "table" then
            out[#out + 1] = {
                item = item,
                itemID = item.id or item.itemID or (type(key) == "string" and key or nil),
                mapKey = key,
            }
        end
    end
    return out
end

local function itemMatchesNeed(item, needKind)
    if type(item) ~= "table" then return false end
    local ft = tostring(item.type or item.fullType or item.itemType or "")
    local lo = string.lower(ft)
    local util = PNC.ItemUtility
    if util and type(util.Supports) == "function" then
        if needKind == "eat" and util.Supports(item, "food.access") == true then return true end
        if needKind == "drink" and util.Supports(item, "survival.drink.inventory") == true then return true end
        if needKind == "bleed" and (util.Supports(item, "medical.bandage") == true or util.Supports(item, "firstaid.bandage") == true) then
            return true
        end
    end
    if needKind == "eat" then
        if item.isFood == true or (tonumber(item.hungerChange) or 0) < 0 then return true end
        return string.find(lo, "food", 1, true) ~= nil
            or string.find(lo, "canned", 1, true) ~= nil
            or string.find(lo, "beans", 1, true) ~= nil
            or string.find(lo, "chips", 1, true) ~= nil
            or string.find(lo, "bread", 1, true) ~= nil
            or string.find(lo, "apple", 1, true) ~= nil
            or string.find(lo, "jerky", 1, true) ~= nil
            or string.find(lo, "ration", 1, true) ~= nil
    elseif needKind == "drink" then
        if item.isWater == true or (tonumber(item.thirstChange) or 0) < 0 then return true end
        return (string.find(lo, "water", 1, true) ~= nil and string.find(lo, "empty", 1, true) == nil)
            or string.find(lo, "soda", 1, true) ~= nil
            or string.find(lo, "pop", 1, true) ~= nil
            or string.find(lo, "juice", 1, true) ~= nil
    elseif needKind == "bleed" then
        return (string.find(lo, "bandage", 1, true) ~= nil or string.find(lo, "rippedsheets", 1, true) ~= nil)
            and string.find(lo, "dirty", 1, true) == nil
    end
    return false
end

local function findMatchingItems(rec, needKind)
    local entries = inventoryItems(rec)
    local matches = {}
    for i = 1, #entries do
        if itemMatchesNeed(entries[i].item, needKind) then
            matches[#matches + 1] = entries[i]
        end
    end
    return matches
end

local function friendlyItemName(item)
    if type(item) ~= "table" then return "supplies" end
    local name = tostring(item.displayName or item.name or "")
    if name ~= "" then return name end
    local ft = tostring(item.type or item.fullType or "supplies")
    local stripped = string.match(ft, "%.([^%.]+)$") or ft
    stripped = string.gsub(stripped, "(%l)(%u)", "%1 %2")
    return string.lower(stripped)
end

local function getPairRelationship(speaker, addressee)
    if type(speaker) ~= "table" or type(addressee) ~= "table" or addressee.id == nil then
        return nil
    end
    local targetKey = "npc:" .. tostring(addressee.id)
    local relSvc = PNC.Relationships or PNC.RelationshipService
    if relSvc and type(relSvc.GetRelationship) == "function" then
        local ok, rel = pcall(relSvc.GetRelationship, speaker, targetKey)
        if ok and type(rel) == "table" then return rel end
    end
    local rels = speaker.social and speaker.social.relationships or speaker.relationships or nil
    if type(rels) == "table" then
        return rels[targetKey] or rels[tostring(addressee.id)]
    end
    return nil
end

local function isFemaleActor(rec)
    if type(rec) ~= "table" then return false end
    if rec.isFemale == true then return true end
    local g = string.lower(tostring(rec.gender or rec.sex or ""))
    return g == "female" or g == "woman"
end

-- Resolves proper kinship / pronoun-aware terms of address (e.g. father -> "son" / "sweetheart",
-- child -> "Dad" / "Mom", spouse -> "hon", sibling -> "bro" / "sis", fallback -> first name).
function Beats.ResolveKinshipAddress(speaker, addressee, rel)
    local firstName = tostring((addressee and (addressee.name or addressee.fullName)) or "friend")
    firstName = string.match(firstName, "^(%S+)") or firstName
    rel = rel or getPairRelationship(speaker, addressee)
    local bond = type(rel) == "table" and type(rel.bond) == "table" and rel.bond or nil
    local kind = string.lower(tostring(
        (bond and (bond.kind or bond.role or bond.class))
        or (type(rel) == "table" and (rel.relationshipKind or rel.kinship))
        or ""
    ))
    local addrFemale = isFemaleActor(addressee)

    -- Speaker is addressing their child (father/mother -> son/daughter)
    if kind == "child" or kind == "son" or kind == "daughter" or kind == "offspring" then
        if kind == "son" or (kind ~= "daughter" and not addrFemale and (addressee and (addressee.isFemale == false or string.lower(tostring(addressee.gender or "")) == "male"))) then
            return "son", "parent_to_child"
        elseif kind == "daughter" or addrFemale then
            return "sweetheart", "parent_to_child"
        end
        return "kiddo", "parent_to_child"
    end
    -- Speaker is addressing their parent (child -> father/mother)
    if kind == "parent" or kind == "father" or kind == "mother" or kind == "dad" or kind == "mom" then
        if kind == "mother" or kind == "mom" or (kind ~= "father" and kind ~= "dad" and addrFemale) then
            return "Mom", "child_to_parent"
        end
        return "Dad", "child_to_parent"
    end
    if kind == "spouse" or kind == "partner" or kind == "lover" then
        return "hon", "spouse"
    end
    if kind == "sibling" or kind == "brother" or kind == "sister" then
        if kind == "sister" or (kind ~= "brother" and addrFemale) then
            return "sis", "sibling"
        end
        return "bro", "sibling"
    end
    return firstName, kind ~= "" and kind or "teammate"
end

-- Computes willingness probability [0, 1] based on relationship, kinship, traits/personality,
-- need intensity, and donor surplus.
function Beats.EvaluateShareWillingness(donor, recipient, needKind, intensity, donorItemCount)
    local rel = getPairRelationship(donor, recipient)
    local approval = tonumber(rel and rel.approval) or 0
    local state = string.lower(tostring(rel and rel.state or ""))
    local _, kinKind = Beats.ResolveKinshipAddress(donor, recipient, rel)
    local isFamily = (kinKind == "parent_to_child" or kinKind == "child_to_parent"
        or kinKind == "spouse" or kinKind == "sibling" or kinKind == "family")

    if state == "enemy" or state == "rival" or approval < -25 then
        return 0.0
    end

    local donorOwn = (needKind == "eat" and readNeed(donor, "hunger"))
        or (needKind == "drink" and readNeed(donor, "thirst"))
        or (needKind == "bleed" and ((donor.health and donor.health.bleeding == true) and 0.8 or 0))
        or 0
    if donorOwn >= 0.70 and (tonumber(donorItemCount) or 1) <= 1 and not isFamily then
        return 0.0
    end

    local prob = 0.35
    if isFamily then
        prob = prob + 0.45
    elseif state == "friend" or approval >= 40 then
        prob = prob + 0.25
    elseif approval >= 15 then
        prob = prob + 0.12
    elseif approval < 0 then
        prob = prob - 0.20
    end

    local pers = (donor.social and donor.social.personality) or donor.personality or {}
    local compassion = tonumber(pers.compassion) or 0.5
    local materialism = tonumber(pers.materialism) or 0.5
    local loyalty = tonumber(pers.loyalty) or 0.5
    prob = prob + (compassion - 0.5) * 0.35 + (loyalty - 0.5) * 0.15 - (materialism - 0.5) * 0.30

    local traits = type(donor.traits) == "table" and donor.traits or nil
    if traits then
        if traits.Generous == true or traits.Empathetic == true then prob = prob + 0.20 end
        if traits.Selfish == true or traits.Greedy == true then prob = prob - 0.25 end
    end

    if intensity == "critical" then prob = prob + 0.20 end
    if (tonumber(donorItemCount) or 1) >= 2 then
        prob = prob + 0.18
    elseif donorOwn >= 0.45 and not isFamily then
        prob = prob - 0.22
    end

    if prob < 0 then prob = 0 end
    if prob > 0.98 then prob = 0.98 end
    return prob
end

local function cloneItemSpecForTransfer(item, fullType)
    local spec = {
        type = fullType,
        fullType = fullType,
        stack = 1,
    }
    for k, v in pairs(item) do
        if k ~= "id" and k ~= "itemID" and k ~= "container" and k ~= "stack" and k ~= "count" and k ~= "type" and k ~= "fullType" then
            spec[k] = v
        end
    end
    return spec
end

local function removeMaterializedItem(body, fullType)
    if not body or type(body.getInventory) ~= "function" then return end
    local okInv, inv = pcall(body.getInventory, body)
    if not okInv or not inv or type(inv.FindAndReturn) ~= "function" then return end
    local okFound, liveItem = pcall(inv.FindAndReturn, inv, fullType)
    if okFound and liveItem and type(inv.Remove) == "function" then
        pcall(inv.Remove, inv, liveItem)
    end
end

local function transferSharedItem(donor, recipient, entry, reason)
    local item = type(entry) == "table" and entry.item or entry
    if type(item) ~= "table" then return false, "invalid_item" end
    local invSvc = PNC.Inventory
    local reg = PNC.Registry
    local fullType = tostring(item.type or item.fullType or item.itemType or "")
    if fullType == "" then return false, "missing_full_type" end
    local itemID = (type(entry) == "table" and entry.itemID) or item.id or item.itemID
    local txReason = tostring(reason or "provision_teammate_share")
    local spec = cloneItemSpecForTransfer(item, fullType)
    local donorBody = reg and type(reg.GetLiveZombie) == "function" and reg.GetLiveZombie(donor.id) or nil
    local recipBody = reg and type(reg.GetLiveZombie) == "function" and reg.GetLiveZombie(recipient.id) or nil

    -- 1) Authoritative removal from donor via PNC.Inventory.RemoveItems (checked!)
    local removed = false
    local removeReason = "remove_failed"
    if invSvc and type(invSvc.RemoveItems) == "function" and itemID ~= nil then
        local okCall, okRem, rsn = pcall(invSvc.RemoveItems, donor, { itemID }, txReason)
        removed = okCall == true and okRem == true
        removeReason = tostring(rsn or (okCall and "remove_failed" or okRem))
    elseif type(donor.inventory) == "table" then
        local list = type(donor.inventory.items) == "table" and donor.inventory.items or donor.inventory
        for k, v in pairs(list) do
            if v == item or (itemID ~= nil and type(v) == "table" and (v.id == itemID or v.itemID == itemID)) then
                if type(k) == "number" then table.remove(list, k) else list[k] = nil end
                removed = true
                break
            end
        end
    end
    if not removed then
        return false, removeReason
    end

    -- 2) Authoritative add + live-body sync onto recipient (checked, with rollback on failure!)
    local added = false
    local addReason = "add_failed"
    if invSvc and type(invSvc.AddItemsAndSync) == "function" then
        local okCall, okAdd, rsn = pcall(invSvc.AddItemsAndSync, recipient, recipBody, { spec }, "root", txReason)
        added = okCall == true and okAdd == true
        addReason = tostring(rsn or (okCall and "add_failed" or okAdd))
    elseif invSvc and type(invSvc.AddItems) == "function" then
        local okCall, okAdd, rsn = pcall(invSvc.AddItems, recipient, { spec }, "root", txReason)
        added = okCall == true and okAdd == true
        addReason = tostring(rsn or (okCall and "add_failed" or okAdd))
    else
        recipient.inventory = recipient.inventory or { items = {} }
        local list = type(recipient.inventory.items) == "table" and recipient.inventory.items or recipient.inventory
        list[#list + 1] = spec
        added = true
    end

    if not added then
        -- Rollback so the item is never lost if recipient's inventory was full
        if invSvc and type(invSvc.AddItems) == "function" then
            pcall(invSvc.AddItems, donor, { spec }, "root", txReason .. "_rollback")
        end
        return false, addReason
    end

    removeMaterializedItem(donorBody, fullType)
    if reg and type(reg.MarkDirty) == "function" then
        pcall(reg.MarkDirty, donor, "inventory")
        pcall(reg.MarkDirty, recipient, "inventory")
    end
    return true, "transferred"
end

local function faceEachOther(bodyA, recA, bodyB, recB)
    if bodyA and recB and type(bodyA.faceLocation) == "function" then
        pcall(bodyA.faceLocation, bodyA, tonumber(recB.x) or 0, tonumber(recB.y) or 0)
    end
    if bodyB and recA and type(bodyB.faceLocation) == "function" then
        pcall(bodyB.faceLocation, bodyB, tonumber(recA.x) or 0, tonumber(recA.y) or 0)
    end
end

local function playHandoverScenes(donor, recipient, fullType)
    local scenes = PNC.AnimationScenes
    local reg = PNC.Registry
    local donorBody = reg and type(reg.GetLiveZombie) == "function" and reg.GetLiveZombie(donor.id) or nil
    local recipBody = reg and type(reg.GetLiveZombie) == "function" and reg.GetLiveZombie(recipient.id) or nil

    local medInternal = PNC.MedicalCareExecutor and PNC.MedicalCareExecutor.Internal or nil
    if medInternal and type(medInternal.AlignCloseContact) == "function"
        and donorBody and recipBody
    then
        medInternal.AlignCloseContact(donor, donorBody, recipient, recipBody, 0.60)
    end
    faceEachOther(donorBody, donor, recipBody, recipient)

    if scenes and type(scenes.Request) == "function" then
        pcall(scenes.Request, donor, donorBody, "social.item_share_give", {
            reason = "group_item_share",
            propPrimary = fullType,
            propSecondary = fullType,
        })
        pcall(scenes.Request, recipient, recipBody, "social.item_share_receive", {
            reason = "group_item_share",
            propPrimary = fullType,
            propSecondary = fullType,
        })
    else
        donor.runtime = donor.runtime or {}
        donor.runtime.sceneActionProps = { primary = fullType, secondary = fullType }
        recipient.runtime = recipient.runtime or {}
        recipient.runtime.sceneActionProps = { primary = fullType, secondary = fullType }
        if scenes and type(scenes.Start) == "function" then
            pcall(scenes.Start, donor, donorBody, "social.item_share_give")
            pcall(scenes.Start, recipient, recipBody, "social.item_share_receive")
        end
    end
end

local function applyShareRelationshipGain(donor, recipient, intensity, now)
    local relSvc = PNC.Relationships or PNC.RelationshipService
    if not relSvc or type(relSvc.ApplyConversationEffect) ~= "function" then return end
    local worldHours = PNC.Core and type(PNC.Core.NowWorldAgeHours) == "function"
        and PNC.Core.NowWorldAgeHours() or 0
    local isCrit = intensity == "critical"
    pcall(relSvc.ApplyConversationEffect, tostring(recipient.id), "npc:" .. tostring(donor.id), {
        approval = isCrit and 6 or 4,
        respect = isCrit and 4 or 3,
        familiarity = 2,
        memoryType = "shared_essential_item",
        interactionType = "shared_essential_item",
        tags = { social = true, item_share = true, gratitude = true },
    }, {
        worldAgeHours = worldHours,
        sourceSystem = "group_item_share",
        eventID = "share_recv:" .. tostring(recipient.id) .. ":" .. tostring(donor.id) .. ":" .. tostring(math.floor(now)),
    })
    pcall(relSvc.ApplyConversationEffect, tostring(donor.id), "npc:" .. tostring(recipient.id), {
        approval = 2,
        respect = 1,
        familiarity = 1,
        memoryType = "helped_teammate_with_item",
        interactionType = "helped_teammate_with_item",
        tags = { social = true, item_share = true },
    }, {
        worldAgeHours = worldHours,
        sourceSystem = "group_item_share",
        eventID = "share_give:" .. tostring(donor.id) .. ":" .. tostring(recipient.id) .. ":" .. tostring(math.floor(now)),
    })
end

if type(Beats.RegisterHook) == "function" then
    Beats.RegisterHook("npc.group_item_share", {
        eventTypes = { "npc.group_item_share" },
        priority = 58,
        cooldownMs = 0,
        evaluate = function(_, payload)
            if type(Beats.BuildWorldThread) ~= "function" then return nil end
            local donor = payload and payload.donor or nil
            local recipient = payload and payload.recipient or nil
            if type(donor) ~= "table" or type(recipient) ~= "table" then return nil end
            local needKind = tostring(payload.needKind or "eat")
            local intensity = tostring(payload.intensity or "medium")
            return Beats.BuildWorldThread(donor, recipient, {
                refPrefix = "item_share:" .. needKind,
                family = "group_item_share_" .. needKind,
                poolID = "semantic.social.item_share",
                eventType = "group_item_share_beat",
                domain = "social",
                channel = "social",
                topic = "group_item_share",
                openAct = "OFFER",
                openRole = "share_give_" .. needKind,
                replyAct = "THANK",
                replyRole = "share_thanks_" .. needKind,
                delayMs = 1400,
                priority = intensity == "critical" and 62 or 54,
                tokens = {
                    ["addressee.name"] = tostring(payload.donorAddress or recipient.name or "friend"),
                    ["term.address"] = tostring(payload.donorAddress or recipient.name or "friend"),
                    ["slot.giver_address"] = tostring(payload.recipAddress or donor.name or "friend"),
                    ["slot.item"] = tostring(payload.itemName or "supplies"),
                },
                context = {
                    needType = needKind,
                    needUrgency = intensity,
                    kinshipRole = payload.kinshipRole,
                },
            })
        end,
    })
end

function Beats.TryShareItem(donor, recipient, needKind, intensity, opts)
    opts = type(opts) == "table" and opts or {}
    local now = nowMs(opts.now)
    local donorMatches = findMatchingItems(donor, needKind)
    if #donorMatches == 0 then return false, "donor_no_item" end
    local recipMatches = findMatchingItems(recipient, needKind)
    if #recipMatches > 0 and opts.ignoreRecipientStock ~= true then
        return false, "recipient_has_item"
    end

    local prob = Beats.EvaluateShareWillingness(donor, recipient, needKind, intensity, #donorMatches)
    local roll = opts.forceRoll ~= nil and tonumber(opts.forceRoll)
        or (type(ZombRandFloat) == "function" and ZombRandFloat(0.0, 1.0) or math.random())
    if roll > prob then
        return false, "unwilling"
    end

    local entry = donorMatches[1]
    local item = entry.item
    local fullType = tostring(item.type or item.fullType or item.itemType or "")
    local itemName = friendlyItemName(item)
    local okTx, txReason = transferSharedItem(donor, recipient, entry, opts.reason or "provision_teammate_share")
    if not okTx then
        return false, txReason or "transfer_failed"
    end

    playHandoverScenes(donor, recipient, fullType)
    applyShareRelationshipGain(donor, recipient, intensity, now)

    local donorAddress, donorKin = Beats.ResolveKinshipAddress(donor, recipient)
    local recipAddress = Beats.ResolveKinshipAddress(recipient, donor)

    local emitted = false
    if type(Beats.Emit) == "function" and type(Beats.BuildWorldThread) == "function" then
        emitted = Beats.Emit("npc.group_item_share", {
            donor = donor,
            recipient = recipient,
            needKind = needKind,
            intensity = intensity,
            itemFullType = fullType,
            itemName = itemName,
            donorAddress = donorAddress,
            recipAddress = recipAddress,
            kinshipRole = donorKin,
        }, now) == true
    else
        local Transport = PNC.Semantics and PNC.Semantics.SpeechTransport or nil
        if Transport and type(Transport.ResolveLine) == "function" and type(Transport.Deliver) == "function" then
            local function sayTurn(spk, addr, role, act, addrLabel, atMs)
                local text, res = Transport.ResolveLine(spk, {
                    eventType = "group_item_share_beat",
                    eventID = "item_share:" .. tostring(spk.id) .. ":" .. tostring(math.floor(atMs)),
                    act = act,
                    topic = "group_item_share",
                    poolID = "semantic.social.item_share",
                    role = role,
                    tokens = {
                        ["addressee.name"] = addrLabel,
                        ["term.address"] = addrLabel,
                        ["slot.giver_address"] = recipAddress,
                        ["slot.item"] = itemName,
                    },
                    context = {
                        beatRole = role,
                        needType = needKind,
                        needUrgency = intensity,
                        kinshipRole = donorKin,
                        inCombat = false,
                    },
                })
                if text then
                    Transport.Deliver(spk, atMs, {
                        eventType = "group_item_share_beat",
                        poolID = res and res.poolID or "semantic.social.item_share",
                        act = act,
                        domain = "social",
                        topic = "group_item_share",
                        family = "group_item_share",
                        priority = 58,
                        text = text,
                        addressee = addr,
                    })
                    return true
                end
                return false
            end
            emitted = sayTurn(donor, recipient, "share_give_" .. needKind, "OFFER", donorAddress, now)
            if emitted then
                sayTurn(recipient, donor, "share_thanks_" .. needKind, "THANK", recipAddress, now + 1400)
            end
        end
    end

    local sharePayload = {
        donorId = donor.id,
        donorName = tostring(donor.name or donor.fullName or donor.id),
        recipientId = recipient.id,
        recipientName = tostring(recipient.name or recipient.fullName or recipient.id),
        needKind = needKind,
        intensity = intensity,
        itemFullType = fullType,
        itemName = itemName,
        donorAddress = donorAddress,
        recipAddress = recipAddress,
        source = tostring(opts.source or "group_item_share"),
        emitted = emitted,
        at = now,
    }
    local okBus, EventBus = pcall(require, "PsychopatzCore/Events/PC_EventBus")
    local evType = PNC.EventTypes and PNC.EventTypes.NPC_ITEM_SHARED or "projecthoomans.npc.provision.itemShared"
    if okBus and type(EventBus) == "table" and type(EventBus.emit) == "function" then
        pcall(EventBus.emit, evType, sharePayload)
    end
    if PNC.Core and type(PNC.Core.LogInfo) == "function" then
        PNC.Core.LogInfo(string.format(
            "[Provision][ItemShare] event=%s donor=%s(%s) -> recipient=%s(%s) item=%s need=%s intensity=%s addr=%s/%s source=%s",
            tostring(evType),
            tostring(donor.id), sharePayload.donorName,
            tostring(recipient.id), sharePayload.recipientName,
            fullType, tostring(needKind), tostring(intensity),
            donorAddress, recipAddress, sharePayload.source
        ))
    end
    if type(Beats.AuditLog) == "function" then
        Beats.AuditLog("group_item_share", {
            "donor=" .. tostring(donor.id),
            "recipient=" .. tostring(recipient.id),
            "need=" .. tostring(needKind),
            "intensity=" .. tostring(intensity),
            "item=" .. fullType,
            "donorAddr=" .. donorAddress,
            "recipAddr=" .. recipAddress,
            "source=" .. sharePayload.source,
        })
    end
    return true, sharePayload
end

local RULE_TO_NEED_KIND = {
    food = "eat",
    hydration = "drink",
    bandage = "bleed",
}

-- Canonical Provision integration point: called by PNC.ProvisionScheduler when
-- a colonist needs food/hydration/bandage (while following, away from home, or
-- when colony storage is empty).
function Beats.TryProvisionFromTeammate(recipient, ruleID, at, opts)
    local needKind = RULE_TO_NEED_KIND[tostring(ruleID or "")]
    if not needKind or type(recipient) ~= "table" then return false, "unsupported_rule" end
    local now = nowMs(at)
    if not isEligibleNPC(recipient, now) then return false, "recipient_ineligible" end
    if #findMatchingItems(recipient, needKind) > 0 then
        return false, "recipient_has_item"
    end
    local reg = PNC.Registry
    if not reg or type(reg.ForEach) ~= "function" then return false, "registry_unavailable" end

    local need = detectShareableNeed(recipient)
    local intensity = (need and need.kind == needKind and need.intensity) or "medium"
    local rz = tonumber(recipient.z) or 0
    local shared, result = false, nil
    reg.ForEach(function(donor)
        if shared then return end
        if donor.id ~= recipient.id
            and isEligibleNPC(donor, now)
            and isSameGroup(donor, recipient)
            and math.abs((tonumber(donor.z) or 0) - rz) < 1
            and distSq(donor, recipient) <= SHARE_RADIUS_SQ
        then
            local cdKey = tostring(donor.id) .. ":" .. tostring(recipient.id) .. ":" .. needKind
            if now >= (tonumber(pairCooldowns[cdKey]) or 0) then
                local ok, res = Beats.TryShareItem(donor, recipient, needKind, intensity, {
                    now = now,
                    source = "provision",
                    reason = "provision_teammate_share",
                    forceRoll = opts and opts.forceRoll,
                })
                if ok then
                    lruPut(pairCooldowns, pairOrder, cdKey, now + SHARE_PAIR_COOLDOWN_MS)
                    shared = true
                    result = res
                end
            end
        end
    end)
    if shared then return true, result end
    return false, "no_willing_teammate_donor"
end

-- Debug trigger: forces `donor` to hand over a carried item (or a debug Apple
-- if empty) to the nearest live NPC within 14 tiles, bypassing cooldown & roll.
function Beats.ForceShareItemFromDonor(donor, opts)
    opts = type(opts) == "table" and opts or {}
    if type(donor) ~= "table" or donor.id == nil or donor.alive == false then
        return false, "invalid_donor"
    end
    local now = nowMs(opts.now)
    local reg = PNC.Registry
    if not reg or type(reg.ForEach) ~= "function" then
        return false, "registry_unavailable"
    end
    local dz = tonumber(donor.z) or 0
    local bestRecipient, bestScore = nil, -math.huge
    reg.ForEach(function(other)
        if type(other) ~= "table" or other.id == nil or tostring(other.id) == tostring(donor.id) then
            return
        end
        if not isEligibleNPC(other, now) then return end
        if math.abs((tonumber(other.z) or 0) - dz) >= 1 then return end
        local dSq = distSq(donor, other)
        if dSq > (14 * 14) then return end
        local need = detectShareableNeed(other)
        local score = (isSameGroup(donor, other) and 1000 or 100) + (need and 200 or 0) - dSq
        if score > bestScore then
            bestRecipient, bestScore = other, score
        end
    end)
    if not bestRecipient then
        if PNC.Core and type(PNC.Core.LogInfo) == "function" then
            PNC.Core.LogInfo("[Provision][ItemShare][Debug] force_share_item skipped: no nearby NPC for donor=" .. tostring(donor.id))
        end
        return false, "no_nearby_recipient"
    end

    local need = detectShareableNeed(bestRecipient)
    local preferredKind = need and need.kind or "eat"
    local order = { preferredKind, "eat", "drink", "bleed" }
    local chosenKind = nil
    for i = 1, #order do
        local k = order[i]
        if #findMatchingItems(donor, k) > 0 then
            chosenKind = k
            break
        end
    end

    if not chosenKind and opts.spawnFallback ~= false then
        chosenKind = preferredKind
        local fallbackType = chosenKind == "drink" and "Base.WaterBottleFull"
            or (chosenKind == "bleed" and "Base.Bandage" or "Base.Apple")
        local fallbackSpec = {
            type = fallbackType,
            fullType = fallbackType,
            stack = 1,
            isFood = chosenKind == "eat" or nil,
            isWater = chosenKind == "drink" or nil,
        }
        if PNC.Inventory and type(PNC.Inventory.AddItems) == "function" then
            pcall(PNC.Inventory.AddItems, donor, { fallbackSpec }, "root", "debug_force_share_seed")
        else
            donor.inventory = donor.inventory or { items = {} }
            local list = type(donor.inventory.items) == "table" and donor.inventory.items or donor.inventory
            list[#list + 1] = fallbackSpec
        end
    end
    if not chosenKind then return false, "donor_no_item" end

    local intensity = (need and need.intensity) or "critical"
    local ok, res = Beats.TryShareItem(donor, bestRecipient, chosenKind, intensity, {
        now = now,
        forceRoll = -1,
        ignoreRecipientStock = true,
        source = "debug_force_share",
        reason = "debug_force_share",
    })
    if ok and PNC.Network and type(PNC.Network.BroadcastRecord) == "function" then
        pcall(PNC.Network.BroadcastRecord, donor, "debug_force_share")
        pcall(PNC.Network.BroadcastRecord, bestRecipient, "debug_force_share")
    end
    return ok, res
end

function Beats.CheckGroupItemShare(at, opts)
    local now = nowMs(at)
    if not (opts and opts.force) and now < (lastCheckAt + SHARE_CHECK_INTERVAL_MS) then
        return false
    end
    lastCheckAt = now

    local reg = PNC.Registry
    if not reg or type(reg.ForEach) ~= "function" then return false end

    local liveList = {}
    reg.ForEach(function(rec)
        if isEligibleNPC(rec, now) then
            liveList[#liveList + 1] = rec
        end
    end)

    for i = 1, #liveList do
        local recipient = liveList[i]
        local need = detectShareableNeed(recipient)
        if need and #findMatchingItems(recipient, need.kind) == 0 then
            local rz = tonumber(recipient.z) or 0
            for j = 1, #liveList do
                local donor = liveList[j]
                if donor.id ~= recipient.id
                    and isSameGroup(donor, recipient)
                    and math.abs((tonumber(donor.z) or 0) - rz) < 1
                    and distSq(donor, recipient) <= SHARE_RADIUS_SQ
                then
                    local cdKey = tostring(donor.id) .. ":" .. tostring(recipient.id) .. ":" .. need.kind
                    if now >= (tonumber(pairCooldowns[cdKey]) or 0) then
                        local ok, res = Beats.TryShareItem(donor, recipient, need.kind, need.intensity, {
                            now = now,
                            forceRoll = opts and opts.forceRoll,
                        })
                        if ok then
                            lruPut(pairCooldowns, pairOrder, cdKey, now + SHARE_PAIR_COOLDOWN_MS)
                            return true, res
                        end
                    end
                end
            end
        end
    end
    return false
end

function Beats.ResetGroupItemShareRuntime()
    lastCheckAt = 0
    pairCooldowns, pairOrder = {}, {}
end

local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
if Dir and type(Dir.RegisterTopicAxis) == "function" then
    Dir.RegisterTopicAxis("group_item_share", "compassion")
end

return Beats
