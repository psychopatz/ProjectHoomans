-- Live and abstract lumber execution state machines.
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
local expireClaims = Internal.ExpireClaims
local resolveAbstractTool = Internal.ResolveAbstractTool
local resolveLiveTool = Internal.ResolveLiveTool
local toolDiagnostic = Internal.ToolDiagnostic
local persistLiveToolCondition = Internal.PersistLiveToolCondition
local skillRate = Internal.SkillRate

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
        pcall(body.faceLocationF, body, tree.x + 0.5, tree.y + 0.5)
    end
end

local function beginChopAnimation(record, body)
    if PNC.AnimationScenes and type(PNC.AnimationScenes.Request) == "function"
        and body
    then
        local scene = record.runtime and record.runtime.animationScene
        if not scene or scene.id ~= "lumber.chop" then
            pcall(PNC.AnimationScenes.Request, record, body, "lumber.chop", {
                reason = "lumber_chop", repeatMode = "loop",
            })
        end
    end
    if body and type(body.setVariable) == "function" then
        pcall(body.setVariable, body, "PNCLumbering", true)
    end
end

local function stopChopAnimation(record, body)
    local scene = record and record.runtime and record.runtime.animationScene
    if scene and scene.id == "lumber.chop"
        and PNC.AnimationScenes and PNC.AnimationScenes.Stop
    then pcall(PNC.AnimationScenes.Stop, record, body, "lumber_stopped") end
    if body and type(body.setVariable) == "function" then
        pcall(body.setVariable, body, "PNCLumbering", false)
    end
end

local function tickLive(job, record, body, tree, at)
    local actual, square = Service.GetTreeAt(tree.x, tree.y, tree.z)
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
    local distance = math.abs((tonumber(bx) or 0) - approach.x)
        + math.abs((tonumber(by) or 0) - approach.y)
    if distance > 1.0 or math.abs((tonumber(bz) or 0) - approach.z) > 0.6 then
        job.state, job.phase = "TRAVELING", "TRAVEL"
        if PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord then
            PNC.BehaviorCommon.MoveRecord(record, body,
                approach.x, approach.y, approach.z, "walk", 0.7, "lumber")
        end
        updateRuntime(record, job, tree)
        return true, false, "traveling"
    end
    if not adjacentToTree(body, tree) then
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
        job.state, job.phase = "WAITING", "WAITING_FOR_TOOL"
        updateRuntime(record, job, tree)
        return true, false, toolReason
    end
    if type(body.isEnduranceSufficientForAction) == "function" then
        local ok, enough = pcall(body.isEnduranceSufficientForAction, body)
        if ok and enough == false then
            job.state, job.phase = "WAITING", "WAITING_FOR_ENDURANCE"
            updateRuntime(record, job, tree)
            return true, false, "endurance"
        end
    end
    beginChopAnimation(record, body)
    job.state, job.phase = "WORKING", "CHOPPING"
    local lastHit = tonumber(job.lastHitAt) or 0
    if at - lastHit >= Service.HIT_INTERVAL_MS then
        local ok, result = pcall(actual.WeaponHit, actual, body, tool.item)
        if not ok then
            stopChopAnimation(record, body)
            job.state, job.phase = "FAILED", "FAILED"
            return false, false, tostring(result)
        end
        persistLiveToolCondition(record, tool.item)
        job.lastHitAt = at
        job.lastProgressAt = at
        if type(actual.getHealth) == "function" then
            local healthOK, health = pcall(actual.getHealth, actual)
            if healthOK and tonumber(health) then
                tree.remainingWork = math.max(0, tonumber(health))
            end
        end
        tree.revision = (tonumber(tree.revision) or 0) + 1
        markDirty()
    end
    local stillThere = Service.GetTreeAt(tree.x, tree.y, tree.z)
    if not stillThere or tonumber(tree.remainingWork) <= 0 then
        stopChopAnimation(record, body)
        Service.CompleteTree(tree.key, "live")
        job.targetKey, job.approach, job.lastHitAt = nil, nil, nil
        job.state, job.phase = "READY", "RECONCILING"
        updateRuntime(record, job, nil)
        return true, false, "tree_depleted_vanilla_output"
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
        pcall(PNC.Inventory.ApplyDelta, record, {
            { op = "update", itemID = tool.itemID, cond = condition },
        }, "lumber_tool_wear")
    end
end

