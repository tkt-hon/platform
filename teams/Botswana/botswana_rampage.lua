local _G = getfenv(0)
local rampage = _G.object

rampage.heroName = "Hero_Rampage"

runfile 'bots/core_herobot.lua'
runfile 'bots/lib/rune_controlling/init.lua'

local core, behaviorLib = rampage.core, rampage.behaviorLib

local tinsert = _G.table.insert

behaviorLib.StartingItems = { "Item_Marchers", "Item_RunesOfTheBlight", "Item_LoggersHatchet" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_Lifetube", "Item_ManaBattery" }
behaviorLib.MidItems = { "Item_EnhancedMarchers", "Item_Shield2", "Item_PowerSupply", "Item_MysticVestments" }
behaviorLib.LateItems = { "Item_Immunity", "Item_DaemonicBreastplate" }

local CHARGE_NONE, CHARGE_STARTED, CHARGE_TIMER, CHARGE_WARP = 0, 1, 2, 3

rampage.charged = CHARGE_NONE

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
rampage.skills = {}
local skills = rampage.skills

rampage.tSkills = {
  1, 2, 1, 0, 1,
  3, 1, 2, 2, 2,
  3, 0, 0, 0, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}
function rampage:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilCharge == nil then
    skills.abilCharge = unitSelf:GetAbility(0)
    skills.abilSlow = unitSelf:GetAbility(1)
    skills.abilBash = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
rampage.SkillBuildOld = rampage.SkillBuild
rampage.SkillBuild = rampage.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function rampage:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
rampage.onthinkOld = rampage.onthink
rampage.onthink = rampage.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function rampage:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
rampage.oncombateventOld = rampage.oncombatevent
rampage.oncombatevent = rampage.oncombateventOverride
