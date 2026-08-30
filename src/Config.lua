local addonName, addon = ...
---@type MiniFramework
local mini = addon.Framework
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
	CompactArenaFrame = false,
	BagsBar = false,
	MicroMenu = false,
	HotKeysBorder = false,
	StatusTrackingBarManager = false,
	Helptips = false,
}
---@class CharDB
local charDbDefaults = {
	StanceBar = false,
	HotKeysText = false,
}
---@class Config
local M = {}
addon.Config = M

local function LayoutSettings(settings, relativeTo, xOffset, yOffset)
	local x = xOffset
	local y = yOffset
	local bottomLeftCheckbox = nil
	local isNewRow = true

	for i, setting in ipairs(settings) do
		local checkbox = mini:Checkbox(setting)
		checkbox:SetPoint("TOPLEFT", relativeTo, "TOPLEFT", x, y)

		if isNewRow then
			bottomLeftCheckbox = checkbox
		end

		if i % checkboxesPerLine == 0 then
			y = y - (verticalSpacing * 2)
			x = xOffset

			isNewRow = true
		else
			x = x + checkboxWidth

			isNewRow = false
		end
	end

	return bottomLeftCheckbox
end

function M:Init()
	-- A styled button clashes with the stock Blizzard art around it in the settings screen.
	mini:SetCustomStyling(true, { Button = false })

	db = mini:GetSavedVars(dbDefaults)
	charDb = mini:GetCharacterSavedVars(charDbDefaults)

	local panel = CreateFrame("Frame")
	panel.name = addonName

	local category = mini:AddCategory(panel)

	if not category then
		return
	end

	local header = mini:PanelHeader({
		Parent = panel,
		Description = "Hide various frames for a cleaner UI.",
		Gap = 4,
	})

	---@type CheckboxOptions[]
	local settings = {
		{
			Parent = panel,
			LabelText = "Resting animation",
			Tooltip = "Hides the playing 'zzz' animation loop.",
			GetValue = function()
				return db.PlayerRestLoop
			end,
			SetValue = function(enabled)
				db.PlayerRestLoop = enabled
				addon:Run()
			end,
		},
		{
			Parent = panel,
			LabelText = "Prestige badges",
			Tooltip = "Hides the player, target, and focus prestige badges.",
			GetValue = function()
				return db.PrestigeBadges
			end,
			SetValue = function(enabled)
				db.PrestigeBadges = enabled
				addon:Run()
			end,
		},
		{
			Parent = panel,
			LabelText = "Player corner icon",
			Tooltip = "Hides the player portrait bottom right corner icon.",
			GetValue = function()
				return db.PlayerPortraitCornerIcon
			end,
			SetValue = function(enabled)
				db.PlayerPortraitCornerIcon = enabled
				addon:Run()
			end,
		},
		{
			Parent = panel,
			LabelText = "Player level text",
			Tooltip = "Hides the player portrait level text.",
			GetValue = function()
				return db.PlayerLevelText
			end,
			SetValue = function(enabled)
				db.PlayerLevelText = enabled
				addon:Run()
			end,
		},
		{
			Parent = panel,
			LabelText = "Arena Frames",
			Tooltip = "Hides the blizzard arena frames.",
			GetValue = function()
				return db.CompactArenaFrame
			end,
			SetValue = function(enabled)
				db.CompactArenaFrame = enabled
				addon:Run()
			end,
		},
		{
			Parent = panel,
			LabelText = "Arena title",
			Tooltip = "Hides the arena frames title.",
			GetValue = function()
				return db.CompactArenaFrameTitle
			end,
			SetValue = function(enabled)
				db.CompactArenaFrameTitle = enabled
				addon:Run()
			end,
		},
		{
			Parent = panel,
			LabelText = "Party title",
			Tooltip = "Hides the party frames title.",
			GetValue = function()
				return db.CompactPartyFrameTitle
			end,
			SetValue = function(enabled)
				db.CompactPartyFrameTitle = enabled
				addon:Run()
			end,
		},
		{
			Parent = panel,
			LabelText = "Social icon",
			Tooltip = "Hides the social icon (a.k.a quick join toast button) above the chat window.",
			GetValue = function()
				return db.QuickJoinToastButton
			end,
			SetValue = function(enabled)
				db.QuickJoinToastButton = enabled
				addon:Run()
			end,
		},
		{
			Parent = panel,
			LabelText = "Bags bar",
			Tooltip = "Hides the bags bar.",
			GetValue = function()
				return db.BagsBar
			end,
			SetValue = function(enabled)
				db.BagsBar = enabled
				addon:Run()
			end,
		},
		{
			Parent = panel,
			LabelText = "Micro menu",
			Tooltip = "Hides the micro menu.",
			GetValue = function()
				return db.MicroMenu
			end,
			SetValue = function(enabled)
				db.MicroMenu = enabled
				addon:Run()
			end,
		},
		{
			Parent = panel,
			LabelText = "HotKeys Border",
			Tooltip = "Hides the hot key borders on your action bars.",
			GetValue = function()
				return db.HotKeysBorder
			end,
			SetValue = function(enabled)
				db.HotKeysBorder = enabled
				addon:Run()
			end,
		},
		{
			Parent = panel,
			LabelText = "XP and Rep",
			Tooltip = "Hides the xp and reputation bars.",
			GetValue = function()
				return db.StatusTrackingBarManager
			end,
			SetValue = function(enabled)
				db.StatusTrackingBarManager = enabled
				addon:Run()
			end,
		},
		{
			Parent = panel,
			LabelText = "Help tips",
			Tooltip = "Hides tooltips such as new profession points and new collections.",
			GetValue = function()
				return db.Helptips
			end,
			SetValue = function(enabled)
				db.Helptips = enabled
				addon:Run()
			end,
		},
	}

	local globalDivider = mini:Divider({
		Parent = panel,
		Text = "Global",
	})

	globalDivider:SetPoint("TOPLEFT", header.Anchor, 0, -verticalSpacing * 2)
	globalDivider:SetPoint("RIGHT", panel, "RIGHT", 0, 0)

	local anchor = LayoutSettings(settings, globalDivider, 0, -verticalSpacing * 2)

	local charDivider = mini:Divider({
		Parent = panel,
		Text = "Character",
	})

	charDivider:SetPoint("TOPLEFT", anchor, 0, -verticalSpacing * 3)
	charDivider:SetPoint("RIGHT", panel, "RIGHT", 0, 0)

	---@type CheckboxOptions[]
	local charSettings = {
		{
			Parent = panel,
			LabelText = "Stance Bar",
			Tooltip = "Hides the stance bar (druid forms, warrior stances).",
			GetValue = function()
				return charDb.StanceBar
			end,
			SetValue = function(enabled)
				charDb.StanceBar = enabled
				addon:Run()
			end,
		},
		{
			Parent = panel,
			LabelText = "HotKeys Text",
			Tooltip = "Hides the hot keys text on your action bars.",
			GetValue = function()
				return charDb.HotKeysText
			end,
			SetValue = function(enabled)
				charDb.HotKeysText = enabled
				addon:Run()
			end,
		},
	}

	LayoutSettings(charSettings, charDivider, 0, -verticalSpacing * 2)

	mini:RegisterSlashCommand(category, panel, {
		"/minihider",
		"/mh",
	})
end