local function flushAbstractOutput(job, record)
    local output = job.pendingOutput
    if not output then return true end
    if PNC.Inventory and type(PNC.Inventory.AddItems) == "function" then
        local ok = PNC.Inventory.AddItems(record, {
            { type = output.fullType, stack = output.quantity },
        }, "root", "lumber_abstract_output")
        if ok then job.pendingOutput = nil; return true end
    end
    return false
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
        job.state, job.phase = "WAITING", "WAITING_FOR_TOOL"
        updateRuntime(record, job, tree)
        return true, false, toolReason
    end
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
        Service.CompleteTree(tree.key, "abstract")
        job.pendingOutput = {
            fullType = "Base.Log", quantity = tree.logYield,
        }
        job.targetKey = nil
        job.approach = nil
        job.lastProgressAt = at
        job.state, job.phase = "WAITING", "OUTPUT_PENDING"
        if flushAbstractOutput(job, record) then
            job.state, job.phase = "READY", "OUTPUT_DELIVERED"
        end
        updateRuntime(record, job, nil)
        return true, false, "tree_depleted_abstract_output"
    end
    return true, false, actual and "physical_tree_appeared" or "abstract_chopping"
end

local function tickJob(lease)
    local npcId = tostring(lease and lease.npcId or "")
    local job = Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    if not job or not zone or not record or job.active ~= true
        or zone.enabled ~= true
    then return false, false, "job_unavailable" end
    local at = now()
    expireClaims(at)
    if job.pendingOutput and not flushAbstractOutput(job, record) then
        job.state, job.phase = "WAITING", "OUTPUT_PENDING"
        updateRuntime(record, job, nil)
        return true, false, "output_pending"
    end
    local body = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(npcId) or nil
    lease.executionMode = body and "LIVE" or "ABSTRACT"
    job.executionMode = lease.executionMode
    local tree = job.targetKey and Service.GetTree(job.targetKey) or nil
    if not tree or tree.status == "DEPLETED" or tree.status == "INVALID" then
        tree = nil
        job.targetKey, job.approach = nil, nil
    end
    if not tree then
        tree = selectClaimedTarget(npcId, at)
        if tree then
            job.targetKey = tree.key
            job.approach = nil
            job.lastHitAt = nil
            job.lastProgressAt = at
            job.revision = (tonumber(job.revision) or 0) + 1
        end
    end
    if tree and not ensureTreeClaim(tree.key, npcId, at) then
        tree = nil
        job.targetKey, job.approach = nil, nil
        tree = selectClaimedTarget(npcId, at)
        if tree then
            job.targetKey, job.approach = tree.key, nil
            job.lastHitAt, job.lastProgressAt = nil, at
        end
    end
    if not tree then
        local pendingScan = zone.scan.complete ~= true
        if pendingScan then
            guideToZone(job, zone, record, body)
            return true, false, "scanning"
        end
        job.state, job.phase = "COMPLETED", "COMPLETE"
        updateRuntime(record, job, nil)
        return true, true, "zone_exhausted"
    end
    if body then return tickLive(job, record, body, tree, at) end
    return tickAbstract(job, record, tree, at)
end

local function waitingFor(phase, reason)
    if phase == "WAITING_FOR_TOOL"
        or string.find(tostring(reason or ""), "lumber_tool", 1, true)
        or reason == "tool_cannot_chop"
    then return "primary_tool" end
    if phase == "WAITING_FOR_ENDURANCE" then return "endurance" end
    if phase == "WAITING_FOR_MATERIALIZATION" then return "live_execution" end
    if phase == "OUTPUT_PENDING" then return "output" end
    if phase == "TRAVEL" or reason == "traveling"
        or reason == "not_adjacent"
    then return "travel" end
    if phase == "WAITING_FOR_WORKER" or reason == "waiting_for_worker" then
        return "worker"
    end
    return nil
end

local function publishTickDiagnostic(lease, reason, complete)
    local npcId = tostring(lease and lease.npcId or "")
    local job = Service.GetJob(npcId)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    if not job or not record then return end
    record.runtime = record.runtime or {}
    local runtime = record.runtime.lumber
    if not runtime then
        runtime = {}
        record.runtime.lumber = runtime
    end
    local phase = tostring(job.phase or runtime.phase or "")
    runtime.lastReason = reason
    runtime.waitingFor = waitingFor(phase, reason)
    runtime.waitingReason = runtime.waitingFor and reason or nil
    if runtime.waitingFor == "primary_tool" then
        local body = PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(npcId) or nil
        runtime.tool = toolDiagnostic(record, body)
    else
        runtime.tool = nil
    end
    if complete then
        runtime.waitingFor = nil
        runtime.waitingReason = nil
        runtime.tool = nil
    end
end

function Service.TickJob(lease)
    local ok, complete, reason = tickJob(lease)
    publishTickDiagnostic(lease, reason, complete)
    return ok, complete, reason
end

return Service
