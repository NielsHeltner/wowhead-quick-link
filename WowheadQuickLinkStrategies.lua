local addonName, nameSpace = ...
nameSpace.strategies = {}
local tooltipState = {}


local function GetFromLink(link)
    if not link then return end
    local _, _, type, id = link:find("%|?H?(%a+):(%d+):")
    return id, type
end


function nameSpace.strategies.GetHyperlinkFromTooltip()
    if not tooltipState.hyperlink then return end
    return GetFromLink(tooltipState.hyperlink)
end


function nameSpace.strategies.GetAuraFromTooltip()
    if not tooltipState.aura then return end
    return tooltipState.aura, "spell"
end


function nameSpace.strategies.GetItemFromTooltip(data)
    if not data.tooltip then return end
    local _, link = data.tooltip:GetItem()
    return GetFromLink(link)
end


function nameSpace.strategies.GetSpellFromTooltip(data)
    if not data.tooltip then return end
    return select(2, data.tooltip:GetSpell()), "spell"
end


function nameSpace.strategies.GetAchievementFromFocus(data)
    if not data.focus.id or not data.focus.dateCompleted then return end
    return data.focus.id, "achievement"
end


function nameSpace.strategies.GetQuestFromFocus(data)
    if not data.focus.questID then return end
    return data.focus.questID, "quest"
end


function nameSpace.strategies.GetTrackerFromFocus(data)
    if not data.focus:GetParent() then return end
    local parent = data.focus:GetParent()
    local id = data.focus.id or parent.id
    if parent.module == ACHIEVEMENT_TRACKER_MODULE then
        return id, "achievement"
    end
    return id, "quest"
end


function nameSpace.strategies.GetNpcFromTooltip(data)
    if not data.tooltip then return end
    local _, unit = data.tooltip:GetUnit()
    if not unit then return end
    return select(6, strsplit("-", UnitGUID(unit))), "npc"
end


function nameSpace.strategies.GetMountFromFocus(data)
    if not data.focus.spellID then return end
    return data.focus.spellID, "spell"
end


function nameSpace.strategies.GetLearntMountFromFocus(data)
    if not data.focus.mountID then return end
    return select(2, C_MountJournal.GetMountInfoByID(data.focus.mountID)), "spell"
end


function nameSpace.strategies.GetCompanionFromFocus(data)
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


function nameSpace.strategies.GetCompanionFromFloatingTooltip(data)
    if not data.focus.speciesID then return end
    return select(4, C_PetJournal.GetPetInfoBySpeciesID(data.focus.speciesID)), "npc"
end


function nameSpace.strategies.GetItemFromAuctionHouse(data)
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


function nameSpace.strategies.GetFactionFromFocus(data)
    if not data.focus.index or not data.focus.standingText then return end
    return select(14, GetFactionInfo(data.focus.index)), "faction"
end


function nameSpace.strategies.GetCurrencyFromFocus(data)
    if data.focus.isUnused == nil and (not data.focus:GetParent() or data.focus:GetParent().isUnused == nil) then return end
    local index = data.focus.index or data.focus:GetParent().index
    local link = GetCurrencyListLink(index)
    return GetFromLink(link)
end


local function HookTooltip(tooltip)
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

HookTooltip(GameTooltip)
HookTooltip(ItemRefTooltip)
