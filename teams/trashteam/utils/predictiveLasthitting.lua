local _G = getfenv(0)
local lastHitter = _G.object

local core, behaviorLib = lastHitter.core, lastHitter.behaviorLib

local BotEcho = core.BotEcho

lastHitter.trackedCreeps = lastHitter.trackedCreeps or {}

DmgInfo = {d = 0.0, hpList = {}, timeList = {}, lastUpdateTime = 0}

function DmgInfo:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end
																    
function DmgInfo:update(hp)
	local timeNow = HoN.GetMatchTime()
--	local deltaTimeS = (timeNow - self.lastUpdateTime)/1000.0
	
	if #self.hpList - hp > 0 then
--	  self.d = (self.lastHp - hp)/deltaTimeS
--		self.lastUpdateTime = timeNow
		self.hpList.insert(hp)
		self.timeList.insert(timeNow)
	end

--	self.lastHp = hp
end

function DmgInfo:least_squares_fit(xx,yy)
	local xsum,ysum,xxsum,yysum,xysum = 0,0,0,0,0
	local m,c,d
	local n = #xx

	for i = 1,n do
		local x,y = xx[i],yy[i]
		xsum = xsum + x
		ysum = ysum + y
		xxsum = xxsum + x*x
		yysum = yysum + y*y
		xysum = xysum + x*y
	end

	d = n*xxsum - xsum*xsum
	m = (n*xysum - xsum*ysum)/d
	c = (xxsum*ysum - xysum*xsum)/d

	return m,c
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
			if unit:GetHealth() == 0 then
				self.trackedCreeps[unit] = nil
			end
		end
	end
	
	onthinkOld(self, tGameVariables)
end

function behaviorLib.GetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep) --called pretty much constantly
  local bDebugEchos = false
  -- prefers LH over deny


  local unitSelf = core.unitSelf
  local nDamageMin = unitSelf:GetFinalAttackDamageMin()

  core.FindItems(botBrain)

	BotEcho("Tracked creeps: ")
	for i,v in pairs(lastHitter.trackedCreeps) do
		BotEcho(string.format("		- %s, %g", tostring(i), v.d))
	end

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
