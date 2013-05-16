local _G = getfenv(0)
local lastHitter = _G.object

local core, behaviorLib = lastHitter.core, lastHitter.behaviorLib

local BotEcho = core.BotEcho

runfile 'bots/teams/trashteam/utils/predictiveLasthittingVesa.lua'


function behaviorLib.GetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep) --called pretty much constantly
  local bDebugEchos = false

  if core.alalalal then
    return nil
  end

  local matchTime = HoN.GetMatchTime()

  --Get info about self
  local unitSelf = core.unitSelf
  local nDamageMin = unitSelf:GetFinalAttackDamageMin()
  local myTeam = botBrain:GetTeam()
  local myASPD = unitSelf:GetAttackSpeed()*100
  local myPos = unitSelf:GetPosition()
  local nProjectileSpeed = 0
  local attaType = unitSelf:GetAttackType()
  local isRanged = false
  if attaType == "ranged" then
    isRange = true
    nProjectileSpeed = unitSelf:GetAttackProjectileSpeed()
  end
  core.BotEcho("GetCreepAttackTarget")
	for unit,dmgInfo in pairs(botBrain.focusCreeps) do
		if unit and core.CanSeeUnit(botBrain, unit) then
      if isRanged then
        local nProjectileTravelTime = Vector3.Distance2D(myPos, unit:GetPosition()) / nProjectileSpeed
      end
      local nTargetHealth = unit:GetHealth()
      local armor = unit:GetArmor() -- 5
      local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)
      nDamageMin = nDamageMin*dmgReduc


      local killTime = (nDamageMin-dmgInfo.c)/dmgInfo.c

      if not(myTeam == unit:GetTeam()) then
		    --Only attack if, by the time our attack reaches the target
		    -- the damage done by other sources brings the target's health
		    -- below our minimum damage
		    if killTime <= matchTime then
		      if bDebugEchos then BotEcho("Returning an enemy") end
          core.unitCreepTargetdmgInfo = dmgInfo
          core.alalalal = true
		      return unit
		    end
		  end


      if myTeam == unit:GetTeam() then
		    --Only attack if, by the time our attack reaches the target
		    -- the damage done by other sources brings the target's health
		    -- below our minimum damage
		    if killTime <= matchTime then
		      if bDebugEchos then BotEcho("Returning an ally") end
          core.unitCreepTargetdmgInfo = dmgInfo
          core.alalalal = true
          return unit
		    end
		  end
		end
	end

  return nil
end


function AttackCreepsExecuteOverride(botBrain)
  local unitSelf = core.unitSelf
  local unitCreepTarget = core.unitCreepTarget
  local matchTime = HoN.GetMatchTime()
  local dmgInfo = core.unitCreepTargetdmgInfo
  local vecSelfPos = unitSelf:GetPosition()
  core.alalalal = false


  core.BotEcho("AttackCreepsExecute")
  if unitCreepTarget and core.CanSeeUnit(botBrain, unitCreepTarget) then

    local attaType = unitSelf:GetAttackType()
    local isRanged = false
    local LastHitDelay = 0
    if attaType == "ranged" then
      isRange = true
      nProjectileSpeed = unitSelf:GetAttackProjectileSpeed()
      local distance = Vector3.Distance2D(vecSelfPos, unitCreepTarget:GetPosition())
      local nProjectileTravelTime = distance / nProjectileSpeed
      LastHitDelay = nProjectileTravelTime*nProjectileSpeed
    else
      LastHitDelay = 50
    end
    --Get info about the target we are about to attack
    local vecTargetPos = unitCreepTarget:GetPosition()
    local nDistSq = Vector3.Distance2DSq(vecSelfPos, vecTargetPos)
    local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)
    local nTargetHealth = unitCreepTarget:GetHealth()
    local nDamageMin = unitSelf:GetFinalAttackDamageMin()
    local armor = unitCreepTarget:GetArmor()
    local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)
    nDamageMin = nDamageMin*dmgReduc

    -- getkillTime if attacked now
    -- TODO: add ranged and some delay
    local killTime = (nDamageMin-dmgInfo.c)/dmgInfo.c - LastHitDelay

    --Only attack if, by the time our attack reaches the target
    -- the damage done by other sources brings the target's health
    -- below our minimum damage, and we are in range and can attack right now
    if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() and killTime <= matchTime  then
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
