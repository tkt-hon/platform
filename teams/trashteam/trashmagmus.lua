local _G = getfenv(0)
local magmus = _G.object

magmus.heroName = "Hero_Magmar"

runfile 'bots/core_herobot.lua'

local tinsert = _G.table.insert

local core, behaviorLib = magmus.core, magmus.behaviorLib

magmus.bRunLogic         = true
magmus.bRunBehaviors    = true
magmus.bUpdates         = true
magmus.bUseShop         = true

magmus.bRunCommands     = true
magmus.bMoveCommands     = true
magmus.bAttackCommands     = true
magmus.bAbilityCommands = true
magmus.bOtherCommands     = true

magmus.bReportBehavior = false
magmus.bDebugUtility = false

magmus.logger = {}
magmus.logger.bWriteLog = false
magmus.logger.bVerboseLog = false

behaviorLib.StartingItems = { "Item_MinorTotem", "Item_MinorTotem", "Item_MinorTotem", "Item_PretendersCrown", "Item_MinorTotem", "Item_RunesOfTheBlight", "Item_RunesOfTheBlight" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_Replenish", "Item_MysticVestments"}
behaviorLib.MidItems = { "Item_EnhancedMarchers", "Item_Protect", "Item_MysticVestments" }
behaviorLib.LateItems = { "Item_Immunity", "Item_DaemonicBreastplate" }

local steam = false

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none

magmus.tSkills = {
  0, 2, 0, 1, 0,
  3, 0, 2, 2, 2,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}


function magmus:SkillBuildOverride()
  magmus:SkillBuildOld()
  local unitSelf = self.core.unitSelf
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
self.eventsLib.printCombatEvent(EventData)  


	if EventData.Type == "Projectile" then
		steam = true
	end
  -- custom code here
end

magmus.oncombateventOld = magmus.oncombatevent
magmus.oncombatevent = magmus.oncombateventOverride

local function IsChanneling()
return core.unitSelf:IsChanneling()
end

local function SteamBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilSteam = unitSelf:GetAbility(1)

  if steam and abilSteam:CanActivate() and not IsChanneling() then
    return 100
  end
  return 0
end

local function SteamBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilSteam = unitSelf:GetAbility(1)
	steam = false
	if IsChanneling() then
		return
	end
core.BotEcho("Trollliii")
    return core.OrderAbility(botBrain, abilSteam, false)
end

local SteamBehavior = {}
SteamBehavior["Utility"] = SteamBehaviorUtility
SteamBehavior["Execute"] = SteamBehaviorExecute
SteamBehavior["Name"] = "Steaming"
tinsert(behaviorLib.tBehaviors, SteamBehavior)

local function ManaRingBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  core.FindItems(botBrain)
	local util = 0	
	local itemRing = core.itemRing

 	if botBrain.bDebugUtility == true and utility ~= 0 then
     core.BotEcho("  ManaRingBehaviorUtility: " .. tostring(util))
  end
  if itemRing and itemRing:CanActivate() and unitSelf:GetManaPercent() < 0.9 and not IsChanneling() then
    util = 50
  end
  	return util
end

local function ManaRingExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
	core.FindItems(botBrain)	
	local itemRing = core.itemRing
		magmus.bRunCommands = true
		return core.OrderItemClamp(botBrain, unitSelf, itemRing)
end

local ManaRingBehavior = {}
ManaRingBehavior["Utility"] = ManaRingBehaviorUtility
ManaRingBehavior["Execute"] = ManaRingExecute
ManaRingBehavior["Name"] = "ManaRing"
tinsert(behaviorLib.tBehaviors, ManaRingBehavior)

magmus.PussyUtilityOld = behaviorLib.RetreatFromThreatBehavior["Utility"]
local function PussyUtilityOverride(BotBrain)
  local util = magmus.PussyUtilityOld(BotBrain)
  return math.min(util*0.5,21)
end
behaviorLib.RetreatFromThreatBehavior["Utility"] = PussyUtilityOverride

-- override combat event trigger function.
local function CustomHarassUtilityFnOverride(hero)
	local nUtil = 0
	
	if core.unitSelf:GetLevel() > 2 and core.unitSelf:GetHealthPercent() > 0.20 then
    nUtil = nUtil + 20
  end

	if core.unitSelf:GetLevel() > 6 then
		nUtil = nUtil + 10
	end

  local damaget = {100, 160, 220, 280}

	if hero:GetHealth() < damaget[core.unitSelf:GetAbility(0):GetLevel()] 
    and core.unitSelf:GetMana() > 130 then
		nUtil = nUtil + 20
	end
	if IsTowerThreateningUnit(core.unitSelf) and core.unitSelf:GetLevel() < 6 then
		nUtil = nUtil - 50
	end
  
  return nUtil
end

	function IsTowerThreateningUnit(unit)
	vecPosition = unit:GetPosition()
	--TODO: switch to just iterate through the enemy towers instead of calling GetUnitsInRadius

	local nTowerRange = 821.6 --700 + (86 * sqrtTwo)
	nTowerRange = nTowerRange
	local tBuildings = HoN.GetUnitsInRadius(vecPosition, nTowerRange, core.UNIT_MASK_ALIVE + core.UNIT_MASK_BUILDING)
	for key, unitBuilding in pairs(tBuildings) do
		if unitBuilding:IsTower() and unitBuilding:GetCanAttack() and (unitBuilding:GetTeam()==unit:GetTeam())==false then
			return true
		end
	end

	return false
end

behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)

	if core.unitSelf:IsChanneling() then
		return
	end

  local unitTarget = behaviorLib.heroTarget

  if unitTarget == nil then
    return magmus.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())

  local bActionTaken = false
	local abilSurge = unitSelf:GetAbility(0)
  if core.CanSeeUnit(botBrain, unitTarget) then
    if abilSurge:CanActivate() then
      local nRange = abilSurge:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilSurge, unitTarget)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end

    local abilUltimate = unitSelf:GetAbility(3)
    if not bActionTaken and abilUltimate:CanActivate() then
      if abilUltimate:CanActivate() and unitTarget:IsStunned() then
          bActionTaken = core.OrderAbility(botBrain, abilUltimate)
			else
					bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)	
      end
    end

		if not bActionTaken then
			if unitTarget ~= nil and not core.unitSelf:IsChanneling() then
				bActionTaken = core.OrderAttack(botBrain, unitSelf, unitTarget)
			else
				bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)	
      end
		end
  end

  if not bActionTaken then
    return magmus.harassExecuteOld(botBrain)
  end
end
magmus.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

local function funcFindItemsOverride(botBrain)
	local bUpdated = magmus.FindItemsOld(botBrain)

	if core.itemRing ~= nil and not core.itemRing:IsValid() then
		core.itemRing = nil
	end
	if core.itemCodex ~= nil and not core.itemCodex:IsValid() then
		core.itemCodex = nil
	end

	if bUpdated then
		--only update if we need to
		if core.itemRing and core.itemCodex then
			return
		end

		local inventory = core.unitSelf:GetInventory(true)
		for slot = 1, 12, 1 do
			local curItem = inventory[slot]
			if curItem then
				if core.itemRing == nil and curItem:GetName() == "Item_Replenish" then
					core.itemRing = core.WrapInTable(curItem)

				elseif core.itemCodex == nil and curItem:GetName() == "Item_Nuke" then
					core.itemCodex = core.WrapInTable(curItem)
				end
			end
		end
	end
end
magmus.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride

