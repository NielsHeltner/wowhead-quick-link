local addonName, nameSpace = ...
if IsRetail() then
    nameSpace.baseWowheadUrl = "https://%swowhead.com/%s=%s%s"
end
if IsClassic() then
    nameSpace.baseWowheadUrl = "https://%swowhead.com/classic/%s=%s%s"
end
if IsMop() then
    nameSpace.baseWowheadUrl = "https://%swowhead.com/mop-classic/%s=%s%s"
end

nameSpace.baseWowheadAzEsUrl = "https://%swowhead.com/azerite-essence/%s%s"
nameSpace.baseWowheadTradingPostActivityUrl = "https://%swowhead.com/trading-post-activity/%s%s"
nameSpace.baseArmoryUrl = "https://worldofwarcraft.com/%s/character/%s/%s"
nameSpace.baseRaiderIoUrl = "https://raider.io/characters/%s/%s/%s"

local popupText = "%s Link\nCTRL-C to copy"


local function ShowUrlPopup(header, url)
    StaticPopup_Show("WowheadQuickLinkUrl", header, _, url)
end


local function CreateUrl(dataSources, strategies)
    for _, strategy in pairs(strategies) do
        local header, url = strategy(dataSources)
        if header and url then
            ShowUrlPopup(header, url)
            return
        end
    end
end

local function GetDataSources()
    local focus = {}
    local foci = GetMouseFoci()
    if foci[1] then
        focus = foci[1]
    end
    local tooltip = GameTooltip
    return {focus = focus, tooltip = tooltip}
end


function RunWowheadQuickLink()
    CreateUrl(GetDataSources(), nameSpace.strategies)
end


function RunAlternativeQuickLink()
    CreateUrl(GetDataSources(), nameSpace.altStrategies)
end


StaticPopupDialogs["WowheadQuickLinkUrl"] = {
    text = popupText,
    button1 = "Close",
    OnShow = function(self, data)
        local function HidePopup(self) self:GetParent():Hide() end
        local editBox
        if IsRetail() then
            editBox = self.EditBox
        else
            editBox = self.editBox
        end
        editBox:SetScript("OnEscapePressed", HidePopup)
        editBox:SetScript("OnEnterPressed", HidePopup)
        editBox:SetScript("OnKeyUp", function(self, key)
            if IsControlKeyDown() and key == "C" then HidePopup(self) end
        end)
        editBox:SetMaxLetters(0)
        editBox:SetText(data)
        editBox:HighlightText()
    end,
    hasEditBox = true,
    editBoxWidth = 240,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
