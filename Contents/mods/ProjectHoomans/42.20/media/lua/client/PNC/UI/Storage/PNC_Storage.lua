-- Canonical storage composition root. Other Project Hoomans UI surfaces and
-- future mods should depend on this API rather than a management tab shell.

require "PNC/UI/Storage/PNC_StorageClient"
require "PNC/UI/Storage/PNC_StoragePresentation"
require "PNC/UI/Storage/PNC_StorageLayout"
require "PNC/UI/Storage/PNC_StorageController"

return require "PNC/UI/Storage/PNC_StorageWindow"
