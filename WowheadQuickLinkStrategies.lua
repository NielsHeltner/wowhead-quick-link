local addonName, nameSpace = ...
nameSpace.strategies = {}
local wowheadStrategies = {}
local wowheadAzEsStrategies = {}
local armoryStrategies = {}
local tooltipState = {}


function nameSpace.strategies.GetWowheadUrl(dataSources)
    for _, strategy in pairs(wowheadStrategies) do
        local id, type = strategy(dataSources)
        if id and type then
            return "Wowhead " .. type:sub(1, 1):upper() .. type:sub(2), 
                string.format(nameSpace.baseWowheadUrl, WowheadQuickLinkCfg.prefix, type, id, WowheadQuickLinkCfg.suffix)
        end
    end
end


function nameSpace.strategies.GetWowheadAzEsUrl(dataSources)
    for _, strategy in pairs(wowheadAzEsStrategies) do
        local id = strategy(dataSources)
        if id then
            return "Wowhead Azerite Essence", 
                string.format(nameSpace.baseWowheadAzEsUrl, WowheadQuickLinkCfg.prefix, id, WowheadQuickLinkCfg.suffix)
        end
    end
end


function nameSpace.strategies.GetArmoryUrl(dataSources)
    for _, strategy in pairs(armoryStrategies) do
        local locale, realm, name = strategy(dataSources)
        if locale and realm and name then
            return "Armory", string.format(nameSpace.baseArmoryUrl, locale, realm, name)
        end
    end
end


local function GetFromNameAndRealm(name, realm)
    realm = realm or GetRealmName()
    realm = realm:gsub("'", "")
    realm = realm:gsub(" ", "-")
    local index = realm:find(".%u")
    if index then
        realm = realm:sub(1, index) .. "-" .. realm:sub(index + 1)
    end
    local region = GetCurrentRegion()
    local locale = GetLocale()
    local isEu = region == 3
    if isEu and locale == "enUS" then
        locale = "enGB"
    end
    locale = locale:sub(1, 2) .. "-" .. locale:sub(3)
    return locale, realm, name
end


function armoryStrategies.GetArmoryFromTooltip(data)
    if not data.tooltip then return end
    local name, unit = data.tooltip:GetUnit()
    if not (unit and UnitIsPlayer(unit)) then return end
    return GetFromNameAndRealm(UnitFullName(unit))
end


function armoryStrategies.GetArmoryFromLfgLeader(data)
    if not data.focus.resultID then return end
    leader = C_LFGList.GetSearchResultInfo(data.focus.resultID).leaderName
    return GetFromNameAndRealm(strsplit("-", leader))
end


local function GetFromLink(link)
    if not link then return end
    local _, _, type, id = link:find("%|?H?(%a+):(%d+):")
    if type == "azessence" then type = nil end
    return id, type
end


function wowheadStrategies.GetHyperlinkFromTooltip()
    for _, tooltip in pairs(tooltipState) do
        if tooltip.hyperlink then
            return GetFromLink(tooltip.hyperlink)
        end
    end
end


function wowheadStrategies.GetAuraFromTooltip()
    for _, tooltip in pairs(tooltipState) do
        if tooltip.aura then
            return tooltip.aura, "spell"
        end
    end
end


function wowheadStrategies.GetItemFromTooltip(data)
    if not data.tooltip then return end
    local _, link = data.tooltip:GetItem()
    return GetFromLink(link)
end


function wowheadStrategies.GetSpellFromTooltip(data)
    if not data.tooltip then return end
    return select(2, data.tooltip:GetSpell()), "spell"
end


function wowheadStrategies.GetAchievementFromFocus(data)
    if not data.focus.id or not data.focus.dateCompleted then return end
    return data.focus.id, "achievement"
end


function wowheadStrategies.GetQuestFromFocus(data)
    if not data.focus.questID then return end
    return data.focus.questID, "quest"
end


function wowheadStrategies.GetTrackerFromFocus(data)
    if (data.focus.id and not data.focus.module) or not data.focus:GetParent() then return end
    local parent = data.focus:GetParent()
    local id = data.focus.id or parent.id
    if parent.module == ACHIEVEMENT_TRACKER_MODULE then
        return id, "achievement"
    end
    return id, "quest"
