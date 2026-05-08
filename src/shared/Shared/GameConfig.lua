-- Shared hacky sack MVP settings. Both server and client can read this module.
local GameConfig = {
    IntermissionDuration = 5,
    RoundDuration = 45,
    PostRoundDelay = 3,

    DropTimeout = 8,
    CoinsPerJuggle = 1,

    SackSize = 1.2,
    SackBounceVelocity = 35,
    SackColor = Color3.fromRGB(245, 210, 75),
    JugglePromptDistance = 12,
}

return GameConfig
