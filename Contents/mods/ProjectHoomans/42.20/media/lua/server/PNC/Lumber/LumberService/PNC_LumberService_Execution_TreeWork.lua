-- Live and abstract tree work progression.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local now = Internal.Now
local markDirty = Internal.MarkDirty
local updateRuntime = Internal.UpdateRuntime
local guideToZone = Internal.GuideToZone
local ensureTreeClaim = Internal.EnsureTreeClaim
local selectClaimedTarget = Internal.SelectClaimedTarget
local treeSignature = Internal.TreeSignature
local resolveAbstractTool = Internal.ResolveAbstractTool
local resolveLiveTool = Internal.ResolveLiveTool
local toolFullType = Internal.ToolFullType
local persistLiveToolCondition = Internal.PersistLiveToolCondition
local skillRate = Internal.SkillRate
local WorldEffects = Internal.WorldEffects
local FatigueGate = Internal.FatigueGate

local function adjacentToTree(body, tree)
    if not body or not tree then return false end
    local x = type(body.getX) == "function" and body:getX() or nil
    local y = type(body.getY) == "function" and body:getY() or nil
    local z = type(body.getZ) == "function" and body:getZ() or nil
    return x and y and z and math.abs(z - tree.z) < 0.6
        and math.abs(x - (tree.x + 0.5)) <= 1.2
        and math.abs(y - (tree.y + 0.5)) <= 1.2
end

local function faceTree(body, tree)
    if body and tree and type(body.faceLocationF) == "function" then
        body:faceLocationF(tree.x + 0.5, tree.y + 0.5)
    end
end

local function beginChopAnimation(record, body)
    if PNC.AnimationScenes and type(PNC.AnimationScenes.Request) == "function"
        and body
    then
        local scene = record.runtime and record.runtime.animationScene
        if not scene or scene.id ~= "lumber.chop" then
            PNC.AnimationScenes.Request(record, body, "lumber.chop", {
                reason = "lumber_chop", repeatMode = "loop",
            })
        end
    end
    if body and type(body.setVariable) == "function" then
        body:setVariable("PNCLumbering", true)
    end
end

local function stopChopAnimation(record, body)
    local scene = record and record.runtime and record.runtime.animationScene
    if scene and scene.id == "lumber.chop"
        and PNC.AnimationScenes and PNC.AnimationScenes.Stop
    then PNC.AnimationScenes.Stop(record, body, "lumber_stopped") end
    if body and type(body.setVariable) == "function" then
        body:setVariable("PNCLumbering", false)
    end
end

local function npcFatigueIsSufficient(record)
    return FatigueGate.Check(record)
end


