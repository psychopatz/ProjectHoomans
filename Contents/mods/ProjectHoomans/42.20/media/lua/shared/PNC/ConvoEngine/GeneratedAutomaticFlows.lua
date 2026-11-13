-- Persistent generated-flow entry point. Definitions are regenerated from the
-- live registered capability catalog on every worker/game restart.
local Generator = require
    "PNC/ConvoEngine/FlowGenerator"
local Manifest = require
    "PNC/ConvoEngine/FlowManifest"
local Catalog = PNC.Semantics.CapabilityCatalog
local artifact = Generator.Build(Catalog)
artifact.manifest = Manifest
return artifact
