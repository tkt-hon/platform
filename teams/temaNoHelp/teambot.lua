local _G = getfenv(0)
local teambot = _G.object

runfile 'bots/core_teambot.lua'
runfile 'bots/lib/rune_controlling/init_team.lua'
runfile 'bots/teams/temaNoHelp/lib/antimagmus.lua'
runfile 'bots/teams/temaNoHelp/lib/antichronos.lua'

teambot.myName = 'temaNoHelp'

local metadata = teambot.metadata
function teambot:GetDesiredLane()
  return metadata.GetMiddleLane()
end

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
