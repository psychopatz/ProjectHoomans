-- Modular Behavior Script Compiler for ConvoEngine.
-- Compiles single or chained natural-language commands into ordered, bounded
-- ActionPlan primitive steps (e.g. PICKUP_AREA, LOOT_CONTAINER, STORE_CONTAINER,
-- MOVE_TO, WAIT, FOLLOW, GUARD, SIT, EMOTE).
--
-- Strictly gated to player-controllable NPCs (colonists / recruited followers).
-- Extensible: add any future verb or primitive via Compiler.RegisterActionCompiler().

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Compiler = PNC.ConvoEngine.BehaviorScriptCompiler or {}
PNC.ConvoEngine.BehaviorScriptCompiler = Compiler

local GrammarJoin = PNC.ConvoEngine.GrammarJoin
    or require "PNC/ConvoEngine/GrammarJoin"

Compiler.VERSION = 2
Compiler.MAX_STEPS = 12
Compiler.ActionCompilers = Compiler.ActionCompilers or {}

local CANCEL_PHRASES = {
    ["okay thats enough"] = true,
    ["ok thats enough"] = true,
    ["thats enough"] = true,
    ["that is enough"] = true,
    ["enough"] = true,
    ["stop"] = true,
    ["stop that"] = true,
    ["stop it"] = true,
    ["cancel"] = true,
    ["cancel that"] = true,
    ["abort"] = true,
    ["never mind"] = true,
    ["nevermind"] = true,
    ["nvm"] = true,
    ["forget it"] = true,
    ["leave it"] = true,
    ["stand down"] = true,
}

local function safeCall(obj, m, ...)
    local fn = obj and obj[m]
    if type(fn) ~= "function" then return nil end
    local ok, v = pcall(fn, obj, ...)
    return ok and v or nil
end

function Compiler.IsCancelPhrase(rawText)
    local s = string.lower(tostring(rawText or ""))
    s = string.gsub(s, "['’`]", "")
    s = string.gsub(s, "[^%w%s]", " ")
    s = string.gsub(s, "%s+", " ")
    s = (s:gsub("^%s+", ""):gsub("%s+$", ""))
    return CANCEL_PHRASES[s] == true
end

-- Resolves the player's current room into pure serializable primitives (no Java objects).
function Compiler.ResolvePlayerRoomContext(player)
    if not player then return nil end
    local sq = safeCall(player, "getCurrentSquare") or safeCall(player, "getSquare")
    if not sq then return nil end
    local room = safeCall(sq, "getRoom")
    local roomName = room and safeCall(room, "getName") or nil
    if type(roomName) == "string" then
        roomName = string.lower(roomName)
        if roomName == "" then roomName = nil end
    else
        roomName = nil
    end
    return {
        roomName = roomName,
        roomX = math.floor(tonumber(safeCall(sq, "getX") or safeCall(player, "getX")) or 0),
        roomY = math.floor(tonumber(safeCall(sq, "getY") or safeCall(player, "getY")) or 0),
        roomZ = math.floor(tonumber(safeCall(sq, "getZ") or safeCall(player, "getZ")) or 0),
    }
end

local ALL_ITEM_WORDS = {
    all = true,
    everything = true,
    items = true,
    ["all items"] = true,
    ["the items"] = true,
    stuff = true,
    ["all stuff"] = true,
    loot = true,
    ["all loot"] = true,
    anything = true,
}

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalizeItemFilter(raw)
    if type(raw) ~= "string" then return "all" end
    local s = string.lower(trim(raw))
    -- Strip leading quantifiers/articles ("all the food" -> "food", "that food" -> "food")
    s = string.gsub(s, "^all%s+the%s+", "")
    s = string.gsub(s, "^all%s+", "")
    s = string.gsub(s, "^every%s+", "")
    s = string.gsub(s, "^the%s+", "")
    s = string.gsub(s, "^that%s+", "")
    s = string.gsub(s, "^those%s+", "")
    s = string.gsub(s, "^this%s+", "")
    s = string.gsub(s, "^these%s+", "")
    s = string.gsub(s, "^some%s+", "")
    s = trim(s)
    if s == "" or ALL_ITEM_WORDS[s] then return "all" end
    return s
end

