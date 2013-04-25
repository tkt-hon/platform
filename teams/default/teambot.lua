local _G = getfenv(0)
local teambot = _G.object

runfile 'bots/core_teambot.lua'
runfile 'bots/utils/rune_controlling/team.lua'

Utils_RuneControlling_Team.Initialize(teambot)

teambot.bGroupAndPush = false
teambot.nInitialBotMove = 99999
teambot.laneDoubleCheckTime = 0

local core = teambot.core

local tinsert = _G.table.insert

teambot.myName = 'Default Team'

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

local function FindGanker(units)
  for _, unit in pairs(units) do
    if unit and unit.isMid and unit.isGanker then
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

  local ganker = FindGanker(memUnits)
  if ganker then
    local nUID = ganker:GetUniqueID()
    tMiddleLane[nUID] = ganker
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
end
teambot.BuildLanesOld = teambot.BuildLanes
teambot.BuildLanes = teambot.BuildLanesOverride

function teambot:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  self.data.rune:Locate()
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
  "Hero_Rampage"
}
local tCarries = {
  "Hero_Krixi"
}
local tMidHeros = {
  "Hero_Rampage",
  "Hero_Krixi"
}
local tSuiciders = {
  "Hero_DiseasedRider"
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
  end
  return original
end
teambot.CreateMemoryUnitOld = teambot.CreateMemoryUnit
teambot.CreateMemoryUnit = teambot.CreateMemoryUnitOverride
