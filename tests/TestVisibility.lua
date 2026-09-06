-- MiniHider is almost entirely repeated show/hide functions driven off a saved boolean, so
-- the value here isn't in the per-element wiring but in the bookkeeping every one of them
-- shares: didWeHide, and the early-exit guard it drives, which is what stops MiniHider from
-- fighting Blizzard's or another addon's own state once it has nothing left to change.
--
-- Four kinds of element carry extra bookkeeping of their own: the corner icon (alpha, plus a
-- filler texture it only creates once), the toast button (Show/Hide rather than alpha, and one
-- Blizzard toggles itself), the stance bar (a character-scoped setting driving
-- RegisterAttributeDriver, a mechanism the shared mock doesn't record on its own), and the hit
-- indicators (a reparent, plus the anchors they have to hand back).

local fw = require("TestFramework")
local harness = require("AddonHarness")
local WowMock = require("WowMock")

---@param db table? overrides merged into the account-wide defaults
---@param charDb table? overrides merged into the per-character defaults
local function LoginWith(db, charDb)
	local context = harness.Load("MiniHider")

	_G.MiniHiderDB = db or {}
	_G.MiniHiderCharDB = charDb or {}

	harness.Login(context)

	return context
end

local function CornerIcon()
	return _G.PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon
end

local function ToastButton()
	return _G.QuickJoinToastButton
end

---Hangs a hit indicator off the player frame the way retail does, since the shared mock
---doesn't carry one, and anchors it so the restore has points to put back.
---@return table indicator, table parent
local function NewHitIndicator()
	local main = _G.PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
	local indicator = WowMock.NewFrame("Frame", nil, main)

	indicator:SetPoint("CENTER", main, "CENTER", 3, -7)
	main.HitIndicator = indicator

	return indicator, main
end

---Hangs the pet's hit indicator off the pet frame the way retail does, as the font string it
---really is rather than a frame, and anchors it so the restore has points to put back.
---@return table indicator, table parent
local function NewPetHitIndicator()
	local parent = _G.PetFrame
	local indicator = WowMock.NewFrame("FontString", "PetHitIndicator", parent)

	indicator:SetPoint("CENTER", parent, "CENTER", -2, 4)

	return indicator, parent
end

---Replaces the mock's no-op RegisterAttributeDriver with one that records every call, since
---the stance bar's hidden state lives on the secure state driver rather than on the frame.
---@return { Frame: table, Attribute: string, Condition: string }[]
local function StubAttributeDriver()
	local calls = {}

	_G.RegisterAttributeDriver = function(frame, attribute, condition)
		calls[#calls + 1] = { Frame = frame, Attribute = attribute, Condition = condition }
	end

	return calls
end

fw.describe("MiniHider - corner icon bookkeeping", function()
	fw.it("keeps enforcing hidden on every pass, not just the first", function()
		local context = LoginWith({ PlayerPortraitCornerIcon = true })
		local icon = CornerIcon()

		fw.eq(icon:GetAlpha(), 0, "hidden")

		-- something else tries to show it again between passes
		icon:SetAlpha(1)
		context.Addon:Run()

		fw.eq(icon:GetAlpha(), 0, "MiniHider puts it back down rather than accepting the change")
	end)

	fw.it("restores the corner icon, then leaves later changes alone", function()
		local context = LoginWith({ PlayerPortraitCornerIcon = true })
		local icon = CornerIcon()

		fw.eq(icon:GetAlpha(), 0, "hidden")

		_G.MiniHiderDB.PlayerPortraitCornerIcon = false
		context.Addon:Run()

		fw.eq(icon:GetAlpha(), 1, "shown again once the setting turns off")

		-- something else can legitimately fade this once MiniHider is done with it; a repeat
		-- pass must not fight that, which only holds if turning the setting off cleared the
		-- record the hide made
		icon:SetAlpha(0.6)
		context.Addon:Run()

		fw.eq(icon:GetAlpha(), 0.6, "left alone after being shown again")
	end)

	fw.it("never touches the corner icon when it was never hidden", function()
		local context = LoginWith({ PlayerPortraitCornerIcon = false })
		local icon = CornerIcon()

		-- stands in for whatever alpha the icon already had before MiniHider ever ran
		icon:SetAlpha(0.6)
		context.Addon:Run()

		fw.eq(icon:GetAlpha(), 0.6, "MiniHider never hid it, so it never touches it")
	end)

	fw.it("creates the filler texture once, not on every pass", function()
		local context = LoginWith({ PlayerPortraitCornerIcon = true })

		local regions = _G.PlayerFrame:GetNumRegions()

		context.Addon:Run()
		context.Addon:Run()

		fw.eq(_G.PlayerFrame:GetNumRegions(), regions, "no extra filler texture on repeat passes")
	end)
end)

fw.describe("MiniHider - toast button bookkeeping", function()
	fw.it("keeps enforcing hidden on every pass, not just the first", function()
		local context = LoginWith({ QuickJoinToastButton = true })
		local button = ToastButton()

		fw.falsy(button:IsShown(), "hidden")

		button:Show()
		context.Addon:Run()

		fw.falsy(button:IsShown(), "MiniHider hides it again rather than accepting the change")
	end)

	fw.it("restores the toast button, then leaves later changes alone", function()
		local context = LoginWith({ QuickJoinToastButton = true })
		local button = ToastButton()

		fw.falsy(button:IsShown(), "hidden")

		_G.MiniHiderDB.QuickJoinToastButton = false
		context.Addon:Run()

		fw.truthy(button:IsShown(), "shown again once the setting turns off")

		-- Blizzard hides this on its own whenever there's nothing to join; a repeat pass
		-- must not fight that, which only holds if restoring it cleared the record
		button:Hide()
		context.Addon:Run()

		fw.falsy(button:IsShown(), "left alone: MiniHider didn't force it back open")
	end)

	fw.it("never touches the toast button when it was never hidden", function()
		local context = LoginWith({ QuickJoinToastButton = false })
		local button = ToastButton()

		-- Blizzard's own natural state, e.g. nothing currently to join
		button:Hide()
		context.Addon:Run()

		fw.falsy(button:IsShown(), "MiniHider never hid it, so it leaves Blizzard's own Hide alone")
	end)
end)

fw.describe("MiniHider - stance bar bookkeeping (character-scoped)", function()
	fw.it("keeps driving the stance bar hidden on every pass, not just the first", function()
		local context = harness.Load("MiniHider")
		local calls = StubAttributeDriver()

		_G.MiniHiderDB = {}
		_G.MiniHiderCharDB = { StanceBar = true }

		harness.Login(context)

		fw.truthy(#calls > 0, "driver registered on login")
		fw.eq(calls[#calls].Condition, "hide", "hidden")

		context.Addon:Run()

		fw.eq(calls[#calls].Condition, "hide", "still driving it hidden on a repeat pass")
	end)

	fw.it("restores the stance bar, then leaves it alone", function()
		local context = harness.Load("MiniHider")
		local calls = StubAttributeDriver()

		_G.MiniHiderDB = {}
		_G.MiniHiderCharDB = { StanceBar = true }

		harness.Login(context)
		fw.eq(calls[#calls].Condition, "hide", "hidden")

		_G.MiniHiderCharDB.StanceBar = false
		context.Addon:Run()

		fw.eq(calls[#calls].Condition, "show", "restored once the character setting turns off")

		local callsAfterRestore = #calls
		context.Addon:Run()

		fw.eq(#calls, callsAfterRestore, "no further driver call once already restored")
	end)
end)

fw.describe("MiniHider - arena title guard", function()
	fw.it("never touches the arena title when it was never hidden", function()
		local context = LoginWith({ CompactArenaFrameTitle = false, CompactPartyFrameTitle = false })

		_G.CompactArenaFrameTitle = WowMock.NewFrame("Frame")
		_G.CompactPartyFrameTitle = WowMock.NewFrame("Frame")

		_G.CompactArenaFrameTitle:SetAlpha(0.6)
		_G.CompactPartyFrameTitle:SetAlpha(0.6)

		context.Addon:Run()

		fw.eq(_G.CompactArenaFrameTitle:GetAlpha(), 0.6, "MiniHider never hid it, so it never touches it")
		fw.eq(_G.CompactPartyFrameTitle:GetAlpha(), 0.6, "the working sibling leaves an untouched title alone too")
	end)

	fw.it("restores the arena title, then leaves later changes alone", function()
		local context = LoginWith({ CompactArenaFrameTitle = true })

		_G.CompactArenaFrameTitle = WowMock.NewFrame("Frame")
		_G.CompactArenaFrameTitle:SetAlpha(1)

		context.Addon:Run()

		fw.eq(_G.CompactArenaFrameTitle:GetAlpha(), 0, "hidden")

		_G.MiniHiderDB.CompactArenaFrameTitle = false
		context.Addon:Run()

		fw.eq(_G.CompactArenaFrameTitle:GetAlpha(), 1, "shown again once the setting turns off")

		-- Something else can legitimately fade this once MiniHider is done with it.
		_G.CompactArenaFrameTitle:SetAlpha(0.6)
		context.Addon:Run()

		fw.eq(_G.CompactArenaFrameTitle:GetAlpha(), 0.6, "left alone after being shown again")
	end)
end)

-- Blizzard sets these regions' alpha every time they flash a number, so MiniHider moves them
-- instead of fading them.
fw.describe("MiniHider - hit indicator parking", function()
	fw.it("never touches either hit indicator when it was never hidden", function()
		local context = LoginWith({ HitIndicator = false })
		local player, playerParent = NewHitIndicator()
		local pet, petParent = NewPetHitIndicator()

		context.Addon:Run()

		fw.eq(player:GetParent(), playerParent, "MiniHider never hid it, so it never reparents it")
		fw.eq(pet:GetParent(), petParent, "same for the pet's")
	end)

	fw.it("parks both hit indicators on every pass, not just the first", function()
		local context = LoginWith({ HitIndicator = true })
		local player, playerParent = NewHitIndicator()
		local pet, petParent = NewPetHitIndicator()

		context.Addon:Run()

		fw.neq(player:GetParent(), playerParent, "moved off the player frame")
		fw.neq(pet:GetParent(), petParent, "moved off the pet frame")
		fw.falsy(player:GetParent():IsShown(), "the player's is parked on a hidden parent")
		fw.falsy(pet:GetParent():IsShown(), "the pet's is parked on a hidden parent")

		context.Addon:Run()

		fw.falsy(player:GetParent():IsShown(), "the player's is still parked on a repeat pass")
		fw.falsy(pet:GetParent():IsShown(), "the pet's is still parked on a repeat pass")
	end)

	fw.it("restores both hit indicators, each to its own parent and anchors", function()
		local context = LoginWith({ HitIndicator = true })
		local player, playerParent = NewHitIndicator()
		local pet, petParent = NewPetHitIndicator()

		context.Addon:Run()
		fw.neq(player:GetParent(), playerParent, "the player's is parked")
		fw.neq(pet:GetParent(), petParent, "the pet's is parked")

		-- the client drops a region's anchors when it changes parent, which the mock doesn't
		-- model, so do it by hand
		player:ClearAllPoints()
		pet:ClearAllPoints()

		_G.MiniHiderDB.HitIndicator = false
		context.Addon:Run()

		fw.eq(player:GetParent(), playerParent, "the player's comes home to the player frame")
		fw.eq(pet:GetParent(), petParent, "the pet's comes home to the pet frame, not the player's")

		local playerPoint, playerRelativeTo, playerRelativePoint, playerX, playerY = player:GetPoint(1)

		fw.eq(player:GetNumPoints(), 1, "the player's has its own anchor back")
		fw.eq(playerPoint, "CENTER", "player anchor point")
		fw.eq(playerRelativeTo, playerParent, "player anchored to the player frame again")
		fw.eq(playerRelativePoint, "CENTER", "player relative point")
		fw.eq(playerX, 3, "player x offset")
		fw.eq(playerY, -7, "player y offset")

		local petPoint, petRelativeTo, petRelativePoint, petX, petY = pet:GetPoint(1)

		fw.eq(pet:GetNumPoints(), 1, "the pet's has its own anchor back, not the player's")
		fw.eq(petPoint, "CENTER", "pet anchor point")
		fw.eq(petRelativeTo, petParent, "pet anchored to the pet frame again")
		fw.eq(petRelativePoint, "CENTER", "pet relative point")
		fw.eq(petX, -2, "pet x offset")
		fw.eq(petY, 4, "pet y offset")
	end)

	fw.it("covers its parent again when it had no anchors of its own", function()
		local context = LoginWith({ HitIndicator = true })
		local main = _G.PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
		-- a region placed with SetAllPoints reports no points, and the restore has to put that
		-- back rather than leave it unanchored
		local indicator = WowMock.NewFrame("Frame", nil, main)

		main.HitIndicator = indicator

		context.Addon:Run()

		fw.neq(indicator:GetParent(), main, "parked")
		fw.eq(indicator:GetNumPoints(), 0, "still carrying no anchors of its own")

		_G.MiniHiderDB.HitIndicator = false
		context.Addon:Run()

		fw.eq(indicator:GetParent(), main, "back on the player frame")
		-- the mock stores SetAllPoints as a point where the real client reports none, so the
		-- count going up stands in for the call having happened
		fw.eq(indicator:GetNumPoints(), 1, "covering its parent again rather than floating free")
	end)

	fw.it("does not error, and still parks the pet's, when the client has no player hit indicator", function()
		local context = LoginWith({ HitIndicator = true })
		local pet, petParent = NewPetHitIndicator()

		fw.is_nil(
			_G.PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator,
			"the mock has no player hit indicator, which stands in for a client that dropped the path"
		)

		fw.no_error(function()
			context.Addon:Run()
		end, "a missing player hit indicator is skipped rather than erroring")

		fw.neq(pet:GetParent(), petParent, "the pet's is still parked")
	end)

	fw.it("does not error, and still parks the player's, when the client has no pet hit indicator", function()
		local context = LoginWith({ HitIndicator = true })
		local player, main = NewHitIndicator()

		fw.is_nil(_G.PetHitIndicator, "the mock has no pet hit indicator, which stands in for no pet out")

		fw.no_error(function()
			context.Addon:Run()
		end, "a missing pet hit indicator is skipped rather than erroring")

		fw.neq(player:GetParent(), main, "the player's is still parked")
	end)

	fw.it("parks a hit indicator that only shows up after the setting was already on", function()
		local context = LoginWith({ HitIndicator = true })
		local player, main = NewHitIndicator()

		context.Addon:Run()
		fw.neq(player:GetParent(), main, "the player's is parked from the first pass")

		-- stands in for a pet summoned after the toggle was already switched on
		local pet, petParent = NewPetHitIndicator()

		context.Addon:Run()

		fw.neq(pet:GetParent(), petParent, "parked once it exists, even though the toggle was already on")
	end)

	fw.it("puts back a hit indicator that was away when the setting turned off", function()
		local context = LoginWith({ HitIndicator = true })
		local player, main = NewHitIndicator()
		local pet, petParent = NewPetHitIndicator()

		context.Addon:Run()
		fw.neq(pet:GetParent(), petParent, "the pet's is parked")

		-- stands in for a pet dismissed while the toggle was on, which takes its region away
		_G.PetHitIndicator = nil

		_G.MiniHiderDB.HitIndicator = false
		context.Addon:Run()

		fw.eq(player:GetParent(), main, "the player's comes home while the pet's is away")

		_G.PetHitIndicator = pet
		context.Addon:Run()

		fw.eq(pet:GetParent(), petParent, "and the pet's comes home once it is back")
	end)

	fw.it("leaves a restored indicator alone on later passes", function()
		local context = LoginWith({ HitIndicator = true })
		local player, main = NewHitIndicator()
		local elsewhere = WowMock.NewFrame("Frame")

		context.Addon:Run()
		_G.MiniHiderDB.HitIndicator = false
		context.Addon:Run()
		fw.eq(player:GetParent(), main, "restored")

		player:SetParent(elsewhere)
		player:ClearAllPoints()
		context.Addon:Run()

		fw.eq(player:GetParent(), elsewhere, "left alone after being restored")
		fw.eq(player:GetNumPoints(), 0, "no anchors forced back on")
	end)
end)
