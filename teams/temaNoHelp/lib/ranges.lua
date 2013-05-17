local _G = getfenv(0)
local herobot = _G.object

local tinsert, tremove, max, format = _G.table.insert, _G.table.remove, _G.math.max, _G.string.format

local core, behaviorLib = herobot.core, herobot.behaviorLib

function behaviorLib.ProxToEnemyTowerUtility(unit, unitClosestEnemyTower)
  local bDebugEchos = true

  local nUtility = 0

  if unitClosestEnemyTower then
    local nDist = Vector3.Distance2D(unitClosestEnemyTower:GetPosition(), unit:GetPosition())
    local nTowerRange = core.GetAbsoluteAttackRangeToUnit(unitClosestEnemyTower, unit)
    local nBuffers = unit:GetBoundsRadius() + unitClosestEnemyTower:GetBoundsRadius()

    nUtility = -1 * core.ExpDecay((nDist - nBuffers), 100, nTowerRange, 2)
    nUtility = nUtility * 2

  end

  nUtility = core.Clamp(nUtility, -100, 0)

  return nUtility
end
