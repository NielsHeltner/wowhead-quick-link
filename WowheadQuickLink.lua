local addonName, nameSpace = ...
if IsRetail() then
    nameSpace.baseWowheadUrl = "https://%swowhead.com/%s=%s%s"
end
if IsClassic() then
    nameSpace.baseWowheadUrl = "https://%swowhead.com/classic/%s=%s%s"
end
if IsBCC() then
    nameSpace.baseWowheadUrl = "https://%swowhead.com/tbc/%s=%s%s"
end
if IsMop() then
    nameSpace.baseWowheadUrl = "https://%swowhead.com/mop-classic/%s=%s%s"
end
if IsForever() then
    nameSpace.baseWowheadUrl = "https://%swowhead.com/forever/%s=%s%s"
end

nameSpace.baseWowheadAzEsUrl = "https://%swowhead.com/azerite-essence/%s%s"
nameSpace.baseWowheadTradingPostActivityUrl = "https://%swowhead.com/trading-post-activity/%s%s"
nameSpace.baseArmoryUrl = "https://worldofwarcraft.com/%s/character/%s/%s"
nameSpace.baseRaiderIoUrl = "https://raider.io/characters/%s/%s/%s"

local popupText = "%s Link\nCTRL-C to copy"

local foreverPopup

local function ShowForeverUrlPopup(header, url)
    if not foreverPopup then
        -- Keep addon handlers off Blizzard's shared StaticPopup frames. Their
        -- native gamepad navigation also manages protected input bindings.
        -- Create without a parent first: Forever observes parented creation
        -- when registering frames with its native navigation.
        local function NewFrame(kind, parent, template)
            local frame = CreateFrame(kind, nil, nil, template)
            frame:SetParent(parent)
            return frame
        end

        local frame = NewFrame("Frame", UIParent, "BackdropTemplate")
        frame:Hide()
        frame:SetSize(360, 140)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetClampedToScreen(true)
        frame:EnableMouse(true)
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })

        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", 0, -18)

        local editBox = NewFrame("EditBox", frame, "InputBoxTemplate")
        editBox:SetSize(300, 24)
        editBox:SetPoint("TOP", 0, -60)
        editBox:SetAutoFocus(false)
        editBox:SetMaxLetters(0)

        local function HidePopup() frame:Hide() end
        editBox:SetScript("OnEscapePressed", HidePopup)
        editBox:SetScript("OnEnterPressed", HidePopup)
        editBox:SetScript("OnKeyUp", function(self, key)
            if (IsControlKeyDown() and key == "C")
                or (IsKeyDown("C") and (key == "LCTRL" or key == "RCTRL")) then
                HidePopup()
            end
        end)
        frame:SetScript("OnHide", function() editBox:ClearFocus() end)

        local close = NewFrame("Button", frame, "UIPanelButtonTemplate")
        close:SetSize(120, 24)
        close:SetPoint("BOTTOM", 0, 16)
        close:SetText("Close")
        close:SetScript("OnClick", HidePopup)

        foreverPopup = { frame = frame, title = title, editBox = editBox }
    end

    foreverPopup.title:SetText(string.format(popupText, header))
    foreverPopup.editBox:SetText(url)
    foreverPopup.frame:Show()
    foreverPopup.editBox:SetFocus()
    foreverPopup.editBox:HighlightText()
end


local function ShowUrlPopup(header, url)
    if IsForever() then
        ShowForeverUrlPopup(header, url)
    else
        StaticPopup_Show("WowheadQuickLinkUrl", header, nil, url)
    end
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
    local focus = {}
    local foci = GetMouseFoci()
    if foci[1] then
        focus = foci[1]
    end
    local tooltip = GameTooltip
    return {focus = focus, tooltip = tooltip}
end


function RunWowheadQuickLink()
    CreateUrl(GetDataSources(), nameSpace.strategies)
end


function RunAlternativeQuickLink()
    CreateUrl(GetDataSources(), nameSpace.altStrategies)
end


-- Do not register with the shared popup system on Forever, even before the
-- first link is opened.
if not IsForever() then
StaticPopupDialogs["WowheadQuickLinkUrl"] = {
    text = popupText,
    button1 = "Close",
    OnShow = function(self, data)
        local function HidePopup(self) self:GetParent():Hide() end
        
        -- Changed from "if (IsRetail() or IsMop() or IsClassic()) then" to this to make it version agnostic
        local editBox = self.EditBox or self.editBox
        if not editBox then return end

        editBox:SetScript("OnEscapePressed", HidePopup)
        editBox:SetScript("OnEnterPressed", HidePopup)
        editBox:SetScript("OnKeyUp", function(self, key)
            if
                (IsControlKeyDown() and key == "C")
                or (IsKeyDown("C") and (key == "LCTRL" or key == "RCTRL"))
            then
                HidePopup(self)
            end
        end)
        editBox:SetMaxLetters(0)
        editBox:SetText(data)
        editBox:HighlightText()
    end,
    hasEditBox = true,
    editBoxWidth = 240,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
end
