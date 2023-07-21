local addonName, nameSpace = ...
nameSpace.strategies = {}
nameSpace.altStrategies = {}
local strategies = {
    wowhead = {},
    wowheadAzEs = {},
    wowheadTradingPostActivity = {},
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
            local typeStr
            if type == "npc" then
                typeStr = type:upper()
            else
                typeStr = type:sub(1, 1):upper() .. type:sub(2)
            end
            return "Wowhead " .. typeStr,
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

function nameSpace.strategies.GetWowheadTradingPostActivityUrl(dataSources)
    for _, strategy in pairs(strategies.wowheadTradingPostActivity) do
        local id = strategy(dataSources)
        if id then
            return "Wowhead Trading Post Activity",
                string.format(nameSpace.baseWowheadTradingPostActivityUrl, WowheadQuickLinkCfg.prefix, id, WowheadQuickLinkCfg.suffix)
        end
    end
end

function nameSpace.strategies.GetArmoryUrl(dataSources)
    if IsRetail() then
        for _, strategy in pairs(strategies.armory) do
            local _, locale, realm, name = strategy(dataSources)
            if locale and realm and name then
                return "Armory", string.format(nameSpace.baseArmoryUrl, locale, realm, name)
            end
        end
    end
end


function nameSpace.altStrategies.GetRaiderIoUrl(dataSources)
    if IsRetail() then
        for _, strategy in pairs(strategies.armory) do
            local region, _, realm, name = strategy(dataSources)
            if region and realm and name then
                return "Raider.IO", string.format(nameSpace.baseRaiderIoUrl, region, realm, name)
            end
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
    local leader = C_LFGList.GetSearchResultInfo(data.focus.resultID).leaderName
    return GetFromNameAndRealm(strsplit("-", leader))
end


function strategies.armory.GetArmoryFromLfgApplicant(data)
    if not data.focus.memberIdx or not data.focus:GetParent() or not data.focus:GetParent().applicantID then return end
    local applicant = select(1, C_LFGList.GetApplicantMemberInfo(data.focus:GetParent().applicantID, data.focus.memberIdx))
    return GetFromNameAndRealm(strsplit("-", applicant))
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


-- data type ID comes from the TooltipDataType enum in blizzard's lua:
-- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoSharedDocumentation.lua
function strategies.wowhead.GetMountOrToyFromTooltip(data)
    if not IsRetail() or not data.tooltip then return end
    tooltipData = data.tooltip:GetTooltipData()
    if not tooltipData then return end

    if tooltipData.type == Enum.TooltipDataType.Mount and tooltipData.id then
        return select(2, C_MountJournal.GetMountInfoByID(tooltipData.id)), "spell"
    end

    if tooltipData.type == Enum.TooltipDataType.Toy and tooltipData.id then
        return tooltipData.id, "item"
    end
end


-- gets achievement link from the main achievements window
function strategies.wowhead.GetAchievementFromFocus(data)
    -- retail uses DateCompleted, classic uses dateCompleted
    if not data.focus.id or not (data.focus.DateCompleted or data.focus.dateCompleted) then return end
    return data.focus.id, "achievement"
end


-- gets achievement link when using Krowi's Achievement Filter
function strategies.wowhead.GetKrowisAchievementFromFocus(data)
    if not data.focus.Achievement or not data.focus.Achievement.Id then return end
    return data.focus.Achievement.Id, "achievement"
end


function strategies.wowhead.GetQuestFromFocus(data)
    if not data.focus.questID then return end
    return data.focus.questID, "quest"
end


function strategies.wowhead.GetQuestFromClassicLogFocus(data)
    if not ((IsClassic() or IsWrath()) and data.focus.normalText and data.focus:GetID()) then return end
    local questIndex = data.focus:GetID() + FauxScrollFrame_GetOffset(QuestLogListScrollFrame)
    local questID = GetQuestIDFromLogIndex(questIndex)
    if questID == 0 then return end
    return questID, "quest"
end


function strategies.wowhead.GetQuestFromQuestieTracker(data)
    if not ((IsClassic() or IsWrath()) and data.focus.Quest) then return end
    return data.focus.Quest.Id, "quest"
end


function strategies.wowhead.GetTrackerFromFocus(data)
    local parent = data.focus:GetParent()
    if (data.focus.id and not data.focus.module) or not parent then return end
    local id = data.focus.id or parent.id

    -- handled in GetTradingPostActivityFromTracker because i'm not refactoring this right now
    if parent.module == MONTHLY_ACTIVITIES_TRACKER_MODULE then
        return
    end

    if parent.module == PROFESSION_RECIPE_TRACKER_MODULE then
        return id, "spell"
    end

    local focusName = data.focus:GetName()
    if parent.module == ACHIEVEMENT_TRACKER_MODULE or
        (focusName and string.find(focusName, "^AchievementFrameCriteria")) or
        -- support Kaliel's Tracker
        (data.focus.module and data.focus.module.friendlyName == "ACHIEVEMENT_TRACKER_MODULE") then
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


function strategies.wowhead.GetBattlePetFromFocus(data)
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


function strategies.wowhead.GetBattlePetFromFloatingTooltip(data)
    if not data.focus.speciesID then return end
    return select(4, C_PetJournal.GetPetInfoBySpeciesID(data.focus.speciesID)), "npc"
end


function strategies.wowhead.GetBattlePetFromAuctionHouse(data)
    if not data.focus.itemKey and (not data.focus.GetRowData or not data.focus:GetRowData().itemKey) then return end
    local itemKey = data.focus.itemKey or data.focus:GetRowData().itemKey
    return select(4, C_PetJournal.GetPetInfoBySpeciesID(itemKey.battlePetSpeciesID)), "npc"
end


function strategies.wowhead.GetItemFromAuctionHouseClassic(data)
    if not (IsClassic() or IsWrath()) or (not data.focus.itemIndex and (not data.focus:GetParent() or not data.focus:GetParent().itemIndex)) then return end
    local index = data.focus.itemIndex or data.focus:GetParent().itemIndex
    local link = GetAuctionItemLink("list", index)
    local id, type = GetFromLink(link)
    if type == "battlepet" then
        id = select(4, C_PetJournal.GetPetInfoBySpeciesID(id))
        type = "npc"
    end
    return id, type
end


function strategies.wowhead.GetToyCollectionItemFromFocus(data)
    if not data.focus.itemID then return end
    return data.focus.itemID, "item"
end


function strategies.wowhead.GetTransmogCollectionItemFromFocus(data)
    if not data.focus.visualInfo or not WardrobeCollectionFrame.tooltipSourceIndex then return end
    local selectedAppearance = data.focus.visualInfo.visualID
    local selectedStyle = WardrobeCollectionFrame.tooltipSourceIndex
    return CollectionWardrobeUtil.GetSortedAppearanceSources(selectedAppearance)[selectedStyle].itemID, "item"
end


function strategies.wowhead.GetTransmogSetItemFromFocus(data)
    if not data.focus.sourceID or not WardrobeCollectionFrame.tooltipSourceIndex then return end
    local selectedAppearance = C_TransmogCollection.GetAppearanceInfoBySource(data.focus.sourceID).appearanceID
    local selectedStyle = WardrobeCollectionFrame.tooltipSourceIndex

    local appearanceSources = C_TransmogCollection.GetAppearanceSources(selectedAppearance)
    CollectionWardrobeUtil.SortSources(appearanceSources, appearanceID, data.focus.sourceID)

    return appearanceSources[selectedStyle].itemID, "item"
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
    local link = C_CurrencyInfo.GetCurrencyListLink(index)
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

function strategies.wowhead.GetConduitFromTree(data)
    if not data.focus.GetConduitID or data.focus:GetConduitID() == 0 then return end
    local conduitID = data.focus:GetConduitID()
    local conduitData = C_Soulbinds.GetConduitCollectionData(conduitID)
    return conduitData.conduitItemID, "item"
end

function strategies.wowhead.GetConduitFromList(data)
    if not data.focus.conduitData then return end
    return data.focus.conduitData.conduitItemID, "item"
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

function strategies.wowheadTradingPostActivity.GetTradingPostActivity(data)
    if not IsRetail() or not (data.focus.activityName and data.focus.requirementsList) then return end
    return data.focus.id
end

function strategies.wowheadTradingPostActivity.GetTradingPostActivityFromTracker(data)
    local parent = data.focus:GetParent()
    if (parent and parent.module == MONTHLY_ACTIVITIES_TRACKER_MODULE and parent.id) then return parent.id end
end

local function HookTooltip(tooltip)
    tooltipStates[tooltip] = {}
    hooksecurefunc(tooltip, "SetHyperlink", function(tooltip, hyperlink)
        tooltipStates[tooltip].hyperlink = hyperlink
    end)

    if IsRetail() then
        hooksecurefunc(tooltip, "SetRecipeReagentItem", function(tooltip, recipeId, reagentIndex)
            if C_TradeSkillUI.GetRecipeReagentItemLink then
                tooltipStates[tooltip].hyperlink = C_TradeSkillUI.GetRecipeReagentItemLink(recipeId, reagentIndex)
            end
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
