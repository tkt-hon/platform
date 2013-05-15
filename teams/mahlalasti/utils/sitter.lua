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

local function EnemiesNearPosition(vecPosition)
  local tHeroes = HoN.GetUnitsInRadius(vecPosition, core.localCreepRange, core.UNIT_MASK_ALIVE + core.UNIT_MASK_HERO)
  for _, hero in pairs(tHeroes) do
    if hero:GetTeam() == core.enemyTeam then
      return true
    end
  end
  return false
end

local function PreGameSitterExecute(botBrain)
  local gankSpot = nil
  local unitSelf = core.unitSelf
  if core.myTeam == HoN.GetLegionTeam() then
    gankSpot = Vector3.Create(13200.0000, 3600.0000, 128.0000)
  else
    gankSpot = Vector3.Create(3100.0000, 12300.0000, 128.0000)
  end
  if EnemiesNearPosition(unitSelf:GetPosition()) then
    return false
  else
    return core.OrderMoveToPosClamp(botBrain, unitSelf, gankSpot)
  end
end
behaviorLib.PreGameSitterExecute = PreGameSitterExecute

local function EnemiesNearPosition(vecPosition)
  local tHeroes = HoN.GetUnitsInRadius(vecPosition, core.localCreepRange, core.UNIT_MASK_ALIVE + core.UNIT_MASK_HERO)
  for _, hero in pairs(tHeroes) do
    if hero:GetTeam() == core.enemyTeam then
      return true
    end
  end
  return false
end

local function PositionSelfExecuteOverride(botBrain)
  local unitSelf = core.unitSelf
  local curTime = HoN.GetMatchTime()
  if unitSelf.isSitter and not sitter.bMetEnemies and 0 < curTime and curTime < core.MinToMS(1) then
    if EnemiesNearPosition(unitSelf:GetPosition()) then
      sitter.bMetEnemies = true
      return core.OrderAttackPositionClamp(botBrain, unitSelf, core.GetGroupCenter(core.AssessLocalUnits(botBrain).EnemyHeroes))
    end
    return core.OrderHold(botBrain, unitSelf)
  end
  return behaviorLib.PositionSelfExecute(botBrain)
end
behaviorLib.PositionSelfBehavior["Execute"] = PositionSelfExecuteOverride

local function CustomHarassUtilityFnOverride(hero)
  if HoN.GetMatchTime() < core.MinToMS(1) then
    return 100
  end
  return behaviorLib.CustomHarassUtilityOld(hero)
end
behaviorLib.CustomHarassUtilityOld = behaviorLib.CustomHarassUtility
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride
