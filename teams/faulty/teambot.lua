local _G = getfenv(0)
local teambot = _G.object

runfile 'bots/core_teambot.lua'
runfile 'bots/lib/rune_controlling/init_team.lua'

local core = teambot.core
local print, tinsert = _G.print, _G.table.insert
local abs, acos, pi = _G.math.abs, _G.math.acos, _G.math.pi

teambot.myName = 'Faulty'

local tGankers = {}
local tCarries = {
	"Hero_Hammerstorm"
}
local tMidHeroes = {
	"Hero_Mumra"
}
local tSuiciders = {
	"Hero_DiseasedRider"
}
local tSupports = {
	"Hero_Shaman"
}
local tSitters = {
	"Hero_Shaman",
	"Hero_Krixi"
}
local tSnipers = {
	"Hero_Mumra"
}

-- try to find the value from given table
local function tfind(table, value)
	for _,v in ipairs(table) do
		if v == value then
			return true
		end
	end
	return false
end

local function FindMidUnit(units)
	for _, unit in pairs(units) do
		-- first try to find mid and ganker
		if unit and unit.isMid and unit.isGanker then
			return unit.object
		end
	end
	for _, unit in pairs(units) do
		-- if not found, find only mid
		if unit and unit.isMid then
			return unit.object
		end
	end
	return nil
end

local function FindSuicider(units)
	for _, unit in pairs(units) do
		if unit and unit.isSuicide then
			return unit.object
		end
	end
	return nil
end

local function FindSniper(teambot)
	for nUID, unit in pairs(teambot.tAllyBotHeroes) do
		if tfind(tSnipers, unit:GetTypeName()) then
			return unit
		end
	end
	return nil
end

local function VectorAngle(vec1, vec2)
	local nDot = Vector3.Dot(vec1, vec2)
	nDot = nDot/(Vector3.Length(vec1) * Vector3.Length(vec2))
	local nAcos = acos(nDot)
	return nAcos * 180/math.pi
end

local function UID2Name(teambot, nUID)
	if teambot.tEnemyHeroes[nUID] then
		return teambot.tEnemyHeroes[nUID]:GetTypeName()
	elseif teambot.tAllyHeroes[nUID] then
		return teambot.tAllyHeroes[nUID]:GetTypeName()
	else
		return "Unknown("..nUID..")"
	end
end


-- enemy unit
local tPositionBuffer = {}
local nPositionBufferSize = 4
local function UpdatePositionBuffer(nUID, hero)
	local nCount = 0
	local tNewPositionBuffer = {}

	if tPositionBuffer[nUID] then
		for key, value in pairs(tPositionBuffer[nUID]) do
			local nNewKey = key + 1
			tNewPositionBuffer[nNewKey] = value

			nCount = nCount + 1
		end
	end

	tNewPositionBuffer[0] = hero:GetPosition()
	if nCount > nPositionBufferSize then
		tNewPositionBuffer[nCount] = nil
	end

	return tNewPositionBuffer
end

local function PrintPositionBuffers()
	for nUID, array in pairs(tPositionBuffer) do
		print('{')
		for id, pos in pairs(array) do
			print('['..id..']: {'..pos.x..', '..pos.y..'} ,')
		end
		print('}\n')
	end
end

-- if enemy movement vector hits this, we're good.
local nWellRadius = 500

-- function just tests if the movements in given array are predictable
local function IsPredictable(array)
	local wellPos = core.enemyWell:GetPosition()

	if not array[4] then
		return false
	end

	if array[0] == array[4] then
		return false
	end

	local vecMovement   = -array[4] + array[0]
	local vecCurrentPos =  array[0]
	local vecToWell     =  wellPos - vecCurrentPos

	-- here should test the mid points: 1, 2, 3
	local firstToSecond = -array[4] + array[3]
	local firstToThird  = -array[4] + array[2]
	local firstToFourth = -array[4] + array[1]

	local nAngle1 = VectorAngle(firstToSecond, vecMovement)
	local nAngle2 = VectorAngle(firstToThird, vecMovement)
	local nAngle3 = VectorAngle(firstToFourth, vecMovement)

	if nAngle1 < 15 or nAngle2 < 15 or nAngle3 < 15 then
		return false
	end

	local vecProjection = Vector3.Project(vecToWell, vecMovement)

	local nSqrt = (nWellRadius*nWellRadius)
	nSqrt = nSqrt - Vector3.Dot(vecProjection, vecProjection)
	nSqrt = nSqrt + Vector3.Dot(vecToWell, vecToWell)

	if nSqrt > 0 and VectorAngle(vecMovement, vecToWell) < 10 then
		core.DrawDebugArrow(array[4], array[0], 'blue')
		core.DrawDebugLine(vecCurrentPos, wellPos, 'red')
		return true
	else
		return false
	end
end

