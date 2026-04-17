-------------------------------------------------------------------------------
-- enUS.lua
-- English (default) locale for DragonLoot
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------
local ADDON_NAME, _ = ... -- luacheck: ignore 211/ns
local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", true, true)
if not L then
    return
end

-- Core/Init.lua
L["Loaded. Type /dl help for commands."] = true

-- Core/SlashCommands.lua
L["--- DragonLoot Commands ---"] = true
L["--- DragonLoot Status ---"] = true
L["Disable addon"] = true
L["Enable addon"] = true
L["Open settings panel"] = true
L["Reset loot frame position"] = true
L["Show current settings"] = true
L["Show test loot"] = true
L["Show test roll frames"] = true
L["Show this help"] = true
L["Toggle addon on/off"] = true
L["Toggle loot history"] = true
L["Toggle minimap icon"] = true
L["Addon disabled"] = true
L["Addon enabled"] = true
L["Animations:"] = true
L["Enabled:"] = true
L["History:"] = true
L["Loot Window:"] = true
L["Loot frame not yet available."] = true
L["Loot frame position reset."] = true
L["Loot history not yet available."] = true
L["Minimap Icon:"] = true
L["No"] = true
L["Roll Frame:"] = true
L["Test loot not yet available."] = true
L["Test roll not yet available."] = true
L["Unknown command:"] = true
L["Yes"] = true

-- Core/MinimapIcon.lua
L["Disabled"] = true
L["Enabled"] = true
L["Left-Click"] = true
L["Open settings"] = true
L["Right-Click"] = true
L["Shift-Left-Click"] = true
L["Shift-click test: DragonLoot is working."] = true
L["Status:"] = true
L["Test message"] = true
L["Toggle on/off"] = true

-- Core/ConfigWindow.lua
L["DragonLoot_Options addon not found. Please ensure it is installed."] = true

-- Display/LootFrame.lua
L["BoE"] = true
L["BoP"] = true
L["BoU"] = true
L["Currency"] = true
L["Fishing"] = true
L["Loot"] = true
L["Money"] = true
L["Quest"] = true
L["Showing test loot window."] = true
L["Test slot clicked: "] = true
L["iLvl"] = true
L["Show Item Level"] = true
L["Show item level overlay on roll frame icon"] = true

-- Display/RollManager.lua (shared roll-type labels via ns.RollTypeNames)
L["Disenchant"] = true
L["Greed"] = true
L["Need"] = true
L["Pass"] = true
L["Transmog"] = true
L["Unknown"] = true

-- Display/RollFrame.lua
L["Center Horizontally"] = true
L["Center roll frame to horizontal center of screen"] = true
L["Center Vertically"] = true
L["Center roll frame to vertical center of screen"] = true
L["Icon Position"] = true
L["Icon position: Inside places the icon inside the frame." .. " Outside places the icon outside the frame border."] =
    true
L["Icon Horizontal Offset"] = true
L["Icon Outside Gap"] = true
L["Icon Side"] = true
L["Icon Vertical Offset"] = true
L["Inside"] = true
L["Left"] = true
L["Not available for this item"] = true
L["Nudge the icon horizontally from its anchor position"] = true
L["Nudge the icon vertically from its anchor position"] = true
L["Outside"] = true
L["Place the icon on the left or right side of the frame"] = true
L["Right"] = true
L["Roll"] = true
L["Showing test roll frames."] = true
L["Start continuous test roll spawning"] = true
L["Start or stop continuous test roll spawning"] = true
L["Stop continuous test roll spawning"] = true
L["Test Item"] = true
L["Test Loop"] = true
L["Test Roll"] = true
L["Test item: "] = true
L["Test roll loop started. Type /dl testroll stop to end."] = true
L["Test roll loop stopped."] = true
L["Test roll: "] = true
L["The gap in pixels between the icon and the frame border when the icon is outside"] = true

-- Display/HistoryFrame.lua
L["%dh ago"] = true
L["%dm ago"] = true
L["%ds ago"] = true
L["Clear History"] = true
L["DragonLoot - Loot History"] = true
L["Looted"] = true
L["Unknown Item"] = true

