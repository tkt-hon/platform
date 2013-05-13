local _G = getfenv(0)
local magmus = _G.object

magmus.heroName = "Hero_Magmar"

runfile 'bots/core_herobot.lua'

local tinsert = _G.table.insert

local core, behaviorLib = magmus.core, magmus.behaviorLib

behaviorLib.StartingItems = { "Item_MinorTotem", "Item_MinorTotem", "Item_MinorTotem", "Item_PretendersCrown", "Item_MinorTotem", "Item_RunesOfTheBlight", "Item_RunesOfTheBlight" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_Replenish", "Item_MysticVestments"}
behaviorLib.MidItems = { "Item_EnhancedMarchers", "Item_Shield2", "Item_MysticVestments" }
behaviorLib.LateItems = { "Item_Immunity", "Item_DaemonicBreastplate" }


local core, behaviorLib = magmus.core, magmus.behaviorLib

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none

object.tSkills = {
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


	if core.unitSelf:GetManaPercent() < 90 then
		core.FindItems(self)	
		local itemRing = core.itemRing
		if itemRing and itemRing:CanActivate() then
			magmus.bRunCommands = true
			core.OrderItemClamp(self, unitSelf, itemRing)
		end
	end
	
	core.nRange = 99999 * 99999

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
--self.eventsLib.printCombatEvent(EventData)

end

-- override combat event trigger function.
local function CustomHarassUtilityFnOverride(hero)
	local nUtil = 0
	core.BotEcho(nUtil)
  
	if core.unitSelf:GetAbility(0):CanActivate() then
    nUtil = nUtil + (core.unitSelf:GetLevel() * 5) / 2
  end

	if core.unitSelf:GetLevel() > 6 then
		nUtil = nUtil + 10
	end

  local damaget = {100, 160, 220, 280}

	if hero:GetHealth() < damaget[core.unitSelf:GetAbility(0):GetLevel()] 
    and core.unitSelf:GetMana() > 130 then
		nUtil = nUtil + 60
	end
  
  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)

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
    if not bActionTaken then
      if abilUltimate:CanActivate() then
        local nRange = abilUltimate:GetRange()
        if nTargetDistanceSq < (nRange * nRange) then
          bActionTaken = core.OrderAbilityEntity(botBrain, abilUltimate, unitTarget)
        else
          bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
        end
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