-- first version
-- quick-and-dirty iterative algorithm.
--
-- @return the position on map to snipe
local function FindCollisionPoint(teambot, sniper, heroUnit)
	local wellPos = core.enemyWell:GetPosition()
	local sniperPos = sniper:GetPosition()
	local skill = sniper:GetAbility(3)
	local nProjectileSpeed = 1200 -- hardcoded, for nao.
	local nCastTime = skill:GetCastTime()
	local nHeroSpeed = heroUnit:GetMoveSpeed();
	local heroPos = heroUnit:GetPosition()
	local vecToWell = wellPos - heroPos

	-- minimal projectile vector, and its travel time
	local vecProjectileMin, timeMin = nil, nil

	local nIterations = 30
	local vecAdd = vecToWell/nIterations
	for i = 1, nIterations, 1 do
		local currentPos = heroPos + (vecAdd * i)

		local nHeroDistance = Vector3.Distance2D(heroPos, currentPos)
		local nProjectileDistance = Vector3.Distance2D(sniperPos, currentPos)

		local nHeroArriveTime = nHeroDistance/nHeroSpeed
		local nProjectileArriveTime = nCastTime + nProjectileDistance/nProjectileSpeed

		if not timeMin then
			vecProjectileMin = currentPos - sniperPos
			timeMin = abs(nHeroArriveTime - nProjectileArriveTime)
		end

		if abs(nHeroArriveTime - nProjectileArriveTime) < timeMin then
			vecProjectileMin = currentPos - sniperPos
			timeMin = abs(nHeroArriveTime - nProjectileArriveTime)
		end
	end

	core.DrawDebugLine(sniperPos, sniperPos + vecProjectileMin, 'red')

	return (sniperPos + vecProjectileMin)
end

local nTicks = 0
local nUpdateInterval = 4

-- health must be below this to start predicting enemy movements
local nHealthPreThreshold = 0.4

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function teambot:onthinkOverride(tGameVariables)
	self:onthinkOld(tGameVariables)

	nTicks = nTicks + 1

	-- custom code here
	if self.teamBotBrainInitialized and (nTicks%nUpdateInterval) == 0 then
		local tEnemyHeroes = self.tEnemyHeroes
		for nUID, unitHero in pairs(tEnemyHeroes) do
			if core.CanSeeUnit(self, unitHero) then
				local nHealthPercent = unitHero:GetHealthPercent()
				if nHealthPercent < nHealthPreThreshold then
					tPositionBuffer[nUID] = UpdatePositionBuffer(nUID, unitHero)
				end
			else
				tPositionBuffer[nUID] = nil
			end
		end

		local sniper = FindSniper(teambot)
		if not sniper then
			return
		end

		for nUID, arr in pairs(tPositionBuffer) do
			if IsPredictable(tPositionBuffer[nUID]) then
				print(UID2Name(self, nUID)..': can predict\n')
				local pos = FindCollisionPoint(self, sniper, teambot.tEnemyHeroes[nUID])
				if pos then
					teambot.snipeTargetPos = pos
					print("YATTTAA!\n")
				end
			end
		end
	end
end
teambot.onthinkOld = teambot.onthink
teambot.onthink = teambot.onthinkOverride

function teambot:GetMemoryUnits(unit)
	return unit and self.tMemoryUnits[unit:GetUniqueID()]
end

function teambot:BuildLanesOverride()
	local tUnits = core.CopyTable(self.tAllyBotHeroes)
	local memUnits = {}
	for nUID,_ in pairs(tUnits) do
		memUnits[nUID] = self.tMemoryUnits[nUID]
	end

	if core.NumberElements(memUnits) <= 0 then
		self:BuildLanesOld()
		self.laneReassessInterval = 1000
		return
	end
	self.laneReassessInterval = core.MinToMS(3)

	local tTopLane = {}
	local tMiddleLane = {}
	local tBottomLane = {}

	local tExposedLane = nil
	local tSafeLane = nil
	if core.myTeam == HoN.GetLegionTeam() then
		tExposedLane = tTopLane
		tSafeLane = tBottomLane
	else
		tExposedLane = tBottomLane
		tSafeLane = tTopLane
	end

	local mid = FindMidUnit(memUnits)
	if mid then
		local nUID = mid:GetUniqueID()
		tMiddleLane[nUID] = mid
		memUnits[nUID] = nil
	end

	local suicider = FindSuicider(memUnits)
	if suicider then
		local nUID = suicider:GetUniqueID()
		tExposedLane[nUID] = suicider
		memUnits[nUID] = nil
	end

	for nUID, memUnit in pairs(memUnits) do
		if memUnit then
			tSafeLane[nUID] = memUnit.object
		end
	end

	self.tTopLane = tTopLane
	self.tMiddleLane = tMiddleLane
	self.tBottomLane = tBottomLane

	teambot:PrintLanes(tTopLane, tMiddleLane, tBottomLane)
end
teambot.BuildLanesOld = teambot.BuildLanes
teambot.BuildLanes = teambot.BuildLanesOverride

function teambot:CreateMemoryUnitOverride(unit)
	local original = self:CreateMemoryUnitOld(unit)
	if original then
		local unitType = unit:GetTypeName()
		if tfind(tGankers, unitType) then
			original.isGanker = true
		end
		if tfind(tCarries, unitType) then
			original.isCarry = true
		end
		if tfind(tMidHeroes, unitType) then
			original.isMid = true
		end
		if tfind(tSuiciders, unitType) then
			original.isSuicide = true
		end
		if tfind(tSupports, unitType) then
			original.isSupport = true
		end
		if tfind(tSnipers, unitType) then
			original.isSniper = true
		end
		if tfind(tSitters, unitType) then
			original.isSitter = true
		end
	end
	return original
end
teambot.CreateMemoryUnitOld = teambot.CreateMemoryUnit
teambot.CreateMemoryUnit = teambot.CreateMemoryUnitOverride
