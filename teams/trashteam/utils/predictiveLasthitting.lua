local _G = getfenv(0)
local lastHitter = _G.object

local core, behaviorLib = lastHitter.core, lastHitter.behaviorLib

local BotEcho = core.BotEcho

function behaviorLib.GetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep) --called pretty much constantly
  local bDebugEchos = false
  -- prefers LH over deny


  local unitSelf = core.unitSelf
  local nDamageMin = unitSelf:GetFinalAttackDamageMin()

  core.FindItems(botBrain)


  local nProjectileSpeed = unitSelf:GetAttackProjectileSpeed()


  if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then
    local nTargetHealth = unitEnemyCreep:GetHealth()
    local tNearbyAllyCreeps = core.localUnits['AllyCreeps']
    local tNearbyAllyTowers = core.localUnits['AllyTowers']
    local nExpectedCreepDamage = 0
    local nExpectedTowerDamage = 0


    local vecTargetPos = unitEnemyCreep:GetPosition()
    local nProjectileTravelTime = Vector3.Distance2D(unitSelf:GetPosition(), vecTargetPos) / nProjectileSpeed
    if bDebugEchos then BotEcho ("Projectile travel time: " .. nProjectileTravelTime ) end

    --Determine the damage expcted on the creep by other creeps
    for i, unitCreep in pairs(tNearbyAllyCreeps) do
      if unitCreep:GetAttackTarget() == unitEnemyCreep then
        --if unitCreep:IsAttackReady() then
        local nCreepAttacks = 1 + math.floor(unitCreep:GetAttackSpeed() * nProjectileTravelTime)
        nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
        --end
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

    if bDebugEchos then BotEcho ("Excpecting ally creeps to damage enemy creep for " .. nExpectedCreepDamage .. " - using this to anticipate lasthit time") end

    if nDamageMin >= (nTargetHealth - nExpectedCreepDamage - nExpectedTowerDamage) then
      local bActuallyLH = true

      if bActuallyLH then
        if bDebugEchos then BotEcho("Returning an enemy") end
        return unitEnemyCreep
      end
    end
  end


  if unitAllyCreep then
    local nTargetHealth = unitAllyCreep:GetHealth()
    local tNearbyEnemyCreeps = core.localUnits['EnemyCreeps']
    local tNearbyEnemyTowers = core.localUnits['EnemyTowers']
    local nExpectedCreepDamage = 0
    local nExpectedTowerDamage = 0


    local vecTargetPos = unitAllyCreep:GetPosition()
    local nProjectileTravelTime = Vector3.Distance2D(unitSelf:GetPosition(), vecTargetPos) / nProjectileSpeed
    if bDebugEchos then BotEcho ("Projectile travel time: " .. nProjectileTravelTime ) end

    --Determine the damage expcted on the creep by other creeps
    for i, unitCreep in pairs(tNearbyEnemyCreeps) do
      if unitCreep:GetAttackTarget() == unitAllyCreep then
        --if unitCreep:IsAttackReady() then
        local nCreepAttacks = 1 + math.floor(unitCreep:GetAttackSpeed() * nProjectileTravelTime)
        nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
        --end
      end
    end


    for i, unitTower in pairs(tNearbyEnemyTowers) do
      if unitTower:GetAttackTarget() == unitAllyCreep then
        --if unitTower:IsAttackReady() then


        local nTowerAttacks = 1 + math.floor(unitTower:GetAttackSpeed() * nProjectileTravelTime)
        nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
        --end
      end
    end

    if nDamageMin >= (nTargetHealth - nExpectedCreepDamage - nExpectedTowerDamage) then
      local bActuallyDeny = true


      if bActuallyDeny then
        if bDebugEchos then BotEcho("Returning an ally") end
        return unitAllyCreep
      end
    end
  end


  return nil
end


function AttackCreepsExecuteOverride(botBrain)
  local unitSelf = core.unitSelf
  local unitCreepTarget = core.unitCreepTarget


  if unitCreepTarget and core.CanSeeUnit(botBrain, unitCreepTarget) then
    local vecTargetPos = unitCreepTarget:GetPosition()
    local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), vecTargetPos)
    local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)

    local nDamageMin = unitSelf:GetFinalAttackDamageMin()


    if unitCreepTarget ~= nil then
      local nProjectileSpeed = unitSelf:GetAttackProjectileSpeed()
      local nTargetHealth = unitCreepTarget:GetHealth()


      local vecTargetPos = unitCreepTarget:GetPosition()
      local nProjectileTravelTime = Vector3.Distance2D(unitSelf:GetPosition(), vecTargetPos) / nProjectileSpeed
      if bDebugEchos then BotEcho ("Projectile travel time: " .. nProjectileTravelTime ) end

      local nExpectedCreepDamage = 0
      local nExpectedTowerDamage = 0
      local tNearbyAttackingCreeps = nil
      local tNearbyAttackingTowers = nil


      if unitCreepTarget:GetTeam() == unitSelf:GetTeam() then
        tNearbyAttackingCreeps = core.localUnits['EnemyCreeps']
        tNearbyAttackingTowers = core.localUnits['EnemyTowers']
      else
        tNearbyAttackingCreeps = core.localUnits['AllyCreeps']
        tNearbyAttackingTowers = core.localUnits['AllyTowers']
      end

      --Determine the damage expcted on the creep by other creeps
      for i, unitCreep in pairs(tNearbyAttackingCreeps) do
        if unitCreep:GetAttackTarget() == unitCreepTarget then
          --if unitCreep:IsAttackReady() then
          local nCreepAttacks = 1 + math.floor(unitCreep:GetAttackSpeed() * nProjectileTravelTime)
          nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
          --end
        end
      end

      --Determine the damage expcted on the creep by other creeps
      for i, unitTower in pairs(tNearbyAttackingTowers) do
        if unitTower:GetAttackTarget() == unitCreepTarget then
          --if unitTower:IsAttackReady() then
          local nTowerAttacks = 1 + math.floor(unitTower:GetAttackSpeed() * nProjectileTravelTime)
          nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
          --end
        end
      end


      if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() and nDamageMin>=(unitCreepTarget:GetHealth() - nExpectedCreepDamage - nExpectedTowerDamage) then --only kill if you can get gold
        --only attack when in nRange, so not to aggro towers/creeps until necessary, and move forward when attack is on cd
        core.OrderAttackClamp(botBrain, unitSelf, unitCreepTarget)
      elseif (nDistSq > nAttackRangeSq * 0.6) then
        --SR is a ranged hero - get somewhat closer to creep to slow down projectile travel time
        --BotEcho("MOVIN OUT")
        local vecDesiredPos = core.AdjustMovementForTowerLogic(vecTargetPos)
        core.OrderMoveToPosClamp(botBrain, unitSelf, vecDesiredPos, false)
      else
        core.OrderHoldClamp(botBrain, unitSelf, false)
      end
    end
  else
    return false
  end
end

object.AttackCreepsExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.AttackCreepsBehavior["Execute"] = AttackCreepsExecuteOverride
