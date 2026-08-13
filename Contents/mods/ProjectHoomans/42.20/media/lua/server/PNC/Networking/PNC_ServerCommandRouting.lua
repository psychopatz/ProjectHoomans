-- Canonical entry point for authoritative client-command routing.

require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerInventoryCommandHandler"

return PNC.ServerCommandRouter
