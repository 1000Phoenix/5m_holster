local function setPedComponentVariationBasedOnWeaponChange(ped, component, equipment, texture, currentTexture)
    if not IsPedComponentVariationValid(ped, component, equipment, texture) then
        local num_avail_equip = GetNumberOfPedDrawableVariations(ped, component) - 1
        local num_avail_textures = GetNumberOfPedTextureVariations(ped, component, equipment) - 1
        local suggested_issue_msg

        print(equipment, num_avail_equip)
        print(texture, num_avail_textures)

        if equipment > num_avail_equip then
            equipment = "!" .. equipment .. "!"
            suggested_issue_msg = " | INVALID EQUIPMENT ID " .. tostring(equipment) .. " available variants: " .. tostring(num_avail_equip)
        end

        if texture > num_avail_textures then
            texture = "!" .. texture .. "!"
            suggested_issue_msg = " | INVALID TEXTURE ID " .. tostring(texture) .. " available textures: " .. tostring(num_avail_textures)
        end

        error("Invalid ped component variation: " .. tostring(ped) .. " " .. tostring(component) .. " " ..  tostring(equipment) .. " " ..  tostring(texture) .. suggested_issue_msg)
    end

    if RETAIN_TEXTURE_ID then
        SetPedComponentVariation(ped, component, equipment, currentTexture, 0)
    else
        SetPedComponentVariation(ped, component, equipment, texture, 0)
    end
end

local function getMatchingEquipment(ped, ped_supported_components)
    for component_id, component_list in pairs(ped_supported_components) do
        local ped_equipment_id = GetPedDrawableVariation(ped, component_id)
        local equipment = component_list[ped_equipment_id]

        if equipment and (equipment.id_holstered == ped_equipment_id or equipment.id_drawn == ped_equipment_id) then
            return component_id, equipment
        end
    end
end

local function updateEquipment(cache)
    local ped = GetPlayerPed(-1)
    local ped_weapon = GetSelectedPedWeapon(ped)

    if ped_weapon == cache.weapon then
        return
    end

    cache.weapon = ped_weapon

    if cache.component then
        local currentTexture = GetPedTextureVariation(ped, cache.component)
        setPedComponentVariationBasedOnWeaponChange(ped, cache.component, cache.equipment.id_holstered, cache.equipment.texture_holstered, currentTexture)
        cache.component = nil
    end

    if not SUPPORTED_WEAPONS_HASH[ped_weapon] then
        return
    end

    local ped_supported_components = (SUPPORTED_EQUIPMENT[GetEntityModel(ped)] or {})[ped_weapon]

    if not ped_supported_components then
        return
    end

    local component, equipment = getMatchingEquipment(ped, ped_supported_components)

    if not equipment then
        return
    end

    local currentTexture = GetPedTextureVariation(ped, component)
    setPedComponentVariationBasedOnWeaponChange(ped, component, equipment.id_drawn, equipment.texture_drawn, currentTexture)

    cache.component = component
    cache.equipment = equipment
end

Citizen.CreateThread(function()
    local cached_ped_data = {}

    while true do
        updateEquipment(cached_ped_data)
        Citizen.Wait(PAUSE_DURATION_BETWEEN_UPDATES_IN_MS)
    end
end)
