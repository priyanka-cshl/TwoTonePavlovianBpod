function [MyTone] = GeneratePureTones(ToneFreq, SamplingRate, ToneDuration, ToneAmplitude)
 
% SamplingRate = 41000; % Hz
% ToneDuration = 2; % sec
% ToneFreq = 4000; %Hz
% adjust sound duration to hack emulator mode in Bpod
ToneDuration = ToneDuration*0.25; % 48Khz/192Khz
toneVec = 1/SamplingRate:1/SamplingRate:ToneDuration; % Here go the tones
%tones = (sin(toneVec'*freqs*2*pi)).*Envelope; % Here are the enveloped tones as a matrix
MyTone = ToneAmplitude*(sin(toneVec'*ToneFreq*2*pi)); % Here are the enveloped tones as a matrix

% handle amplitude ramping 
rampDuration = 0.01; % s
rampVec = linspace(0, 1, ceil(SamplingRate*rampDuration));
ampVec = 1 + 0*MyTone;
ampVec(1:length(rampVec)) = rampVec;
ampVec(end-length(rampVec)+1:end) = fliplr(rampVec);
MyTone = MyTone.*ampVec;
end