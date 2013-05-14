local _G = getfenv(0)
local teambot = _G.object

runfile 'bots/core_teambot.lua'
runfile 'bots/lib/rune_controlling/init_team.lua'

local core = teambot.core
local tinsert = _G.table.insert

teambot.myName = 'Faulty'

local tGankers = {}
local tCarries = {
	"Hero_Hammerstorm"
}
local tMidHeroes = {
	"Hero_Magmar"
}
local tSuiciders = {
	"Hero_DiseasedRider"
}
local tSupports = {
	"Hero_Shaman"
}

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function teambot:onthinkOverride(tGameVariables)
	self:onthinkOld(tGameVariables)

	-- custom code here
end
teambot.onthinkOld = teambot.onthink
teambot.onthink = teambot.onthinkOverride

function teambot:GetMemoryUnits(unit)
	return unit and self.tMemoryUnits[unit:GetUniqueID()]
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

-- try to find the value from given table
local function tfind(table, value)
	for _,v in ipairs(table) do
		if v == value then
			return true
		end
	end
	return false
end

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
	end
	return original
end
teambot.CreateMemoryUnitOld = teambot.CreateMemoryUnit
teambot.CreateMemoryUnit = teambot.CreateMemoryUnitOverride
