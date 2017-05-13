%{
----------------------------------------------------------------------------

This file is part of the Sanworks Bpod repository
Copyright (C) 2016 Sanworks LLC, Sound Beach, New York, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}
function TwoTonePavlovian
% This protocol is a starting point for a two sound pavlovian task
% Each trial starts with a variable 'No Lick period',
% during which the subject has to wait for the cue to arrive,
% Cues can be one of three cues A, B, C, or no cue
% followed by a delay
% followed by a reinforcer - water, white noise or nothing, with
% user-defined probablities
% Written by Priyanka Gupta, 5/2017.
%
% SETUP
% You will need:
% - A Bpod Lick port (or equivalent) with a lick detector and water spout.
% > Connect the Lick port in the box to Bpod Port#1.
% > Make sure the liquid calibration tables for port 1 has
%   calibration curves with several points surrounding 3ul.
% - An Arduino Due, a 2.2uF, 1uF capacitors, 2.2K resistor and powered speakers
% > Connect the sound trigger A to Bpod Port#2.
% > Connect the sound trigger B to Bpod Port#3.
% > Connect the sound trigger C to Bpod Port#4.
% > Connect the white noise trigger to Bpod Port#5.
% > Connect the scanimage start trigger to Bpod Port#6.
% > Connect the scanimage next trigger to Bpod Port#7.


global BpodSystem
global LickRasterWindow
%global LickPlotTrialCounts
global numplots
global S

%% Define parameters
%S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S

% load settings from the previous session
Allfiles = dir(fileparts(BpodSystem.DataPath));
try
    LastSession = load(fullfile(fileparts(BpodSystem.DataPath),Allfiles(end).name));
    S = LastSession.SessionData.TrialSettings(end);
catch % If settings file was an empty struct, populate struct with default settings
    TwoTonePavlovian_TaskParameters()
end
clear LastSession Allfiles

% Initialize parameter GUI plugin
PriyankaBpodParameterGUI('init', S);
BpodSystem.Pause = 1;
HandlePauseCondition;
S = PriyankaBpodParameterGUI('sync', S);

%% Define trials
MaxTrials = S.GUI.MaxTrials;
pCuedTrials = 1 - S.GUI.pUnCuedReward - S.GUI.pUnCuedPunishment;
pCues = str2num(S.GUI.pCues_ABC);
pRewards = str2num(S.GUI.pRewards_ABC);
pPunish = str2num(S.GUI.pPunishment_ABC);
nCuedTrials = ceil(ceil(MaxTrials*pCuedTrials)*pCues);

% Trialtypes
% 0 = uncued trials
% 1,2,3 = cue A,B,C
%TrialTypes = ceil(rand(1,1000)*2);
TrialTypes =   [zeros(1,ceil(MaxTrials*S.GUI.pUnCuedReward)), ...
                zeros(1,ceil(MaxTrials*S.GUI.pUnCuedPunishment)), ...
                ones(1,nCuedTrials(1)), ...
                2*ones(1,nCuedTrials(2)), ...                
                3*ones(1,nCuedTrials(3)), ...
                ];

% randomize the trial list
random_order = randperm(numel(TrialTypes));
TrialTypes = TrialTypes(random_order)';

for i = 1:3
    Outcomes.(['Cue',num2str(i)]) = [ones(1,ceil(pRewards(i)*nCuedTrials(i))), ...
                -1*ones(1,ceil(pPunish(i)*nCuedTrials(i))), ...
                zeros(1,nCuedTrials(i) - (ceil(pRewards(i)*nCuedTrials(i)) + ceil(pPunish(i)*nCuedTrials(i))))];
    Outcomes.(['Cue',num2str(i)]) = Outcomes.(['Cue',num2str(i)])(randperm(nCuedTrials(i)));
end

ReinforcerTypes = [ones(1,ceil(MaxTrials*S.GUI.pUnCuedReward)), ...
                -1*ones(1,ceil(MaxTrials*S.GUI.pUnCuedPunishment)), ...
                Outcomes.Cue1, Outcomes.Cue2, Outcomes.Cue3];
ReinforcerTypes = ReinforcerTypes(random_order);
clear Outcomes

RewardedTrials = TrialTypes;
RewardedTrials(find(ReinforcerTypes~=1)) = NaN;

