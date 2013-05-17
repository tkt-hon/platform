local _G = getfenv(0)
local shaman = _G.object

shaman.heroName = "Hero_Shaman"


runfile 'bots/core_herobot.lua'
runfile 'bots/teams/trashteam/utils/utils.lua'
runfile 'bots/teams/trashteam/utils/predLastHitSupport.lua'

local tinsert = _G.table.insert

local core, behaviorLib = shaman.core, shaman.behaviorLib


--skills!? T0ntsu/fazias
behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_GuardianRing", "Item_MinorTotem", "Item_MinorTotem", "Item_PretendersCrown" }
behaviorLib.LaneItems = { "Item_ManaRegen3", "Item_Marchers", "Item_Steamboots" }
behaviorLib.MidItems = { "Item_LifeSteal5","Item_MagicArmor2","Item_Protect" }
behaviorLib.LateItems = { "Item_NomesWisdom"}

shaman.skills = {}
local skills = shaman.skills


shaman.tSkills = {
  2, 0, 2, 0, 2,
  3, 2, 1, 0, 0,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function shaman:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilEntangle == nil then
    skills.abilEntangle = unitSelf:GetAbility(0)
    skills.abilUnbreak = unitSelf:GetAbility(1)
    skills.abilHeal = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
    skills.taunt = unitSelf:GetAbility(8)
  end
  shaman:SkillBuildOld()
end
shaman.SkillBuildOld = shaman.SkillBuild
shaman.SkillBuild = shaman.SkillBuildOverride


------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function shaman:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)
  local unitSelf = self.core.unitSelf

	--initTracking(self)
	--updateCreepHistory(self)
end
shaman.onthinkOld = shaman.onthink
shaman.onthink = shaman.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function shaman:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
  local nAddBonus = 0

end

shaman.oncombateventOld = shaman.oncombatevent
shaman.oncombatevent = shaman.oncombateventOverride
-- override combat event trigger function.


-- Should shaman be afraid, hmm. This adds a so called MAN UP -behaviour, never run from "threat".
shaman.PussyUtilityOld = behaviorLib.RetreatFromThreatBehavior["Utility"]
local function PussyUtilityOverride(BotBrain)
  local util = shaman.PussyUtilityOld(BotBrain)
  return math.min(26, util*0.5)
end
behaviorLib.RetreatFromThreatBehavior["Utility"] = PussyUtilityOverride

local function CustomHarassUtilityFnOverride(hero)
  -- "hero" given to this function is enemy hero
  local nUtil = 0
  local unitSelf = core.unitSelf -- this is you
  -- This utility decides wether we try to slow/autoattack enemy hero
  -- maybe raise nUtil value if hero is already in range for normal attack?
  -- maybe also raise utility to initiate a kill try, predator should(?) jump in if slow hits
  -- Help Predator when he is trying to kill someone? or something :D
  -- We could get more kills if we had more heroes trying to kill one instead of only 1

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return shaman.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false

  local abilEntangle = skills.abilEntangle

  if abilEntangle:CanActivate() then
    local nRange = abilEntangle:GetRange()
    if nTargetDistanceSq < (nRange*nRange) then
      bActionTaken = core.OrderAbilityEntity(botBrain, abilEntangle, unitTarget)
    else
      bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
    end
  end

  if not bActionTaken then
    return shaman.harassExecuteOld(botBrain)
  end
end
shaman.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

-- Behaviours only after this point


local function castHealingWaveUtility(botBrain)
  if not skills.abilHeal:CanActivate() then
    return 0
  end
	if skills.abilHeal:GetLevel() < 2 then
		return 0
  end

	local unitSelf = botBrain.core.unitSelf
  local heroesInRange = HoN.GetUnitsInRadius(unitSelf:GetPosition(), 1000, ALIVE + HERO)

	local enemyHeroesInRange = 0
	local allyCreepsInRange = 0

	for _,unit in pairs(heroesInRange) do
    if unit and botBrain:GetTeam() ~= unit:GetTeam() then

			local creepsInRange = HoN.GetUnitsInRadius(unit:GetPosition(), 180, ALIVE+UNIT+HERO)
			for _,creep in pairs(creepsInRange) do
				if creep and unitSelf:GetTeam() == creep:GetTeam() and (not IsSiege(creep)) then
					allyCreepsInRange = allyCreepsInRange + 1
					shaman.healTarget = creep
					--core.DrawDebugArrow(unit:GetPosition(), creep:GetPosition(), 'red')
				end
			end

		end
  end

	if allyCreepsInRange > 3 then
		return 100
	elseif allyCreepsInRange > 2 then -- maybe try for less frequent but bigger dmg, fazias. Save mana etc.
		return 80                       -- should be changed if debugging
	end

	return 0
