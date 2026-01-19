local _, addon = ...
---@type MiniFramework
local mini = addon.Framework
local eventsFrame
local playerIconFiller
local hiddenFrame
---@type DB
local db
---@type CharDB
local charDb
-- keep track of stuff we hid to avoid touching things that we didn't change
local didWeHide = {}

local function ShowHidePlayerCornerIcon()
	local target = PlayerFrame
		and PlayerFrame.PlayerFrameContent
		and PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual
		and PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon

	if not target then
		return
	end

	local show = type(db.PlayerPortraitCornerIcon) == "boolean" and not db.PlayerPortraitCornerIcon

	if show and not didWeHide["PlayerPortraitCornerIcon"] then
		return
	end

	target:SetAlpha(show and 1 or 0)

	-- fill in the hole that's left from hiding the corner icon
	if not playerIconFiller then
		playerIconFiller = PlayerFrame:CreateTexture(nil, "ARTWORK")
		playerIconFiller:SetColorTexture(0, 0, 0, 1)
		playerIconFiller:SetSize(target:GetWidth() + 2, target:GetHeight() + 2)
		playerIconFiller:SetPoint("TOPLEFT", target, "TOPLEFT", 0, 0)
	end

	playerIconFiller:SetAlpha(show and 1 or 0)
	didWeHide["PlayerPortraitCornerIcon"] = not show
end

local function ShowHidePrestigeBadge()
	local playerParent = PlayerFrame
		and PlayerFrame.PlayerFrameContent
		and PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual
	local targetParent = TargetFrame
		and TargetFrame.TargetFrameContent
		and TargetFrame.TargetFrameContent.TargetFrameContentContextual
	local focusParent = FocusFrame
		and FocusFrame.TargetFrameContent
		and FocusFrame.TargetFrameContent.TargetFrameContentContextual

	local targets = {
		playerParent.PrestigeBadge,
		playerParent.PrestigePortrait,

		targetParent.PrestigeBadge,
		targetParent.PrestigePortrait,

		focusParent.PrestigeBadge,
		focusParent.PrestigePortrait,
	}

	local show = type(db.PrestigeBadges) == "boolean" and not db.PrestigeBadges

	if show and not didWeHide["PrestigeBadges"] then
		return
	end

	for _, target in ipairs(targets) do
		target:SetAlpha(show and 1 or 0)
	end

	didWeHide["PrestigeBadges"] = not show
end

local function ShowHideRestingAnimation()
	local target = PlayerFrame
		and PlayerFrame.PlayerFrameContent
		and PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual
		and PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop

	if not target then
		return
	end

	local show = type(db.PlayerRestLoop) == "boolean" and not db.PlayerRestLoop

	if show and not didWeHide["PlayerRestLoop"] then
		return
	end

	target:SetAlpha(show and 1 or 0)

	didWeHide["PlayerRestLoop"] = not show

	-- hide the flashing animation
	local statusTexture = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
		and PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.StatusTexture

	if statusTexture then
		if show then
			statusTexture:Show()
		else
			statusTexture:Hide()
		end

		if not statusTexture.MiniHiderHooked then
			statusTexture:HookScript("OnShow", function()
				if not didWeHide["PlayerRestLoop"] then
					return
				end

				if db.PlayerRestLoop then
					statusTexture:Hide()
				else
					statusTexture:Show()
				end
			end)

			statusTexture.MiniHiderHooked = true
		end
	end
end

local function ShowHideToastButton()
	local target = QuickJoinToastButton

	if not target then
		return
	end

	local show = type(db.QuickJoinToastButton) == "boolean" and not db.QuickJoinToastButton

	if show and not didWeHide["QuickJoinToastButton"] then
		return
	end

	target:SetAlpha(show and 1 or 0)
	didWeHide["QuickJoinToastButton"] = not show
end

local function ShowHideStanceBar()
	if not StanceBar then
		return
	end

	local show = type(charDb.StanceBar) == "boolean" and not charDb.StanceBar

	if show and not didWeHide["StanceBar"] then
		return
	end

	RegisterAttributeDriver(StanceBar, "state-visibility", show and "show" or "hide")
	didWeHide["StanceBar"] = not show
end

local function ShowHidePartyTitle()
	local target = CompactPartyFrameTitle

	if not target then
		return
	end

	local show = type(db.CompactPartyFrameTitle) == "boolean" and not db.CompactPartyFrameTitle

	if show and not didWeHide["CompactPartyFrameTitle"] then
		return
	end

	target:SetAlpha(show and 1 or 0)
	didWeHide["CompactPartyFrameTitle"] = not show
end

local function ShowHideArenaTitle()
	local target = CompactArenaFrameTitle

	if not target then
		return
	end

	if show and not didWeHide["CompactArenaFrameTitle"] then
		return
	end

	local show = type(db.CompactArenaFrameTitle) == "boolean" and not db.CompactArenaFrameTitle
	target:SetAlpha(show and 1 or 0)
	didWeHide["CompactArenaFrameTitle"] = not show
end

local function ShowHidePlayerLevel()
	if not PlayerLevelText then
		return
	end

	local show = type(db.PlayerLevelText) == "boolean" and not db.PlayerLevelText

	if show and not didWeHide["PlayerLevelText"] then
		return
	end

	-- blizzard expect this function to exists and throws a million errors when it doesn't
	PlayerLevelText.SetAttribute = PlayerLevelText.SetAttribute or function() end
	PlayerLevelText:SetAlpha(show and 1 or 0)
	didWeHide["PlayerLevelText"] = not show
end

