-- WorkService operation-handler registration boundary.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.WorkService

function Service.RegisterCompletion(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.CompletionHandlers[operation] = handler
    return true
end

function Service.RegisterCompletionRecovery(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.CompletionRecoveryHandlers[operation] = handler
    return true
end

function Service.RegisterPreparation(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.PreparationHandlers[operation] = handler
    return true
end

function Service.RegisterCollection(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.CollectionHandlers[operation] = handler
    return true
end

function Service.RegisterTargetProvider(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.TargetProviders[operation] = handler
    return true
end

function Service.RegisterExecution(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.ExecutionHandlers[operation] = handler
    return true
end

function Service.RegisterAbstractExecution(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.AbstractExecutionHandlers[operation] = handler
    return true
end

function Service.RegisterReconciler(id, handler)
    id = tostring(id or "")
    if id == "" or type(handler) ~= "function" then return false end
    Service.ReconcileHandlers[id] = handler
    return true
end