-------------------------------------------------------------------------------
-- DragonLoot_Options
-------------------------------------------------------------------------------

-- DragonLoot_Options/Core.lua
L["DragonLoot namespace not found."] = true

-- DragonLoot_Options/Core.lua (shared quality values via ns.QualityValues)
L["Common"] = true
L["Epic"] = true
L["Legendary"] = true
L["Poor"] = true
L["Rare"] = true
L["Uncommon"] = true

-- DragonLoot_Options/Widgets/ItemList.lua
L["%d / %d items"] = true
L["%d items"] = true
L["Drop item here to add"] = true

-- DragonLoot_Options/Widgets/Panel.lua
L["DragonLoot Options"] = true

-- DragonLoot_Options/Tabs/GeneralTab.lua
L["Debug Mode"] = true
L["Enable DragonLoot"] = true
L["Enable or disable the DragonLoot addon"] = true
L["Enable verbose debug output in chat"] = true
L["General"] = true
L["Show Minimap Icon"] = true
L["Show or hide the minimap button"] = true

-- DragonLoot_Options/Tabs/LootWindowTab.lua
L["Content Padding"] = true
L["Enable Custom Loot Window"] = true
L["Height"] = true
L["Layout"] = true
L["Lock Position"] = true
L["Open the loot window at the mouse cursor instead of the saved position"] = true
L["Position at Cursor"] = true
L["Prevent the loot window from being moved"] = true
L["Replace the default loot window with DragonLoot's custom frame"] = true
L["Scale"] = true
L["Slot Spacing"] = true
L["Width"] = true

-- DragonLoot_Options/Tabs/LootRollTab.lua
L["Buttons"] = true
L["Frame"] = true
L["Icon"] = true
L["Timer Bar"] = true
L["Button Size"] = true
L["Button Spacing"] = true
L["Compact Text Layout"] = true
L["Enable Custom Roll Frame"] = true
L["Frame Spacing"] = true
L["Frame Height"] = true
L["Frame Width"] = true
L["Height of the countdown timer bar"] = true
L["Minimum height of the roll frame (effective height may be higher based on icon size)"] = true
L["Inner padding of the roll frame"] = true
L["Instance Filters"] = true
L["Loot Roll"] = true
L["Minimum Quality"] = true
L["Prevent the roll frame from being dragged"] = true
L["Replace the default Blizzard roll frame with DragonLoot's custom version"] = true
L["Roll Frame"] = true
L["Roll Notifications"] = true
L["Roll frame scale"] = true
L["Row Spacing"] = true
L["Show Group Rolls"] = true
L["Show Group Wins"] = true
L["Show My Rolls"] = true
L["Show Roll Results"] = true
L["Show Roll Won"] = true
L["Show a notification when someone wins a roll"] = true
L["Show in Dungeons"] = true
L["Show in Open World"] = true
L["Show in Raids"] = true
L["Show individual roll result notifications"] = true
L["Hide After Voting"] = true
-- stylua: ignore
L["Hide the roll frame after you cast your vote. The roll continues in the background"
    .. " and notifications still fire."] = true
L["Show item name and bind type on the same line"] = true
L["Show notifications for other group members' roll results"] = true
L["Show notifications for your own roll results"] = true
L["Show notifications when other group members win rolls"] = true
L["Show roll notifications while in dungeons"] = true
L["Show roll notifications while in raids"] = true
L["Show roll notifications while in the open world"] = true
L["Size of Need/Greed/Pass buttons"] = true
L["Space between item row and timer bar"] = true
L["Spacing between multiple roll frames"] = true
L["Spacing between roll buttons"] = true
L["Timer Bar Height"] = true
L["Timer Bar Spacing"] = true
L["Timer Bar Style"] = true
L["Normal"] = true
L["Minimal"] = true
L["Minimal Height"] = true
L["Height of the minimal timer bar"] = true
L["Timer Bar Appearance"] = true
L["Timer Bar Border"] = true
L["Timer Bar Border Color"] = true
L["Timer Bar Texture"] = true
L["Color Mode"] = true
L["Custom"] = true
L["Bar Color"] = true
L["Bar Background"] = true
L["Bar Background Opacity"] = true
L["Show a border around the timer bar"] = true
L["Vertical spacing between roll rows"] = true
L["Width of the roll frame"] = true