PunishedTrials = TrialTypes;
PunishedTrials(find(ReinforcerTypes~=-1)) = NaN;

ReinforcerTypes(ReinforcerTypes==-1) = 2;

BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
BpodSystem.Data.Outcomes = []; % the outcome of each trial and anticipatory lick state will be added here

%% Initialize plots
BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', [200 200 1000 600],...
    'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');

numplots = numel(find(pCues));

%BpodSystem.GUIHandles.SideOutcomePlot = axes('Position', [.075 .8 .89 .15]);
BpodSystem.GUIHandles.SideOutcomePlot = subplot(3,numplots,[1:numplots]);
%BpodNotebook('init');

for i = 1:3
    if pCues(i) > 0
        BpodSystem.GUIHandles.(['Cue',num2str(i),'ReinforcerPlot']) = subplot(3,numplots,numplots + i);
        BpodSystem.GUIHandles.(['Cue',num2str(i),'NoReinforcerPlot']) = subplot(3,numplots,2*numplots + i);
    end
end
%LickPlotTrialCounts = zeros(2,3);

PavlovianTrialTypeOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,'init',{TrialTypes, RewardedTrials, PunishedTrials});

% LickRasterWindow = S.GUI.ITIDuration + S.GUI.CueDuration + ...
%                     S.GUI.ReinforcerDelay + S.GUI.NoiseDuration;

LickRasterWindow = [-1 4];

PavlovianLickRasterPlot(BpodSystem.GUIHandles, 'init');

StateToAlignTo = S.GUI.AlignLicksTo;

% Program Fake Sound Server
%SoundSamplingRate = 48000;  % Sound card sampling rate;
SoundSamplingRate = 192000;
AttenuationFactor = .5;
PunishSound = (rand(1,SoundSamplingRate*.5)*AttenuationFactor) - AttenuationFactor*.5;

% Program sound server
FakeSoundServer('init')
FakeSoundServer('Load', 2, 0);
FakeSoundServer('Load', 3, PunishSound);
% Set soft code handler to trigger sounds
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

