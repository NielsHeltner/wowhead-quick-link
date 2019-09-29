local addonName, nameSpace = ...
nameSpace.strategies = {}
nameSpace.altStrategies = {}
local strategies = {
    wowhead = {}, 
    wowheadAzEs = {}, 
    armory = {}
}
local tooltipStates = {}
local regions = {
    [1] = "us", 
    [2] = "kr", 
    [3] = "eu", 
    [4] = "tw", 
    [5] = "cn"
}


function nameSpace.strategies.GetWowheadUrl(dataSources)
    for _, strategy in pairs(strategies.wowhead) do
        local id, type = strategy(dataSources)
        if id and type then
            return "Wowhead " .. type:sub(1, 1):upper() .. type:sub(2), 
                string.format(nameSpace.baseWowheadUrl, WowheadQuickLinkCfg.prefix, type, id, WowheadQuickLinkCfg.suffix)
        end
    end
end


function nameSpace.strategies.GetWowheadAzEsUrl(dataSources)
    for _, strategy in pairs(strategies.wowheadAzEs) do
        local id = strategy(dataSources)
        if id then
            return "Wowhead Azerite Essence", 
                string.format(nameSpace.baseWowheadAzEsUrl, WowheadQuickLinkCfg.prefix, id, WowheadQuickLinkCfg.suffix)
        end
    end
end


function nameSpace.strategies.GetArmoryUrl(dataSources)
    for _, strategy in pairs(strategies.armory) do
        local _, locale, realm, name = strategy(dataSources)
        if locale and realm and name then
            return "Armory", string.format(nameSpace.baseArmoryUrl, locale, realm, name)
        end
    end
end


function nameSpace.altStrategies.GetRaiderIoUrl(dataSources)
    for _, strategy in pairs(strategies.armory) do
        local region, _, realm, name = strategy(dataSources)
        if region and realm and name then
            return "Raider.IO", string.format(nameSpace.baseRaiderIoUrl, region, realm, name)
        end
    end
end


local function GetFromNameAndRealm(name, realm)
    if not realm or realm == '' then
        realm = GetRealmName()
    end
    if realm:find("'") then
        realm = realm:gsub("'", ""):lower()
    end
    realm = realm:gsub(" ", "-")
    local index = realm:find("%a%u")
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
    return regions[region], locale, realm, name
end


function strategies.armory.GetArmoryFromTooltip(data)
    if not data.tooltip then return end
    local name, unit = data.tooltip:GetUnit()
    if not (unit and UnitIsPlayer(unit)) then return end
    return GetFromNameAndRealm(UnitFullName(unit))
end


function strategies.armory.GetArmoryFromLfgLeader(data)
    if not data.focus.resultID then return end
    leader = C_LFGList.GetSearchResultInfo(data.focus.resultID).leaderName
    return GetFromNameAndRealm(strsplit("-", leader))
end


local function GetFromLink(link)
    if not link then return end
    local _, _, type, id = link:find("%|?H?(%a+):(%d+):")
    if type == "azessence" then return id end
    return id, type
end


function strategies.wowhead.GetHyperlinkFromTooltip()
    for _, tooltip in pairs(tooltipStates) do
        if tooltip.hyperlink then
            return GetFromLink(tooltip.hyperlink)
        end
    end
end


function strategies.wowhead.GetAuraFromTooltip()
    for _, tooltip in pairs(tooltipStates) do
        if tooltip.aura then
            return tooltip.aura, "spell"
        end
    end
end


function strategies.wowhead.GetItemFromTooltip(data)
    if not data.tooltip then return end
    local _, link = data.tooltip:GetItem()
    return GetFromLink(link)
end


function strategies.wowhead.GetSpellFromTooltip(data)
    if not data.tooltip then return end
    return select(2, data.tooltip:GetSpell()), "spell"
end


function strategies.wowhead.GetAchievementFromFocus(data)
    if not data.focus.id or not data.focus.dateCompleted then return end
    return data.focus.id, "achievement"
end


function strategies.wowhead.GetQuestFromFocus(data)
    if not data.focus.questID then return end
    return data.focus.questID, "quest"
end


function strategies.wowhead.GetQuestFromClassicLogFocus(data)
    if not (IsClassic() and data.focus:GetID()) then return end
    local questIndex = data.focus:GetID() + FauxScrollFrame_GetOffset(QuestLogListScrollFrame)
    local questID = GetQuestIDFromLogIndex(questIndex)
    if questID == 0 then return end
    return questID, "quest"
