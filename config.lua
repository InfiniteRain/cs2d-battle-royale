return

{
    gracePeriodSeconds = 12,

    finalAreaRadius    = 10,
    areaShrinkingSpeed = 70,
    dangerAreaDamage   = 10,

    dangerZoneImage     = 'gfx/br/dz2.png',
    fontImage           = 'gfx/br/fn2.png',
    killSoundFile       = 'br/ds.ogg',
    auraImage           = 'gfx/sprites/flare4.bmp',
    skinsMenuImage      = 'gfx/br/sm.png',
    hoverCatImage       = 'gfx/br/ssc.png',
    hoverExitImage      = 'gfx/br/sse.png',
    hoverSlotImage      = 'gfx/br/sss.png',
    hoverDirImage       = 'gfx/br/ssd.png',

    ui = {
        expBarImage         = 'gfx/br/xb.png',
        progressBarImage    = 'gfx/br/bb.png',
        bigProgressBarImage = 'gfx/br/eb.png',

        hpBar = {
            position = {90, 450}
        },

        armorBar = {
            position = {246, 450}
        },

        expBar = {
            position = {415, 430}
        },

        stamBar = {
            position = {415, 450}
        },

        skins = {
            position = {425, 240},
            scale = {0.6, 0.6},

            exit = {
                name = 'Exit',
                box  = {198, 367, 306, 406}
            },

            categories = {
                {
                    name = 'Common skins',
                    box  = {192, 82 , 312, 107}
                },
                {
                    name = 'Buyable skins',
                    box  = {192, 120, 312, 145}
                },
                {
                    name = 'Event skins',
                    box  = {192, 159, 312, 183}
                },
                {
                    name = 'Special skins',
                    box  = {192, 196, 312, 220}
                }
            },

            slots = {
                firstBox   = {339, 64 , 387, 113},

                offset     = {7, 6},
                dimensions = {6, 5}
            },

            directionals = {
                prev = {435, 350, 460, 370},
                next = {541, 350, 566, 370}
            },

            misc = {
                page  = {499, 360},
                level = {418, 396},
                gold  = {585, 396}
            }
        }
    },

    packages = {
        gray = {
            image           = 'gfx/br/c0.png',
            spawns          = 10,
            items           = {1, 2, 4, 61, 62, 64, 65, 61, 62, 64, 65, 78, 85},
            extraItemChance = 0.25,
            effectColor     = {64, 64, 64}
        },

        orange = {
            image           = 'gfx/br/c1.png',
            spawns          = 12,
            items           = {51, 52, 53, 57, 57, 58, 61, 62, 64, 79},
            extraItemChance = 0.25,
            effectColor     = {255, 127, 0}
        },

        green = {
            image           = 'gfx/br/c2.png',
            spawns          = 23,
            items           = {1, 2, 3, 4, 5, 6, 10, 11, 20, 21, 22, 23, 24, 75, 77, 79},
            extraItemChance = 0.25,
            effectColor     = {0, 255, 0}
        },

        purple = {
            image           = 'gfx/br/c3.png',
            spawns          = 10,
            items           = {3, 6, 30, 31, 32, 33, 34, 64, 80, 89},
            extraItemChance = 0.25,
            effectColor     = {255, 000, 255}
        },

        white = {
            image           = 'gfx/br/c4.png',
            spawns          = 15,
            items           = {64, 65, 65, 57, 58},
            extraItemChance = 0.25,
            effectColor     = {255, 255, 255}
        },

        black = {
            image           = 'gfx/br/c5.png',
            spawns          = 3,
            items           = {47, 46, 90, 91, 84, 86, 86},
            extraItemChance = 0.25,
            effectColor     = {0, 0, 0}
        }
    },

    maps = {
        ['^bg_foes.*'] = {
            unspawnableZones = {
                {15 , 108, 15 , 108},
                {72 , 0  , 80 , 14 },
                {0  , 72 , 14 , 79 },
                {72 , 135, 79 , 149},
                {135, 72 , 149, 79 },
                {70 , 44 , 71 , 45 },
                {104, 75 , 109, 78 },
                {30 , 76 , 31 , 76 },
                {33 , 0  , 78 , 14 }
            },

            trains = {
                {
                    start  = {50 , 0  },
                    finish = {50 , 179},
                    speed  = 960,
                    cycle  = 10,

                    image  = 'gfx/br/t2.png',
                    size   = {90, 1239}
                }
            }
        }
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
    },

    servertransfer = {
        'gfx/br/c0.png',
        'gfx/br/c1.png',
        'gfx/br/c2.png',
        'gfx/br/c3.png',
        'gfx/br/c4.png',
        'gfx/br/c5.png',
        'gfx/br/dz2.png',
        'gfx/br/fn2.png',
        'gfx/br/xb.png',
        'gfx/br/bb.png',
        'gfx/br/eb.png',
        'gfx/br/t2.png',
        'gfx/br/sm.png',

        'sfx/br/ds.ogg'
    },

    roles = {
        admin = {
            tag      = 'ADMIN',
            color    = {255, 255, 255},
            allowAtC = true,

            players  = {
                '76561198050038534',
                '76561198005898017'
            }
        },

        vip = {
            tag     = 'VIP',
            color   = {95, 255, 95},
            allowAtC = true,

            players = {}
        },

        player = {
            color = {255, 220, 0},
            allowAtC = false,
        }
    }
}
