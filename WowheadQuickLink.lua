local addonName, nameSpace = ...
nameSpace.baseWowheadUrl = "https://%swowhead.com/%s=%s%s"
nameSpace.baseWowheadAzEsUrl = "https://%swowhead.com/azerite-essence/%s%s"
nameSpace.baseArmoryUrl = "https://worldofwarcraft.com/%s/character/%s/%s"

local popupText = "%s Link\nCTRL-C to copy"
local popupStrategies = {}


local function ShowUrlPopup(header, url)
    StaticPopup_Show("WowheadQuickLinkUrl", header, _, url)
end


local function CreateUrl(dataSources)
    for _, strategy in pairs(nameSpace.strategies) do
        local header, url = strategy(dataSources)
        if header and url then
            ShowUrlPopup(header, url)
            return
        end
    end
end


function RunWowheadQuickLink()
    local focus = GetMouseFocus()
    local tooltip = GameTooltip
    local dataSources = {focus = focus, tooltip = tooltip}

    CreateUrl(dataSources)
end


StaticPopupDialogs["WowheadQuickLinkUrl"] = {
    text = popupText,
    button1 = "Close", 
    OnShow = function(self, data)
        local function HidePopup(self) self:GetParent():Hide() end
        self.editBox:SetScript("OnEscapePressed", HidePopup)
        self.editBox:SetScript("OnEnterPressed", HidePopup)
        self.editBox:SetMaxLetters(0)
        self.editBox:SetText(data)
        self.editBox:HighlightText(0, self.editBox:GetNumLetters())
    end, 
    hasEditBox = true, 
    editBoxWidth = 233, 
    timeout = 0, 
    whileDead = true, 
    hideOnEscape = true, 
    preferredIndex = 3, 
}