local function ShowHideXpAndRep()
	local show = type(db.StatusTrackingBarManager) == "boolean" and not db.StatusTrackingBarManager

	if show and not didWeHide["StatusTrackingBarManager"] then
		return
	end

	local target = StatusTrackingBarManager

	if not target then
		return
	end

	if show then
		target:Show()
	else
		target:Hide()
	end

	didWeHide["StatusTrackingBarManager"] = not show
end

local function ShowHideHotkeys()
	local show = type(charDb.HotKeysText) == "boolean" and not charDb.HotKeysText

	if show and not didWeHide["HotKeysText"] then
		return
	end

	local hotKeyAlpha = show and 1 or 0

	local function ApplyAlpha(frame, alpha)
		if not frame then
			return
		end

		frame:SetAlpha(alpha)
	end

	for i = 1, 12 do
		ApplyAlpha(_G["ActionButton" .. i .. "HotKey"], hotKeyAlpha)
		ApplyAlpha(_G["MultiBarBottomLeftButton" .. i .. "HotKey"], hotKeyAlpha)
		ApplyAlpha(_G["MultiBarBottomRightButton" .. i .. "HotKey"], hotKeyAlpha)
		ApplyAlpha(_G["MultiBarRightButton" .. i .. "HotKey"], hotKeyAlpha)
		ApplyAlpha(_G["MultiBarLeftButton" .. i .. "HotKey"], hotKeyAlpha)
		ApplyAlpha(_G["MultiBar5Button" .. i .. "HotKey"], hotKeyAlpha)
		ApplyAlpha(_G["MultiBar6Button" .. i .. "HotKey"], hotKeyAlpha)
		ApplyAlpha(_G["MultiBar7Button" .. i .. "HotKey"], hotKeyAlpha)
		ApplyAlpha(_G["PetActionButton" .. i .. "HotKey"], hotKeyAlpha)

		ApplyAlpha(_G["ActionButton" .. i .. "Name"], hotKeyAlpha)
		ApplyAlpha(_G["MultiBarBottomLeftButton" .. i .. "Name"], hotKeyAlpha)
		ApplyAlpha(_G["MultiBarBottomRightButton" .. i .. "Name"], hotKeyAlpha)
		ApplyAlpha(_G["MultiBarRightButton" .. i .. "Name"], hotKeyAlpha)
		ApplyAlpha(_G["MultiBarLeftButton" .. i .. "Name"], hotKeyAlpha)
		ApplyAlpha(_G["MultiBar5Button" .. i .. "Name"], hotKeyAlpha)
		ApplyAlpha(_G["MultiBar6Button" .. i .. "Name"], hotKeyAlpha)
		ApplyAlpha(_G["MultiBar7Button" .. i .. "Name"], hotKeyAlpha)
		ApplyAlpha(_G["PetActionButton" .. i .. "Name"], hotKeyAlpha)
	end

	didWeHide["HotKeysText"] = not show
end

local function ShowHideHotkeysBorder()
	local show = type(db.HotKeysBorder) == "boolean" and not db.HotKeysBorder

	if show and not didWeHide["HotKeysBorder"] then
		return
	end

	local alpha = show and 1 or 0

	local names = {
		"ActionButton",
		"MultiBarBottomLeftButton",
		"MultiBarBottomRightButton",
		"MultiBarRightButton",
		"MultiBarLeftButton",
		"MultiBar5Button",
		"MultiBar6Button",
		"MultiBar7Button",
	}

	for _, prefix in ipairs(names) do
		for i = 1, 12 do
			local button = _G[prefix .. i]

			if button then
				button.NormalTexture:SetAlpha(alpha)
			end
		end
	end

	didWeHide["HotKeysBorder"] = not show
end

function ShowHideArenaFrames()
	local show = type(db.CompactArenaFrame) == "boolean" and not db.CompactArenaFrame

	if show and not didWeHide["CompactArenaFrame"] then
		return
	end

	if show then
		CompactArenaFrame:SetParent(UIParent)
	else
		CompactArenaFrame:SetParent(hiddenFrame)
	end

	didWeHide["CompactArenaFrame"] = not show
end

function ShowHideBags()
	local show = type(db.BagsBar) == "boolean" and not db.BagsBar

	if show and not didWeHide["BagsBar"] then
		return
	end

	if show then
		BagsBar:Show()
	else
		BagsBar:Hide()
	end

	didWeHide["BagsBar"] = not show
end

function ShowHideMicroMenu()
	local show = type(db.MicroMenu) == "boolean" and not db.MicroMenu

	if show and not didWeHide["MicroMenu"] then
		return
	end

	if show then
		MicroMenu:Show()
	else
		MicroMenu:Hide()
	end

	didWeHide["MicroMenu"] = not show
end

function addon:Run()
	ShowHideStanceBar()
	ShowHideRestingAnimation()
	ShowHidePrestigeBadge()
	ShowHidePlayerCornerIcon()
	ShowHidePlayerLevel()
	ShowHidePartyTitle()
	ShowHideArenaTitle()
	ShowHideToastButton()
	ShowHideHotkeys()
	ShowHideHotkeysBorder()
	ShowHideArenaFrames()
	ShowHideBags()
	ShowHideMicroMenu()
	ShowHideXpAndRep()
end

local function OnEvent()
	-- seems we still need to wait a frame for hotkeys text to load
	C_Timer.After(0, function()
		addon:Run()
	end)
end

local function OnAddonLoaded()
	addon.Config:Init()

	db = mini:GetSavedVars()
	charDb = mini:GetCharacterSavedVars()

	hiddenFrame = CreateFrame("Frame")
	hiddenFrame:Hide()

	eventsFrame = CreateFrame("Frame")
	eventsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	eventsFrame:SetScript("OnEvent", OnEvent)
end

mini:WaitForAddonLoad(OnAddonLoaded)
