﻿local PassLoot = LibStub("AceAddon-3.0"):GetAddon("PassLoot")
local L = LibStub("AceLocale-3.0"):GetLocale("PassLoot_Modules")
local module = PassLoot:NewModule(L["Wardrobe Unlock"])

module.Choices = {{
	["Name"] = L["Any"],
	["Value"] = 1,
}, {
	["Name"] = L["Unlocked"],
	["Value"] = 2,
}, {
	["Name"] = L["Unknown"],
	["Value"] = 3,
}, {
	["Name"] = L["Unlocked from Different Item"],
	["Value"] = 4,
}}

module.ConfigOptions_RuleDefaults = { -- { VariableName, Default },
{"Wardrobe", {
	-- [1] = { Value, Exception }
}}}
module.NewFilterValue = 1

function module:OnEnable()
	self:RegisterDefaultVariables(self.ConfigOptions_RuleDefaults)
	self:AddWidget(self.Widget)
	-- self:AddProfileWidget(self.Widget)
end

function module:OnDisable()
	self:UnregisterDefaultVariables()
	self:RemoveWidgets()
end

function module:CreateWidget()
	local Widget = CreateFrame("Frame", "PassLoot_Frames_Widgets_Wardrobe", nil, "UIDropDownMenuTemplate")
	Widget:EnableMouse(true)
	Widget:SetHitRectInsets(15, 15, 0, 0)
	_G[Widget:GetName() .. "Text"]:SetJustifyH("CENTER")
	if (select(4, GetBuildInfo()) < 30000) then
		UIDropDownMenu_SetWidth(120, Widget)
	else
		UIDropDownMenu_SetWidth(Widget, 120)
	end
	Widget:SetScript("OnEnter", function() self:ShowTooltip(L["Wardrobe Unlock"], L["Selected rule will only match unlearned Wardrobe items."]) end)
	Widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
	local Button = _G[Widget:GetName() .. "Button"]
	Button:SetScript("OnEnter", function() self:ShowTooltip(L["Wardrobe Unlock"], L["Selected rule will only match unlearned Wardrobe items."]) end)
	Button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	local Title = Widget:CreateFontString(Widget:GetName() .. "Title", "BACKGROUND", "GameFontNormalSmall")
	Title:SetParent(Widget)
	Title:SetPoint("BOTTOMLEFT", Widget, "TOPLEFT", 20, 0)
	Title:SetText(L["Wardrobe Unlock"])
	Widget:SetParent(nil)
	Widget:Hide()
	if (select(4, GetBuildInfo()) < 30000) then
		Widget.initialize = function(...) self:DropDown_Init(Widget, ...) end
	else
		Widget.initialize = function(...) self:DropDown_Init(...) end
	end
	Widget.YPaddingTop = Title:GetHeight()
	Widget.Height = Widget:GetHeight() + Widget.YPaddingTop
	Widget.XPaddingLeft = -15
	Widget.XPaddingRight = -15
	Widget.Width = Widget:GetWidth() + Widget.XPaddingLeft + Widget.XPaddingRight
	Widget.PreferredPriority = 4
	Widget.Info = {L["Wardrobe Unlock"], L["Selected rule will only match unlearned Wardrobe items."]}
	return Widget
end
module.Widget = module:CreateWidget()

-- Local function to get the data and make sure it's valid data
function module.Widget:GetData(RuleNum)
	local Data = module:GetConfigOption("Wardrobe", RuleNum)
	local Changed = false
	if (not Data or type(Data) ~= "table") then
		Data = {}
		Changed = true
	end
	for Key, Value in ipairs(Data) do
		if (type(Value) ~= "table" or type(Value[1]) ~= "number") then
			Data[Key] = {module.NewFilterValue, false}
			Changed = true
		end
	end
	if (Changed) then module:SetConfigOption("Wardrobe", Data) end
	return Data
end

function module.Widget:GetNumFilters(RuleNum)
	local Value = self:GetData(RuleNum)
	return #Value
end

function module.Widget:AddNewFilter()
	local Value = self:GetData()
	table.insert(Value, {module.NewFilterValue, false})
	module:SetConfigOption("Wardrobe", Value)
end

function module.Widget:RemoveFilter(Index)
	local Value = self:GetData()
	table.remove(Value, Index)
	module:SetConfigOption("Wardrobe", Value)
end

function module.Widget:DisplayWidget(Index)
	if (Index) then module.FilterIndex = Index end
	local Value = self:GetData()
	if (select(4, GetBuildInfo()) < 30000) then
		UIDropDownMenu_SetText(module:GetUsableText(Value[module.FilterIndex][1]), module.Widget)
	else
		UIDropDownMenu_SetText(module.Widget, module:GetUsableText(Value[module.FilterIndex][1]))
	end
end

function module.Widget:GetFilterText(Index)
	local Value = self:GetData()
	return module:GetUsableText(Value[Index][1])
end

function module.Widget:IsException(RuleNum, Index)
	local Data = self:GetData(RuleNum)
	return Data[Index][2]
end

function module.Widget:SetException(RuleNum, Index, Value)
	local Data = self:GetData(RuleNum)
	Data[Index][2] = Value
	module:SetConfigOption("Unowned", Data)
end

function module.Widget:SetMatch(ItemLink, Tooltip)
	local itemID = GetItemInfoFromHyperlink(ItemLink)
	local Owned = 0 -- 0 means no Wardrobe line on tooltip
	local _, _, _, _, _, _, sSubType = GetItemInfo(ItemLink)
	if sSubType ~= "Thrown" then -- you can't get wardrobe unlocks from thrown weapons
		if APPEARANCE_ITEM_INFO[itemID] then
			local collectedID = APPEARANCE_ITEM_INFO[itemID]:GetCollectedID()
			if collectedID == itemID then -- unlocked
				Owned = 2
			elseif collectedID then -- unlocked but from different item
				Owned = 4
			else -- unknown
				Owned = 3
			end
		end
	end
	module.CurrentMatch = Owned
	module:Debug("Wardrobe: " .. Owned .. " (" .. itemID .. ")")
end

function module.Widget:GetMatch(RuleNum, Index)
	local RuleValue = self:GetData(RuleNum)
	if (RuleValue[Index][1] == 1 and module.CurrentMatch > 0) or -- rule is "any" and item contains a Wardrobe line
	(RuleValue[Index][1] > 1 and RuleValue[Index][1] == module.CurrentMatch) then return true end
	return false
end

function module:DropDown_Init(Frame, Level)
	Level = Level or 1
	local info = {}
	info.checked = false
	if (select(4, GetBuildInfo()) < 30000) then
		info.func = function(...) self:DropDown_OnClick(this, ...) end
	else
		info.func = function(...) self:DropDown_OnClick(...) end
	end
	info.owner = Frame
	for Key, Value in ipairs(self.Choices) do
		info.text = Value.Name
		info.value = Value.Value
		UIDropDownMenu_AddButton(info, Level)
	end
end

function module:DropDown_OnClick(Frame)
	local Value = self.Widget:GetData()
	Value[self.FilterIndex][1] = Frame.value
	self:SetConfigOption("Wardrobe", Value)
	if (select(4, GetBuildInfo()) < 30000) then
		UIDropDownMenu_SetText(Frame:GetText(), Frame.owner)
	else
		UIDropDownMenu_SetText(Frame.owner, Frame:GetText())
	end
end

function module:GetUsableText(ID)
	for Key, Value in ipairs(self.Choices) do if (Value.Value == ID) then return Value.Name end end
	return ""
end
