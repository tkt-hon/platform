local _G = getfenv(0)
moonqueen = _G.object

moonqueen.heroName = "Hero_Krixi"

runfile 'bots/teams/drop-table-bots/droptable-herobot.lua'
runfile 'bots/teams/drop-table-bots/libhon.lua'

local core, behaviorLib = moonqueen.core, moonqueen.behaviorLib

--[[
-- empty spaces filled with Minor Totems
-- game adds Homecoming Stones to list at some point
behaviorLib.StartingItems = { "6 Item_MinorTotem", "Item_Fleetfeet", "Item_Quickblade", "Item_Sicarius", "Item_BrainOfMaliken", "Item_ApprenticesRobe" }
-- {Fleetfeet} -> {Fleetfeet, Quickblade} -> {Firebrand} -> {Firebrand, Pickled Brain} -> {Firebrand, Apprentice's Robe, Pickled Brain}
behaviorLib.LaneItems = { "Item_ApprenticesRobe", "Item_NeophytesBook", "Item_Searinglight", "Item_Manatube" }
-- {Firebrand, Apprentice's Robe, Neophyte's Book, Pickled Brain} -> {Searing Light, Pickled Brain} -> {Searing Light, Manatube, Pickled Brain}
behaviorLib.MidItems = { "Item_BlessedArmband", "Item_MightyBlade", "Item_Dawnbringer", "Item_Regen", "Item_Confluence" }
-- {Searing Light, Bolstering Armband, Manatube, Pickled Brain} -> {Searing Light, Bolstering Armband, Mighty Blade, Manatube, Pickled Brain}
-- {Dawnbringer, Manatube, Pickled Brain} -> {Dawnbringer, Sustainer, Pickled Brain} -> {Dawnbringer, Sustainer, Blessed Orb, Pickled Brain}
behaviorLib.LateItems = { "Item_Protect", "Item_Quickblade", "Item_Glowstone", "Item_MightyBlade", "Item_Intelligence7" }
-- {Dawnbringer, Null Stone, Pickled Brain} -> {Dawnbringer, Null Stone, Quickblade, Pickled Brain} -> {Dawnbringer, Null Stone, Quickblade, Glowstone, Pickled Brain}
-- {Dawnbringer, Null Stone, Quickblade, Mighty Blade, Glowstone, Pickled Brain} -> {Dawnbringer, Null Stone, Staff of the Master, Pickled Brain}
]]

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "2 Item_DuckBoots", "2 Item_MinorTotem" }
behaviorLib.LaneItems = { "Item_IronShield", "Item_Marchers", "Item_Steamboots", "Item_WhisperingHelm" }
behaviorLib.MidItems = { "Item_ManaBurn2", "Item_Evasion", "Item_Immunity", "Item_Stealth" }
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke" }

behaviorLib.pushingStrUtilMul = 1

moonqueen.skills = {}
local skills = moonqueen.skills

core.itemGeoBane = nil

moonqueen.tSkills = {
  4, 0, 2, 0, 0,
  3, 2, 4, 4, 0,
  3, 1, 1, 1, 2,
  3, 2, 4, 4, 4,
  4, 4, 4, 4, 4
}

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
-- default
function moonqueen:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilMoonbeam == nil then
    skills.abilMoonbeam = unitSelf:GetAbility(0)
    skills.abilUlti = unitSelf:GetAbility(3)
    skills.abilStats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
moonqueen.SkillBuildOld = moonqueen.SkillBuild
moonqueen.SkillBuild = moonqueen.SkillBuildOverride

---------------------------------------------------------------
--            Harass utility override                        --
---------------------------------------------------------------
-- @param: hero
-- @return: utility
function behaviorLib.CustomHarassUtility(heroTarget)
  -- Default 0
  local t = core.AssessLocalUnits(moonqueen, nil, 400)
  local numCreeps = core.NumberElements(t.EnemyUnits)
  local util = 20 - numCreeps*2
  local unitSelf = core.unitSelf

  local moonbeanMult = 3
  local ultiMult = 6
  util = util + moonbeanMult * skills.abilMoonbeam:GetLevel()
  util = util + ultiMult * skills.abilUlti:GetLevel()

  if heroTarget then
    if skills.abilMoonbeam:CanActivate() and (unitSelf:GetManaPercent() >= 0.95 or heroTarget:GetHealthPercent() < 0.5) then
      util = util + 1000 -- Moonbeam
    end
    if skills.abilUlti:CanActivate() and numCreeps < 3 then
      util = util + 10000 -- Ulti
    end
  end
  return util
end

--------------------------------------------------------------
--                    Harass Behavior                       --
-- All code how to use abilities against enemies goes here  --
--------------------------------------------------------------
-- @param: botbrain
-- @return: none
local oldExecute = behaviorLib.HarassHeroBehavior["Execute"]
local function executeBehavior(botBrain)
  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return oldExecute(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())

  local success = false
  local ultiRange = 600
  if behaviorLib.lastHarassUtil >= 5000 then
    success = core.OrderAbility(botBrain, skills.abilUlti)
  end

  if not success and behaviorLib.lastHarassUtil >= 500 then
    local range = skills.abilMoonbeam:GetRange()
    success = core.OrderAbilityEntity(botBrain, skills.abilMoonbeam, unitTarget)
  end

  if not success then
    return oldExecute(botBrain)
  end
  return success
end
behaviorLib.HarassHeroBehavior["Execute"] = executeBehavior

local lastChatMessageIndex = nil

function sanitizeChat(msg)
  -- remove leading space & color codes
  msg = msg:sub(2)
  msg = msg:gsub("%^%*", "")
  msg = msg:gsub("%^%d%d%d", "")
  return msg
end

function moonqueen:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  local chat = GameChat.gameChat
  if lastChatMessageIndex ~= nil then
    for i = lastChatMessageIndex + 1, #chat do
      local msg = chat[i]
      if msg.senderName == "dezgeg" then
        local code = sanitizeChat(msg.message)
        local func, err = loadstring(code)

        if not func then
          self:Chat('^900Parse Error: ^*' .. err)
        else
          local status, err = pcall(function()
            self:Chat(str(func()))
          end)
          if not status then
            self:Chat('^900Lua Error: ^*' .. err)
          end
        end
      end
    end
  end
  lastChatMessageIndex = #chat

end
moonqueen.onthinkOld = moonqueen.onthink
moonqueen.onthink = moonqueen.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function moonqueen:oncombateventOverride(eventData)
  self:oncombateventOld(eventData)

  -- Uncomment this to print the combat events
  -- p(eventData)
end
-- override combat event trigger function.
moonqueen.oncombateventOld = moonqueen.oncombatevent
moonqueen.oncombatevent = moonqueen.oncombateventOverride
