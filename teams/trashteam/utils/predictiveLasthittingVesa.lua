local _G = getfenv(0)
local lastHitter = _G.object

local core, behaviorLib = lastHitter.core, lastHitter.behaviorLib

local BotEcho = core.BotEcho

lastHitter.trackedCreeps = {}
lastHitter.focusCreeps = {}

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

function lastHitter:onthinkOverride(tGameVariables)
  self:onthinkOld2(tGameVariables)
	self:updateCreepHistory()
end
lastHitter.onthinkOld2 = lastHitter.onthink
lastHitter.onthink = lastHitter.onthinkOverride



--[
function lastHitter:updateCreepHistory(unit)
	self:updateAllCreepHistory()

	if self.trackedCreeps[unit] then
		self.trackedCreeps[unit]:update(unit:GetHealth())
	else
		local hp = {unit:GetHealth()}
		local time = {HoN.GetMatchTime()}
		self.trackedCreeps[unit] = DmgInfo:new{hpList = hp, timeList = time}
	end

end
--]


function lastHitter:updateCreepHistory()
	self:updateAllCreepHistory()

  local unitSelf = core.unitSelf
  local unitsLocal, unitsSorted = HoN.GetUnitsInRadius(unitSelf:GetPosition(), 2000, ALIVE + UNIT, true)
	for _,unit in pairs(unitsLocal) do
		if self.trackedCreeps[unit] then
			self.trackedCreeps[unit]:update(unit:GetHealth())
		else
			local hp = {unit:GetHealth()}
			local time = {HoN.GetMatchTime()}
			self.trackedCreeps[unit] = DmgInfo:new{hpList = hp, timeList = time}
		end
	end
end


function lastHitter:updateAllCreepHistory()
  if self.trackedCreeps == nil then
    return
  end
	for unit, v in pairs(self.trackedCreeps) do
		local dmgInfo = self.trackedCreeps[unit]
    if not unit:IsAlive() then
			self.trackedCreeps[unit] = nil
		else
      dmgInfo:LeastSquaresFit()
      self.trackedCreeps[unit] = dmgInfo
    end
    local matchTime = HoN.GetMatchTime()
    if dmgInfo.m ~= 0.0 and dmgInfo.c ~= 0.0 then
      BotEcho(string.format("		- %s dead in: %g", tostring(unit), -dmgInfo.c/dmgInfo.m))
      BotEcho("                                         " .. tostring(matchTime))
      local lifeExpectancy = -dmgInfo.c/dmgInfo.m-matchTime
      if lifeExpectancy < 1800 then
        --self.focusCreeps[unit] = lifeExpectancy
        self.focusCreeps[unit] = dmgInfo
      end
    end
	end

  for unit, v in pairs(self.focusCreeps) do
    local dmgInfo = self.focusCreeps[unit]
    if not unit:IsAlive() then
      self.focusCreeps[unit] = nil
    else
      self.focusCreeps[unit]:update(unit:GetHealth())
      dmgInfo:LeastSquaresFit()
      self.focusCreeps[unit] = dmgInfo
    end
  end
end



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
    local killTime = (nDamageMin-dmgInfo.c)/dmgInfo.c
    core.BotEcho("killTime vs Matchtime : " .. tostring(killTime) .. " / " .. tostring(matchTime))
    killTime = killTime - LastHitDelay
    core.BotEcho("killTime vs Matchtime : " .. tostring(killTime) .. " / " .. tostring(matchTime) .. " with delay")
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