--SoulReaperBot v1.0
-- By community member paradox870
-- Modified by Mahlalasti

local _G = getfenv(0)
local soulreaper = _G.object

local tinsert = _G.table.insert

runfile 'bots/soulreaper/soulreaper_main.lua'

local core, behaviorLib = soulreaper.core, soulreaper.behaviorLib

behaviorLib.MidItems = {"Item_PlatedGreaves", "Item_HealthMana2", "Item_Morph"}

soulreaper.purseMax = 4400
soulreaper.purseMin = 2000

function behaviorLib.bigPurseUtility(botBrain)
  local level = core.unitSelf:GetLevel()
  local bDebugEchos = false
  local Clamp = core.Clamp
  local m = (100/(soulreaper.purseMax - soulreaper.purseMin))
  nUtil = m*botBrain:GetGold() - m*soulreaper.purseMin
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
