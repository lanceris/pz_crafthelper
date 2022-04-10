local tex = function (tn) return getTexture(tn) end

CHC_building_defs = {}

CHC_building_defs.buildObjectsDefs = {
    --region walls
    {
        name=getText("ContextMenu_Wooden_Wall_Frame"),
        tex=tex("carpentry_02_100"),
        req={["Base.Plank"]=2, ["Base.Nails"]=2, [getText("IGUI_perks_Carpentry")]=2},
        desc=getText("Tooltip_craft_woodenWallFrameDesc"),
        params={["xp:Woodwork"]=5, health=50, canBarricade=false}
    },
    {
        name=getText("ContextMenu_Wooden_Pillar"),
        tex=tex("walls_exterior_wooden_01_27"),
        req={["Base.Plank"]=2, ["Base.Nails"]=3, [getText("IGUI_perks_Carpentry")]=2},
        desc=getText("Tooltip_craft_woodenPillarDesc"),
        params={["xp:Woodwork"]=3, wallType="pillar", canBePlastered=true, canPassThrough=true, canBarricade=false, isCorner=true}
    },
    {
        name=getText("ContextMenu_Log_Wall"),
        tex=tex("carpentry_02_80"),
        req={["Base.Log"]=4},
        req_or={["Base.RippedSheets"]=4,["Base.RippedSheetsDirty"]=4,["Base.Twine"]=4,["Base.Rope"]=2},
        desc=getText("Tooltip_craft_wallLogDesc"),
        params={["xp:Woodwork"]=5, noNeedHammer=true, canBarricade=false}
    },
    {
        name=getText("ContextMenu_Windows_Frame"),
        tex=tex("walls_exterior_wooden_01_32"),
        req={["Base.Plank"]=4,["Base.Nails"]=4,[getText("IGUI_perks_Carpentry")]=2},
        desc=getText("Tooltip_craft_woodenFrameDesc"),
        params={["xp:Woodwork"]=5, wallType='windowsframe', hoppable=true, isThumpable=false},
    },
    {
        name=getText("ContextMenu_Wooden_Floor"),
        tex=tex("carpentry_02_56"),
        req={["Base.Plank"]=1,["Base.Nails"]=2,[getText("IGUI_perks_Carpentry")]=1},
        desc=getText("Tooltip_craft_woodenFloorDesc"),
        params={["xp:Woodwork"]=3},
    },
    {
        name=getText("ContextMenu_Wooden_Crate"),
        tex=tex("carpentry_01_16"),
        req={["Base.Plank"]=3,["Base.Nails"]=3,[getText("IGUI_perks_Carpentry")]=3},
        desc=getText("Tooltip_craft_woodenFloorDesc"),
        params={["xp:Woodwork"]=3},
    },
    --endregion

    -- region furniture
    {
        name=getText("ContextMenu_Small_Table"),
        tex=tex("carpentry_01_62"),
        req={["Base.Plank"]=5,["Base.Nails"]=4,[getText("IGUI_perks_Carpentry")]=3},
        desc=getText("Tooltip_craft_smallTableDesc"),
        params={["xp:Woodwork"]=3},
    },
    {
        name=getText("ContextMenu_Large_Table"),
        tex=tex("carpentry_01_62"),
        req={["Base.Plank"]=6,["Base.Nails"]=4,[getText("IGUI_perks_Carpentry")]=5},
        desc=getText("Tooltip_craft_largeTableDesc"),
        params={["xp:Woodwork"]=5},
    },
    {
        name=getText("ContextMenu_Table_with_Drawer"),
        tex=tex("carpentry_02_8"),
        req={["Base.Plank"]=5,["Base.Nails"]=4,[getText("IGUI_perks_Carpentry")]=5,["Base.Drawer"]=1},
        desc=getText("Tooltip_craft_tableDrawerDesc"),
        params={["xp:Woodwork"]=5, isContainer=true},
    },

    {
        name=getText("ContextMenu_Wooden_Chair"),
        tex=tex("carpentry_01_44"),
        req={["Base.Plank"]=5,["Base.Nails"]=4,[getText("IGUI_perks_Carpentry")]=2},
        desc=getText("Tooltip_craft_woodenChairDesc"),
        params={["xp:Woodwork"]=3,canPassThrough=true},
    },
    {
        name=getText("ContextMenu_Rain_Collector_Barrel"),
        tex=tex("carpentry_02_54"),
        req={["Base.Plank"]=4,["Base.Nails"]=4,["Base.Garbagebag"]=4,[getText("IGUI_perks_Carpentry")]=4},
        desc=getText("Tooltip_craft_rainBarrelDesc"),
        params={["xp:Woodwork"]=3},
    },
    {
        name=getText("ContextMenu_Rain_Collector_Barrel"),
        tex=tex("carpentry_02_52"),
        req={["Base.Plank"]=4,["Base.Nails"]=4,["Base.Garbagebag"]=4,[getText("IGUI_perks_Carpentry")]=7},
        desc=getText("Tooltip_craft_rainBarrelDesc"),
        params={["xp:Woodwork"]=5},
    },
    {
        name=getText("ContextMenu_Compost"),
        tex=tex("camping_01_19"),
        req={["Base.Plank"]=5,["Base.Nails"]=4,[getText("IGUI_perks_Carpentry")]=2},
        desc=getText("Tooltip_craft_compostDesc"),
        params={["xp:Woodwork"]=5,notExterior=true},
    },
    {
        name=getText("ContextMenu_Bookcase"),
        tex=tex("furniture_shelving_01_41"),
        req={["Base.Plank"]=5,["Base.Nails"]=4,[getText("IGUI_perks_Carpentry")]=5},
        desc=getText("Tooltip_craft_bookcaseDesc"),
        params={["xp:Woodwork"]=3,canBeAlwaysPlaced=true,isContainer=true,containerType='shelves'},
    },
    {
        name=getText("ContextMenu_SmallBookcase"),
        tex=tex("furniture_shelving_01_23"),
        req={["Base.Plank"]=5,["Base.Nails"]=4,[getText("IGUI_perks_Carpentry")]=5},
        desc=getText("Tooltip_craft_smallBookcaseDesc"),
        params={["xp:Woodwork"]=5,canBeAlwaysPlaced=true,isContainer=true,containerType='shelves'},
    },
    {
        name=getText("ContextMenu_Shelves"),
        tex=tex("carpentry_02_68"),
        req={["Base.Plank"]=3,["Base.Nails"]=3,[getText("IGUI_perks_Carpentry")]=3},
        desc=getText("Tooltip_craft_shelvesDesc"),
        params={["xp:Woodwork"]=3,isContainer=true,containerType='shelves',needToBeAgainstWall=true,buildLow=false,blockAllTheSquare=false,isWallLike=true},
    },
    {
        name=getText("ContextMenu_DoubleShelves"),
        tex=tex("furniture_shelving_01_2"),
        req={["Base.Plank"]=2,["Base.Nails"]=4,[getText("IGUI_perks_Carpentry")]=2},
        desc=getText("Tooltip_craft_doubleShelvesDesc"),
        params={["xp:Woodwork"]=3,isContainer=true,containerType="shelves",needToBeAgainstWall=true,buildLow=false,blockAllTheSquare=false,isWallLike=true},
    },
    {
        name=getText("ContextMenu_Bed"),
        tex=tex("carpentry_02_74"),
        req={["Base.Plank"]=6,["Base.Nails"]=4,["Base.Mattress"]=1,[getText("IGUI_perks_Carpentry")]=4},
        desc=getText("Tooltip_craft_bedDesc"),
        params={["xp:Woodwork"]=5},
    },
    {
        name=getText("ContextMenu_Sign"),
        tex=tex("constructedobjects_signs_01_27"),
        req={["Base.Plank"]=3,["Base.Nails"]=3,[getText("IGUI_perks_Carpentry")]=1},
        desc=getText("Tooltip_craft_signDesc"),
        params={["xp:Woodwork"]=3},
    },
    --endregion

    --region doors
    {
        name=getText("ContextMenu_Door_Frame"),
        tex=tex("walls_exterior_wooden_01_34"),
        req={["Base.Plank"]=4,["Base.Nails"]=4,[getText("IGUI_perks_Carpentry")]=2},
        desc=getText("Tooltip_craft_doorFrameDesc"),
        params={["xp:Woodwork"]=5},
    },
    {
        name=getText("ContextMenu_Wooden_Door"),
        tex=tex("carpentry_01_56"),
        req={["Base.Plank"]=4,["Base.Nails"]=4,["Base.Hinge"]=2,["Base.Doorknob"]=1,[getText("IGUI_perks_Carpentry")]=3},
        desc=getText("Tooltip_craft_woodenDoorDesc"),
        params={["xp:Woodwork"]=3},
    },
    {
        name=getText("ContextMenu_Double_Wooden_Door"),
        tex=tex("fixtures_doors_fences_01_105"),
        req={["Base.Plank"]=12,["Base.Nails"]=12,["Base.Hinge"]=4,knob=2,[getText("IGUI_perks_Carpentry")]=6},
        desc=getText("Tooltip_craft_doubleWoodenDoorDesc"),
        params={["xp:Woodwork"]=6},
    },
    --endregion

    --region misc
    {
        name=getText("ContextMenu_Wooden_Cross"),
        tex=tex("location_community_cemetary_01_23"),
        req={["Base.Plank"]=2,["Base.Nails"]=2},
        desc=getText("Tooltip_craft_woodenCrossDesc"),
        params={["xp:Woodwork"]=5, canPassThrough=true, canBarricade=false, canBeAlwaysPlaced=false, isThumpable=false, maxTime=80},
    },
    {
        name=getText("ContextMenu_Stone_Pile"),
        tex=tex("location_community_cemetary_01_30"),
        req={["Base.Stone"]=6},
        desc=getText("Tooltip_craft_stonePileDesc"),
        params={canPassThrough=true, canBarricade=false, canBeAlwaysPlaced=false, isThumpable=false, maxTime=50, noNeedHammer=true}
    },
    {
        name=getText("ContextMenu_Wooden_Picket"),
        tex=tex("location_community_cemetary_01_31"),
        req={["Base.Plank"]=1,["Base.SheetRope"]=1},
        desc=getText("Tooltip_craft_woodenPicketDesc"),
        params={["xp:Woodwork"]=5, canPassThrough=true, canBarricade=false, canBeAlwaysPlaced=false, isThumpable=false, maxTime=50, noNeedHammer=true},
    },
    --endregion

    --region bar
    {
        name=getText("ContextMenu_Bar_Element"),
        tex=tex("carpentry_02_19"),
        req={["Base.Plank"]=4,["Base.Nails"]=4,[getText("IGUI_perks_Carpentry")]=7},
        desc=getText("Tooltip_craft_barElementDesc"),
        params={["xp:Woodwork"]=5},
    },
    {
        name=getText("ContextMenu_Bar_Corner"),
        tex=tex("fixtures_doors_fences_01_105"),
        req={["Base.Plank"]=4,["Base.Nails"]=4,[getText("IGUI_perks_Carpentry")]=7},
        desc=getText("Tooltip_craft_barElementDesc"),
        params={["xp:Woodwork"]=5},
    },
    --endregion

    --region fence
    {
        name=getText("ContextMenu_Wooden_Stake"),
        tex=tex("fencing_01_19"),
        req={["Base.Plank"]=1,["Base.Nails"]=2,[getText("IGUI_perks_Carpentry")]=5},
        desc=getText("Tooltip_craft_woodenStakeDesc"),
        params={["xp:Woodwork"]=5, hoppable=true, isThumpable=false, canBarricade=false},
    },
    {
        name=getText("ContextMenu_Barbed_Fence"),
        tex=tex("fencing_01_20"),
        req={["Base.BarbedWire"]=1,[getText("IGUI_perks_Carpentry")]=5},
        desc=getText("Tooltip_craft_barbedFenceDesc"),
        params={["xp:Woodwork"]=5, isThumpable=false, hoppable=true, canBarricade=false},
    },
    {
        name=getText("ContextMenu_Wooden_Fence"),
        tex=tex("carpentry_02_48"),
        req={["Base.Plank"]=2,["Base.Nails"]=3,[getText("IGUI_perks_Carpentry")]=2},
        desc=getText("Tooltip_craft_woodenFenceDesc"),
        params={["xp:Woodwork"]=5, canPassThrough=true, isThumpable=false, canBarricade=false, canBeAlwaysPlaced=true},
    },
    {
        name=getText("ContextMenu_Sang_Bag_Wall"),
        tex=tex("carpentry_02_12"),
        req={["Base.Sandbag"]=3},
        desc=getText("Tooltip_craft_sandBagDesc"),
        params={["xp:Woodwork"]=5, hoppable=true, canBarricade=false, isWallLike=false, noNeedHammer=true},
    },
    {
        name=getText("ContextMenu_Gravel_Bag_Wall"),
        tex=tex("carpentry_02_12"),
        req={["Base.Gravelbag"]=3},
        desc=getText("Tooltip_craft_gravelBagDesc"),
        params={["xp:Woodwork"]=5, hoppable=true, canBarricade=false, isWallLike=false, noNeedHammer=true},
    },
    --endregion

    -- region lights
    {
        name=getText("ContextMenu_Lamp_on_Pillar"),
        tex=tex("carpentry_02_59"),
        req={["Base.Plank"]=2, ["Base.Nails"]=4, ["Base.Rope"]=1, ["Base.Torch"]=1, [getText("IGUI_perks_Carpentry")]=4},
        desc=getText("ContextMenu_Lamp_on_Pillar"),
        params={["xp:Woodwork"]=5, radius=10},
    },
    --endregion

}

return CHC_building_defs