local _G = getfenv(0)
local teambot = _G.object

runfile "bots/teambot/tournament_options.lua"
runfile 'bots/core_teambot.lua'
runfile 'bots/lib/rune_controlling/init_team.lua'

teambot.bGroupAndPush = false
teambot.bDefense = false
teambot.nInitialBotMove = 99999
teambot.laneDoubleCheckTime = 0

-- Magmus, Pyro, Preda, Shaman, WitchSlayer
local core = teambot.core

local tinsert = _G.table.insert

teambot.myName = 'TrashTeam'

function teambot:GetMemoryUnit(unit)
  return unit and self.tMemoryUnits[unit:GetUniqueID()]
end

local function FindLonglane(units)
  local retUnits = {}
  for _, unit in pairs(units) do
    if unit and unit.isSuicide then
      table.insert(retUnits, unit.object)
    end
  end
  if #retUnits > 1 then
    return retUnits
  end
  return nil
end

local function FindMid(units)
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

  if self.Is1v1() then
    self.tMiddleLane = tUnits
    return
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

  if self.Is1v1() then
    self.tMiddleLane = tUnits
    return
  end

  local suiciders = FindLonglane(memUnits)
  core.BotEcho(tostring(#suiciders) .. " amount of suiciders")
  for i=1,#suiciders,1  do
    if suiciders[i] then
      local unit = suiciders[i]:GetUniqueID()
      tExposedLane[unit] = suiciders[i]
      memUnits[unit] = nil
    end
  end

  local gankers = FindMid(memUnits)
  if gankers then
    local nUID = gankers:GetUniqueID()
    tMiddleLane[nUID] = gankers
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

function teambot.CalculateThreatOverride(unitHero)
  return 0
end
teambot.CalculateThreatOld = teambot.CalculateThreat
teambot.CalculateThreat = teambot.CalculateThreatOverride


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
  "Hero_WitchSlayer"
}
local tCarries = {
  "Hero_Predator"
}
local tMidHeros = {
  "Hero_WitchSlayer"
}
local tSuiciders = {
  "Hero_Predator",
  "Hero_Shaman"
}
local tSitters = {
  "Hero_Shaman"
}
local tSupports = {
  "Hero_Shaman"
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
