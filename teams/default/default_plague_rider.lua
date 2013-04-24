local _G = getfenv(0)
local plaguerider = _G.object

plaguerider.heroName = "Hero_DiseasedRider"

runfile 'bots/core_herobot.lua'

plaguerider.bReportBehavior = true
plaguerider.bDebugUtility = true

plaguerider.skills = {}

local core, behaviorLib = plaguerider.core, plaguerider.behaviorLib

local BotEcho = core.BotEcho
local tinsert = _G.table.insert

function plaguerider:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  local skills = self.skills
  if skills.abilDeny == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilShield = unitSelf:GetAbility(1)
    skills.abilDeny = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end
  if skills.abilUltimate:CanLevelUp() then
    skills.abilUltimate:LevelUp()
  elseif skills.abilDeny:CanLevelUp() then
    skills.abilDeny:LevelUp()
  elseif skills.abilNuke:CanLevelUp() then
    skills.abilNuke:LevelUp()
  elseif skills.abilShield:CanLevelUp() then
    skills.abilShield:LevelUp()
  else
    skills.stats:LevelUp()
  end
end
plaguerider.SkillBuildOld = plaguerider.SkillBuild
plaguerider.SkillBuild = plaguerider.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function plaguerider:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
plaguerider.onthinkOld = plaguerider.onthink
plaguerider.onthink = plaguerider.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function plaguerider:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
plaguerider.oncombateventOld = plaguerider.oncombatevent
plaguerider.oncombatevent = plaguerider.oncombateventOverride

local function IsSiege(unit)
  local unitType = unit:GetTypeName()
  return unitType == "Creep_LegionSiege" or unitType == "Creep_HellbourneSiege"
end

local function GetUnitToDenyWithSpell(botBrain, center, radius)
  local unitsLocal = core.AssessLocalUnits(botBrain, center, radius)
  local allies = unitsLocal.AllyCreeps
  for _,unit in pairs(allies) do
    if not IsSiege(unit) then
      return unit
    end
  end
  return nil
end

local function DenyBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilDeny = botBrain.skills.abilDeny
  local randomAlly = GetUnitToDenyWithSpell(botBrain, unitSelf:GetPosition(), abilDeny:GetRange())
  if abilDeny:CanActivate() and randomAlly then
    return 100
  end
  return 0
end

local function DenyBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilDeny = botBrain.skills.abilDeny
  local randomAlly = GetUnitToDenyWithSpell(botBrain, unitSelf:GetPosition(), abilDeny:GetRange())
  return core.OrderAbilityEntity(botBrain, abilDeny, randomAlly, false)
end

local DenyBehavior = {}
DenyBehavior["Utility"] = DenyBehaviorUtility
DenyBehavior["Execute"] = DenyBehaviorExecute
DenyBehavior["Name"] = "Denying creep with spell"
tinsert(behaviorLib.tBehaviors, DenyBehavior)
