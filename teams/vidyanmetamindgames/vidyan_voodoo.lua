local _G = getfenv(0)
local voodoo = _G.object

voodoo.heroName = "Hero_Voodoo"

runfile 'bots/core_herobot.lua'

--------------------------------------------------------------
-- Itembuild --
--------------------------------------------------------------

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_PretendersCrown", "2 Item_ManaPotion" }
behaviorLib.LaneItems = { "Item_Strength5", "Item_Marchers", "Item_MightyBlade",  "Item_Warhammer", "Item_Immunity", "Item_Glowstone", "Item_NeophytesBook", "Item_MigthyBlade", "Item_Intelligence7" }
behaviorLib.MidItems = { }
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke", "Item_Damage9" }

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none

voodoo.skills = {}
local skills = voodoo.skills

---------------------------------------------------------------
-- Selitys buildin takana: Stun + debuff + ulti combolla saa --
-- heron kuin heron hengiltä, stunni tärkeimpänä, koska muut --
-- herot pystyvät maksimoimaan vahinkonsa silloin. Mojo on   --
-- käytettävissä myöhemmissä tilanteissa tukevana skillinä,  --
-- mikäli siihen on tarve (esim nallen elossapitäminen).     --
---------------------------------------------------------------


voodoo.tSkills = {
  0, 2, 0, 2, 0,
  3, 0, 2, 2, 1,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

function voodoo:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilStun == nil then
    skills.abilStun = unitSelf:GetAbility(0)
    skills.abilMojo = unitSelf:GetAbility(1)
    skills.abilDebuff = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
voodoo.SkillBuildOld = voodoo.SkillBuild
voodoo.SkillBuild = voodoo.SkillBuildOverride

------------------------------------------------------
-- onthink override --
-- Called every bot tick, custom onthink code here --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function voodoo:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
voodoo.onthinkOld = voodoo.onthink
voodoo.onthink = voodoo.onthinkOverride

----------------------------------------------
-- oncombatevent override --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function voodoo:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
voodoo.oncombateventOld = voodoo.oncombatevent
tempest.oncombatevent = tempest.oncombateventOverride
