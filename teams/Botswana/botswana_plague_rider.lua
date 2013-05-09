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
  4, 3, 1, 2, 4,
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
plaguerider.nNukeUp = 10
plaguerider.nArmorUp = 0
plaguerider.nManaUp = 0
plaguerider.nUltUp = 30
 
 
-- These are bonus agression points that are applied to the bot upon successfully using a skill/item
plaguerider.nNukeUse = 15
plaguerider.nArmorUse = 5
plaguerider.nManaUse = 0
plaguerider.nUltUse = 50
 
 
--These are thresholds of aggression the bot must reach to use these abilities

plaguerider.nNukeThreshold = 15
plaguerider.nArmorThreshold = 35
plaguerider.nManaThreshold = 12
plaguerider.nUltThreshold = 55


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
  	if EventData.Inflictorname == "Ability_DiseasedRider1" then
  		nAddBonus = nAddBonus + plaguerider.nNukeUse
  	elseif EventData.Inflictorname == "Ability_DiseasedRider4" then
  		nAddBonus = nAddBonus + plaguerider.nUltUse
  	elseif EventData.Inflictorname == "Ability_DiseasedRider3" then
  		nAddBonus = nAddBonus + plaguerider.ManaUse
  	elseif EventData.Inflictorname == "Ability_DiseasedRider2" then
  		nAddBonus = nAddBonus + plaguerider.nArmorUse
  	
  	end
  end
  
  if nAddBonus > 0 then
  	core.Decaybonus(self)
  	core.nHarassBonus = core.nHarassBonus + nAddBonus
  end
  
end
  
  

  -- custom code here

-- override combat event trigger function.
plaguerider.oncombateventOld = plaguerider.oncombatevent
plaguerider.oncombatevent = plaguerider.oncombateventOverride
-------------------------------------------------------------
--              CustomHarassUtility Override
-------------------------------------------------------------

local function CustomHarassUtilityFnOverride(hero)
	local nUtil = 40

	if skills.abilNuke:CanActivate() then
	  nUtil = nUtil + plaguerider.nNukeUp
	end
	
	if skills.abilDeny:CanActivate() then
	  nUtil = nUtil + plaguerider.nManaUp
	end
	
	if skills.abilUltimate:CanActivate() then
	  nUtil = nUtil + plaguerider.nUltUp
	end
	
	if skills.abilShield:CanActivate() then
	  nUtil = nUtil + plaguerider.nArmorUp
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
		return plaguerider.harassExecuteOld(botBrain)
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
    
    
    	
	local bTargetVuln = unitTarget:IsStunned() or unitTarget:IsImmobilized() or unitTarget:IsPerplexed()
	local abilArmor = skills.abilShield
	local abilMana = skills.abilDeny
	local abilNuke = skills.abilNuke
	local abilUlt = skills.abilUltimate
	
   
-- Contagion
	if not bActionTaken then
            local nRange = abilNuke:GetRange()
                if abilNuke:CanActivate() and nLastHarassUtility > botBrain.nNukeThreshold then
                    if nTargetDistanceSq < (nRange*nRange) then
                        bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
                        
                    else bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
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
	   
           if abilArmor:CanActivate() and nLastHarassUtility > botBrain.nArmorThreshold then
		local nRange = abilArmor:GetRange()
		if(unitSelf:GetHealth()<900) then 
		bActionTaken = core.OrderAbility(botBrain, abilArmor, unitSelf)
		end
	   end
	end

-- Plague Carrier
	if core.CanSeeUnit(botBrain, unitTarget) then
           
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
		
		if not bActionTaken then
			if abilMana:CanActivate() and
			nLastHarassUtility > botBrain.nManaThreshold then 
			bActionTaken = core.OrderAbilityEntity(botBrain, abilMana, unitTarget)
			end

		end
	end



    
    if not bActionTaken then
        return plaguerider.harassExecuteOld(botBrain)
    end
end


	
plaguerider.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

---------------------------------------------------------------
--           PushExecuteOverride
---------------------------------------------------------------


local function PushExecuteOverride(botBrain)
	self: PushExecuteOld(botBrain)
	
	local bDebugLines = false

	--if botBrain.myName == 'ShamanBot' then bDebugLines = true end

	if core.unitSelf:IsChanneling() then
	return
	end

	local unitSelf = core.unitSelf
	local bActionTaken = false

	--Turn on Ring of the Teacher if we have it
	if bActionTaken == false then
		local itemRoT = core.itemRoT
		if itemRoT then
			itemRoT:Update()
			local tInventory = unitSelf:GetInventory()
			if itemRoT.bHeroesOnly then
				local tRoT = core.InventoryContains(tInventory, itemRoT:GetTypeName())
				if not core.IsTableEmpty(tRoT) then
					if bDebugEchos then BotEcho("Turning on RoTeacher") end
					bActionTaken = core.OrderItemClamp(botBrain, unitSelf, 
					core.itemRoT)
				end
			end
		end
	end

	--Attack creeps if we're in range
	if bActionTaken == false then
		local unitTarget = core.unitEnemyCreepTarget
		if unitTarget then
			if bDebugEchos then BotEcho("Attacking creeps") end
			local nRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
			if unitSelf:GetAttackType() == "melee" then
			--override melee so they don't stand *just* out of range
				nRange = 250
			end

			if unitSelf:IsAttackReady() and core.IsUnitInRange(unitSelf, unitTarget, nRange) then
				bActionTaken = core.OrderAttackClamp(botBrain, unitSelf, unitTarget)
			end

			if bDebugLines then core.DrawXPosition(unitTarget:GetPosition(), 'red', 125) end
		end
	end

	if bActionTaken == false then
		local vecDesiredPos = behaviorLib.PositionSelfLogic(botBrain)
		if vecDesiredPos then
			if bDebugEchos then BotEcho("Moving out") end
			bActionTaken = behaviorLib.MoveExecute(botBrain, vecDesiredPos)

		if bDebugLines then core.DrawXPosition(vecDesiredPos, 'blue') end
	end
