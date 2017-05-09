function SoftCodeHandler_PlaySound(SoundID)
if SoundID ~= 255
    FakeSoundServer('Play', SoundID);
else
    FakeSoundServer('StopAll');
end