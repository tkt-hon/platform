local _G = getfenv(0)
local plaguerider = _G.object

plaguerider.heroName = "Hero_DiseasedRider"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = plaguerider.core, plaguerider.behaviorLib

behaviorLib.StartingItems = { "Item_MinorTotem", "Item_MinorTotem", "Item_RunesOfTheBlight", "Item_RunesOfTheBlight",  }
behaviorLib.LaneItems = { "Item_Marchers", "Item_ManaBattery", "Item_MagicArmor2" }
behaviorLib.MidItems = { "Item_Striders", "Item_SpellShards", "Item_Intelligence7", "Item_Lightbrand" }
behaviorLib.LateItems = { "Item_GrimoireOfPower", "Item_RestorationStone" }

plaguerider.skills = {}
local skills = plaguerider.skills

local tinsert = _G.table.insert

core.itemWard = nil

plaguerider.tSkills = {
  2, 0, 0, 2, 0,
  3, 0, 4, 2, 1,
  3, 4, 1, 2, 4,
  3, 2, 4, 4, 4,
  3, 4, 4, 4, 4
}
function plaguerider:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilDeny == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilShield = unitSelf:GetAbility(1)
    skills.abilDeny = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
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


-- bonus aggro pts if skill/item is available
object.nNukeUp = 17
object.nArmorUp = 5
object.nManaUp = 35
object.nUltUp = 36
 
 
-- These are bonus agression points that are applied to the bot upon successfully using a skill/item
object.nNukeUse = 35
object.nArmorUse = 5
object.nManaUse = 10
object.nUltUse = 50
 
 
--These are thresholds of aggression the bot must reach to use these abilities

object.nNukeThreshold = 15
object.nArmorThreshold = 35
object.nManaThreshold = 12
object.nUltThreshold = 55


----------------------------------------------
--            OnCombatEvent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function plaguerider:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)
  
  local nAddBonus = 0
  
  if EventData.Type == "Ability" then
  	if EventData.Inflictorname = "Ability_DiseasedRider1" then
  		nAddBonus = nAddBonus + object.nNukeUse
  	elseif EventData.Inflictorname = "Ability_DiseasedRider4" then
  		nAddBonus = nAddBonus + object.nUltUse
  	elseif EventData.Inflictorname = "Ability_DiseasedRider2" then
  		nAddBonus = nAddBonus + object.nArmorUse
  	elseif EventData.Inflictorname = "Ability_DiseasedRider3" then
  		nAddBonus = nAddBonus + object.ManaUse
  	end
  end
  
  if nAddBonus > 0 then
  	core.Decaybonus(self)
  	core.nHarassBonus = core.nHarassBonus + nAddBonus
  end
  
end
  
  

  -- custom code here
end
-- override combat event trigger function.
plaguerider.oncombateventOld = plaguerider.oncombatevent
plaguerider.oncombatevent = plaguerider.oncombateventOverride
-------------------------------------------------------------
--              CustomHarassUtility Override
-------------------------------------------------------------

local function CustomHarassUtilityFnOverride(hero)
	local nUtil = 40

	if skills.abilNuke:CanActivate() then
	  nUtil = nUtil + object.nNukeUp
	end
	
	if skills.abilDeny:CanActivate() then
	  nUtil = nUtil + object.nManaUp
	end
	
	if skills.abilUltimate:CanActivate() then
	  Util = nUtil + object.nUltiUp
	end
	
	if skills.abilShield:CanActivate() then
	  nUtil = nUtil + object.nArmorUp
	end
	
	return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

----------------------------------------------------------------
--              Harass Behaviour
-- How to to use abilities
----------------------------------------------------------------

local function HarassHeroExecuteOverride(botBrain)
    local unitTarget = behaviorLib.heroTarget
	if unitTarget == nil then
		return object.harassExecuteOld(botBrain)
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
    
    
    	if core.CanSeeUnit(botBrain, unitTarget) then
    	
	  local bTargetVuln = unitTarget:IsStunned() or unitTarget:IsImmobilized() or unitTarget:IsPerplexed()
	  local abilArmor = skills.abilW
	  local abilMana = skills.abilE
          local abilNuke = skills.abilQ
          local abilUlt = skills.abilR

   
-- Contagion
     if not bActionTaken then
            local nRange = abilNuke:GetRange()
                if abilNuke:CanActivate() and nLastHarassUtility > botBrain.nNukeThreshold then
                    if nTargetDistanceSq < (nRange*nRange) then
                        bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
                        
                    else bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
                    end
                end
            end
   
            if abilUlt:CanActivate() and nLastHarassUtility > botBrain.nUltThreshold then
                local nRange = abilUlt:GetRange()
                if nTargetDistanceSq < (nRange * nRange) then
                    bActionTaken = core.OrderAbilityEntity(botBrain, abilUlt, unitTarget)
                end
            end
      end
    


-- Plague Shield
    if not bActionTaken then
        local abilArmor = skills.abilW
        if abilArmor:CanActivate() and nLastHarassUtility > botBrain.nArmorThreshold then
            local nRange = abilArmor:GetRange()
            
            if(unitSelf:GetHealth()<900) then
                bActionTaken = core.OrderAbility(botBrain, abilArmor, unitSelf)
        end
    end

     -- Plague Carrier
    if core.CanSeeUnit(botBrain, unitTarget) then
        local abilUlt = skills.abilR
        if not bActionTaken then --and bTargetVuln then
            if abilUlt:CanActivate() and nLastHarassUtility > botBrain.nUltThreshold then
                local nRange = abilUlt:GetRange()
                if nTargetDistanceSq < (nRange * nRange) then
                    bActionTaken = core.OrderAbilityEntity(botBrain, abilUlt, unitTarget)
                else
                    bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
                end
            end
        end
    end

-- Extinguish
    if core.CanSeeUnit(botBrain, unitTarget) and (unitTarget:GetHealth()>549)then
	local abilMana = skills.abilE
	if not bActionTaken then
	if abilMana:CanActivate() and nLastHarassUtility > botBrain.nManaThreshold then
	    bActionTaken = core.OrderAbilityEntity(botBrain, abilMana, unitTarget)
	end

	end
    end



    
    if not bActionTaken then
        return object.harassExecuteOld(botBrain)
    end
end
end
	
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride




