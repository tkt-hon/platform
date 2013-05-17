--------------------------------------------------------------------------------
-- Bottle usage behavior
--
-- Utility: will return some value
--
-- Execute: 

local _G = getfenv(0)
local object = _G.object

local core, behaviorLib = object.core, object.behaviorLib
local tinsert, format = _G.table.insert, _G.string.format
local BotEcho, Clamp = core.BotEcho, core.Clamp

function behaviorLib.BottleRegenUtility(botBrain)
	local unitSelf = core.unitSelf

	if unitSelf:HasState("State_Bottle") then
		return 0
	end

	local tInventory = unitSelf:GetInventory()
	local tBottles = core.InventoryContains(tInventory, "Item_Bottle")

	if #tBottles > 0 and tBottles[1]:GetActiveModifierKey() ~= "bottle_empty" then
		local nHealthMissing = unitSelf:GetMaxHealth() - unitSelf:GetHealth()
		local nManaMissing   = unitSelf:GetMaxMana() - unitSelf:GetMana()

		local nHealAmount = 150
		local nManaAmount = 75

		local nHealthUtlityThreshold = 20
		local nManaUtlityThreshold = 15

		local vecHealPoint = Vector3.Create(nHealAmount, nHealthUtilityThreshold)
		local vecManaPoint = Vector3.Create(nManaAmount, nManaUtilityThreshold)
		local vecHealOrigin = Vector3.Create(-10, -20)
		local vecManaOrigin = Vector3.Create(-10, -15)

		local nHeal = core.ATanFn(nHealthMissing, vecHealPoint, vecHealOrigin, 80)
		local nMana = core.ATanFn(nManaMissing, vecManaPoint, vecManaOrigin, 80)

		--BotEcho(format("BottleRegenUtility: %g", Clamp(nHeal + nMana, 0, 35)))
		return Clamp(nHeal + nMana, 0, 35)
	end

	return 0
end

function behaviorLib.BottleRegenExecute(botBrain)
	local unitSelf = core.unitSelf
	local tInventory = unitSelf:GetInventory()
	local tBottles = core.InventoryContains(tInventory, "Item_Bottle")

	if not unitSelf:HasState("State_Bottle") and #tBottles > 0 then
		BotEcho(unitSelf:GetTypeName().." Drinking bottle!")
		core.OrderItemClamp(botBrain, unitSelf, tBottles[1])
	end
end

behaviorLib.BottleRegenBehavior = {}
behaviorLib.BottleRegenBehavior["Utility"] = behaviorLib.BottleRegenUtility
behaviorLib.BottleRegenBehavior["Execute"] = behaviorLib.BottleRegenExecute
behaviorLib.BottleRegenBehavior["Name"] = "Drinking laika bauss"
tinsert(behaviorLib.tBehaviors, behaviorLib.BottleRegenBehavior)
--------------------------------------------------------------------------------
