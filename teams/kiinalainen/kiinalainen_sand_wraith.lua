local _G = getfenv(0)
local sand = _G.object

sand.heroName = "Hero_SandWraith"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = sand.core, sand.behaviorLib

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_IronBuckler", "Item_LoggersHatchet" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_Lifetube", "Item_ManaBattery" }
behaviorLib.MidItems = { "Item_EnhancedMarchers", "Item_Shield2", "Item_PowerSupply", "Item_MysticVestments" }
behaviorLib.LateItems = { "Item_Immunity", "Item_DaemonicBreastplate" }

behaviorLib.pushingStrUtilMul = 1

sand.skills = {}
local skills = sand.skills


---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none


sand.tSkills = {
  0, 1, 0, 1, 0,
  3, 0, 1, 1, 2,
  3, 2, 2, 2, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

function sand:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilStun == nil then
    skills.abilQ = unitSelf:GetAbility(0)
    skills.abilW = unitSelf:GetAbility(1)
    skills.abilE = unitSelf:GetAbility(2)
    skills.abilR = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
sand.SkillBuildOld = sand.SkillBuild
sand.SkillBuild = sand.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function sand:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
sand.onthinkOld = sand.onthink
sand.onthink = sand.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function sand:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return sand.harassExecuteOld(botBrain)
  end

  print("HARASS")

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  core.OrderAbilityEntity(botBrain, skills.abilQ, unitTarget)
end
-- override combat event trigger function.
sand.oncombateventOld = sand.oncombatevent
sand.oncombatevent = sand.oncombateventOverride
