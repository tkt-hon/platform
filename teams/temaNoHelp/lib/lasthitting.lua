local _G = getfenv(0)
local lasthitter = _G.object

local core, behaviorLib = lasthitter.core, lasthitter.behaviorLib

--------------------------------------------------
--    SoulReapers's Predictive Last Hitting Helper
--
--    Assumes that you have vision on the creep
--    passed in to the function
--
--    Developed by paradox870
--------------------------------------------------
local function GetAttackDamageOnCreep(botBrain, unitCreepTarget)


  if not unitCreepTarget or not core.CanSeeUnit(botBrain, unitCreepTarget) then
    return nil
  end


  local unitSelf = core.unitSelf


  --Get info about the target we are about to attack
  local vecSelfPos = unitSelf:GetPosition()
  local vecTargetPos = unitCreepTarget:GetPosition()
  local nDistSq = Vector3.Distance2DSq(vecSelfPos, vecTargetPos)
  local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)
  local nTargetHealth = unitCreepTarget:GetHealth()
  local nDamageMin = unitSelf:GetFinalAttackDamageMin()


  local nProjectileTravelTime = nil
  if unitSelf:GetAttackType() == "ranged" then
    nProjectileTravelTime = Vector3.Distance2D(vecSelfPos, vecTargetPos) / unitSelf:GetAttackProjectileSpeed()
  else
    nProjectileTravelTime = Vector3.Distance2D(vecSelfPos, vecTargetPos) / unitSelf:GetMoveSpeed()
  end

  local nExpectedCreepDamage = 0
  local nExpectedTowerDamage = 0
  local tNearbyAttackingCreeps = nil
  local tNearbyAttackingTowers = nil


  --Get the creeps and towers on the opposite team
  -- of our target
  if unitCreepTarget:GetTeam() == unitSelf:GetTeam() then
    tNearbyAttackingCreeps = core.localUnits['EnemyCreeps']
    tNearbyAttackingTowers = core.localUnits['EnemyTowers']
  else
    tNearbyAttackingCreeps = core.localUnits['AllyCreeps']
    tNearbyAttackingTowers = core.localUnits['AllyTowers']
  end


  --Determine the damage expected on the creep by other creeps
  for i, unitCreep in pairs(tNearbyAttackingCreeps) do
    if unitCreep:GetAttackTarget() == unitCreepTarget then
      local nCreepAttacks = 1 + math.floor(unitCreep:GetAttackSpeed() * nProjectileTravelTime)
      nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
    end
  end


  --Determine the damage expected on the creep by other towers
  for i, unitTower in pairs(tNearbyAttackingTowers) do
    if unitTower:GetAttackTarget() == unitCreepTarget then
      local nTowerAttacks = 1 + math.floor(unitTower:GetAttackSpeed() * nProjectileTravelTime)
      nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
    end
  end


  return nExpectedCreepDamage + nExpectedTowerDamage
end


function behaviorLib.GetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep) --called pretty much constantly
  local bDebugEchos = false


  --Get info about self
  local unitSelf = core.unitSelf
  local nDamageMin = unitSelf:GetFinalAttackDamageMin()


  if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then
    local nTargetHealth = unitEnemyCreep:GetHealth()
    --Only attack if, by the time our attack reaches the target
    -- the damage done by other sources brings the target's health
    -- below our minimum damage
    if nDamageMin >= (nTargetHealth - GetAttackDamageOnCreep(botBrain, unitEnemyCreep)) then
      if bDebugEchos then BotEcho("Returning an enemy") end
      return unitEnemyCreep
    end
  end


  if unitAllyCreep then
    local nTargetHealth = unitAllyCreep:GetHealth()


    --Only attack if, by the time our attack reaches the target
    -- the damage done by other sources brings the target's health
    -- below our minimum damage
    if nDamageMin >= (nTargetHealth - GetAttackDamageOnCreep(botBrain, unitAllyCreep)) then
      local bActuallyDeny = true

      --[Difficulty: Easy] Don't deny
      if core.nDifficulty == core.nEASY_DIFFICULTY then
        bActuallyDeny = false
      end

      -- [Tutorial] Hellbourne *will* deny creeps after **** gets real
      if core.bIsTutorial and core.bTutorialBehaviorReset == true and core.myTeam == HoN.GetHellbourneTeam() then
        bActuallyDeny = true
      end

      if bActuallyDeny then
        if bDebugEchos then BotEcho("Returning an ally") end
        return unitAllyCreep
      end
    end
  end


  return nil
end


local function AttackCreepsExecuteOverride(botBrain)
  local unitSelf = core.unitSelf
  local unitCreepTarget = core.unitCreepTarget


  if unitCreepTarget and core.CanSeeUnit(botBrain, unitCreepTarget) then
    --Get info about the target we are about to attack
    local vecSelfPos = unitSelf:GetPosition()
    local vecTargetPos = unitCreepTarget:GetPosition()
    local nDistSq = Vector3.Distance2DSq(vecSelfPos, vecTargetPos)
    local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)
    local nTargetHealth = unitCreepTarget:GetHealth()
    local nDamageMin = unitSelf:GetFinalAttackDamageMin()

    --Only attack if, by the time our attack reaches the target
    -- the damage done by other sources brings the target's health
    -- below our minimum damage, and we are in range and can attack right now
    if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() and nDamageMin >= (nTargetHealth - GetAttackDamageOnCreep(botBrain, unitCreepTarget)) then
      core.OrderAttackClamp(botBrain, unitSelf, unitCreepTarget)


      --Otherwise get within 70% of attack range if not already
      -- This will decrease travel time for the projectile
    elseif (nDistSq > nAttackRangeSq * 0.5) then
      local vecDesiredPos = core.AdjustMovementForTowerLogic(vecTargetPos)
      core.OrderMoveToPosClamp(botBrain, unitSelf, vecDesiredPos, false)


      --If within a good range, just hold tight
    else
      core.OrderHoldClamp(botBrain, unitSelf, false)
    end
  else
    return false
  end
end
behaviorLib.AttackCreepsBehavior["Execute"] = AttackCreepsExecuteOverride
