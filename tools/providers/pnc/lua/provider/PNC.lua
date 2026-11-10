local Adapter = require "provider/Adapter"

local Provider = {}

function Provider.New(SemanticExecution, context, callbacks)
    return Adapter.New(SemanticExecution, context, callbacks)
end

return Provider
