local _G = getfenv(0)
local andromeda = _G.object

andromeda.heroName = "Hero_Andromeda"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = andromeda.core, andromeda.behaviorLib

behaviorLib.StartingItems = { "Item_TrinketOfRestoration", "Item_RunesOfTheBlight", "3 Item_MinorTotem"}
behaviorLib.LaneItems = { "Item_Marchers", "Item_MysticVestments", "Item_EnhancedMarchers", "Item_MagicArmor2" }
behaviorLib.MidItems = { "Item_SpellShards 3", "Item_Intelligence7", "Item_Lightbrand" }
behaviorLib.LateItems = { "Item_GrimoireOfPower" }

andromeda.skills = {
  2, 0, 2, 0, 2,
  3, 0, 0, 2, 1,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}
local skills = andromeda.skills

local tinsert = _G.table.insert

core.itemWard = nil

function andromeda:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilDeny == nil then
    skills.abilStun = unitSelf:GetAbility(0)
    skills.abilDebuff = unitSelf:GetAbility(1)
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
  elseif skills.abilStun:CanLevelUp() then
    skills.abilStun:LevelUp()
  elseif skills.abilDebuff:CanLevelUp() then
    skills.abilDebuff:LevelUp()
  else
    skills.stats:LevelUp()
  end
end
andromeda.SkillBuildOld = andromeda.SkillBuild
andromeda.SkillBuild = andromeda.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function andromeda:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
andromeda.onthinkOld = andromeda.onthink
andromeda.onthink = andromeda.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function andromeda:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
andromeda.oncombateventOld = andromeda.oncombatevent
andromeda.oncombatevent = andromeda.oncombateventOverride
