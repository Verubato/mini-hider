-- MiniHider is almost entirely repeated show/hide functions driven off a saved boolean, so
-- the value here isn't in the per-element wiring but in the bookkeeping every one of them
-- shares: didWeHide, and the early-exit guard it drives, which is what stops MiniHider from
-- fighting Blizzard's or another addon's own state once it has nothing left to change.
--
-- Three elements carry extra bookkeeping of their own: the corner icon (alpha, plus a filler
-- texture it only creates once), the toast button (Show/Hide rather than alpha, and one
-- Blizzard toggles itself), and the stance bar (a character-scoped setting driving
-- RegisterAttributeDriver, a mechanism the shared mock doesn't record on its own).

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
