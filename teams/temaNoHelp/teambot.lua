local _G = getfenv(0)
local teambot = _G.object

runfile 'bots/core_teambot.lua'
runfile 'bots/teams/temaNoHelp/lib/antimagmus.lua'

teambot.myName = 'temaNoHelp Team'


------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function teambot:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
teambot.onthinkOld = teambot.onthink
teambot.onthink = teambot.onthinkOverride