local function tickLive(job, record, body, tree, at)
    local actual, square = Service.GetTreeAt(tree.x, tree.y, tree.z)
    if not square then
        -- A missing grid square means the target chunk is unavailable, not
        -- that the tree was removed. Keep the ledger record and claim intact
        -- until the chunk is loaded and the tree can be revalidated.
        job.state, job.phase = "WAITING", "WAITING_FOR_TREE_CHUNK"
        updateRuntime(record, job, tree)
        return true, false, "tree_chunk_loading"
    end
    if not actual then
        tree.status = "INVALID"
        Service.Runtime.claims[tree.key] = nil
        job.targetKey, job.approach = nil, nil
        job.state, job.phase = "READY", "RECONCILING"
        markDirty()
        return true, false, "tree_missing"
    end
    if tree.signature ~= treeSignature(actual) then
        tree.status = "INVALID"
        Service.Runtime.claims[tree.key] = nil
        job.targetKey, job.approach = nil, nil
        job.state, job.phase = "READY", "RECONCILING"
        markDirty()
        return true, false, "tree_replaced"
    end
    local approach = job.approach
    if not approach then
        approach = Service.FindApproach(tree, record)
        job.approach = approach
    end
    if not approach then
        Service.ReleaseTree(tree.key, "no_approach")
        job.targetKey, job.approach = nil, nil
        job.state, job.phase = "READY", "BLOCKED"
        return true, false, "no_approach_point"
    end
    local bx = body and body.getX and body:getX() or record.x
    local by = body and body.getY and body:getY() or record.y
    local bz = body and body.getZ and body:getZ() or record.z
    -- The approach point is a navigation hint, not the interaction point.
    -- Bodies can stop slightly off the selected square while still being in
    -- the valid tree interaction envelope. Test adjacency first so a visually
    -- arrived worker does not remain in TRAVEL forever.
    local adjacent = adjacentToTree(body, tree)
    local distance = math.abs((tonumber(bx) or 0) - approach.x)
        + math.abs((tonumber(by) or 0) - approach.y)
    if not adjacent and (distance > 1.0
        or math.abs((tonumber(bz) or 0) - approach.z) > 0.6) then
        job.state, job.phase = "TRAVELING", "TRAVEL"
        if PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord then
            PNC.BehaviorCommon.MoveRecord(record, body,
                approach.x, approach.y, approach.z, "walk", 0.7, "lumber")
        end
        updateRuntime(record, job, tree)
        return true, false, "traveling"
    end
    if not adjacent then
        job.state, job.phase = "TRAVELING", "TRAVEL"
        if PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord then
            PNC.BehaviorCommon.MoveRecord(record, body,
                approach.x, approach.y, approach.z, "walk", 0.7, "lumber")
        end
        updateRuntime(record, job, tree)
        return true, false, "not_adjacent"
    end
    if PNC.BehaviorCommon and PNC.BehaviorCommon.HaltMovement then
        PNC.BehaviorCommon.HaltMovement(record, body, "lumber_chop")
    end
    faceTree(body, tree)
    local tool, toolReason = resolveLiveTool(record, body)
    if not tool then
        job.activityItemFullType = nil
        job.state, job.phase = "WAITING", "WAITING_FOR_TOOL"
        updateRuntime(record, job, tree)
        return true, false, toolReason
    end
    job.activityItemFullType = toolFullType and toolFullType(tool.item) or nil
    if not npcFatigueIsSufficient(record) then
        job.state, job.phase = "WAITING", "WAITING_FOR_FATIGUE"
        updateRuntime(record, job, tree)
        return true, false, "fatigue"
    end
    beginChopAnimation(record, body)
    job.state, job.phase = "WORKING", "CHOPPING"
    local lastHit = tonumber(job.lastHitAt) or 0
    local beforeWorldObjects
    if at - lastHit >= Service.HIT_INTERVAL_MS then
        beforeWorldObjects = Internal.CaptureOutputItems
            and Internal.CaptureOutputItems(square, nil, nil, true) or nil
        actual:WeaponHit(body, tool.item)
        persistLiveToolCondition(record, tool.item)
        job.lastHitAt = at
        job.lastProgressAt = at
        if type(actual.getHealth) == "function" then
            local health = tonumber(actual:getHealth())
            if health then tree.remainingWork = math.max(0, health) end
        end
        tree.revision = (tonumber(tree.revision) or 0) + 1
        markDirty()
    end
    local stillThere, stillSquare = Service.GetTreeAt(tree.x, tree.y, tree.z)
    if not stillSquare then
        job.state, job.phase = "WAITING", "WAITING_FOR_TREE_CHUNK"
        updateRuntime(record, job, tree)
        return true, false, "tree_chunk_loading_after_hit"
    end
    if not stillThere or tonumber(tree.remainingWork) <= 0 then
        job.activityItemFullType = nil
        stopChopAnimation(record, body)
        local outputEffect = Internal.EnsureLumberOutputEffect(tree, "LIVE", nil,
            "ON_GROUND",
            "VANILLA_WORLD_OUTPUT_ON_GROUND", record and record.id)
        if outputEffect and Internal.CaptureOutputItems then
            Internal.CaptureOutputItems(square, beforeWorldObjects, outputEffect)
        end
        job.pendingOutput = {
            mode = "LIVE", treeKey = tree.key,
            outputEffectId = outputEffect and outputEffect.id or nil,
        }
        job.outputTreeKey = tree.key
        Service.CompleteTree(tree.key, "live")
        job.targetKey, job.approach, job.lastHitAt = nil, nil, nil
        job.state, job.phase = "TRAVELING", "OUTPUT_APPROACH"
        updateRuntime(record, job, tree)
        return true, false, "tree_depleted_live_output_pending"
    end
    updateRuntime(record, job, tree)
    return true, false, "chopping"
end

local function updateAbstractToolWear(record, job, tool)
    if not tool.itemID or not tool.condition then return end
    job.toolHitCount = (tonumber(job.toolHitCount) or 0) + 1
    if job.toolHitCount < Service.ABSTRACT_TOOL_HITS_PER_CONDITION then return end
    job.toolHitCount = 0
    if PNC.Inventory and type(PNC.Inventory.ApplyDelta) == "function" then
        local condition = math.max(0, tool.condition - 1)
        PNC.Inventory.ApplyDelta(record, {
            { op = "update", itemID = tool.itemID, cond = condition },
        }, "lumber_tool_wear")
    end