end


function wowheadStrategies.GetNpcFromTooltip(data)
    if not data.tooltip then return end
    local _, unit = data.tooltip:GetUnit()
    if not unit then return end
    return select(6, strsplit("-", UnitGUID(unit))), "npc"
end


function wowheadStrategies.GetMountFromFocus(data)
    if not data.focus.spellID then return end
    return data.focus.spellID, "spell"
end


function wowheadStrategies.GetLearntMountFromFocus(data)
    if not data.focus.mountID then return end
    return select(2, C_MountJournal.GetMountInfoByID(data.focus.mountID)), "spell"
end


function wowheadStrategies.GetCompanionFromFocus(data)
    if not data.focus.petID and (not data.focus:GetParent() or not data.focus:GetParent().petID) then return end
    local petId = data.focus.petID or data.focus:GetParent().petID
    local id
    if type(petId) == "string" then
        id = select(11, C_PetJournal.GetPetInfoByPetID(petId))
    else
        id = select(4, C_PetJournal.GetPetInfoBySpeciesID(petId))
    end
    return id, "npc"
end


function wowheadStrategies.GetCompanionFromFloatingTooltip(data)
    if not data.focus.speciesID then return end
    return select(4, C_PetJournal.GetPetInfoBySpeciesID(data.focus.speciesID)), "npc"
end


function wowheadStrategies.GetItemFromAuctionHouse(data)
    if not data.focus.itemIndex and (not data.focus:GetParent() or not data.focus:GetParent().itemIndex) then return end
    local index = data.focus.itemIndex or data.focus:GetParent().itemIndex
    local link = GetAuctionItemLink("list", index)
    local id, type = GetFromLink(link)
    if type == "battlepet" then
        id = select(4, C_PetJournal.GetPetInfoBySpeciesID(id))
        type = "npc"
    end
    return id, type
end


function wowheadStrategies.GetFactionFromFocus(data)
    if not data.focus.index or not data.focus.standingText then return end
    return select(14, GetFactionInfo(data.focus.index)), "faction"
end


function wowheadStrategies.GetCurrencyInTabFromFocus(data)
    if data.focus.isUnused == nil and (not data.focus:GetParent() or data.focus:GetParent().isUnused == nil) then return end
    local index = data.focus.index or data.focus:GetParent().index
    local link = GetCurrencyListLink(index)
    return GetFromLink(link)
end


function wowheadStrategies.GetCurrencyInVendorFromFocus(data)
    if not data.focus.itemLink then return end
    return GetFromLink(data.focus.itemLink)
end


function wowheadStrategies.GetCurrencyInVendorBottomFromFocus(data)
    if not data.focus.currencyID then return end
    return data.focus.currencyID, "currency"
end


function wowheadAzEsStrategies.GetAzEsFromNeckList(data)
    if not data.focus.essenceID then return end
    return data.focus.essenceID
end


function wowheadAzEsStrategies.GetAzEsFromNeckSlot(data)
    if not data.focus.milestoneID then return end
    return C_AzeriteEssence.GetMilestoneEssence(data.focus.milestoneID)
end


function wowheadAzEsStrategies.GetAzEsHyperlinkFromTooltip()
    for _, tooltip in pairs(tooltipState) do
        if tooltip.hyperlink then
            return select(1, GetFromLink(tooltip.hyperlink))
        end
    end
end


local function HookTooltip(tooltip)
    tooltipState[tooltip] = {}
    hooksecurefunc(tooltip, "SetHyperlink", function(tooltip, hyperlink)
            tooltipState[tooltip].hyperlink = hyperlink
    end)
    hooksecurefunc(tooltip, "SetUnitAura", function(tooltip, unit, index, filter)
            tooltipState[tooltip].aura = select(10, UnitAura(unit, index, filter))
    end)
    tooltip:HookScript("OnTooltipCleared", function(tooltip)
            tooltipState[tooltip] = {}
    end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        HookTooltip(GameTooltip)
        HookTooltip(ItemRefTooltip)
    end
end)