-- Strict controllability gate: ONLY colonists / player-owned companions can
-- execute multi-step behavior scripts or pickup/loot/store primitives.
function Compiler.CanExecuteScript(record, player)
    if type(record) ~= "table" or record.alive == false then
        return false, "actor_unavailable"
    end
    local tc = string.lower(tostring(record.tacticalClass or ""))
    if tc == "hostile" or record.isHostile == true then
        return false, "colonist_control_required"
    end
    if PNC.Types and type(PNC.Types.IsColonist) == "function"
        and PNC.Types.IsColonist(record) == true
    then
        return true, "colonist"
    end
    if tc == "colonist" or record.colonist == true or record.recruited == true then
        return true, "colonist"
    end
    if player then
        local oid = player.getOnlineID and tostring(player:getOnlineID()) or nil
        local uname = player.getUsername and tostring(player:getUsername()) or nil
        if (oid and record.ownerOnlineID ~= nil and tostring(record.ownerOnlineID) == oid)
            or (uname and record.ownerUsername ~= nil and tostring(record.ownerUsername) == uname)
        then
            return true, "player_owned"
        end
    end
    return false, "colonist_control_required"
end

function Compiler.RegisterActionCompiler(actionID, fn)
    local key = string.upper(tostring(actionID or ""))
    if key == "" or type(fn) ~= "function" then return false end
    Compiler.ActionCompilers[key] = fn
    return true
end

local function compilePickup(ir)
    local ext = type(ir.extensions) == "table" and ir.extensions or {}
    local filter = normalizeItemFilter(ir.object)
    local qty = ext.quantity or "all"
    local container = ir.source or ir.destination or (type(ir.target) == "string" and ir.target or nil)
    if type(container) == "string" then
        container = trim(string.gsub(string.lower(container), "^nearby%s+", ""))
        if container == "" then container = nil end
    end
    if container then
        return {
            { kind = "MOVE_TO", target = { text = container } },
            {
                kind = "PICKUP",
                target = { text = container },
                filter = filter,
                quantity = qty,
                includeGround = false,
                includeContainers = true,
            },
        }
    end
    return {
        {
            kind = "PICKUP",
            filter = filter,
            quantity = qty,
            areaScope = ext.areaScope,
            includeGround = true,
            includeContainers = ext.areaScope ~= nil and ext.areaScope.kind == "room",
        },
    }
end

-- Built-in modular action compilers (easily extended via RegisterActionCompiler)
Compiler.RegisterActionCompiler("FETCH", compilePickup)
Compiler.RegisterActionCompiler("PICKUP", compilePickup)
Compiler.RegisterActionCompiler("SCAVENGE", compilePickup)

Compiler.RegisterActionCompiler("STORE", function(ir)
    local ext = type(ir.extensions) == "table" and ir.extensions or {}
    local filter = normalizeItemFilter(ir.object)
    local dest = ir.destination or (type(ir.target) == "string" and ir.target or nil)
    if not dest then return {} end
    dest = trim(string.gsub(string.lower(dest), "^nearby%s+", ""))
    return {
        { kind = "MOVE_TO", target = { text = dest } },
        { kind = "STORE", target = { text = dest }, filter = filter, quantity = ext.quantity or "all" },
    }
end)

Compiler.RegisterActionCompiler("WAIT_AT", function(ir)
    local target = type(ir.target) == "table" and ir.target or { text = tostring(ir.target or "") }
    return {
        { kind = "MOVE_TO", target = target },
        { kind = "WAIT" },
    }
end)

Compiler.RegisterActionCompiler("STAY", function()
    return { { kind = "WAIT" } }
end)

Compiler.RegisterActionCompiler("FOLLOW", function()
    return { { kind = "FOLLOW" } }
end)

Compiler.RegisterActionCompiler("GUARD", function(ir)
    if type(ir.target) == "string" and ir.target ~= "" then
        return {
            { kind = "MOVE_TO", target = { text = ir.target } },
            { kind = "GUARD", target = { text = ir.target } },
        }
    end
    return { { kind = "GUARD" } }
end)

Compiler.RegisterActionCompiler("SIT", function()
    return { { kind = "POSTURE", pose = "sit" } }
end)

Compiler.RegisterActionCompiler("STAND", function()
    return { { kind = "POSTURE", pose = "stand" } }
end)

