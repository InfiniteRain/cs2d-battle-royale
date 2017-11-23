return 

{
    gracePeriodSeconds = 12,
    
    finalAreaRadius    = 15,
    areaShrinkingSpeed = 70,
    dangerAreaDamage   = 10,

    packages = {
        gray = {
            image           = 'gfx/battle_royale/crate_gray.png',
            spawns          = 6,
            items           = {1, 2, 4, 61, 62, 64, 65, 61, 62, 64, 65, 78, 85},
            extraItemChance = 0.25,
            effectColor     = {64, 64, 64}
        },

        orange = {
            image           = 'gfx/battle_royale/crate_orange.png',
            spawns          = 5,
            items           = {51, 52, 53, 57, 57, 58, 61, 62, 64, 79},
            extraItemChance = 0.25,
            effectColor     = {255, 127, 0}
        },

        green = {
            image           = 'gfx/battle_royale/crate_green.png',
            spawns          = 15,
            items           = {1, 2, 3, 4, 5, 6, 10, 11, 20, 21, 22, 23, 24, 75, 77, 79},
            extraItemChance = 0.25,
            effectColor     = {0, 255, 0}
        },

        purple = {
            image           = 'gfx/battle_royale/crate_purple.png',
            spawns          = 5,
            items           = {3, 6, 30, 31, 32, 33, 34, 64, 80, 89},
            extraItemChance = 0.25,
            effectColor     = {255, 000, 255}
        },

        white = {
            image           = 'gfx/battle_royale/crate_white.png',
            spawns          = 8,
            items           = {64, 65, 65, 57, 58},
            extraItemChance = 0.25,
            effectColor     = {255, 255, 255}
        },

        black = {
            image           = 'gfx/battle_royale/crate_black.png',
            spawns          = 1,
            items           = {47, 46, 90, 91, 84, 86, 86},
            extraItemChance = 0.25,
            effectColor     = {0, 0, 0}
        }
    },

    unspawnableZones = {
        ['^bg_foes.*'] = {
            {37 , 0  , 80 , 14 },
            {15 , 108, 15 , 108},
            {72 , 0  , 80 , 14 },
            {0  , 72 , 14 , 79 },
            {72 , 135, 79 , 149},
            {135, 72 , 149, 79 },
            {70 , 44 , 71 , 45 },
            {104, 75 , 109, 78 },
            {30 , 76 , 31 , 76 }
        }
    },

    playerStoredDataSchema = {
        exp  = 0,
        aura = 0
    },

    auras = {
        {'Red'   , 255, 0  , 0  },
        {'Green' , 0  , 255, 0  },
        {'Blue'  , 0  , 80 , 255},
        {'Yellow', 255, 255, 0  },
        {'Teal'  , 0  , 255, 210},
        {'Orange', 255, 128, 0  },
        {'Purple', 110, 0  , 220},
        {'Pink'  , 255, 80 , 255}
    }
}
