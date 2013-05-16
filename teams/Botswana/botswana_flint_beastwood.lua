local _G = getfenv(0)
local beastwood = _G.object

beastwood.heroName = "Hero_FlintBeastwood"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = beastwood.core, beastwood.behaviorLib

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_ManaRegen3" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_Steamboots", "Item_Manatube" }
behaviorLib.MidItems = { "Item_Protect", "Item_Evasion" }
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke" }

behaviorLib.pushingStrUtilMul = 1

beastwood.skills = {}
local skills = beastwood.skills

core.itemGeoBane = nil
beastwood.bReportBehavior = false
beastwood.bDebugUtility = false

beastwood.tSkills = {
  2, 1, 2, 1, 2,
  3, 2, 1, 1, 4,
  3, 4, 4, 4, 4,
  3, 4, 1, 1, 1,
  1, 1, 1, 4, 4
}

function beastwood:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilNuke == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilStun = unitSelf:GetAbility(1)
    skills.abilRange = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
beastwood.SkillBuildOld = beastwood.SkillBuild
beastwood.SkillBuild = beastwood.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function beastwood:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
beastwood.onthinkOld = beastwood.onthink
beastwood.onthink = beastwood.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function beastwood:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
beastwood.oncombateventOld = beastwood.oncombatevent
beastwood.oncombatevent = beastwood.oncombateventOverride

local function GetUltiRange()
  local tEnemyHeroes = HoN.GetHeroes(core.enemyTeam)
  local leveli = beastwood:GetHeroUnit():GetLevel()
  local ultiRange = 0
	if leveli == 6 then
	ultiRange = 1500
	elseif leveli == 11 then
	ultiRange = 2000
	elseif leveli == 16 then
	ultiRange = 2500
	end
  return ultiRange
end

local function closestLowHpHero()
  local currentTarget = nil
  for nUID, unit in pairs(tEnemyHeroes) do
    local position = unit:GetPosition()
    local selfPos = core.unitSelf:GetPosition()
    local distance = Vector3.Distance2DSq(position, selfPos)
    if core.CanSeeUnit(botBrain, unit) and unit:IsAlive() and distance <= ultiRange and ( currentTarget == nil or currentTarget:GetHealth() < unit:GetHealth() ) then
      currentTarget = unit
    end
  end
  return currentTarget
end

local function NearbyCreepCount(botBrain, center, radius)
  local count = 0
  local unitsLocal = core.AssessLocalUnits(botBrain, center, radius)
  local enemies = unitsLocal.EnemyCreeps
  for _,unit in pairs(enemies) do
    count = count + 1
  end
  return count
end

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if skills.abilUltimate:CanActivate() then
    nUtil = nUtil + 5*skills.abilNuke:GetLevel()
  end

  if skills.abilUltimate:CanActivate() then
    nUtil = nUtil + 100
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return beastwood.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then
    local itemGeoBane = core.itemGeoBane
    if not bActionTaken then
      if itemGeoBane then
        if itemGeoBane:CanActivate() then
          bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemGeoBane)
        end
      end
    end

    local abilUltimate = skills.abilUltimate
    if not bActionTaken and nLastHarassUtility > 50 then
      if abilUltimate:CanActivate() then
        local nRange = abilUltimate:GetRange()
        if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilUltimate, unitTarget)
	end

      end
    end

    local abilNuke = skills.abilNuke
    if abilNuke:CanActivate() then
      local nRange = abilNuke:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end
  end

  if not bActionTaken then
    return beastwood.harassExecuteOld(botBrain)
  end
end
beastwood.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

local function DPSPushingUtilityOverride(myHero)
  local modifier = 1 + myHero:GetAbility(1):GetLevel()*0.3
  return beastwood.DPSPushingUtilityOld(myHero) * modifier
end
beastwood.DPSPushingUtilityOld = behaviorLib.DPSPushingUtility
behaviorLib.DPSPushingUtility = DPSPushingUtilityOverride

local function funcFindItemsOverride(botBrain)
  local bUpdated = beastwood.FindItemsOld(botBrain)

  if core.itemGeoBane ~= nil and not core.itemGeoBane:IsValid() then
    core.itemGeoBane = nil
  end

  if bUpdated then
    if core.itemGeoBane then
      return
    end

    local inventory = core.unitSelf:GetInventory(true)
    for slot = 1, 12, 1 do
      local curItem = inventory[slot]
      if curItem then
        if core.itemGeoBane == nil and curItem:GetName() == "Item_ManaBurn2" and not curItem:IsRecipe() then
          core.itemGeoBane = core.WrapInTable(curItem)
        end
      end
    end
  end
  return bUpdated
end
beastwood.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride

local function checkTower(range)
	local selfPos = core.unitSelf:GetPosition()
	local torni = core.GetClosestEnemyTower(selfPos, range)
	return torni

end

local function PushExecuteOverwrite(botBrain)


	local bDebugLines = true

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
					bActionTaken = core.OrderItemClamp(botBrain, unitSelf, core.itemRoT)
				end
			end
		end
	end

	-- attack tower if we're in range
	if bActionTaken == false then
		local attackRange = ( skills.abilRange:GetLevel() * 60 ) + 570
		local unitTarget = checkTower(attackRange)
		if unitTarget then
			if bDebugEchos then BotEcho("Attacking Tower") end
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
behaviorLib.PushBehavior["Execute"] = PushExecuteOverwrite

