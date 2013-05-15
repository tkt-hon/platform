local _G = getfenv(0)
local magmus = _G.object

runfile 'bots/magmus/magmus_main.lua'

local tinsert = _G.table.insert

local core, behaviorLib = magmus.core, magmus.behaviorLib

behaviorLib.LaneItems = { "Item_MinorTotem", "Item_MinorTotem", "Item_CrushingClaws", "Item_MinorTotem", "Item_CrushingClaws"  }
behaviorLib.StartingItems = { "Item_MinorTotem", "Item_MinorTotem", "Item_CrushingClaws", "Item_MinorTotem", "Item_CrushingClaws"  }
behaviorLib.MidItems = { "Item_PortalKey", "Item_EnhancedMarchers", "Item_PowerSupply" }
behaviorLib.LateItems = { "Item_GrimoireOfPower", "Item_RestorationStone" }

magmus.skills = {}
local skills = magmus.skills

core.itemWard = nil

magmus.tSkills = {
  2, 0, 0, 2, 0,
  3, 0, 4, 2, 4,
  3, 4, 4, 2, 4,
  3, 2, 4, 4, 4,
  3, 4, 4, 4, 4
}

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function magmus:SkillBuildOverride()
local unitSelf = self.core.unitSelf
  if skills.abilTouch == nil then
    skills.abilSurge = unitSelf:GetAbility(0)
    skills.abilBath = unitSelf:GetAbility(1)
    skills.abilTouch = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
magmus.SkillBuildOld = magmus.SkillBuild
magmus.SkillBuild = magmus.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function magmus:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
magmus.onthinkOld = magmus.onthink
magmus.onthink = magmus.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function magmus:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
magmus.oncombateventOld = magmus.oncombatevent
magmus.oncombatevent = magmus.oncombateventOverride

----------------------------------
--	HarassHeroOverride	--
----------------------------------
local unitTarget = behaviorLib.heroTarget
    if unitTarget == nil then
        return object.harassExecuteOld(botBrain)  --Target is invalid, move on to the next behavior
    end
     
     
    local unitSelf = core.unitSelf
    local vecMyPosition = unitSelf:GetPosition() 
    local nAttackRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
    local nMyExtraRange = core.GetExtraRange(unitSelf)