end

	if bActionTaken == false then
		return false
	end
end

behaviorLib.PushBehavior = {}
behaviorLib.PushBehavior["Utility"] = behaviorLib.PushUtility
behaviorLib.PushBehavior["Execute"] = behaviorLib.PushExecute
behaviorLib.PushBehavior["Name"] = "Push"
tinsert(behaviorLib.tBehaviors, behaviorLib.PushBehavior)

plaguerider.PushExecuteOld = plaguerider.PushExecute
plaguerider.PushExecute = plaguerider.PushExecuteOverride

---------------------------------------------------------
--		AttackCreepUtility and Execute
---------------------------------------------------------

local function AttackCreepsUtilityOverride(botBrain)	
	local nDenyVal = 21
	local nLastHitVal = 24

	local nUtility = 0

--we don't want to deny if we are pushing
	local unitDenyTarget = core.unitAllyCreepTarget
	if core.GetCurrentBehaviorName(botBrain) == "Push" then
		unitDenyTarget = nil
	end

	local unitTarget = behaviorLib.GetCreepAttackTarget(botBrain, core.unitEnemyCreepTarget, unitDenyTarget)

	if unitTarget and core.unitSelf:IsAttackReady() then
		if unitTarget:GetTeam() == core.myTeam then
			nUtility = nDenyVal
		else
			nUtility = nLastHitVal
		end
	core.unitCreepTarget = unitTarget
	end

		if botBrain.bDebugUtility == true and nUtility ~= 0 then
			BotEcho(format(" AttackCreepsUtility: %g", nUtility))
		end

	return nUtility
end

behaviorLib.AttackCreepsUtility = AttackCreepsUtilityOverride


local function AttackCreepsExecute(botBrain)
	local unitSelf = core.unitSelf
	local currentTarget = core.unitCreepTarget

	if currentTarget and core.CanSeeUnit(botBrain, currentTarget) then	
	local vecTargetPos = currentTarget:GetPosition()
	local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), vecTargetPos)
	local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)

		if currentTarget ~= nil then
			if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() then
--only attack when in nRange, so not to aggro towers/creeps until necessary, and move forward when attack is on cd
				core.OrderAttackClamp(botBrain, unitSelf, currentTarget)
			else
--BotEcho("MOVIN OUT")
		local vecDesiredPos = core.AdjustMovementForTowerLogic(vecTargetPos)
		core.OrderMoveToPosClamp(botBrain, unitSelf, vecDesiredPos, false)
			end
		end
	else
	return false
	end
end

behaviorLib.AttackCreepsBehavior = {}
behaviorLib.AttackCreepsBehavior["Utility"] = behaviorLib.AttackCreepsUtility
behaviorLib.AttackCreepsBehavior["Execute"] = behaviorLib.AttackCreepsExecute
behaviorLib.AttackCreepsBehavior["Name"] = "AttackCreeps"
tinsert(behaviorLib.tBehaviors, behaviorLib.AttackCreepsBehavior)

behaviorLib.AttackCreepsExecute = AttackCreepsExecuteOverride

------------------------------------------------------------------
--		ProxToTower
------------------------------------------------------------------


local function ProxToEnemyTowerUtilityOverride(unit, unitClosestEnemyTower)
	local bDebugEchos = false

	local nUtility = 0

	if unitClosestEnemyTower then
		local nDist = Vector3.Distance2D(unitClosestEnemyTower:GetPosition(), unit:GetPosition())
		local nTowerRange = core.GetAbsoluteAttackRangeToUnit(unitClosestEnemyTower, unit)
		local nBuffers = unit:GetBoundsRadius() + unitClosestEnemyTower:GetBoundsRadius()

		nUtility = -1 * core.ExpDecay((nDist - nBuffers), 100, nTowerRange, 2)

		nUtility = nUtility * 0.32

		if bDebugEchos then BotEcho(format("util: %d nDistance: %d nTowerRange: %d", nUtility, (nDist - 
		nBuffers), nTowerRange)) 
		end
	end

	nUtility = Clamp(nUtility, -100, 0)

	return nUtility
end

behaviorLib.ProxToEnemyTowerUtility = ProxToEnemyTowerUtilityOverride







