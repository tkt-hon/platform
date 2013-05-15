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
--	OnCombatEvent Override	--
----------------------------------
-- @param: EventData
-- @return: none 
function object:oncombateventOverride(EventData)
    self:oncombateventOld(EventData)
 
    local nAddBonus = 0
 
    if EventData.Type == "Ability" then
        if EventData.InflictorName == "Ability_Magmus2" then
            nAddBonus = nAddBonus + 15
	elseif EventData.InflictorName == "Ability_Magmus1" then
            nAddBonus = nAddBonus + 20
        elseif EventData.InflictorName == "Ability_Magmus3" then
            nAddBonus = nAddBonus + 20
        elseif EventData.InflictorName == "Ability_Magmus4" then
            nAddBonus = nAddBonus + 25
        end
    elseif EventData.Type == "Item" then
        end
    end
 
   if nAddBonus > 0 then
        core.DecayBonus(self)
        core.nHarassBonus = core.nHarassBonus + nAddBonus
    end
 
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent     = object.oncombateventOverride

-------------------------------------------------------------
--              CustomHarassUtility Override
-------------------------------------------------------------

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if skills.abilSurge:CanActivate() then
    nUtil = nUtil + 30
    local damages = {50,100,125,175}
    if hero:GetHealth() < damages[skills.abilSurge:GetLevel()] then
      nUtil = nUtil + 30
    end
  end

  if skills.abilUltimate:CanActivate() then
    nUtil = nUtil + 100
  end

  if core.unitSelf.isSuicide then
    nUtil = nUtil / 2
  end

  return nUtil
end



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
     
    local vecTargetPosition = unitTarget:GetPosition()
    local nTargetExtraRange = core.GetExtraRange(unitTarget)
    local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)
 
     
    local nLastHarassUtility = behaviorLib.lastHarassUtil
    local bCanSee = core.CanSeeUnit(botBrain, unitTarget)    
    local bActionTaken = false






