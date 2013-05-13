local _G = getfenv(0)
local ophelia = _G.object

ophelia.heroName = "Hero_Ophelia"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/temaNoHelp/lib/avoidmagmus.lua'

local core = ophelia.core

function ophelia:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  local vecAntiMagSpot = core.teamBotBrain.antimagmus.GetAntiMagmusWardSpot()
  if vecAntiMagSpot then
    core.DrawXPosition(vecAntiMagSpot)
  end
  -- custom code here
end
ophelia.onthinkOld = ophelia.onthink
ophelia.onthink = ophelia.onthinkOverride
