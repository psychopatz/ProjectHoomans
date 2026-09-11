-- Compatibility import for callers that still resolve the former Colony
-- Management debug module. The implementation now belongs to the Colonist
-- DEBUG tab so both surfaces share one snapshot/action contract.
return require "PNC/UI/Colonist/PNC_ColonistDebug"
