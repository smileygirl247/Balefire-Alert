-- Create a frame to listen for events
local frame = CreateFrame("Frame")

-- Create a frame for the skull texture
local skullFrame = CreateFrame("Frame", nil, UIParent)
skullFrame:SetSize(256, 256)  -- Size of the skull
skullFrame:SetPoint("CENTER", UIParent, "CENTER")  -- Position at the center of the screen
skullFrame:Hide()  -- Initially hidden

-- Add the skull texture to the frame
local skullTexture = skullFrame:CreateTexture(nil, "BACKGROUND")
skullTexture:SetAllPoints()
skullTexture:SetTexture("Interface\\AddOns\\Balefire-Beware\\textures\\skull.tga")  -- Path to the skull image
skullTexture:SetAlpha(0.35)

-- Global count variable
local globalCount = 0

-- Animation variables
local alphaValue = 0
local increment = 0.010  -- How much the alpha changes per tick
local pulseDuration = 0.01  -- Time between each alpha change (seconds)
local tickerHandle = nil  -- Variable to store the ticker handle

-- Warning sound
local warningSoundPath = ("Interface\\AddOns\\Balefire-Beware\\warning-siren.wav")

-- Function to update the alpha for pulsing effect
local function PulseAnimation()
    alphaValue = alphaValue + increment

    -- Reverse the direction when fully visible or fully transparent
    if alphaValue >= 0.32 then
        alphaValue = 0.32
        increment = -increment
    elseif alphaValue <= 0.06 then
        alphaValue = 0.06
        increment = -increment
    end

    skullTexture:SetAlpha(alphaValue)
end


-- Function to handle debuff events
local function OnEvent(self, event, ...)
    if event == "UNIT_AURA" or event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit = ...
        if unit == "player" then
            -- Check if the player is a mage
            local _, class = UnitClass("player")
            if class == "MAGE" then
                local balefireBoltFound = false
                -- Check for debuff "Balefire Bolt"
                for i = 1, 40 do
                    local name, _, count = UnitDebuff("player", i)
                    if name == "Balefire Bolt" then
                      globalCount = count
                      balefireBoltFound = true
                      if count == 4 then
                          balefireBoltFound = true
                          if not skullFrame:IsShown() then
                            print('|cFFFF0000WARNING: Stop casting Balefire!!! |r')
                            skullFrame:Show()  -- Show the skull
                            if not tickerHandle then
                              tickerHandle = C_Timer.NewTicker(pulseDuration, PulseAnimation)
                              PlaySoundFile(warningSoundPath, "Master")
                            end
                            return
                          end
                      end
                    end
                end
                if not balefireBoltFound then
                  globalCount = 0
                  skullFrame:Hide()  -- Hide the skull if the debuff is no longer present
                  -- Cancel the ticker if it's running
                  if tickerHandle then
                    tickerHandle:Cancel()
                    tickerHandle = nil
                  end
                end

                if globalCount == 4 then
                  if event == "UNIT_SPELLCAST_START" then
                    -- Check if the player is casting "Balefire Bolt"
                    local spellName = GetSpellInfo(429310)  -- You may need to adjust the spell index if necessary
                    if balefireBoltFound and spellName == "Balefire Bolt" and UnitCastingInfo("player") == spellName then
                        if tickerHandle then
                          tickerHandle:Cancel()
                          tickerHandle = nil
                        end
                        skullTexture:SetAlpha(0.8)
                        PlaySoundFile(warningSoundPath, "Master")
                    elseif balefireBoltFound then
                      if not tickerHandle then
                        tickerHandle = C_Timer.NewTicker(pulseDuration, PulseAnimation)
                      end
                    end
                  end
  
                  if event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_SUCCEEDED" then
                    if balefireBoltFound then
                      if tickerHandle == nil then
                        tickerHandle = C_Timer.NewTicker(pulseDuration, PulseAnimation)
                      end
                    end
                 end
                end

            end
        end
    end
end

-- Register the events
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_STOP")
frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:SetScript("OnEvent", OnEvent)
