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

function teambot:GetDefenseBuildings()
	local tBuildings = {}
	local bDamageableOnly = self.bDamageableDefenseOnly
	
	--Towers
	local tTowers = core.allyTowers
	for nID, unitTower in pairs(tTowers) do
		if unitTower:IsAlive() and (not bDamageableOnly or not unitTower:IsInvulnerable()) and unitTower:GetLevel() >= 3 then
			tBuildings[nID] = unitTower
		end
	end
	
	--Main base structure
	local unitMainBase = core.allyMainBaseStructure
	if (not bDamageableOnly or not unitMainBase:IsInvulnerable()) then
		tBuildings[unitMainBase:GetUniqueID()] = unitMainBase
	end

	--Rax (ignore ranged)
	local tRax = core.allyRax
	for nID, unitRax in pairs(tRax) do
		if unitRax:IsAlive() and (not bDamageableOnly or not unitRax:IsInvulnerable()) and unitRax:IsUnitType("MeleeRax") then
			tBuildings[nID] = unitRax
		end
	end

	return tBuildings
end

function teambot:ShouldPush()
  return false
end

--TEIN TÄHÄ TÄMMÖSTÄ JOKA MELKEIN VARMAA LASKEE ET MONTA OMAA ON MILLÄKI LINJALLA LÄHEN NUKKUU MOI
function teambot:ShouldChangeLane()
  local allyTeam = core.myTeam
  local nTop = core.NumberElements(self.tTopLane)
  local nMid = core.NumberElements(self.tMiddleLane)
  local nBot = core.NumberElements(self.tBottomLane)
  local alliesTop = 0
  local alliesMid = 0
  local alliesBot = 0
  for element in pairs(nTop) do
    if element:GetTeam() == allyTeam and element:IsHero() then
--      alliesTop++
    end
  end
  for element in pairs(nMid) do
    if element:GetTeam() == allyTeam and element:IsHero() then
--      alliesMid++
    end
  end
  for element in pairs(nBot) do
    if element:GetTeam() == allyTeam and element:IsHero() then
--      alliesBot++
    end
  end
end

function teambot:GroupAndPushLogic()
  if self:ShouldPush() then
    if self:ShouldChangeLane() then
    end
  end
end


--TYKITÄN TÄHÄ VÄHÄ COPYPASTEE JA SIT SITÄ VÄHÄ MUUTAN JA TOIVON PARASTA T: MASA KLO 5.50
--EI SE TOIMI COPYPASTELLA KU JEP EIS XD


