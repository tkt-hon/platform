local _G = getfenv(0)
local dampeer = _G.object

dampeer.heroName = "Hero_Dampeer"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = dampeer.core, dampeer.behaviorLib

--huono buildi, paranna
behaviorLib.StartingItems = { "Item_TrinketOfRestoration", "Item_RunesOfTheBlight", "3 Item_MinorTotem"}
behaviorLib.LaneItems = { "Item_Marchers", "Item_MysticVestments", "Item_EnhancedMarchers", "Item_MagicArmor2" }
behaviorLib.MidItems = { "Item_SpellShards 3", "Item_Intelligence7", "Item_Lightbrand" }
behaviorLib.LateItems = { "Item_GrimoireOfPower" }

dampeer.skills = {
  2, 1, 2, 1, 2,
  3, 1, 1, 2, 0,
  3, 0, 0, 0, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}
local skills = dampeer.skills

local tinsert = _G.table.insert

function dampeer:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilDeny == nil then
    skills.abilScare = unitSelf:GetAbility(0)
    skills.abilFlight = unitSelf:GetAbility(1)
    skills.abilAura = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end
  if skills.abilUltimate:CanLevelUp() then
    skills.abilUltimate:LevelUp()
  elseif skills.abilAura:CanLevelUp() then
    skills.abilAura:LevelUp()
  elseif skills.abilScare:CanLevelUp() then
    skills.abilScare:LevelUp()
  elseif skills.abilFlight:CanLevelUp() then
    skills.abilFlight:LevelUp()
  else
    skills.stats:LevelUp()
  end
end
dampeer.SkillBuildOld = dampeer.SkillBuild
dampeer.SkillBuild = dampeer.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function dampeer:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
dampeer.onthinkOld = dampeer.onthink
dampeer.onthink = dampeer.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function dampeer:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
dampeer.oncombateventOld = dampeer.oncombatevent
dampeer.oncombatevent = dampeer.oncombateventOverride