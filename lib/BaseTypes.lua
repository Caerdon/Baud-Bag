local AddOnName, AddOnTable = ...
local _

BagSetType = {
    Backpack = {
        Id = 1,
        IsSubContainerOf = function(containerId)
            return (BACKPACK_CONTAINER <= containerId  and containerId <= BACKPACK_CONTAINER + NUM_BAG_SLOTS)
        end
    },
    Bank = {
        Id = 2,
        IsSubContainerOf = function(containerId)
            local isBankDefaultContainer = (containerId == BANK_CONTAINER) or (containerId == REAGENTBANK_CONTAINER)
            local isBankSubContainer = (ITEM_INVENTORY_BANK_BAG_OFFSET < containerId) and (containerId <= ITEM_INVENTORY_BANK_BAG_OFFSET + NUM_BANKBAGSLOTS)
            return isBankDefaultContainer or isBankSubContainer
        end
    } --[[,
    GuildBank = {
        Id = 3,
        IsSubContainerOf = function(containerId)
            return false
        end
    },
    VoidStorage = {
        Id = 4,
        IsSubContainerOf = function(containerId)
            return false
        end
    } ]]
}

ContainerType = {
    Joined,
    Tabbed
}

--[[ this is a really dump way to  ]]
local idIndexMap = {}
idIndexMap[BANK_CONTAINER] = 1
idIndexMap[REAGENTBANK_CONTAINER] = NUM_BANKBAGSLOTS + 2
for id = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
    idIndexMap[id] = id + 1
end
for id = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
    idIndexMap[id] = id - NUM_BAG_SLOTS + 1
end
AddOnTable.ContainerIdOptionsIndexMap = idIndexMap