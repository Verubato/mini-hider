# MiniHider - support reference

## What it is

MiniHider hides individual pieces of the default Blizzard UI for a cleaner look: the resting "zzz" animation, prestige badges, the player level text, party/arena frame titles, the bags bar, the micro menu, action bar hotkey text and borders, the XP/reputation bars, help tips, the stance bar, and more. Everything is a checkbox: checked = hidden, unchecked = shown.

## Facts

| Item | Value |
|---|---|
| Addon version | 1.6.6 |
| Author | Verz |
| Interface versions (TOC) | 120100 (Retail only) |
| Saved variables | MiniHiderDB (account-wide), MiniHiderCharDB (per character) |
| Slash commands | /minihider, /mh (both open the options panel) |
| Options location | Game Menu -> Options -> AddOns -> MiniHider |
| Bundled libraries | MiniFramework |
| CurseForge project | minihider (ID 1420904) |

## How it works

- Settings apply immediately when you toggle a checkbox, and are re-applied on every loading screen (twice: instantly, and again one frame later for elements that are created late, like hotkey text).
- Toggling anything while in combat does nothing except print "MiniHider - Can't do that during combat." in chat. The checkbox state is still saved and applies after your next loading screen or the next toggle out of combat.
- The addon tracks what it hid and only ever re-shows things it hid itself. It does not force-show elements hidden by other addons.
- MiniHider only touches the default Blizzard frames. Action bars, unit frames, etc from other addons (Bartender, ElvUI, ...) are unaffected.

## Settings

Checked = hidden. Six elements are hidden by default on a fresh install; the rest default to shown.

### Global settings (account-wide, "Global settings:" section)

| Checkbox | Default | Tooltip / what it hides |
|---|---|---|
| Resting animation | Checked (hidden) | The player frame "zzz" animation loop, plus the flashing rest status texture |
| Prestige badges | Checked (hidden) | The player, target, and focus prestige badges |
| Player corner icon | Checked (hidden) | The player portrait bottom right corner icon (the hole left behind is patched with a black filler) |
| Player level text | Checked (hidden) | The player portrait level text |
| Arena Frames | Unchecked | The Blizzard arena frames (CompactArenaFrame) |
| Arena title | Checked (hidden) | The arena frames title text |
| Party title | Checked (hidden) | The party frames title text |
| Social icon | Unchecked | The social / quick join toast button above the chat window |
| Bags bar | Unchecked | The bags bar |
| Micro menu | Unchecked | The micro menu (the row of buttons next to the bags) |
| HotKeys Border | Unchecked | The border (normal texture) on action bar buttons, bars 1-8 |
| XP and Rep | Unchecked | The XP and reputation bars (status tracking bar) |
| Help tips | Unchecked | Help tips such as new profession points and new collections (via the hideHelptips CVar) |

### Character settings (per character, "Character settings:" section)

| Checkbox | Default | Tooltip / what it hides |
|---|---|---|
| Stance Bar | Unchecked | The stance bar (druid forms, warrior stances). Hidden via a secure visibility driver |
| HotKeys Text | Unchecked | The hotkey text and macro name text on action bar buttons (bars 1-8 and the pet bar) |

There is no reset button and no other settings; the two sections above are the whole options panel.

## Conditional behavior

- Retail only. It is not packaged for Classic clients.
- Nothing can be applied during combat (see above); this includes the stance bar, which uses secure code.
- Elements that do not exist on your client or in your current state are silently skipped.

## Troubleshooting

- "I toggled a setting and nothing happened": you were probably in combat; the addon prints "MiniHider - Can't do that during combat." and skips the change. It still saved; toggle again or take a loading screen once out of combat.
- "I unchecked something but it is still hidden": most elements re-show immediately, but if it does not, a /reload restores the default UI state and MiniHider will only re-hide what is still checked.
- "Hotkey text comes back / flickers at login": hotkey elements are created late; the addon re-applies one frame after entering the world. If another action bar addon manages hotkey text, MiniHider only affects the default Blizzard bars.
- "The stance bar setting doesn't carry to my other characters": Stance Bar and HotKeys Text are per-character on purpose. Everything else is account-wide.
- "Arena frames still show": the Arena Frames checkbox is off by default; it must be checked. Note "Arena title" only hides the title text, not the frames.
- "There's a black square on my player portrait": that is the filler texture that patches the hole left by hiding the player corner icon. Unchecking "Player corner icon" removes it.
- "MiniHider hid something another addon needs / another addon's frame": it only touches the specific Blizzard frames listed above, and only re-shows frames it hid itself.
- "Help tips still appear": the setting sets the hideHelptips CVar when toggled; try toggling it off and on again out of combat, then check for other addons or game settings that manage help tips.
- "Does it work on Classic?": no, the TOC only supports Retail 12.1.
