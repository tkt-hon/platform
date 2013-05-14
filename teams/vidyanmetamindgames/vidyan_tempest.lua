local _G = getfenv(0)
local tempest = _G.object

tempest.heroName = "Hero_Tempest"
local core, behaviorLib = tempest.core, tempest.behaviorLib

runfile 'bots/core_herobot.lua'

--------------------------------------------------------------
-- Itembuild --
--------------------------------------------------------------

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_PretendersCrown", "2 Item_ManaPotion" }
behaviorLib.LaneItems = { "Item_Strength5", "Item_Marchers", "Item_MightyBlade", "Item_Warhammer", "Item_Immunity" }
behaviorLib.MidItems = {}
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke", "Item_Damage9" }

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none

tempest.skills = {}
local skills = tempest.skills

---------------------------------------------------------------
-- Selitys buildin takana: Stun + minion autoattack tuhoaa,  --
-- mutta tärkeimpänä on aluksi maksimoida autoattack damage  --
-- minioneilta, jolloin lanen puskeminen + CC:n hyödyntämi-  --
-- nen on parhaimmillaan. Aoe spelli on semiturha omasta     --
-- mielestä, sillä korkea manacost yhdistettynä taistelun    --
-- mukana olevaan ketjustunnailuun on liikaa.                --
---------------------------------------------------------------


tempest.tSkills = {
  0, 1, 1, 0, 1,
  3, 1, 0, 0, 4,
  3, 4, 4, 4, 4,
  3, 4, 4, 4, 4,
  4, 2, 2, 2, 2
}

function tempest:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilStun == nil then
    skills.abilStun = unitSelf:GetAbility(0)
    skills.abilMinions = unitSelf:GetAbility(1)
    skills.abilAoe = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
tempest.SkillBuildOld = tempest.SkillBuild
tempest.SkillBuild = tempest.SkillBuildOverride

------------------------------------------------------
-- onthink override --
-- Called every bot tick, custom onthink code here --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function tempest:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
tempest.onthinkOld = tempest.onthink
tempest.onthink = tempest.onthinkOverride

----------------------------------------------
-- oncombatevent override --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function tempest:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
tempest.oncombateventOld = tempest.oncombatevent
tempest.oncombatevent = tempest.oncombateventOverride
