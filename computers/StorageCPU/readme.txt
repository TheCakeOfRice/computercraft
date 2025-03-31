== API REFERENCE ==

-- Sends the specified item to the player/withdrawal chest
{
    method: "get",
    item: "mod:name",
    count: <positive int>
}

-- Exports the specified item to the target inventory toslot
{
    method: "export",
    item: "mod:name",
    count: <positive int>,
    target: "inv_name",
    toSlot: <positive int>
}

-- Deposits all items in the deposit chest
{
    method: "deposit"
}