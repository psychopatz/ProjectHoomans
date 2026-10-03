local OrderSystem = require "PNC/Core/Orders/PNC_OrderSystem_Base"
-- Compatibility contract: function OrderSystem.RecoverStalled remains the
-- bounded direct-order recovery boundary implemented by Actions, and
-- GetMovementRecoveryState remains the PathService observation hook.
require "PNC/Core/Orders/PNC_OrderSystem_Transition"
require "PNC/Core/Orders/PNC_OrderSystem_Recovery"
require "PNC/Core/Orders/PNC_OrderSystem_Actions"

return OrderSystem
