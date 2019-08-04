local addonName, nameSpace = ...
local baseWowheadUrl = "https://%swowhead.com/%s=%s%s"
local baseArmoryUrl = "https://worldofwarcraft.com/%s/character/%s/%s"
local popupText = "%s Link\nCTRL-C to copy"
local popupStrategies = {}


function GetWowheadUrl(id, type)
    if not (id or type) then return end
    return string.format(baseWowheadUrl, WowheadQuickLinkCfg.prefix, type, id, WowheadQuickLinkCfg.suffix)
end


function GetArmoryUrl(locale, realm, name)
    if not (locale or realm or name) then return end
    return string.format(baseArmoryUrl, locale, realm, name)
end


function popupStrategies.ShowWowheadUrlPopup(data)
    if not (data.id or data.type) then return end
    StaticPopup_Show("WowheadQuestLinkUrl", "Wowhead " .. data.type:sub(1, 1):upper() .. data.type:sub(2), _, GetWowheadUrl(data.id, data.type))
end


function popupStrategies.ShowArmoryUrlPopup(data)
    if not (data.locale or data.realm or data.name) then return end
    StaticPopup_Show("WowheadQuestLinkUrl", "Armory", _, GetArmoryUrl(data.locale, data.realm, data.name))
end


local function GetDataFromDataSources(dataSources)
    for _, strategy in pairs(nameSpace.strategies) do
        local data = strategy(dataSources)
        if data then
            return data
        end
    end
end


function RunWowheadQuickLink()
    local focus = GetMouseFocus()
    local tooltip = GameTooltip
    local dataSources = {focus = focus, tooltip = tooltip}

    local data = GetDataFromDataSources(dataSources)
    if data then
        for _, strategy in pairs(popupStrategies) do
            strategy(data)
        end
    end
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
