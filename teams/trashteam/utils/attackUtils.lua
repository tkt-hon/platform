local _G = getfenv(0)
local lastHitter = _G.object

local core, behaviorLib = lastHitter.core, lastHitter.behaviorLib

local BotEcho = core.BotEcho

runfile 'predictiveLasthittingVesa.lua'

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
  local armor = unitCreepTarget:GetArmor()
  local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)
  nDamageMin = nDamageMin*dmgReduc


  --Get projectile info
  local nProjectileSpeed = unitSelf:GetAttackProjectileSpeed()
  local nProjectileTravelTime = Vector3.Distance2D(vecSelfPos, vecTargetPos) / nProjectileSpeed
  if bDebugEchos then BotEcho ("Projectile travel time: " .. nProjectileTravelTime ) end

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
      nExpectedCreepDamage = nExpectedCreepDamage + (unitCreep:GetFinalAttackDamageMin() +1)* nCreepAttacks
    end
  end


  --Determine the damage expected on the creep by other tower
  for i, unitTower in pairs(tNearbyAttackingTowers) do
    if unitTower:GetAttackTarget() == unitCreepTarget then
  	  local nTowerAttacks = 1 + math.floor(unitTower:GetAttackSpeed() * nProjectileTravelTime)
      nExpectedTowerDamage = nExpectedTowerDamage + (unitTower:GetFinalAttackDamageMin() +1) * nTowerAttacks
    end
  end


  return dmgReduc*(nExpectedCreepDamage + nExpectedTowerDamage)
end


function behaviorLib.GetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep) --called pretty much constantly
  local bDebugEchos = false


  --Get info about self
  local unitSelf = core.unitSelf
  local nDamageMin = unitSelf:GetFinalAttackDamageMin()

	for unit,dmgInfo in pairs(botBrain.focusCreeps) do
		if unit and core.CanSeeUnit(botBrain, unit) then
		  if unitEnemyCreep and  then
				
		    local nTargetHealth = unitEnemyCreep:GetHealth()
		    local armor = unitEnemyCreep:GetArmor() -- 5
		    local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)
		    nDamageMin = nDamageMin*dmgReduc

				local killTime = (nDamageMin-dmgInfo.c)/dmgInfo.c

		    --Only attack if, by the time our attack reaches the target
		    -- the damage done by other sources brings the target's health
		    -- below our minimum damage
		    if killTime <= HoN.GetMatchTime()then
		      if bDebugEchos then BotEcho("Returning an enemy") end
		      return unitEnemyCreep
		    end
		  end
		
		
		  if unitAllyCreep then
		
		    local nTargetHealth = unitAllyCreep:GetHealth()
		    local armor = unitAllyCreep:GetArmor() -- 5
		    local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)
		    nDamageMin = nDamageMin*dmgReduc
		
		
		    --Only attack if, by the time our attack reaches the target
		    -- the damage done by other sources brings the target's health
		    -- below our minimum damage
				local killTime = (nDamageMin-dmgInfo.c)/dmgInfo.c

		    --Only attack if, by the time our attack reaches the target
		    -- the damage done by other sources brings the target's health
		    -- below our minimum damage
		    if killTime <= HoN.GetMatchTime()then
		        return unitAllyCreep
		    end
		  end
		end
	end

  return nil
end


function AttackCreepsExecuteOverride(botBrain)
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
    local armor = unitCreepTarget:GetArmor()
    local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)
    nDamageMin = nDamageMin*dmgReduc

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
object.AttackCreepsExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.AttackCreepsBehavior["Execute"] = AttackCreepsExecuteOverride
