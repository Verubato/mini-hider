local addonName, addon = ...
local verticalSpacing = 20
local checkboxesPerLine = 4
local checkboxWidth = 150
---@type DB
local db
---@type CharDB
local charDb
---@class DB
local dbDefaults = {
	PlayerRestLoop = true,
	PrestigeBadges = true,
	PlayerPortraitCornerIcon = true,
	PlayerLevelText = true,
	CompactPartyFrameTitle = true,
	CompactArenaFrameTitle = true,
	QuickJoinToastButton = false,
}
---@class CharDB
local charDbDefaults = {
	StanceBar = false,
	HotKeysText = false,
}
local M = {}
addon.Config = M

local function CopyTable(src, dst)
	if type(dst) ~= "table" then
		dst = {}
	end

	for k, v in pairs(src) do
		if type(v) == "table" then
			dst[k] = CopyTable(v, dst[k])
		elseif dst[k] == nil then
			dst[k] = v
		end
	end

	return dst
end

local function AddCategory(panel)
	if Settings then
		local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
		Settings.RegisterAddOnCategory(category)

		return category
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(panel)

		return panel
	end

	return nil
end

local function CreateSettingCheckbox(panel, setting)
	local checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	checkbox.Text:SetText(" " .. setting.Name)
	checkbox.Text:SetFontObject("GameFontNormal")
	checkbox:SetChecked(setting.Enabled())
	checkbox:HookScript("OnClick", function()
		setting.OnChanged(checkbox:GetChecked())
	end)

	checkbox:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(setting.Name, 1, 0.82, 0)
		GameTooltip:AddLine(setting.Tooltip, 1, 1, 1, true)
		GameTooltip:Show()
	end)

	checkbox:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	return checkbox
end

local function LayoutSettings(settings, panel, relativeTo, xOffset, yOffset)
	local x = xOffset
	local y = yOffset
	local bottomLeftCheckbox = nil

	for i, setting in ipairs(settings) do
		local checkbox = CreateSettingCheckbox(panel, setting)
		checkbox:SetPoint("TOPLEFT", relativeTo, "TOPLEFT", x, y)

		if not bottomLeftCheckbox or i % (checkboxesPerLine + 1) == 0 then
			bottomLeftCheckbox = checkbox
		end

		if i % checkboxesPerLine == 0 then
			y = y - (verticalSpacing * 2)
			x = xOffset
		else
			x = x + checkboxWidth
		end
	end

	return bottomLeftCheckbox
end

function CanOpenOptionsDuringCombat()
	if LE_EXPANSION_LEVEL_CURRENT == nil or LE_EXPANSION_MIDNIGHT == nil then
		return true
	end

	return LE_EXPANSION_LEVEL_CURRENT < LE_EXPANSION_MIDNIGHT
end

function M:Init()
	MiniHiderDB = MiniHiderDB or {}
	MiniHiderCharDB = MiniHiderCharDB or {}

	db = CopyTable(dbDefaults, MiniHiderDB)
	charDb = CopyTable(charDbDefaults, MiniHiderCharDB)

	local panel = CreateFrame("Frame")
	panel.name = addonName

	local category = AddCategory(panel)

	if not category then
		return
	end

	local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 0, -verticalSpacing)
	title:SetText(string.format("%s - %s", addonName, version))

	local description = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
	description:SetPoint("TOPLEFT", title, 0, -verticalSpacing)
	description:SetText("Hide various frames for a cleaner UI.")

	local settings = {
		{
			Name = "Resting animation",
			Tooltip = "Hides the playing 'zzz' animation loop.",
			Enabled = function()
				return db.PlayerRestLoop
			end,
			OnChanged = function(enabled)
				db.PlayerRestLoop = enabled
				addon:Run()
			end,
		},
		{
			Name = "Prestidge badges",
			Tooltip = "Hides the player, target, and focus prestige badges.",
			Enabled = function()
				return db.PrestigeBadges
			end,
			OnChanged = function(enabled)
				db.PrestigeBadges = enabled
				addon:Run()
			end,
		},
		{
			Name = "Player corner icon",
			Tooltip = "Hides the player portrait bottom right corner icon.",
			Enabled = function()
				return db.PlayerPortraitCornerIcon
			end,
			OnChanged = function(enabled)
				db.PlayerPortraitCornerIcon = enabled
				addon:Run()
			end,
		},
		{
			Name = "Player level text",
			Tooltip = "Hides the player portrait level text.",
			Enabled = function()
				return db.PlayerLevelText
			end,
			OnChanged = function(enabled)
				db.PlayerLevelText = enabled
				addon:Run()
			end,
		},
		{
			Name = "Party title",
			Tooltip = "Hides the party frames title.",
			Enabled = function()
				return db.CompactPartyFrameTitle
			end,
			OnChanged = function(enabled)
				db.CompactPartyFrameTitle = enabled
				addon:Run()
			end,
		},
		{
			Name = "Arena title",
			Tooltip = "Hides the arena frames title.",
			Enabled = function()
				return db.CompactArenaFrameTitle
			end,
			OnChanged = function(enabled)
				db.CompactArenaFrameTitle = enabled
				addon:Run()
			end,
		},
		{
			Name = "Social icon",
			Tooltip = "Hides the social icon (a.k.a quick join toast button) above the chat window.",
			Enabled = function()
				return db.QuickJoinToastButton
			end,
			OnChanged = function(enabled)
				db.QuickJoinToastButton = enabled
				addon:Run()
			end,
		},
	}

	local globalHeading = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
	globalHeading:SetPoint("TOPLEFT", description, 0, -verticalSpacing * 2)
	globalHeading:SetText("Global settings:")

	local anchor = LayoutSettings(settings, panel, globalHeading, 0, -verticalSpacing)

	local charHeading = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
	charHeading:SetPoint("TOPLEFT", anchor, 0, -verticalSpacing * 3)
	charHeading:SetText("Character settings:")

	local charSettings = {
		{
			Name = "Stance Bar",
			Tooltip = "Hides the stance bar (druid forms, warrior stances).",
			Enabled = function()
				return charDb.StanceBar
			end,
			OnChanged = function(enabled)
				charDb.StanceBar = enabled
				addon:Run()
			end,
		},
		{
			Name = "HotKeys Text",
			Tooltip = "Hides the hot keys text on your action bars.",
			Enabled = function()
				return charDb.HotKeysText
			end,
			OnChanged = function(enabled)
				charDb.HotKeysText = enabled
				addon:Run()
			end,
		},
	}

	LayoutSettings(charSettings, panel, charHeading, 0, -verticalSpacing)

	SLASH_MINIHIDER1 = "/minihider"
	SLASH_MINIHIDER2 = "/mh"

	SlashCmdList.MINIHIDER = function()
		if Settings then
			if not InCombatLockdown() or CanOpenOptionsDuringCombat() then
				Settings.OpenToCategory(category:GetID())
			end
		elseif InterfaceOptionsFrame_OpenToCategory then
			-- workaround the classic bug where the first call opens the Game interface
			-- and a second call is required
			InterfaceOptionsFrame_OpenToCategory(panel)
			InterfaceOptionsFrame_OpenToCategory(panel)
		end
	end
end