end

local function castHealingWaveExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
	core.BotEcho("casthealingwave")
  return core.OrderAbilityEntity(botBrain, skills.abilHeal, shaman.healTarget)
end

local healingWaveBehavior = {}
healingWaveBehavior["Utility"] = castHealingWaveUtility
healingWaveBehavior["Execute"] = castHealingWaveExecute
healingWaveBehavior["Name"] = "Healingwaveinstakillyo"
tinsert(behaviorLib.tBehaviors, healingWaveBehavior)


local function ResqueHealingWaveUtility(botBrain) -- done by hiridur, does it work :D?
	if not skills.abilHeal:CanActivate() then
		return 0
	end
	local unitsLocal, unitsSorted = HoN.GetUnitsInRadius(core.unitSelf:GetPosition(), 900, ALIVE + HERO, true)
	if core.NumberElements(unitsSorted.EnemyHeroes)==0 then
		return 0
	end
	local omalkm = core.NumberElements(unitsSorted.AllyHeroes)
	local resque = nil
  local hp = nil
  for key,unit in pairs(unitsSorted.AllyHeroes) do
		local newhp=unit:GetHealth()
    if not resque or newhp<hp then
      resque = unit
			hp = newhp
    end
  end
	if hp and hp<150 then
		shaman.resqueTarget=resque
		return 81
	end
	return 0
end

local function ResqueHealingWaveExecute(botBrain)
	--core.BotEcho("resquehealingwave")
  return core.OrderAbilityEntity(botBrain, skills.abilHeal, shaman.resqueTarget)
end

local ResquehealingWaveBehavior = {}
ResquehealingWaveBehavior["Utility"] = ResqueHealingWaveUtility
ResquehealingWaveBehavior["Execute"] = ResqueHealingWaveExecute
ResquehealingWaveBehavior["Name"] = "HealingwaveEITAPAVITTU"
tinsert(behaviorLib.tBehaviors, ResquehealingWaveBehavior)

shaman.UltiTargetPos = nil
local function UltimateBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilUlti = unitSelf:GetAbility(3)
  local ultiLevel = abilUlti:GetLevel()
  if ultiLevel < 1 or not abilUlti:CanActivate() then
    return 0
  end
  local myPos = unitSelf:GetPosition()
  local unitsLocal = HoN.GetUnitsInRadius(core.unitSelf:GetPosition(), 2000, ALIVE + HERO+UNIT)
  local unitsGot = 0
  local target = nil
  if abilUlti:CanActivate() then
    for _,unit in pairs(unitsLocal) do
      if unit  then
        local _,heroeslocal = HoN.GetUnitsInRadius(core.unitSelf:GetPosition(), 600, ALIVE + HERO, true)
        if core.NumberElements(heroeslocal.EnemyHeroes) > 0 and core.NumberElements(heroeslocal.AllyHeroes) > 0 then
          local asd = core.NumberElements(heroeslocal)
          if unitsGot < asd then
            target = unit:GetPosition()
            unitsGot = asd
          end
        end
      end
    end
    if target then
      shaman.UltiTargetPos = targetPos
      return 100
    end
  end
  return 0
end

local function UltimateBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilUlti = unitSelf:GetAbility(3)
  local target = shaman.UltiTargetPos
  if target then
    return core.OrderAbilityPosition(botBrain, abilUlti, target)
  end
  return false
end

local UltimateBehavior = {}
UltimateBehavior["Utility"] = UltimateBehaviorUtility
UltimateBehavior["Execute"] = UltimateBehaviorExecute
UltimateBehavior["Name"] = "Using ultimate properly"
tinsert(behaviorLib.tBehaviors, UltimateBehavior)

