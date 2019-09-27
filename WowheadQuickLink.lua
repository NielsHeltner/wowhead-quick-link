local addonName, nameSpace = ...
nameSpace.baseWowheadUrl = "https://%swowhead.com/%s=%s%s"
if IsClassic() then
    nameSpace.baseWowheadUrl = "https://%sclassic.wowhead.com/%s=%s%s"
end
nameSpace.baseWowheadAzEsUrl = "https://%swowhead.com/azerite-essence/%s%s"
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
    local focus = GetMouseFocus()
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
        self.editBox:SetScript("OnEscapePressed", HidePopup)
        self.editBox:SetScript("OnEnterPressed", HidePopup)
        self.editBox:SetScript("OnKeyDown", function(self, key)
            if IsControlKeyDown() and key == "C" then HidePopup(self) end
        end)
        self.editBox:SetMaxLetters(0)
        self.editBox:SetText(data)
        self.editBox:HighlightText()
    end, 
    hasEditBox = true, 
    editBoxWidth = 240, 
    timeout = 0, 
    whileDead = true, 
    hideOnEscape = true, 
    preferredIndex = 3, 
}
