-- For QB-Inventory (qb-core/shared/items.lua)
['magazine'] = {
    ['name'] = 'magazine',
    ['label'] = 'Los Santos Magazine',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'magazine.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'A glossy magazine about Los Santos life'
},

-- For QX-Inventory (qx-inventory/shared/items.lua)
['magazine'] = {
    label = 'Magazine',
    weight = 500,
    stack = false,
    close = false,
    description = 'A readable magazine',
    consume = 0,
    client = {
        export = 'fd-magazine.useMagazine'
    }
},