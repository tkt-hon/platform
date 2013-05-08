local _G = getfenv(0)
local moonqueen = _G.object

moonqueen.heroName = "Hero_Krixi"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = moonqueen.core, moonqueen.behaviorLib

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "2 Item_DuckBoots", "2 Item_MinorTotem" }
behaviorLib.LaneItems = { "Item_IronShield", "Item_Marchers", "Item_Steamboots", "Item_WhisperingHelm" }
behaviorLib.MidItems = { "Item_ManaBurn2", "Item_Evasion", "Item_Immunity", "Item_Stealth" }
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke" }


moonqueen.skills = {}
local skills = moonqueen.skills
behaviorLib.pushingCap = 22
behaviorLib.pushingStrUtilMul = 20
moonqueen.bReportBehavior = true
moonqueen.bDebugUtility = true
local BotEcho = core.BotEcho
---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
moonqueen.tSkills = {
  2, 4, 2, 1, 2,
  4, 2, 1, 4, 1,
  4, 1, 4, 4, 4,
  3, 0, 0, 0, 0,
  3, 3, 0, 0, 0
}


--  0, 4, 0, 4, 0,
--  3, 0, 2, 2, 1,
--  3, 1, 1, 1, 2,
--  3, 2, 4, 4, 4,
--  4, 0, 0, 0, 0


function moonqueen:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilNuke == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilBounce = unitSelf:GetAbility(1)
    skills.abilAura = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
moonqueen.SkillBuildOld = moonqueen.SkillBuild
moonqueen.SkillBuild = moonqueen.SkillBuildOverride
------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function moonqueen:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
moonqueen.onthinkOld = moonqueen.onthink
moonqueen.onthink = moonqueen.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function moonqueen:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
moonqueen.oncombateventOld = moonqueen.oncombatevent
moonqueen.oncombatevent = moonqueen.oncombateventOverride


local function nearestCreep()
	local temp = core.localUnits["EnemyCreeps"]
	local selfPos = core.unitSelf:GetPosition()
	local nearest = nil
	local nearestDistance = nil
        for id, creep in pairs(temp) do
		local position = creep:GetPosition()
		local distance = Vector3.Distance2DSq(position, selfPos)
		
		if not nearest or distance < nearestDistance then
			nearest = creep
			nearestDistance = distance
		end
	end
	return nearest
end


local function checkTower(range)
	local selfPos = core.unitSelf:GetPosition()
	local torni = core.GetClosestEnemyTower(selfPos, range)
	if torni == nil then
	return false
	end
	return true

end

local function HarassHeroUtilityOverride(botBrain)
	
	if checkTower(1200) then
		return 0
	end
	
	return behaviorLib.HarassHeroUtility(botBrain)

end

behaviorLib.HarassHeroBehavior["Utility"] = HarassHeroUtilityOverride

local function CheckForFriendlies()

	local AllyCreeps = core.localUnits["AllyCreeps"]
	local size = core.NumberElements(AllyCreeps)	
	if size > 2 then
	return true
	end
	return false
end

local function PushUtilityOverride(botBrain)
	
	if checkTower(1000) then
		return 0
	end
	
	if not CheckForFriendlies() then
		return 0
	end



	return behaviorLib.PushUtility(botBrain)

end

behaviorLib.PushBehavior["Utility"] = PushUtilityOverride

-- = core.AssessLocalUnits(botBrain, vecPosition, nRadius).AllyCreeps





local function PushExecuteOverwrite(botBrain)

	local bDebugLines = true



	if core.unitSelf:IsChanneling() then 
		return
	end

	local unitSelf = core.unitSelf
	local bActionTaken = false


	--If no creeps around, go to tower to wait
	
	
	





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
					bActionTaken = core.OrderItemClamp(botBrain, unitSelf, core.itemRoT)
				end
			end
		end
	end


	--Attack creeps if we're in range
	if bActionTaken == false then

		local unitTarget = nearestCreep()
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

behaviorLib.PushBehavior["Execute"] = PushExecuteOverwrite
