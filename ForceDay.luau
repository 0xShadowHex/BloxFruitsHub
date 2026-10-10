local Lighting = game:GetService("Lighting")
local ForceDayConnection = nil

function ForceDay()
    if ForceDayConnection then
        ForceDayConnection:Disconnect()
    end

    Lighting.ClockTime = 14

    ForceDayConnection = Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
        Lighting.ClockTime = 14
    end)
end
