local baseUrl = "https://www.wowhead.com/"
local keybind = "CTRL-C"
local popupText = "Wowhead %s Link\n" .. keybind .. " to copy"
local tooltipState = {}


local function GetFromLink(link)
    if not link then return end
    local _, _, type, id = link:find("%|?H?(%a+):(%d+):")
    return id, type
end


local function GetHyperlinkFromTooltip()
    if not tooltipState.hyperlink then return end
    return GetFromLink(tooltipState.hyperlink)
end


local function GetAuraFromTooltip()
    if not tooltipState.aura then return end
    return tooltipState.aura, "spell"
end


local function GetItemFromTooltip(data)
    if not data.tooltip then return end
    local _, link = data.tooltip:GetItem()
    return GetFromLink(link)
end


local function GetSpellFromTooltip(data)
    if not data.tooltip then return end
    return select(2, data.tooltip:GetSpell()), "spell"
end


local function GetAchievementFromFocus(data)
    if not data.focus.id or not data.focus.dateCompleted then return end
    return data.focus.id, "achievement"
end


local function GetQuestFromFocus(data)
    if not data.focus.questID then return end
    return data.focus.questID, "quest"
end


local function GetTrackerFromFocus(data)
    if not data.focus:GetParent() then return end
    local parent = data.focus:GetParent()
    local id = data.focus.id or parent.id
    if parent.module == ACHIEVEMENT_TRACKER_MODULE then
        return id, "achievement"
    end
    return id, "quest"
end


local function GetNpcFromTooltip(data)
    if not data.tooltip then return end
    local _, unit = data.tooltip:GetUnit()
    if not unit then return end
    return select(6, strsplit("-", UnitGUID(unit))), "npc"
end


local function GetMountFromFocus(data)
    if not data.focus.spellID then return end
    return data.focus.spellID, "spell"
end


local function GetCompanionFromFocus(data)
    if not data.focus.petID and (not data.focus:GetParent() or not data.focus:GetParent().petID) then return end
    local petId = data.focus.petID or data.focus:GetParent().petID
    return select(11, C_PetJournal.GetPetInfoByPetID(petId)), "npc"
end


local function GetFactionFromFocus(data)
    if not data.focus.index or not data.focus.standingText then return end
    return select(14, GetFactionInfo(data.focus.index)), "faction"
end


local function GetCurrencyFromFocus(data)
    if not data.focus.index and (not data.focus:GetParent() or not data.focus:GetParent().index) then return end
    local index = data.focus.index or data.focus:GetParent().index
    local link = GetCurrencyListLink(index)
    return GetFromLink(link)
end


local idTypeStrategies = {
    GetHyperlinkFromTooltip, 
    GetAuraFromTooltip, 
    GetItemFromTooltip, 
    GetSpellFromTooltip, 
    GetAchievementFromFocus, 
    GetQuestFromFocus, 
    GetTrackerFromFocus, 
    GetNpcFromTooltip, 
    GetMountFromFocus, 
    GetCompanionFromFocus, 
    GetFactionFromFocus, 
    GetCurrencyFromFocus
}


local function getIdAndType(data)
    for _, strategy in ipairs(idTypeStrategies) do
        local id, type = strategy(data)
        if id and type then
            return id, type
        end
    end
end


local function ShowUrlPopup(id, type)
    if not (id or type) then return end
    local url = baseUrl .. type .. "=" .. id
    StaticPopup_Show("WowheadQuestLinkUrl", type:sub(1, 1):upper() .. type:sub(2), _, url)
end


function run()
    local focus = GetMouseFocus()
    local tooltip = GameTooltip
    local data = {focus = focus, tooltip = tooltip}
    
    local id, type = getIdAndType(data)
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


local function hookTooltip(tooltip)
    hooksecurefunc(tooltip, "SetHyperlink", function(_, hyperlink)
            tooltipState.hyperlink = hyperlink
    end)
    hooksecurefunc(tooltip, "SetUnitAura", function(_, unit, index, filter)
            tooltipState.aura = select(10, UnitAura(unit, index, filter))
    end)
    tooltip:HookScript("OnTooltipCleared", function(_)
            tooltipState = {}
    end)
end

hookTooltip(GameTooltip)
hookTooltip(ItemRefTooltip)


BINDING_HEADER_WOWHEAD_QUICK_LINK_HEADER = "Wowhead Quick Link"
BINDING_DESCRIPTION_WOWHEAD_QUICK_LINK_DESC = "Keybind for generating Wowhead link"
BINDING_NAME_WOWHEAD_QUICK_LINK_NAME = "Generate Wowhead link"
