--AmunRaBot v1.0
-- By community member St0l3n_ID
-- Modified by Mahlalasti

local _G = getfenv(0)
local amunra = _G.object

runfile 'bots/amunra/amunra_main.lua'

local tinsert = _G.table.insert

local core, behaviorLib = amunra.core, amunra.behaviorLib

amunra.purseMax = 4400
amunra.purseMin = 2000

function behaviorLib.bigPurseUtility(botBrain)
  local level = core.unitSelf:GetLevel()

  local bDebugEchos = false

  local Clamp = core.Clamp
  local m = (100/(amunra.purseMax - amunra.purseMin))
  nUtil = m*botBrain:GetGold() - m*amunra.purseMin
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