end


function strategies.wowhead.GetTrackerFromFocus(data)
    if (data.focus.id and not data.focus.module) or not data.focus:GetParent() then return end
    local parent = data.focus:GetParent()
    local id = data.focus.id or parent.id
    if parent.module == ACHIEVEMENT_TRACKER_MODULE then
        return id, "achievement"
    end
    return id, "quest"
end


function strategies.wowhead.GetNpcFromTooltip(data)
    if not data.tooltip then return end
    local _, unit = data.tooltip:GetUnit()
    if not unit then return end
    return select(6, strsplit("-", UnitGUID(unit))), "npc"
end


function strategies.wowhead.GetMountFromFocus(data)
    if not data.focus.spellID then return end
    return data.focus.spellID, "spell"
end


function strategies.wowhead.GetLearntMountFromFocus(data)
    if not data.focus.mountID then return end
    return select(2, C_MountJournal.GetMountInfoByID(data.focus.mountID)), "spell"
end


function strategies.wowhead.GetCompanionFromFocus(data)
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


function strategies.wowhead.GetCompanionFromFloatingTooltip(data)
    if not data.focus.speciesID then return end
    return select(4, C_PetJournal.GetPetInfoBySpeciesID(data.focus.speciesID)), "npc"
end


function strategies.wowhead.GetItemFromAuctionHouse(data)
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


function strategies.wowhead.GetRecipeFromFocus(data)
    if not data.focus.tradeSkillInfo then return end
    return data.focus.tradeSkillInfo.recipeID, "spell"
end


function strategies.wowhead.GetFactionFromFocus(data)
    if not data.focus.index or not data.focus.standingText then return end
    return select(14, GetFactionInfo(data.focus.index)), "faction"
end


function strategies.wowhead.GetCurrencyInTabFromFocus(data)
    if data.focus.isUnused == nil and (not data.focus:GetParent() or data.focus:GetParent().isUnused == nil) then return end
    local index = data.focus.index or data.focus:GetParent().index
    local link = GetCurrencyListLink(index)
    return GetFromLink(link)
end


function strategies.wowhead.GetCurrencyInVendorFromFocus(data)
    if not data.focus.itemLink then return end
    return GetFromLink(data.focus.itemLink)
end


function strategies.wowhead.GetCurrencyInVendorBottomFromFocus(data)
    if not data.focus.currencyID then return end
    return data.focus.currencyID, "currency"
end


function strategies.wowheadAzEs.GetAzEsFromNeckList(data)
    if not data.focus.essenceID then return end
    return data.focus.essenceID
end


function strategies.wowheadAzEs.GetAzEsFromNeckSlot(data)
    if not data.focus.milestoneID then return end
    return C_AzeriteEssence.GetMilestoneEssence(data.focus.milestoneID)
end


function strategies.wowheadAzEs.GetAzEsHyperlinkFromTooltip()
    for _, tooltip in pairs(tooltipStates) do
        if tooltip.hyperlink then
            local id, type = GetFromLink(tooltip.hyperlink)
            if id and not type then
                return id
            end
        end
    end
end


local function HookTooltip(tooltip)
    tooltipStates[tooltip] = {}
    hooksecurefunc(tooltip, "SetHyperlink", function(tooltip, hyperlink)
            tooltipStates[tooltip].hyperlink = hyperlink
    end)
    if not IsClassic() then
        hooksecurefunc(tooltip, "SetRecipeReagentItem", function(tooltip, recipeId, reagentIndex)
                tooltipStates[tooltip].hyperlink = C_TradeSkillUI.GetRecipeReagentItemLink(recipeId, reagentIndex)
        end)
    end
    hooksecurefunc(tooltip, "SetUnitAura", function(tooltip, unit, index, filter)
            tooltipStates[tooltip].aura = select(10, UnitAura(unit, index, filter))
    end)
    tooltip:HookScript("OnTooltipCleared", function(tooltip)
            tooltipStates[tooltip] = {}
    end)
end

local eventHookFrame = CreateFrame("Frame")
eventHookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventHookFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        HookTooltip(GameTooltip)
        HookTooltip(ItemRefTooltip)
    end
end)
