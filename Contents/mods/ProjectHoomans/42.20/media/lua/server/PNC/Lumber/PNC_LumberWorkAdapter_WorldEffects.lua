-- Lumber deferred tree-removal and world-effect registrations.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.LumberWorkAdapter = PNC.LumberWorkAdapter or {}

local Adapter = PNC.LumberWorkAdapter
local Internal = Adapter.Internal or {}
local Service = Internal.Service
local WorldEffects = Internal.WorldEffects

if WorldEffects and WorldEffects.RegisterProvider
    and WorldEffects.Register
then
    local function activeJobForTree(tree)
        if not tree then return nil end
        for _, candidate in pairs(Service.Data
            and Service.Data.jobs or {}) do
            if type(candidate) == "table" and candidate.active == true then
                local targetKey = candidate.targetKey
                local outputKey = candidate.pendingOutput
                    and candidate.pendingOutput.treeKey or nil
                if tostring(targetKey or "") == tostring(tree.key or "")
                    or tostring(outputKey or "") == tostring(tree.key or "")
                then
                    return candidate
                end
            end
        end
        return nil
    end

    local function activeTreeDebugEffect(tree, job)
        if not tree or not job then return nil end
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(job.npcId) or nil
        local runtime = record and record.runtime
            and record.runtime.lumber or nil
        local required = math.max(1, tonumber(tree.maxWork) or 1)
        local remaining = math.max(0, math.min(required,
            tonumber(tree.remainingWork) or required))
        return {
            id = "lumber_work:" .. tostring(tree.key),
            kind = "LUMBER_WORK", operation = "LUMBER_WORK",
            state = "PENDING", debugOnly = true,
            treeKey = tree.key, x = tree.x, y = tree.y, z = tree.z,
            workerID = job.npcId, phase = job.phase,
            sourceMode = job.executionMode,
            progress = required - remaining, requiredWork = required,
            remainingWork = remaining, maxWork = required,
            activityItemFullType = runtime
                and runtime.activityItemFullType or job.activityItemFullType,
            waitingReason = runtime and runtime.waitingReason or nil,
            lastReason = runtime and runtime.lastReason or nil,
        }
    end

    WorldEffects.RegisterProvider("LUMBER", {
        List = function()
            local output = {}
            for _, tree in pairs(Service.Data and Service.Data.trees or {}) do
                if type(tree) == "table"
                    and (type(tree.worldEffect) == "table"
                        or type(tree.outputEffect) == "table"
                        or activeJobForTree(tree))
                then
                    output[#output + 1] = tree
                end
            end
            return output
        end,
        GetOwnerID = function(tree) return tree and tree.key end,
        GetEffects = function(tree)
            local output = {}
            if type(tree and tree.worldEffect) == "table" then
                output[#output + 1] = tree.worldEffect
            end
            if type(tree and tree.outputEffect) == "table" then
                output[#output + 1] = tree.outputEffect
            end
            local active = activeJobForTree(tree)
            if active then
                output[#output + 1] = activeTreeDebugEffect(tree, active)
            end
            return output
        end,
        -- LUMBER_OUTPUT is visible in the same ledger snapshot but is not a
        -- generic loaded-square mutation. Its state machine is owned by the
        -- lumber worker, so the world-effects pump must not auto-apply it.
        IsPending = function(_, effect)
            if tostring(effect and effect.kind or "") ~= "TREE_REMOVE" then
                return false
            end
            local state = tostring(effect and effect.state or "PENDING")
            return state ~= "APPLIED" and state ~= "CANCELLED"
                and state ~= "CONFLICT" and state ~= "FAILED"
        end,
        MarkDirty = function() Service.Dirty = true end,
    })
    WorldEffects.Register("TREE_REMOVE", {
        Apply = function(tree, effect)
            return Service.ApplyDeferredTreeRemoval(tree, effect)
        end,
        GetPoints = function(tree, effect)
            return { {
                role = "target", x = effect.x or tree.x,
                y = effect.y or tree.y, z = effect.z or tree.z,
            } }
        end,
    })
end

return Adapter