-- DragonLoot_Options/Tabs/NotificationsTab.lua
L["Notifications"] = true

-- DragonLoot_Options/Tabs/HistoryTab.lua
L["Display"] = true
L["Recording"] = true
L["Auto Show on Loot"] = true
L["Enable History"] = true
L["Entry Spacing"] = true
L["History"] = true
L["Max Entries"] = true
L["Prevent the history frame from being moved"] = true
L["Track Direct Loot"] = true
L["Track items you pick up directly (not from a loot window)"] = true
L["Roll Details"] = true
L["Show Roll Details"] = true
L["Click history entries to expand and see all player rolls"] = true

-- DragonLoot_Options/Tabs/AutoLootTab.lua
L["Settings"] = true
L["Auto-Loot"] = true
-- stylua: ignore
L["Automatically loot items that meet your criteria."
    .. " Items on the whitelist are always picked up."
    .. " Items on the blacklist are never auto-looted."
    .. " Everything else is evaluated against the minimum quality threshold."] = true
L["Blacklist"] = true
L["Enable Smart Auto-Loot"] = true
-- stylua: ignore
L["Items on this list are always looted automatically, regardless of quality."
    .. " Drag an item from your bags onto an empty slot to add it."] = true
-- stylua: ignore
L["Items on this list are never auto-looted, even if they meet the quality threshold."
    .. " They will remain in the loot window for manual pickup."] = true
L["No items - drag items here to add"] = true
L["Smart Auto-Loot"] = true
L["When enabled, qualifying items are automatically looted based on your filter rules"] = true
L["Whitelist"] = true

-- DragonLoot_Options/Tabs/AppearanceTab.lua
L["Appearance"] = true
L["Background"] = true
L["Background Color"] = true
L["Background Opacity"] = true
L["Background Texture"] = true
L["Base font size for all DragonLoot frames"] = true
L["Border"] = true
L["Border Color"] = true
L["Border Size"] = true
L["Border Texture"] = true
L["Flat"] = true
L["Font"] = true
L["Font Family"] = true
L["Font Outline"] = true
L["Font Size"] = true
L["Gradient"] = true
L["History Icon Size"] = true
L["Icon Sizes"] = true
L["Icon size in the history frame"] = true
L["Icon size in the loot window"] = true
L["Icon size in the roll frame"] = true
L["Loot Icon Size"] = true
L["Monochrome"] = true
L["None"] = true
L["Opacity of the frame background"] = true
L["Outline"] = true
L["Quality Border"] = true
L["Roll Icon Size"] = true
L["Show quality-colored borders on item icons"] = true
L["Slot Background"] = true
L["Stripe"] = true
L["Thick Outline"] = true
L["Thickness of the frame border"] = true
L["Text Shadow"] = true
L["Enable text shadow on all text elements"] = true

-- DragonLoot_Options/Tabs/AnimationTab.lua
L["Global Settings"] = true
L["Animation"] = true
L["Close Animation"] = true
L["Close Duration"] = true
L["Duration of close/hide animations in seconds"] = true
L["Duration of open/show animations in seconds"] = true
L["Enable Animations"] = true
L["Enable or disable all DragonLoot animations"] = true
L["Hide Animation"] = true
L["Loot Window"] = true
L["Open Animation"] = true
L["Open Duration"] = true
L["Show Animation"] = true

-- DragonLoot_Options/Tabs/ProfilesTab.lua
L["Active Profile"] = true
L['Are you sure you want to delete profile "%s"?'] = true
L["Are you sure you want to reset the current profile to defaults?"] = true
L["Copy From"] = true
L["Create"] = true
L["Create a new profile with the entered name and switch to it"] = true
L["Current Profile"] = true
L["Delete Profile"] = true
L["New Profile"] = true
L["Profile Actions"] = true
L["Profiles"] = true
-- stylua: ignore
L["Profiles allow you to save different settings configurations."
    .. " You can switch between profiles, copy settings from another profile,"
    .. " or reset to defaults."] = true
L["Reset Current Profile"] = true
L["Reset all settings in the current profile to their default values"] = true
