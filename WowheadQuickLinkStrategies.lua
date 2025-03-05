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
    if not data.focus.memberIdx or not data.focus.GetParent or not data.focus:GetParent().applicantID then return end
    local applicant = select(1, C_LFGList.GetApplicantMemberInfo(data.focus:GetParent().applicantID, data.focus.memberIdx))
    return GetFromNameAndRealm(strsplit("-", applicant))
end


local function GetFromLink(link)
    if not link then return end
    local _, _, type, id = link:find("%|?H?(%a+):(%d+):")
    if type == "azessence" then return id end
    if type == "questie" then return id, "quest" end
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


function strategies.wowhead.GetAuraFromInstanceID(data)
    if not data.focus.auraInstanceID or not data.focus.unit then return end
    local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(data.focus.unit, data.focus.auraInstanceID)
    if not aura then return end
    return aura.spellId, "spell"
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
    if not (IsRetail() or IsCata()) or not data.tooltip.GetTooltipData then return end
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

function strategies.wowhead.GetFromCataWatchTitleFocus(data)
    if not (IsCata() and data.focus.index and data.focus.type) then return end
    if data.focus.type == "QUEST" then
        local logIndex = GetQuestIndexForWatch(data.focus.index)
        local questID = select(8, GetQuestLogTitle(logIndex))
        if questID == 0 then return end
        return questID, "quest"
    elseif data.focus.type == "ACHIEVEMENT" then
        return data.focus.index, "achievement"
    end
end

function strategies.wowhead.GetQuestFromClassicLogTitleFocus(data)
    if not (IsClassic() and CheckFrameName("QuestLogTitle%d+", data) and not data.focus.isHeader) then return end
    local questIndex = data.focus:GetID()
    local _, _, _, _, _, _, _, questID = GetQuestLogTitle(questIndex)
    if questID == 0 then return end
    return questID, "quest"
end

function strategies.wowhead.GetQuestFromQuestieTracker(data)
    if not ((IsClassic() or IsCata()) and data.focus.Quest and type(data.focus.Quest) == "table") then return end
    return data.focus.Quest.Id, "quest"
end

function strategies.wowhead.GetQuestFromQuestieFrame(data)
    if not ((IsClassic() or IsCata()) and CheckFrameName("QuestieFrame%d+", data)) then return end
    if data.focus.data.QuestData then return data.focus.data.QuestData.Id, "quest" end
    if data.focus.data.npcData then return data.focus.data.npcData.id, "npc" end
end

function strategies.wowhead.GetRuneEnchantmentFromRuneFocus(data)
    if not (IsClassic() and CheckFrameName("EngravingFrameScrollFrameButton%d+", data)) then return end
    local abilityID = data.focus.skillLineAbilityID

    -- loop through all runes to find the one with the matching skillLineAbilityID
    for _, category in ipairs(C_Engraving.GetRuneCategories(true, true)) do
        for _, rune in ipairs(C_Engraving.GetRunesForCategory(category, true)) do

            -- return the first spell ID from the list, couldn't find a better way to convert the skillLineAbilityID
            -- to the rune
            if rune.skillLineAbilityID == abilityID and #rune.learnedAbilitySpellIDs > 0 then
                return rune.learnedAbilitySpellIDs[1], "spell"
            end
        end
    end
end

function strategies.wowhead.GetTrackerFromFocus(data)
    if not data.focus.GetParent then return end

    local parent = data.focus:GetParent()
    if not parent or not parent.parentModule then return end
    local name = parent.parentModule:GetName()

    if parent.poiQuestID then
        return parent.poiQuestID, "quest"
    end

    if name == "BonusObjectiveTracker" then
        return parent.id, "quest"
    end

    -- handled in GetTradingPostActivityFromTracker because i'm still not refactoring this right now
    if name == "MonthlyActivitiesObjectiveTracker" then
        return
    end

    if name == "ProfessionsRecipeTracker" then
        return parent.id, "spell"
    end

    local focusName = data.focus:GetName()
    if name == "AchievementObjectiveTracker" or
        -- support Kaliel's Tracker
        (data.focus.module and data.focus.module.friendlyName == "ACHIEVEMENT_TRACKER_MODULE") then
        return parent.id, "achievement"
    end
end


function strategies.wowhead.GetClassicQuestLog(data)
    if not IsRetail() or not data.focus.info or not data.focus.info.questID then return end
    return data.focus.info.questID, "quest"
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
    if not IsRetail() then return end
    if not data.focus.petID and (not data.focus.GetParent or not data.focus:GetParent().petID) then return end
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
    if not (IsClassic() or IsCata()) then return end
    if not data.focus.itemIndex or (not data.focus.GetParent and not data.focus:GetParent().itemIndex) then return end
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


function strategies.wowhead.GetRetailFactionFromFocus(data)
    if not IsRetail() or not data.focus or not data.focus.factionID then return end
    return data.focus.factionID, "faction"
end


function strategies.wowhead.GetClassicCataFactionFromFocus(data)
    if IsRetail() or not data.focus.index or not data.focus.standingText then return end
    return select(14, GetFactionInfo(data.focus.index)), "faction"
end


function strategies.wowhead.GetRetailCurrencyInTabFromFocus(data)
    if not IsRetail() or not data.focus.elementData or not data.focus.elementData.currencyID then return end
    return data.focus.elementData.currencyID, "currency"
end


function strategies.wowhead.GetClassicCataCurrencyInTabFromFocus(data)
    if IsRetail() or (data.focus.isUnused == nil or (not data.focus.GetParent and data.focus:GetParent().isUnused == nil)) then return end
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
    if not data.focus.GetParent then return end

    local parent = data.focus:GetParent()
    if (parent and parent.parentModule and parent.parentModule:GetName() == "MonthlyActivitiesObjectiveTracker" and parent.id) then return parent.id end
end

function CheckFrameName(name, data)
    if not name or not data.focus or not data.focus:GetName() then return false end
    return string.find(data.focus:GetName(), name)
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
        if IsRetail() then
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
            if aura then
                tooltipStates[tooltip].aura = aura.spellId
            end
        else
            tooltipStates[tooltip].aura = select(10, UnitAura(unit, index, filter))
        end
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
