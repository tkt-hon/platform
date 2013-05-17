local _G = getfenv(0)
local teambot = _G.object

runfile 'bots/core_teambot.lua'
runfile 'bots/lib/rune_controlling/init_team.lua'

teambot.bGroupAndPush = false
teambot.bDefense = false
teambot.nInitialBotMove = 99999
teambot.laneDoubleCheckTime = 0

local core = teambot.core

local tinsert = _G.table.insert

teambot.myName = 'Kiinalainen Team'

function teambot:GetMemoryUnit(unit)
  return unit and self.tMemoryUnits[unit:GetUniqueID()]
end

local function FindSuicider(units)
  for _, unit in pairs(units) do
    if unit and unit.isSuicide then
      return unit.object
    end
  end
  return nil
end

local function FindMid(units)
  for _, unit in pairs(units) do
    if unit and unit.isMid then
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

  local suicider = FindSuicider(memUnits)
  if suicider then
    local nUID = suicider:GetUniqueID()
    tExposedLane[nUID] = suicider
    memUnits[nUID] = nil
  end

  for nUID, memUnit in pairs(memUnits) do
  	if memUnit.isMid then
  	  tMiddleLane[nUID] = memUnit.object
    else
      tSafeLane[nUID] = memUnit.object
    end
  end

  self.tTopLane = tTopLane
  self.tMiddleLane = tMiddleLane
  self.tBottomLane = tBottomLane

--  printLanes(self.tTopLane, "top")
--  printLanes(self.tMiddleLane, "middle")
--  printLanes(self.tBottomLane, "bottom")
end
teambot.BuildLanesOld = teambot.BuildLanes
teambot.BuildLanes = teambot.BuildLanesOverride

function teambot:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)
end
teambot.onthinkOld = teambot.onthink
teambot.onthink = teambot.onthinkOverride

local function tfind(table, value)
  for _, v in ipairs(table) do
    if v == value then
      return true
    end
  end
  return false
end

local tGankers = {
  "Hero_Aluna"
}
local tCarries = {
  "Hero_SandWraith",
  "Hero_DiseasedRider"
}
local tMidHeros = {
  "Hero_Mumra",
  "Hero_Aluna"
}
local tSuiciders = {
  "Hero_Yogi"
}
local tSitters = {
  "Hero_HellDemon",
  "Hero_Krixi",
  "Hero_Aluna"
}
local tSupports = {
  "Hero_HellDemon"
}

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
    if tfind(tMidHeros, unitType) then
      original.isMid = true
    end
    if tfind(tSuiciders, unitType) then
      original.isSuicide = true
    end
    if tfind(tSitters, unitType) then
      original.isSitter = true
    end
    if tfind(tSupports, unitType) then
      original.isSupport = true
    end
  end
  return original
end
teambot.CreateMemoryUnitOld = teambot.CreateMemoryUnit
teambot.CreateMemoryUnit = teambot.CreateMemoryUnitOverride

function printLanes(t, lane) 
	print(lane ..'{\n')
	if t then    
		for i,v in pairs(t) do
			print(' '..tostring(i)..', '.. tostring(v:GetTypeName())..'\n')
		end
	end
	print('}\n')
end
