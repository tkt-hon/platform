local _G = getfenv(0)
local self = _G.object

local core, behaviorLib = self.core, self.behaviorLib

local function ProcessDeathChatOverride(unitSource, sSourcePlayerName)
	core.AllChat("I can't understand why all scientists are not atheists.")
end
core.ProcessDeathChat = ProcessDeathChatOverride

local function ProcessKillChatOverride(unitTarget, sTargetPlayerName)
	core.AllChat("In this moment, I am euphoric. Not because of any phony God's blessing. But because,  I am enlightened by my intelligence.")	
end
core.ProcessKillChat = ProcessKillChatOverride

