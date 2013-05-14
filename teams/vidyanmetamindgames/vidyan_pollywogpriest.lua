local _G = getfenv(0)
local pollywogpriest = _G.object

pollywogpriest.heroName = "Hero_PollywogPriest"
local core, behaviorLib = pollywogpriest.core, pollywogpriest.behaviorLib

runfile 'bots/core_herobot.lua'

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none

pollywogpriest.skills = {}
local skills = pollywogpriest.skills

---------------------------------------------------------------
-- Selitys buildin takana: Tongue ekana, jotta voidaan saada --
-- alkupäässä tehtyä damagea enemmän, ykköslevelin joltti ei --
-- tee paskaakaan damagea. Nukea kun saa lisää, niin sitten  --
-- voidaan käyttää sitä puskemisen yhteydessä. Hexiä otetaan --
-- myös sen takia, että sillä saadaan yksi cooldown lisää,   --
-- jolla voidaan selvitä taisteluista. Tärkeää saada frageja --
-- ultimatea käyttämällä suoraan heroihin trapaten ne sinne. --
---------------------------------------------------------------

pollywogpriest.tSkills = {
  2, 0, 0, 1, 0,
  3, 0, 2, 2, 2,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

function pollywogpriest:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilNuke == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilHex = unitSelf:GetAbility(1)
    skills.abilTongue = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
pollywogpriest.SkillBuildOld = pollywogpriest.SkillBuild
pollywogpriest.SkillBuild = pollywogpriest.SkillBuildOverride

------------------------------------------------------
-- onthink override --
-- Called every bot tick, custom onthink code here --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function pollywogpriest:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
pollywogpriest.onthinkOld = pollywogpriest.onthink
pollywogpriest.onthink = pollywogpriest.onthinkOverride

----------------------------------------------
-- oncombatevent override --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function pollywogpriest:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
pollywogpriest.oncombateventOld = pollywogpriest.oncombatevent
tempest.oncombatevent = tempest.oncombateventOverride
