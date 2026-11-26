-- Project Hoomans thin adopter shim for PsychopatzCore's shared ConvoDSL_Loader.
PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local CoreLoader = require "PsychopatzCore/ConvoEngine/ConvoDSL/ConvoDSL_Loader"
CoreLoader.BASE_MOD_ID = "ProjectHoomans"
return CoreLoader