end
local function ensureDeferredTreeEffect(tree, workerID)
    if type(tree) ~= "table" then return nil end
    if type(tree.worldEffect) == "table" then return tree.worldEffect end
    local effectID = PNC.Core and PNC.Core.GenerateID
        and PNC.Core.GenerateID("tree_remove")
        or "tree_remove:" .. tostring(tree.key)
    local effect = {
        id = tostring(effectID), kind = "TREE_REMOVE", state = "PENDING",
        treeKey = tree.key, x = tree.x, y = tree.y, z = tree.z,
        workerID = workerID,
        signature = tree.signature,
        identity = { treeKey = tree.key, signature = tree.signature },
        createdAt = now(), updatedAt = now(), nextRetryAt = 0,
    }
    tree.worldEffect = effect
    markDirty()
    if WorldEffects and WorldEffects.MarkPending then
        WorldEffects.MarkPending("LUMBER", tree, effect,
            "TREE_CHUNK_LOADING")
    end
    return effect
end

local function tickAbstract(job, record, tree, at)
    local actual, square = Service.GetTreeAt(tree.x, tree.y, tree.z)
    if square then
        if not actual then
            -- A player or another authoritative system may have removed the
            -- tree while this worker was abstracted. Treat it as consumed by
            -- the world, never generate a second log reward.
            tree.status = "INVALID"
            Service.Runtime.claims[tree.key] = nil
            job.targetKey, job.approach = nil, nil
            job.state, job.phase = "READY", "RECONCILING"
            markDirty()
            updateRuntime(record, job, nil)
            return true, false, "physical_tree_missing"
        end
        -- A loaded physical tree is authoritative. Wait for materialization
        -- instead of silently deleting a tree that a player can observe.
        job.state, job.phase = "WAITING", "WAITING_FOR_MATERIALIZATION"
        updateRuntime(record, job, tree)
        return true, false, "loaded_tree_requires_live_execution"
    end
    local tool, toolReason = resolveAbstractTool(record)
    if not tool then
        job.activityItemFullType = nil
        job.state, job.phase = "WAITING", "WAITING_FOR_TOOL"
        updateRuntime(record, job, tree)
        return true, false, toolReason
    end
    if not npcFatigueIsSufficient(record) then
        job.state, job.phase = "WAITING", "WAITING_FOR_FATIGUE"
        updateRuntime(record, job, tree)
        return true, false, "fatigue"
    end
    job.activityItemFullType = tool.fullType
    local previous = tonumber(job.lastProgressAt) or at
    local elapsed = math.max(0, math.min(Service.ABSTRACT_MAX_ELAPSED_MS,
        at - previous))
    job.lastProgressAt = at
    local damage = (tool.treeDamage / (Service.HIT_INTERVAL_MS / 1000))
        * (elapsed / 1000) * skillRate(record)
    tree.remainingWork = math.max(0,
        (tonumber(tree.remainingWork) or tree.maxWork) - damage)
    job.state, job.phase = "WORKING", "CHOPPING"
    updateAbstractToolWear(record, job, tool)
    markDirty()
    if tree.remainingWork <= 0 then
        job.activityItemFullType = nil
        ensureDeferredTreeEffect(tree, record and record.id)
        local outputEffect = Internal.EnsureLumberOutputEffect(tree, "ABSTRACT", {
            { fullType = "Base.Log", quantity = tree.logYield },
        }, "OUTPUT_PENDING", "ABSTRACT_OUTPUT_PENDING", record and record.id)
        Service.CompleteTree(tree.key, "abstract")
        job.pendingOutput = {
            mode = "ABSTRACT",
            fullType = "Base.Log", quantity = tree.logYield,
            treeKey = tree.key,
            outputEffectId = outputEffect and outputEffect.id or nil,
        }
        job.targetKey = nil
        job.approach = nil
        job.lastProgressAt = at
        job.state, job.phase = "WAITING", "OUTPUT_PENDING"
        if Internal.FlushAbstractOutput(job, record) then
            job.state, job.phase = "READY", "OUTPUT_DELIVERED"
        end
        updateRuntime(record, job, nil)
        return true, false, "tree_depleted_abstract_output"
    end
    return true, false, actual and "physical_tree_appeared" or "abstract_chopping"
end

Internal.TickLive = tickLive
Internal.TickAbstract = tickAbstract

return Service
