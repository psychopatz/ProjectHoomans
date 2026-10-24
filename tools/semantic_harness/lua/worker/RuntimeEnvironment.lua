-- Project Zomboid engine and packaged-file boundaries used by the harness.

local RuntimeEnvironment = {}
local Context = require "worker/RuntimeEnvironment_Context"
local ModFiles = require "worker/RuntimeEnvironment_ModFiles"
local Engine = require "worker/RuntimeEnvironment_Engine"
local Core = require "worker/RuntimeEnvironment_Core"

function RuntimeEnvironment.configure(context)
    Context.configure(context)
    ModFiles.configure(context)
    Engine.configure(context)
    Core.configure(context)
end

return RuntimeEnvironment
