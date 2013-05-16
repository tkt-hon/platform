local _G = getfenv(0)
local teambot = _G.object

runfile 'bots/core_teambot.lua'
runfile 'bots/lib/rune_controlling/init_team.lua'
runfile 'bots/teams/temaNoHelp/lib/antimagmus.lua'
runfile 'bots/teams/temaNoHelp/lib/antichronos.lua'

teambot.myName = 'temaNoHelp'

local core, metadata = teambot.core, teambot.metadata

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

function teambot:GetMemoryUnit(unit)
  return unit and self.tMemoryUnits[unit:GetUniqueID()]
end

local function FindSolo(units)
  for _, unit in pairs(units) do
    if unit and unit:GetTypeName() == "Hero_DiseasedRider" then
      return unit.object
    end
  end
  return nil
end

local function FindMid(units)
  for _, unit in pairs(units) do
    if unit and unit:GetTypeName() == "Hero_PollywogPriest" then
      return unit.object
    end
  end
  return nil
end

local BuildLanesOld = teambot.BuildLanes
local function BuildLanesOverride(self)
  local tUnits = core.CopyTable(self.tAllyBotHeroes)
  local memUnits = {}
  for nUID,_ in pairs(tUnits) do
    memUnits[nUID] = self.tMemoryUnits[nUID]
  end

  if core.NumberElements(memUnits) <= 0 then
    BuildLanesOld(self)
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
    tTriLane = tTopLane
    tSoloLane = tBottomLane
  else
    tTriLane = tBottomLane
    tSoloLane = tTopLane
  end

  local solo = FindSolo(memUnits)
  if solo then
    local nUID = solo:GetUniqueID()
    tSoloLane[nUID] = solo
    memUnits[nUID] = nil
  end

  local mid = FindMid(memUnits)
  if mid then
    local nUID = mid:GetUniqueID()
    tMiddleLane[nUID] = mid
    memUnits[nUID] = nil
  end

  for nUID, memUnit in pairs(memUnits) do
    if memUnit then
      tTriLane[nUID] = memUnit.object
    end
  end

  self.tTopLane = tTopLane
  self.tMiddleLane = tMiddleLane
  self.tBottomLane = tBottomLane
end
teambot.BuildLanes = BuildLanesOverride

function teambot.CalculateThreat(unitHero)
  local nDPSThreat = teambot.DPSThreat(unitHero)
  local nRangeThreat = unitHero:GetAttackRange() * 0.50
  local nThreat = nDPSThreat + nRangeThreat
  return nThreat
end
