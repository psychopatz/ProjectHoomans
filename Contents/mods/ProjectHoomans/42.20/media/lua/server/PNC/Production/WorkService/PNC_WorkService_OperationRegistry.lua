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

---Registers an operation descriptor table onto WorkService handler registries.
function Service.RegisterOperation(operation, handlers)
    operation = tostring(operation or "")
    if operation == "" or type(handlers) ~= "table" then return false end
    if type(handlers.TargetProvider) == "function" then
        Service.RegisterTargetProvider(operation, handlers.TargetProvider)
    end
    if type(handlers.ExecutionHandler) == "function" then
        Service.RegisterExecution(operation, handlers.ExecutionHandler)
    end
    if type(handlers.AbstractExecutionHandler) == "function" then
        Service.RegisterAbstractExecution(operation, handlers.AbstractExecutionHandler)
    end
    if type(handlers.CompletionHandler) == "function" then
        Service.RegisterCompletion(operation, handlers.CompletionHandler)
    end
    if type(handlers.CompletionRecoveryHandler) == "function" then
        Service.RegisterCompletionRecovery(operation, handlers.CompletionRecoveryHandler)
    end
    if type(handlers.PreparationHandler) == "function" then
        Service.RegisterPreparation(operation, handlers.PreparationHandler)
    end
    if type(handlers.CollectionHandler) == "function" then
        Service.RegisterCollection(operation, handlers.CollectionHandler)
    end
    local cancel = handlers.CancelHandler or handlers.CleanupHandler
    if type(cancel) == "function" then
        Service.CancellationHandlers = Service.CancellationHandlers or {}
        Service.CancellationHandlers[operation] = cancel
    end
    if type(handlers.Reconciler) == "function" then
        Service.RegisterReconciler(operation, handlers.Reconciler)
    end
    return true
end
