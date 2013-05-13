local _G = getfenv(0)
local herobot = _G.object

local core, behaviorLib, eventsLib = herobot.core, herobot.behaviorLib, herobot.eventsLib

local avoidMagmusPosition = nil

local function CalculatedMovementTarget(vecCurrent, vecDanger)
  avoidMagmusPosition = vecCurrent + Vector3.Normalize(vecCurrent - vecDanger) * 200
end

function herobot:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  if EventData.Type == "Debuff" and EventData.StateName == "State_Magmar_Ability2_Damageeffects" then
    local hero = EventData.TargetUnit
    local beha = hero:GetBehavior()
    local position = nil
    if beha then
      position = beha:GetGoalPosition()
      local target = beha:GetAttackTarget()
      if target then
        position = target:GetPosition()
      end
    end
    if not position then
      position = core.allyWell:GetPosition()
    end
    CalculatedMovementTarget(hero:GetPosition(), position)
  elseif EventData.Type == "State_End" and EventData.StateName == "State_Magmar_Ability2_Damageeffects" then
    avoidMagmusPosition = nil
  end
end
-- override combat event trigger function.
herobot.oncombateventOld = herobot.oncombatevent
herobot.oncombatevent = herobot.oncombateventOverride

local PositionSelfLogicOld = behaviorLib.PositionSelfLogic
function behaviorLib.PositionSelfLogic(botBrain)
  if avoidMagmusPosition then
    core.BotEcho(tostring(avoidMagmusPosition))
    core.DrawXPosition(avoidMagmusPosition, "yellow")
    return avoidMagmusPosition, nil
  else
    return PositionSelfLogicOld(botBrain)
  end
end
