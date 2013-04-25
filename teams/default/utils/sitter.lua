local _G = getfenv(0)
local sitter = _G.object

local core, behaviorLib = sitter.core, sitter.behaviorLib

local function GetCreepAttackTargetOverride(botBrain, unitEnemyCreep, unitAllyCreep)
  if core.unitSelf.isSitter and core.NumberElements(core.AssessLocalUnits(botBrain).AllyHeroes) > 0 then
    unitEnemyCreep = nil
  end
  return behaviorLib.GetCreepAttackTargetOld(botBrain, unitEnemyCreep, unitAllyCreep)
end
behaviorLib.GetCreepAttackTargetOld = behaviorLib.GetCreepAttackTarget
behaviorLib.GetCreepAttackTarget = GetCreepAttackTargetOverride
