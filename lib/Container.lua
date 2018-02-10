local AddOnName, AddOnTable = ...
local _

local Prototype = {
    Id = nil,
    Name = "DefaultContainer",
    Frame = nil,
    SubContainers = nil,
    -- the values below aren't used yet
    Columns = 11,
    Icon = "",
    Locked = false
}

function Prototype:GetName()
    return self.Name
end

function Prototype:SetName(name)
    self.Name = name
end

function Prototype:UpdateName()
    local containerConfig = BBConfig[self.Frame.BagSet][self.Id]
    local targetName = containerConfig.Name or ""
    local targetColor = NORMAL_FONT_COLOR

    if ((self.Frame.BagSet == 2) and (not BaudBagFrame.BankOpen)) then
        targetName = containerConfig.Name..AddOnTable["Localized"].Offline
        targetColor = RED_FONT_COLOR
    end

    local nameWidget = self.Frame.Name
    nameWidget:SetText(targetName)
    nameWidget:SetTextColor(targetColor.r, targetColor.g, targetColor.b)
end

function Prototype:SaveCoordsToConfig()
    BaudBag_DebugMsg("Container", "Saving container coords to config (name)", self.Name)
    local scale = self.Frame:GetScale()
    local x, y = self.Frame:GetCenter()
    x = x * scale
    y = y * scale
    BBConfig[self.Frame.BagSet][self.Id].Coords = {x, y}
end

function Prototype:UpdateFromConfig()
    if (self.Frame == nil) then
        BaudBag_DebugMsg("Container", "Frame doesn't exist yet. Called UpdateFromConfig() to early???", self.Id, self.Name)
        return
    end
    BaudBag_DebugMsg("Container", "Updating container from config (name)", self.Name)

    local containerConfig = BBConfig[self.Frame.BagSet][self.Id]

    if not containerConfig.Coords then
        self:SaveCoordsToConfig()
    end

    local scale = containerConfig.Scale / 100
    local x, y = unpack(containerConfig.Coords)

    self.Frame:ClearAllPoints()
    self.Frame:SetScale(scale)
    self.Frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", (x / scale), (y / scale))
    self.Frame.Name:SetText(containerConfig.Name or "")
end

function Prototype:Render()
    -- TODO
end

function Prototype:Update()
    -- TODO
end

function Prototype:UpdateSize()
    local container

    for _, container in pairs(self.SubContainers) do
    
        -- prepare bag cache for use
        local bagCache = BaudBagGetBagCache(container.ContainerId)
        local size, slot

        -- process inventory, bank only if it is open
        if (self.Frame.BagSet ~= 2) or BaudBagFrame.BankOpen then
            size = GetContainerNumSlots(container.ContainerId)

            -- process bank
            if (self.Frame.BagSet == 2) then
                -- Clear out excess information if the size of a bag decreases
                -- TODO move this to cache!
                if (bagCache.Size > size) then
                    for slot = size, bagCache.Size do
                        if bagCache[slot] then
                            bagCache[slot] = nil
                        end
                    end
                end
                bagCache.Size = size
            end
        else
            size = bagCache and bagCache.Size or 0
        end

        -- special treatment for default bank containers, as their data can ALWAYS be retrieved
        if (BaudBag_IsBankDefaultContainer(container.ContainerId)) then
            size = GetContainerNumSlots(container.ContainerId)
        end

        container.Frame.size = size
        container.Size = size
        self.Frame.Slots = self.Frame.Slots + size

        -- last but not least update visibility for deposit button of reagent bank
        if (container.ContainerId == REAGENTBANK_CONTAINER and BaudBagFrame.BankOpen) then
            self.Frame.DepositButton:Show()
        else
            self.Frame.DepositButton:Hide()
        end

    end
end

function Prototype:UpdateSubContainers(col, row)
    local contCfg       = BBConfig[self.Frame.BagSet][self.Id]
    local background    = contCfg.Background
    local maxCols       = contCfg.Columns
    local slotLevel     = self.Frame:GetFrameLevel() + 1
    local container

    BaudBag_DebugMsg("Container", "Started Updating SubContainers For Container", self.Id)

    for _, container in pairs(self.SubContainers) do
        BaudBag_DebugMsg("Container", "Updating SubContainer with ID and Size", container.ContainerId, container.Size)
        -- not existing subbags (bags with no itemslots) are hidden
        if (container.Size <= 0) then
            container.Frame:Hide()
        else
            BaudBag_DebugMsg("Bags", "Adding (bagName)", container.Name)

            container:CreateMissingSlots()
			
            -- update container contents (special bank containers don't need this, regular bank only when open)
            if (not BaudBag_IsBankDefaultContainer(container.ContainerId)) and (BaudBagFrame.BankOpen or (container.ContainerId < 5)) then
                ContainerFrame_Update(container.Frame)
            end

            -- position item slots
            container:UpdateSlotContents()
            col, row = container:UpdateSlotPositions(self.Frame, background, col, row, maxCols, slotLevel)
            container.Frame:Show()
        end
    end

    -- TODO: It seems some how strange to pass this through 2 layers... let's see if we can get rid of that in the future!
    return col, row
end

function Prototype:UpdateBackground()
    local backgroundId = BBConfig[self.Frame.BagSet][self.Id].Background
    local backdrop = self.Frame.Backdrop
    backdrop:SetFrameLevel(self.Frame:GetFrameLevel())
    -- This shifts the name of the bank frame over to make room for the extra button
    local shiftName = (self.Frame:GetID() == 1) and 25 or 0
    
    local left, right, top, bottom = AddOnTable["Backgrounds"][backgroundId]:Update(self.Frame, backdrop, shiftName)
    self.Frame.Name:SetPoint("RIGHT", self.Frame:GetName().."MenuButton", "LEFT")

    backdrop:ClearAllPoints()
    backdrop:SetPoint("TOPLEFT", -left, top)
    backdrop:SetPoint("BOTTOMRIGHT", right, -bottom)
    self.Frame:SetHitRectInsets(-left, -right, -top, -bottom)
    self.Frame.UnlockInfo:ClearAllPoints()
    self.Frame.UnlockInfo:SetPoint("TOPLEFT", -10, 3)
    self.Frame.UnlockInfo:SetPoint("BOTTOMRIGHT", 10, -3)
end

function Prototype:SaveCoordinates()
    -- TODO
end

local Metatable = { __index = Prototype }

function AddOnTable:CreateContainer(bagSetType, bbContainerId)
    local container = _G.setmetatable({}, Metatable)
    container.Id = bbContainerId
    container.Name = AddOnName.."Container"..bagSetType.Id.."_"..bbContainerId
    BaudBag_DebugMsg("Container", "Creating Container (name)", container.Name)
    local frame = _G[container.Name]
    if (frame == nil) then
        BaudBag_DebugMsg("Container", "Frame for container does not yet exist, creating new Frame (name)", name)
        frame = CreateFrame("Frame", container.Name, UIParent, "BaudBagContainerTemplate")
    end
    frame:SetID(bbContainerId)
    frame.BagSet = bagSetType.Id
    frame.Bags = {}
    container.Frame = frame
    container.SubContainers = {}
    return container
end