Compiler.RegisterActionCompiler("POSTURE", function(ir)
    local raw = string.lower(tostring(ir.normalizedText or ir.rawText or "sit"))
    local pose = "sit"
    if string.find(raw, "%f[%a]stand%f[%A]") then pose = "stand"
    elseif string.find(raw, "%f[%a]crouch%f[%A]") or string.find(raw, "%f[%a]sneak%f[%A]") then pose = "sneak"
    elseif string.find(raw, "%f[%a]sleep%f[%A]") then pose = "sleep"
    end
    return { { kind = "POSTURE", pose = pose } }
end)

Compiler.RegisterActionCompiler("INTERACT", function(ir)
    local ext = type(ir.extensions) == "table" and ir.extensions or {}
    local raw = string.lower(tostring(ir.normalizedText or ir.rawText or ""))
    local op = "toggle"
    if string.find(raw, "%f[%a]close%f[%A]") or string.find(raw, "%f[%a]shut%f[%A]") then op = "close"
    elseif string.find(raw, "%f[%a]open%f[%A]") then op = "open"
    elseif string.find(raw, "%f[%a]unbarricade%f[%A]") then op = "unbarricade"
    elseif string.find(raw, "%f[%a]barricade%f[%A]") then op = "barricade"
    elseif string.find(raw, "%f[%a]unlock%f[%A]") then op = "unlock"
    elseif string.find(raw, "%f[%a]lock%f[%A]") then op = "lock"
    elseif string.find(raw, "%f[%a]off%f[%A]") or string.find(raw, "%f[%a]extinguish%f[%A]") then op = "turn_off"
    elseif string.find(raw, "%f[%a]on%f[%A]") then op = "turn_on"
    end
    local targetText = type(ir.target) == "string" and ir.target or (type(ir.object) == "string" and ir.object or nil)
    if targetText then
        targetText = trim(string.gsub(string.lower(targetText), "^(the|a|an|all|this|that)%s+", ""))
    end
    local steps = {}
    if targetText and targetText ~= "" and not ext.areaScope then
        steps[#steps + 1] = { kind = "MOVE_TO", target = { text = targetText } }
    end
    steps[#steps + 1] = {
        kind = "INTERACT",
        op = op,
        target = targetText and { text = targetText } or nil,
        areaScope = ext.areaScope,
    }
    return steps
end)

Compiler.RegisterActionCompiler("EQUIP", function(ir)
    local filter = normalizeItemFilter(ir.object)
    local raw = string.lower(tostring(ir.normalizedText or ir.rawText or ""))
    local unequip = string.find(raw, "%f[%a]holster%f[%A]") ~= nil
        or string.find(raw, "%f[%a]unequip%f[%A]") ~= nil
    return { { kind = "EQUIP", filter = filter, unequip = unequip } }
end)

Compiler.RegisterActionCompiler("GIVE", function(ir)
    local ext = type(ir.extensions) == "table" and ir.extensions or {}
    local filter = normalizeItemFilter(ir.object)
    local recipient = ir.recipient or ir.target
    local steps = {}
    if recipient then
        steps[#steps + 1] = { kind = "MOVE_TO", target = { actor = recipient } }
    end
    steps[#steps + 1] = {
        kind = "GIVE",
        filter = filter,
        quantity = ext.quantity or "one",
        recipient = recipient,
    }
    return steps
end)

local function compileUseItem(ir, defaultFilter)
    local filter = ir.object and normalizeItemFilter(ir.object) or defaultFilter or "all"
    local targetActor = type(ir.target) == "string" and ir.target or nil
    local steps = {}
    if targetActor and targetActor ~= "" and targetActor ~= "self" and targetActor ~= "yourself" then
        steps[#steps + 1] = { kind = "MOVE_TO", target = { actor = targetActor } }
    end
    steps[#steps + 1] = {
        kind = "USE_ITEM",
        filter = filter,
        targetActor = targetActor,
    }
    return steps
end

Compiler.RegisterActionCompiler("USE_ITEM", function(ir)
    local raw = string.lower(tostring(ir.normalizedText or ir.rawText or ""))
    local def = "all"
    if string.find(raw, "%f[%a]eat%f[%A]") then def = "food"
    elseif string.find(raw, "%f[%a]drink%f[%A]") then def = "water"
    elseif string.find(raw, "%f[%a]reload%f[%A]") then def = "ammo"
    elseif string.find(raw, "%f[%a]read%f[%A]") then def = "book"
    end
    return compileUseItem(ir, def)
end)
Compiler.RegisterActionCompiler("EAT", function(ir) return compileUseItem(ir, "food") end)
Compiler.RegisterActionCompiler("DRINK", function(ir) return compileUseItem(ir, "water") end)
Compiler.RegisterActionCompiler("HEAL", function(ir) return compileUseItem(ir, "medical") end)

Compiler.RegisterActionCompiler("HOLD_FIRE", function()
    return { { kind = "ENGAGE", mode = "hold_fire" } }
end)

Compiler.RegisterActionCompiler("ATTACK", function(ir)
    return { { kind = "ENGAGE", mode = "attack", target = ir.target } }
end)

Compiler.RegisterActionCompiler("CAMP", function()
    return { { kind = "CAMP" } }
end)

Compiler.RegisterActionCompiler("DROP", function(ir)
    return { { kind = "DROP", filter = normalizeItemFilter(ir.object) } }
end)

Compiler.RegisterActionCompiler("EMOTE", function(ir)
    local raw = string.lower(tostring(ir.normalizedText or ir.rawText or "dance"))
    local emote = string.match(raw, "%f[%a](dance|wave|salute|clap|cheer)%f[%A]") or "dance"
    return { { kind = "EMOTE", emote = emote } }
end)

-- Compile a list of parsed IR clauses into an ordered, bounded ActionPlan script.
function Compiler.CompileIRList(irList, record, player)
    local allowed, authReason = Compiler.CanExecuteScript(record, player)
    if not allowed then
        return nil, authReason
    end
    if type(irList) ~= "table" or #irList == 0 then
        return nil, "empty_script"
    end

    local steps = {}
    for i = 1, #irList do
        local ir = irList[i]
        local action = type(ir) == "table" and string.upper(tostring(ir.action or "")) or ""
        local fn = Compiler.ActionCompilers[action]
        if fn then
            local compiled = fn(ir)
            if type(compiled) == "table" then
                for j = 1, #compiled do
                    if #steps >= Compiler.MAX_STEPS then break end
                    local st = compiled[j]
                    st.stepIndex = #steps + 1
                    st.sourceAction = action
                    steps[#steps + 1] = st
                end
            end
        end
    end

    if #steps == 0 then
        return nil, "no_compilable_steps"
    end
    return {
        version = Compiler.VERSION,
        authorized = true,
        authKind = authReason,
        actorId = tostring(record.id),
        steps = steps,
        stepCount = #steps,
    }, nil
end

local function describeStep(st)
    if type(st) ~= "table" then return nil end
    local k = tostring(st.kind or "")
    if k == "PICKUP" then
        local what = (st.filter and st.filter ~= "all") and st.filter or "supplies"
        if st.target and st.target.text then
            return "grab " .. what .. " from " .. GrammarJoin.FormatTargetWithArticle(st.target.text)
        end
        if st.areaScope and st.areaScope.room then
            local rLabel = st.areaScope.room == "room" and "this room" or ("the " .. tostring(st.areaScope.room))
            return "search " .. rLabel .. " for " .. what
        end
        return "pick up " .. what .. " around here"
    elseif k == "STORE" then
        local what = (st.filter and st.filter ~= "all") and st.filter or "the gear"
        local dest = st.target and st.target.text and GrammarJoin.FormatTargetWithArticle(st.target.text) or "storage"
        return "store " .. what .. " in " .. dest
    elseif k == "INTERACT" then
        local opLabel = string.gsub(tostring(st.op or "check"), "_", " ")
        local tLabel = st.target and st.target.text and GrammarJoin.FormatTargetWithArticle(st.target.text) or "that"
        if st.areaScope and st.areaScope.room then
            local rLabel = st.areaScope.room == "room" and "this room" or ("the " .. tostring(st.areaScope.room))
            return opLabel .. " " .. tLabel .. " in " .. rLabel
        end
        return opLabel .. " " .. tLabel
    elseif k == "EQUIP" then
        if st.unequip then return "holster my weapon" end
        return "equip " .. GrammarJoin.FormatTargetWithArticle(st.filter or "weapon")
    elseif k == "USE_ITEM" then
        if st.filter == "medical" and st.targetActor then
            return "patch up " .. tostring(st.targetActor)
        end
        return "use " .. tostring(st.filter or "supplies")
    elseif k == "POSTURE" then
        if st.pose == "sit" then return "sit down" end
        if st.pose == "stand" then return "stand up" end
        if st.pose == "sneak" then return "keep low" end
        if st.pose == "sleep" then return "get some rest" end
    elseif k == "GUARD" then
        local t = st.target and st.target.text and GrammarJoin.FormatTargetWithArticle(st.target.text) or "this spot"
        return "guard " .. t
    elseif k == "ENGAGE" then
        return st.mode == "hold_fire" and "hold fire" or "engage hostiles"
    elseif k == "FOLLOW" then
        return "follow you"
    elseif k == "WAIT" then
        return "hold position"
    elseif k == "EMOTE" then
        return tostring(st.emote or "dance")
    elseif k == "DROP" then
        return "drop " .. tostring(st.filter or "the items")
    elseif k == "GIVE" then
        return "hand over " .. tostring(st.filter or "the items")
    end
    return nil
end

local IN_SEAT_TYPES = { armchair = true, recliner = true, booth = true }

local function seatPreposition(seatType)
    local lower = string.lower(tostring(seatType or ""))
    if IN_SEAT_TYPES[lower] then return "in" end
    return "on"
end

-- Resolves an unoccupied/nearby sittable object relative to the player using
-- the shared WorldTargetResolver -> NearbyResourceLocator cache.
function Compiler.ResolvePlayerSeatContext(player, options)
    options = type(options) == "table" and options or {}
    if type(options.nearbySeat) == "table" and options.nearbySeat.seatType then
        return options.nearbySeat
    end
    if not player then return nil end
    local resolver = PNC.Semantics and PNC.Semantics.WorldTargetResolver or nil
    if resolver and type(resolver.FindNearbySeat) == "function" then
        return resolver.FindNearbySeat(player, {
            radius = options.seatRadius or 5,
            cell = options.cell,
        })
    end
    return nil
end

-- Generates a natural English verification summary of the compiled steps so
-- the NPC affirms exactly what they understood before executing.
function Compiler.DescribePlan(plan)
    if type(plan) ~= "table" or type(plan.steps) ~= "table" then return nil end
    local phrases = {}
    local i = 1
    while i <= #plan.steps do
        local st = plan.steps[i]
        local nextSt = plan.steps[i + 1]
        local thirdSt = plan.steps[i + 2]
        -- Pattern: auto-seated open-ended wait (MOVE_TO seat -> POSTURE sit -> WAIT)
        if st.kind == "MOVE_TO" and st.autoSeat == true
            and nextSt and nextSt.kind == "POSTURE" and nextSt.pose == "sit"
            and thirdSt and thirdSt.kind == "WAIT"
        then
            local seatType = (nextSt.seat and nextSt.seat.seatType)
                or (st.target and st.target.text)
                or "chair"
            local prep = seatPreposition(seatType)
            phrases[#phrases + 1] = "just sit " .. prep .. " "
                .. GrammarJoin.FormatTargetWithArticle(seatType) .. " and wait here"
            i = i + 3
        elseif st.kind == "MOVE_TO" and nextSt and nextSt.kind == "WAIT" then
            local t = st.target and st.target.text and GrammarJoin.FormatTargetWithArticle(st.target.text) or "there"
            phrases[#phrases + 1] = "wait by " .. t
            i = i + 2
        elseif st.kind == "MOVE_TO" and nextSt ~= nil then
            -- Skip redundant MOVE_TO right before PICKUP/STORE/INTERACT/GUARD/USE_ITEM
            i = i + 1
        elseif st.kind == "WAIT" and type(st.anchor) == "table" then
            phrases[#phrases + 1] = "wait right here"
            i = i + 1
        else
            local d = describeStep(st)
            if d then phrases[#phrases + 1] = d end
            i = i + 1
        end
    end
    if #phrases == 0 then return nil end
    if #phrases == 1 then return GrammarJoin.CleanSurface(phrases[1]) end
    if #phrases == 2 then return GrammarJoin.CleanSurface(phrases[1] .. ", then " .. phrases[2]) end
    local last = table.remove(phrases)
    return GrammarJoin.CleanSurface(table.concat(phrases, ", ") .. ", then " .. last)
end

-- Enriches open-ended WAIT steps ("wait here", "stay here") using the player's
-- relative location: if a sittable object is nearby, sit on it while waiting;
-- otherwise anchor the wait to the player's current tile.
local function enrichOpenEndedWaitSteps(plan, player, playerRoom, options)
    if type(plan) ~= "table" or type(plan.steps) ~= "table" then return end
    local expanded = {}
    local changed = false
    for i = 1, #plan.steps do
        local st = plan.steps[i]
        local prev = plan.steps[i - 1]
        local isOpenEndedWait = (st.kind == "WAIT"
            and (not prev or prev.kind ~= "MOVE_TO")
            and not st.target)
        if isOpenEndedWait then
            local seat = Compiler.ResolvePlayerSeatContext(player, options)
            if seat and seat.seatType and (#expanded + 3 <= Compiler.MAX_STEPS) then
                changed = true
                expanded[#expanded + 1] = {
                    kind = "MOVE_TO",
                    autoSeat = true,
                    sourceAction = st.sourceAction,
                    target = {
                        kind = "seat",
                        text = seat.seatType,
                        x = seat.x,
                        y = seat.y,
                        z = seat.z,
                        resourceKey = seat.resourceKey,
                    },
                }
                expanded[#expanded + 1] = {
                    kind = "POSTURE",
                    pose = "sit",
                    autoSeat = true,
                    sourceAction = st.sourceAction,
                    seat = {
                        kind = "seat",
                        seatType = seat.seatType,
                        x = seat.x,
                        y = seat.y,
                        z = seat.z,
                        resourceKey = seat.resourceKey,
                    },
                }
                expanded[#expanded + 1] = {
                    kind = "WAIT",
                    autoSeat = true,
                    sourceAction = st.sourceAction,
                    anchor = {
                        x = seat.x,
                        y = seat.y,
                        z = seat.z,
                        seatType = seat.seatType,
                        resourceKey = seat.resourceKey,
                    },
                }
            else
                if playerRoom then
                    st.anchor = {
                        x = playerRoom.roomX,
                        y = playerRoom.roomY,
                        z = playerRoom.roomZ,
                        room = playerRoom.roomName,
                    }
                end
                expanded[#expanded + 1] = st
            end
        else
            expanded[#expanded + 1] = st
        end
    end
    if changed then
        for idx = 1, #expanded do
            expanded[idx].stepIndex = idx
        end
        plan.steps = expanded
        plan.stepCount = #expanded
    end
end

-- Convenience entry point: raw English text -> ClauseSplitter -> compiled script.
function Compiler.CompileFromText(rawText, record, player, options)
    local allowed, authReason = Compiler.CanExecuteScript(record, player)
    if not allowed then
        return nil, authReason
    end
    if Compiler.IsCancelPhrase(rawText) then
        return {
            version = Compiler.VERSION,
            authorized = true,
            isCancel = true,
            actorId = tostring(record.id),
            steps = {},
            stepCount = 0,
            rawText = rawText,
        }, nil
    end
    local sem = PsychopatzCore and PsychopatzCore.Semantics or nil
    local splitter = sem and sem.ClauseSplitter
        or require "PsychopatzCore/Semantics/PsychopatzSemanticClauseSplitter"
    local parser = sem and sem.Parser
        or require "PsychopatzCore/Semantics/PsychopatzSemanticParser"
    local parsed = splitter.ParseScript(rawText, parser, options)
    local plan, err = Compiler.CompileIRList(parsed.steps, record, player)
    if not plan then return nil, err end
    -- Ground any "this room" / currentOnly areaScope to the player's current room.
    local playerRoom = Compiler.ResolvePlayerRoomContext(player)
    if playerRoom then
        for i = 1, #plan.steps do
            local scope = plan.steps[i].areaScope
            if type(scope) == "table" and scope.kind == "room"
                and (scope.currentOnly == true or scope.room == "room")
            then
                if playerRoom.roomName and scope.room == "room" then
                    scope.room = playerRoom.roomName
                end
                scope.roomX = playerRoom.roomX
                scope.roomY = playerRoom.roomY
                scope.roomZ = playerRoom.roomZ
            end
        end
    end
    -- Ground open-ended "wait here" / "stay here" to a nearby seat or player's spot.
    enrichOpenEndedWaitSteps(plan, player, playerRoom, options)
    plan.rawText = rawText
    plan.audienceScope = parsed.audienceScope
    plan.isChained = parsed.isChained
    plan.summary = Compiler.DescribePlan(plan)
    return plan, nil
end

return Compiler
