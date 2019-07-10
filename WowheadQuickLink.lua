local addonName, nameSpace = ...
wowheadQuickLinkBaseUrl = "https://%swowhead.com/%s=%s%s"
local popupText = "Wowhead %s Link\nCTRL-C to copy"


function GetWowheadQuickLinkUrl(id, type)
    if not (id or type) then return end
    return string.format(wowheadQuickLinkBaseUrl, WowheadQuickLinkCfg.prefix, type, id, WowheadQuickLinkCfg.suffix)
end


local function ShowUrlPopup(id, type)
    if not (id or type) then return end
    StaticPopup_Show("WowheadQuestLinkUrl", type:sub(1, 1):upper() .. type:sub(2), _, GetWowheadQuickLinkUrl(id, type))
end


local function GetIdAndType(data)
    for _, strategy in pairs(nameSpace.strategies) do
        local id, type = strategy(data)
        if id and type then
            return id, type
        end
    end
end


function runWowheadQuickLink()
    local focus = GetMouseFocus()
    local tooltip = GameTooltip
    local data = {focus = focus, tooltip = tooltip}
    
    local id, type = GetIdAndType(data)
    ShowUrlPopup(id, type)
end


StaticPopupDialogs["WowheadQuestLinkUrl"] = {
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
