local _G = getfenv(0)
local lastHitter = _G.object

local core, behaviorLib = lastHitter.core, lastHitter.behaviorLib

local BotEcho = core.BotEcho

lastHitter.trackedCreeps = lastHitter.trackedCreeps or {}
lastHitter.focusCreeps = lastHitter.focusCreeps or {}

DmgInfo = {m = 0.0, c = 0.0, hpList = {}, timeList = {}, lastUpdateTime = 0}

function DmgInfo:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end
																    
function DmgInfo:update(hp)
	local timeNow = HoN.GetMatchTime()
	
	if self.hpList and self.hpList[#self.hpList] - hp > 0 then
		table.insert(self.hpList, hp)
		table.insert(self.timeList, timeNow)
	end
end

function DmgInfo:LeastSquaresFit()
  if #self.timeList > 1 then
  	local xsum,ysum,xxsum,yysum,xysum = 0.0,0.0,0.0,0.0,0.0
  	local m,c,d
  	local n = #self.timeList
  
  	for i = 1,n do
  		local x,y = self.timeList[i],self.hpList[i]
  		xsum = xsum + x
  		ysum = ysum + y
  		xxsum = xxsum + x*x
  		yysum = yysum + y*y
  		xysum = xysum + x*y
  	end
  
  	d = n*xxsum - xsum*xsum
  	m = (n*xysum - xsum*ysum)/d
  	c = (xxsum*ysum - xysum*xsum)/d
  
  	self.m = m
    self.c = c
  end
end

local onthinkOld = lastHitter.onthink 
function lastHitter:onthink(tGameVariables)
	if core.unitSelf then
	  local unitsLocal = core.AssessLocalUnits(self) 
	  local enemies = unitsLocal.EnemyCreeps
	  for i,unit in pairs(enemies) do
			if self.trackedCreeps[unit] then
				self.trackedCreeps[unit]:update(unit:GetHealth())
			else
				local hp = {unit:GetHealth()}
				local time = {HoN.GetMatchTime()}
				self.trackedCreeps[unit] = DmgInfo:new{hpList = hp, timeList = time}
			end
	  end

		for unit, v in pairs(self.trackedCreeps) do
			local dmgInfo = self.trackedCreeps[unit]
      if unit:GetHealth() == 0 then
				self.trackedCreeps[unit] = nil
			else
        dmgInfo:LeastSquaresFit()
      end

      if dmgInfo.m ~= 0.0 and dmgInfo.c ~= 0.0 then
        BotEcho(string.format("		- %s dead in: %g", tostring(unit), -dmgInfo.c/dmgInfo.m-HoN.GetMatchTime()))
        local lifeExpectancy = -dmgInfo.c/dmgInfo.m-HoN.GetMatchTime()
        if lifeExpectancy < 2100 then
          self.focusCreeps[unit] = lifeExpectancy
        end
      end

		end
	end
	
	onthinkOld(self, tGameVariables)
end

function behaviorLib.GetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep) --called pretty much constantly
  local bDebugEchos = false
  -- prefers LH over deny

local function GetAttackDamageOnCreep(botBrain, unitCreepTarget)


    if not unitCreepTarget or not core.CanSeeUnit(botBrain, unitCreepTarget) then
        return nil
    end

    local unitSelf = core.unitSelf

	BotEcho("Focused creeps: ")
	for i,v in pairs(lastHitter.focusCreeps) do
		BotEcho(string.format("		- %s", tostring(i)))
    if unit:GetHealth() == 0 then
				self.focusCreeps[unit] = nil
	  end	
	end

    --Get info about the target we are about to attack
    local vecSelfPos = unitSelf:GetPosition()
    local vecTargetPos = unitCreepTarget:GetPosition()
    local nDistSq = Vector3.Distance2DSq(vecSelfPos, vecTargetPos)
    local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)
    local nTargetHealth = unitCreepTarget:GetHealth()
    local nDamageMin = unitSelf:GetFinalAttackDamageMin()
>>>>>>> 4c59ffa2946a92ca7b5324e0fc56b1ff17006f6e


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


    --Determine the damage expected on the creep by other towers
    for i, unitTower in pairs(tNearbyAttackingTowers) do
        if unitTower:GetAttackTarget() == unitCreepTarget then
            local nTowerAttacks = 1 + math.floor(unitTower:GetAttackSpeed() * nProjectileTravelTime)
            nExpectedTowerDamage = nExpectedTowerDamage + (unitTower:GetFinalAttackDamageMin() +1) * nTowerAttacks
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
      local armor = unitEnemyCreep:GetArmor() -- 5
      local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)
      nDamageMin = nDamageMin*dmgReduc
        --Only attack if, by the time our attack reaches the target
        -- the damage done by other sources brings the target's health
        -- below our minimum damage
        if nDamageMin >= (nTargetHealth - dmgReduc * GetAttackDamageOnCreep(botBrain, unitEnemyCreep)) then
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
        if nDamageMin >= (nTargetHealth - dmgReduc * GetAttackDamageOnCreep(botBrain, unitAllyCreep)) then
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
