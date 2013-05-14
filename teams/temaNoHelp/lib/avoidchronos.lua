local _G = getfenv(0)
local herobot = _G.object

local core, behaviorLib = herobot.core, herobot.behaviorLib

local PositionSelfLogicOld = behaviorLib.PositionSelfLogic
function behaviorLib.PositionSelfLogic(botBrain)
  local antichronos = core.teamBotBrain.antichronos
  local vecWanted, unitTarget = PositionSelfLogicOld(botBrain)
  if antichronos.IsDangerZone(vecWanted) then
    vecWanted = antichronos.GetBetterPosition(core.unitSelf:GetPosition(), vecWanted)
  end
  return vecWanted, unitTarget
end

local function LocateChronosUltimate()
  local antichronos = core.teamBotBrain.antichronos
  local vecSelf = core.unitSelf:GetPosition()
  if antichronos.IsDangerZone(vecSelf) then
    core.DrawXPosition(vecSelf)
  end
end