%% Main trial loop
for currentTrial = 1:MaxTrials
    S = PriyankaBpodParameterGUI('sync', S); % Sync parameters with PriyankaBpodParameterGUI plugin
    %R = GetValveTimes(S.GUI.RewardAmount, [1 3]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts
    
    ValveTime = GetValveTimes(S.GUI.RewardAmount, [4]);
    
    % compute ITI and delay durations
    ITIRange = str2num(S.GUI.ITI_offset_mean_max);
    CurrentITI = ITIRange(3)+1;
%     while CurrentITI > (max(ITIRange) - min(ITIRange))
%         CurrentITI = exprnd(ITIRange(2) - ITIRange(1));
%     end
    while CurrentITI > ITIRange(3)
        CurrentITI = exprnd(ITIRange(2));
    end
    CurrentITI = CurrentITI + ITIRange(1);
    DelayRange = str2num(S.GUI.Delay_offset_mean_max);
    CurrentDelay = DelayRange(3)+1;
%     while CurrentDelay > (max(DelayRange) - min(DelayRange))
%         CurrentDelay = exprnd(DelayRange(2) - DelayRange(1));
%     end
    while CurrentDelay > DelayRange(3)
        CurrentDelay = exprnd(DelayRange(2));
    end
    CurrentDelay = CurrentDelay + DelayRange(1);
    
    CurrentCueDuration = S.GUI.CueDuration; 
    
    switch ReinforcerTypes(currentTrial) % Determine trial-specific state matrix fields
        case 0
            Reinforcer = 'NoReinforcer';
        case 1
            Reinforcer = 'Reward';
            S.GUI.WaterDispensed = S.GUI.WaterDispensed + S.GUI.RewardAmount;
            disp(S.GUI.WaterDispensed)
        case 2
            Reinforcer = 'WhiteNoise';
            FakeSoundServer('Load', 3, S.GUI.NoiseAmplitude*PunishSound);
    end
    
    if TrialTypes(currentTrial)>0 % Determine trial-specific state matrix fields
        AllFreq = str2num(S.GUI.ToneFrequencies);
        ToneFreq = AllFreq(TrialTypes(currentTrial));
        [MySound] = GeneratePureTones(ToneFreq, SoundSamplingRate, S.GUI.CueDuration, S.GUI.ToneAmplitude);
        FakeSoundServer('Load', 1, MySound');
        CueAction = {'SoftCode', 1};
    else
        CueAction = {};
    end
    
    if S.GUI.Sync2p
        Trigger2pAction = {'BNCState', 1};
    else
        Trigger2pAction = {};
    end
    
    sma = NewStateMatrix(); % Assemble state matrix
    
    if S.GUI.AllowLicksDuringITI % restart ITI if animal licks, else move to Cue State
        sma = AddState(sma, 'Name', 'ITI', ...
        'Timer', CurrentITI,...
        'StateChangeConditions', {'Tup', 'Cue'},...
        'OutputActions', Trigger2pAction);
    else
        sma = AddState(sma, 'Name', 'ITI', ...
        'Timer', CurrentITI,...
        'StateChangeConditions', {'Port4In', 'ITI', 'Tup', 'Cue'},...
        'OutputActions', Trigger2pAction); 
    end
    
    sma = AddState(sma, 'Name', 'Cue', ...
        'Timer', S.GUI.CueDuration,...
        'StateChangeConditions', {'Tup', 'Delay'},...
        'OutputActions', CueAction); 
    sma = AddState(sma, 'Name', 'Delay', ...
        'Timer', CurrentDelay,...
        'StateChangeConditions', {'Tup', Reinforcer},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'WhiteNoise', ...
        'Timer', S.GUI.NoiseDuration,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {'SoftCode', 3, 'WireState', 8});
    sma = AddState(sma, 'Name', 'NoReinforcer', ...
        'Timer', S.GUI.NoiseDuration,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'Reward', ...
        'Timer', ValveTime,...
        'StateChangeConditions', {'Port4In', 'Drinking', 'Tup', 'DrinkingGrace'},...
        'OutputActions', {'ValveState', 8});
    sma = AddState(sma, 'Name', 'Drinking', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port4Out', 'DrinkingGrace'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'DrinkingGrace', ...
        'Timer', .5,...
        'StateChangeConditions', {'Tup', 'exit', 'Port4In', 'Drinking'},...
        'OutputActions', {});

    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        %BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        %BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        BpodSystem.Data.TrialTypes(currentTrial) = 10*TrialTypes(currentTrial) + ReinforcerTypes(currentTrial); % Adds the trial type and reinforcer type of the current trial to data
        UpdateSideOutcomePlot(currentTrial,ReinforcerTypes(currentTrial),TrialTypes,ReinforcerTypes,...
            RewardedTrials, PunishedTrials, BpodSystem.Data,StateToAlignTo);
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        FakeSoundServer('close');
        return
    end
    
end

function UpdateSideOutcomePlot(currentTrial,currentTrialType,TrialTypes,ReinforcerTypes,RewardedTrials,PunishedTrials,Data,StateToAlignTo)
global BpodSystem
%global LickPlotTrialCounts

% compute trial outcome and extract lick timestamps
[LickEvents, OtherEvents] = ExtractLickTimeStamps(currentTrialType,currentTrial,StateToAlignTo);

% Update Trial Outcome Plot
PavlovianTrialTypeOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,'update',Data.nTrials+1,TrialTypes,RewardedTrials,PunishedTrials);

if TrialTypes(currentTrial)>0
% Update Lick Raster Plot
% determine which subplot to refresh based on 
% the current Cue type and reinforcer type
    if ReinforcerTypes(currentTrial) > 0
        AxesTag = BpodSystem.GUIHandles.(['Cue',num2str(TrialTypes(currentTrial)),'ReinforcerPlot']);
        %LickPlotTrialCounts(1,TrialTypes(currentTrial)) = LickPlotTrialCounts(1,TrialTypes(currentTrial)) + 1;
    else
        AxesTag = BpodSystem.GUIHandles.(['Cue',num2str(TrialTypes(currentTrial)),'NoReinforcerPlot']);
        %LickPlotTrialCounts(2,TrialTypes(currentTrial)) = LickPlotTrialCounts(2,TrialTypes(currentTrial)) + 1;
    end

PavlovianLickRasterPlot(BpodSystem.GUIHandles, 'update', AxesTag, LickEvents, OtherEvents, ReinforcerTypes(currentTrial),currentTrial);
end
