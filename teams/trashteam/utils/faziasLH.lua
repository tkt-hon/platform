
local _G = getfenv(0)
local lastHitter = _G.object

local core, behaviorLib = lastHitter.core, lastHitter.behaviorLib

local BotEcho = core.BotEcho

function behaviorLib.GetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep)
  local unitSelf = core.unitSelf
  local minDmg = unitSelf:GetFinalAttackDamageMin()
  core.FindItems(botBrain)
  local ProjSpeed = unitSelf:GetAttackProjectileSpeed()

  if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then
    local nTargetHealth = unitEnemyCreep:GetHealth()
    local tNearbyAllyCreeps = core.localUnits['AllyCreeps']
    local tNearbyAllyTowers = core.localUnits['AllyTowers']
    local nExpectedCreepDamage = 0
    local nExpectedTowerDamage = 0


    local vecTargetPos = unitEnemyCreep:GetPosition()
    local nProjectileTravelTime = Vector3.Distance2D(unitSelf:GetPosition(), vecTargetPos) / nProjectileSpeed
    for i, unitCreep in pairs(tNearbyAllyCreeps) do
        local nCreepAttacks = 1 + math.floor(unitCreep:GetAttackSpeed() * nProjectileTravelTime)
        nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
      end
    end

    for i, unitTower in pairs(tNearbyAllyTowers) do
      if unitTower:GetAttackTarget() == unitEnemyCreep then
        --if unitTower:IsAttackReady() then


        local nTowerAttacks = 1 + math.floor(unitTower:GetAttackSpeed() * nProjectileTravelTime)
        nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
        --end
      end
    end

    --TODO: implement
    if wouldLHbeSuccessfulllogichere then
      local bActuallyLH = true

      if bActuallyLH then
        return unitEnemyCreep
      end
    end
  end
