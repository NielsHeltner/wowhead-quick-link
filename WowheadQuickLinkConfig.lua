local addonName, nameSpace = ...
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "WowheadQuickLink" then
        if WowheadQuickLinkCfg == nil then
            WowheadQuickLinkCfg = {
                prefix = "", 
                suffix = ""
            }
        end
    end
end)


function IsClassic()
    return select(1, GetBuildInfo()):sub(1, 1) < "2"
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
