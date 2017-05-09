function TwoTonePavlovian_TaskParameters()
% load Task parameters 
% written by Quentin
% modified by Priyanka

global S
    S.GUI.WaterDispensed = 0;

    % Training phase
    S.Names.TrainingPhase = {'CueA-Reward', 'CueB-Reward', 'CueA-Reward-CueB-Punish' , 'CueA-Punish-CueB-Reward', 'CueA-CueB-CueC'};
    S.GUI.TrainingPhase = 5;
    S.GUIMeta.TrainingPhase.Style = 'popupmenu';
    S.GUIMeta.TrainingPhase.String = S.Names.TrainingPhase;
 
%     S.GUI.Duration = 'Temporal settings [seconds]';
%     S.GUIMeta.Duration.Style = 'text';
    S.GUI.CueDuration = 1; %s, duration of the sound stimulus
    S.GUI.ToneAmplitude = 0.005;
    S.GUI.NoiseAmplitude = 0.1;
    S.GUI.ToneFrequencies = [4000 8000 12000];
    S.GUI.Delay_offset_mean_max = [0.5 1 2]; %s, How long after the Cue should the reinforcer be presented
    S.GUI.RewardAmount = 4; %s
    S.GUI.NoiseDuration = 1; %s
    S.GUI.ITI_offset_mean_max = [2 3 5]; %s

%     S.GUI.CueProbabilities = 'Cue Probabilities [A B C]';
%     S.GUIMeta.CueProbabilities.Style = 'text';
    S.GUI.pCues_ABC = [0.49 0.49 0.02]; % 3 cues - total must sum to 1
    S.GUI.MaxTrials = 300;
     
%     S.GUI.RewardProbabilities = 'Reinforcement Probabilities [A B C]';
%     S.GUIMeta.RewardProbabilities.Style = 'text';
    S.GUI.pRewards_ABC = [1 0.2 0]; % chance of getting a reward following a given Cue type
    S.GUI.pPunishment_ABC = [0 0 0]; % chance of getting a whitenoise following a given Cue type
    S.GUI.pUnCuedReward = 0; % fraction of trials when +ve reinforcer is presented without a preceding Cue
    S.GUI.pUnCuedPunishment = 0; % fraction of trials when -ve reinforcer is presented without a preceding Cue
    
%     S.GUI.Conditionals = 'Conditionals';
%     S.GUIMeta.Conditionals.Style = 'text';
    S.GUI.Sync2p = 1;
    S.GUIMeta.Sync2p.Style = 'checkbox';
    S.GUI.AllowLicksDuringITI = 1; % Is the subject required to withhold licking during the ITI
    S.GUIMeta.AllowLicksDuringITI.Style = 'checkbox';
    
    S.GUI.AlignLicksTo = 1;
    S.Names.AlignLicksTo = {'CueStart', 'DelayStart', 'ReinforcerStart'};
    S.GUIMeta.AlignLicksTo.Style = 'popupmenu';
    S.GUIMeta.AlignLicksTo.String = S.Names.AlignLicksTo;
end
