--HammerstormBot v1.0
-- Modified by Mahlalasti

local _G = getfenv(0)
local hammerstorm = _G.object

local tinsert = _G.table.insert

runfile 'bots/hammerstorm/hammerstorm_main.lua'
runfile "bots/teams/mahlalasti/mahlalasti_courier.lua"

local core, behaviorLib = hammerstorm.core, hammerstorm.behaviorLib

function hammerstorm:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)
  local matchtime = HoN.GetMatchTime()
  if matchtime > 0 and matchtime % 5000 == 0 then
    behaviorLib.ShopExecute(self)
  end
  self:onthinkCourier()
end
hammerstorm.onthinkOld = hammerstorm.onthink
hammerstorm.onthink = hammerstorm.onthinkOverride

hammerstorm.purseMax = 4400
hammerstorm.purseMin = 2000

function behaviorLib.bigPurseUtility(botBrain)
  local level = core.unitSelf:GetLevel()
  local bDebugEchos = false
  local Clamp = core.Clamp
  local m = (100/(hammerstorm.purseMax - hammerstorm.purseMin))
  nUtil = m*botBrain:GetGold() - m*hammerstorm.purseMin
  nUtil = Clamp(nUtil,0,100)
  if bDebugEchos then core.BotEcho("Bot return Priority:" ..nUtil) end
  return nUtil
end

-- Execute
function behaviorLib.bigPurseExecute(botBrain)
  local mana = core.unitSelf:GetManaPercent()
  local unitSelf = core.unitSelf
  local wellPos = core.allyWell and core.allyWell:GetPosition() or behaviorLib.PositionSelfBackUp()
  core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, wellPos, false)
end
behaviorLib.bigPurseBehavior = {}
behaviorLib.bigPurseBehavior["Utility"] = behaviorLib.bigPurseUtility
behaviorLib.bigPurseBehavior["Execute"] = behaviorLib.bigPurseExecute
behaviorLib.bigPurseBehavior["Name"] = "bigPurse"
tinsert(behaviorLib.tBehaviors, behaviorLib.bigPurseBehavior)
