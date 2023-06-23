local addonName, nameSpace = ...
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "WowheadQuickLink" then
        if WowheadQuickLinkCfg == nil then
            WowheadQuickLinkCfg = {
                prefix = "",
                suffix = ""
            }
        end
    elseif event == "PLAYER_LOGIN" then
        -- check if binding setup has run before
        if WowheadQuickLinkCfg.default_bindings_set == nil then
            -- hasn't run before, so run it

            -- first value is the name attribute of each from Bindings.xml
            HandleDefaultBindings("WOWHEAD_QUICK_LINK_NAME", "CTRL-C")
            HandleDefaultBindings("WOWHEAD_QUICK_LINK_RAIDERIO_NAME", "CTRL-SHIFT-C")

            SaveBindings(GetCurrentBindingSet())

            -- prevent setup from running again
            WowheadQuickLinkCfg.default_bindings_set = true
        end

        frame:UnregisterEvent("PLAYER_LOGIN")
    end
end)

function HandleDefaultBindings(binding_name, default_key)
    -- get existing binding info
    local bind1, bind2 = GetBindingKey(binding_name)
    local action = GetBindingAction(default_key)

    -- check if binds have been set by the user or the default key is used anywhere else
    if bind1 == nil and bind2 == nil and action == "" then
        -- neither bind has been set by the user and the default key isn't in use, so set the default key
        SetBinding(default_key, binding_name)
    end
end


function IsRetail()
    return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
end


function IsClassic()
    return WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
end


function IsWrath()
    return WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
end


local function Hide()
    WowheadQuickLinkConfig_Frame:Hide()
end

local function SetUrl()
    WowheadQuickLinkConfig_FinalUrlText:SetText(string.format(nameSpace.baseWowheadUrl, WowheadQuickLinkCfg.prefix, "<type>", "<id>", WowheadQuickLinkCfg.suffix))
end


SLASH_WOWHEAD_QUICK_LINK1 = "/wql"
SLASH_WOWHEAD_QUICK_LINK2 = "/wowheadquicklink"
SlashCmdList["WOWHEAD_QUICK_LINK"] = function(message, editBox)
    WowheadQuickLinkConfig_EditBoxPrefix:SetText(WowheadQuickLinkCfg.prefix)
    WowheadQuickLinkConfig_EditBoxSuffix:SetText(WowheadQuickLinkCfg.suffix)
    SetUrl()
    WowheadQuickLinkConfig_Frame:Show()
end


WowheadQuickLinkConfig_EditBoxPrefix:SetScript("OnEscapePressed", Hide)
WowheadQuickLinkConfig_EditBoxPrefix:SetScript("OnEnterPressed", Hide)

WowheadQuickLinkConfig_EditBoxSuffix:SetScript("OnEscapePressed", Hide)
WowheadQuickLinkConfig_EditBoxSuffix:SetScript("OnEnterPressed", Hide)


WowheadQuickLinkConfig_EditBoxPrefix:SetScript("OnTextChanged", function(self)
    WowheadQuickLinkCfg.prefix = self:GetText()
    SetUrl()
end)

WowheadQuickLinkConfig_EditBoxSuffix:SetScript("OnTextChanged", function(self)
    WowheadQuickLinkCfg.suffix = self:GetText()
    SetUrl()
end)

WowheadQuickLinkConfig_EditBoxPrefix:SetScript("OnTabPressed", function(self)
    WowheadQuickLinkConfig_EditBoxSuffix:SetFocus()
end)

WowheadQuickLinkConfig_EditBoxSuffix:SetScript("OnTabPressed", function(self)
    WowheadQuickLinkConfig_EditBoxPrefix:SetFocus()
end)


BINDING_HEADER_WOWHEAD_QUICK_LINK_HEADER = "Wowhead Quick Link"
BINDING_DESCRIPTION_WOWHEAD_QUICK_LINK_DESC = "Keybind for generating Wowhead link"
BINDING_NAME_WOWHEAD_QUICK_LINK_NAME = "Generate Wowhead link"

BINDING_NAME_WOWHEAD_QUICK_LINK_RAIDERIO_NAME = "Generate Raider.IO link"
