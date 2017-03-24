
function generalWhisker

global BpodSystem

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S

%JPL - temp storage, generated from 'testBPodHandleTransfer', of handles
%and callbacks from JustinNoDisrimn

%also this should go into some kind of config dialog where user decides if
%they are using a solo protocol or not

load('~/Documents/github/Bpod/Protocols/generalWhisker/owner_classes.mat');             %loads as 'owner_classes'
load('~/Documents/github/Bpod/Protocols/generalWhisker/owner_classes_full.mat');        %loads as 'owner_classes_full'
load('~/Documents/github/Bpod/Protocols/generalWhisker/callbacks.mat');                 %loads as 'callbacks'
%loading 'param_struct' will load all the gui elemns! neat.
load('~/Documents/github/Bpod/Protocols/generalWhisker/param_struct.mat');              %loads as 'param_struct'
load('~/Documents/github/Bpod/Protocols/generalWhisker/param_vals.mat');                %loads as 'param_vals'
load('~/Documents/github/Bpod/Protocols/generalWhisker/funclist.mat');                  %loads as funclist, equiv to 'private_solofunction_list'
load('~/Documents/github/Bpod/Protocols/generalWhisker/settings.mat');                  %loads as settings

global private_solofunction_list;  %this is populated by SoloFunction/SoloFunctionAddVars, etc
global private_soloparam_list;     %this is populated by SoloParamHandle/SoloParam, etc
global callbacks;                  
global settings;

private_solofunction_list = funclist;
private_soloparam_list = param_struct';
callbacks=callbacks;

%NOTE - the 'owners' in these loaded structs are all going to be the class from the
%       ORIGINAL solo protocol we are porting. Eventually will need to have
%       these be changed, minimally to remove the @, maximally to
%       completely change the protocol name, when we create the structs
%
%       FOR NOW WE WILL HACK IT BY JUST CHANGING @JustinNoDiscrimn which we
%       are using as our example to 'generalWhisker' manually

origProtClass='@JustinNoDiscrimn';
origProtFunc='JustinNoDiscrimn';    %default
newProtName=mfilename;              %default


%first translate the SoloParam fielsd into structures 
for h=1:1:numel(param_struct)
    if strcmp(origProtClass,param_struct{h}.param_owner)
        param_struct{h}.param_owner=mfilename;
    end
    if ~isempty(strfind(param_struct{h}.param_fullname,origProtFunc))
        param_struct{h}.param_fullname=[mfilename '_' param_struct{h}.param_name];
    end
end
%and maintain a seperate list of [SoloParam].values
for h=1:1:numel(param_vals)
    if isa(param_vals{h},origProtFunc) %sort of a hack
        param_vals{h}=struct(param_vals{h});
    end
end

%now translate the Solofunction data
idx=find(strcmp(origProtClass,private_solofunction_list(:,1))); %index of functions matching our orig protocol class name
for h=1:1:numel(idx)
    private_solofunction_list(idx(h),1) = {newProtName};
    %now index function files that match our original protcol;
    %second column has function names
    idx2=find(strcmp(origProtFunc,private_solofunction_list{idx(h),2}(:,1)));
    for b=1:1:numel(idx2)
        private_solofunction_list{idx(h),2}(idx2(b),1) = {newProtName};
    end
    
end

%for any ui that has a callback (which will be go through
%'generic_callback', set to 'translation_callback', which will call the
%appropriate m-file with the proper string arg, from the 'callbacks' struct



keyboard


%assignin the new non-Solo handles
GetSoloFunctionArgs;

%%%%settings for inclusion of SoloParams into the BPod Parameters GUI
%note: an explicit nan is required, NOT empty cells, for igoring a fields

%'include' is a struct for specifing what properties of soloparamhandles to
%use to sort those we want to include in the Bpod Parameters GUI
include.soloParamProps.param_owner = {nan};
include.soloParamProps.param_name = {nan};
include.soloParamProps.param_fullname = {nan};
include.soloParamProps.callback_fn = {nan};
include.soloParamProps.callback_on_load = {nan};
include.soloParamProps.type = {'saveble_nongui'}; %probaly important
%ghandles are probably special, as they themselves have lots of propertyes
%we might want to sort on
include.soloParamProps.ghandle = {nan};
%
include.soloParamProps.lhandle = {nan};
include.soloParamProps.listpos = {nan};
include.soloParamProps.autoset_string = {nan};
include.soloParamProps.saveable = {nan};
include.soloParamProps.save_with_settings = {nan};
include.soloParamProps.default_reset_value = {nan};
include.soloParamProps.UserData = {nan};
include.soloParamProps.value = {nan};
include.soloParamProps.value_history = {nan};

%also have a special field for sorting on ghandle properties...but how to
%do this since different GUI elemn types will have different
%properties...although maybe not since they are all of the 'uicontrol' type?
%the only excpetions to this are a few things i added like 'uimenu' for
%messing with menubars, which i wont need to do anymore

%...so the handle props availble to use as filters are going to be those from
%'uicontrols' ONLY

%NOTE: if a '~' string is included before a string, this will be EXCLUDED

include.gHandleProps.Style = {'menu';'text'}; %%this is probably the most important one
include.gHandleProps.BackgroundColor = {nan};
include.gHandleProps.BeingDeleted = {nan};
include.gHandleProps.BusyAction = {nan};
include.gHandleProps.ButtonDownFcn = {nan};
include.gHandleProps.CData = {nan};
include.gHandleProps.Callback = {nan};
include.gHandleProps.Children = {nan};
include.gHandleProps.CreateFcn = {nan};
include.gHandleProps.DeleteFcn = {nan};
include.gHandleProps.Enable = {nan};
include.gHandleProps.Extent = {nan};
include.gHandleProps.FontAngle = {nan};
include.gHandleProps.FontName = {nan};
include.gHandleProps.FontSize = {nan};
include.gHandleProps.FontUnits = {nan};
include.gHandleProps.FontWeight = {nan};
include.gHandleProps.ForegroundColor = {nan};
include.gHandleProps.HandleVisibility = {nan};
include.gHandleProps.HorizontalAlignment = {nan};
include.gHandleProps.Interruptible = {nan};
include.gHandleProps.KeyPressFcn = {nan};
include.gHandleProps.KeyReleaseFcn = {nan};
include.gHandleProps.ListboxTop = {nan};
include.gHandleProps.Max = {nan};
include.gHandleProps.Min = {nan};
include.gHandleProps.Parent = {nan};
include.gHandleProps.Position = {nan};
include.gHandleProps.SliderStep = {nan};
include.gHandleProps.String = {nan};
include.gHandleProps.Tag = {nan};
include.gHandleProps.TooltipString = {nan};
include.gHandleProps.Type = {nan};
include.gHandleProps.UIContextMenu = {nan};
include.gHandleProps.Units = {nan};
include.gHandleProps.UserData = {nan};
include.gHandleProps.Value = {nan};
include.gHandleProps.Visible = {nan};

debug=1; %bypass for now and add all to the GUI

%Slow dumb way to do this, but meh. Hash it?
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    fnames_props=fieldnames(include.soloParamProps);
    fnames_hprops=fieldnames(include.gHandleProps);
    %loop through SoloParamHandles
    for i=1:1:numel(param_struct)
        if debug==0
            %UNDER CONSTRUCTION
            %loop through settings props
            for g=1:1:numel(fnames_props)
                if isnan(cell2mat(include.soloParamProps.(fnames_props{g})))
                    %nan means include
                    setting=include.soloParamProps.(fnames_props{g});
                else
                    %loop through all elements in the settings cell
                    for v=1:1:numel(include.gHandleProps.(fnames_props{g}))
                        
                    end
                    
                end
            end
            %loop through settings handle props
            for g=1:1:numel(fnames_hprops)
                if ~isnan(cell2mat(include.gHandleProps.(fnames_hprops{g})))
                    setting=include.soloParamProps.(fnames_hprops{g});
                end
            end
        end
        %add parameter to GUI
        %exclude types that are incompatible with the BPod GUI
        if isnumeric(param_struct{i}.value) || ischar(param_struct{i}.value)
            %obj.GUI.(param_struct{i}.param_name) = param_struct{i}.value;
            S.GUI.(param_struct{i}.param_name) = param_vals{i};
        else %add the parameter but not to the GUI since it doesnt play well with arbitraty types
            %obj.NONGUI.(param_struct{i}.param_name) = param_struct{i}.value;
            S.NONGUI.(param_struct{i}.param_name) = param_vals{i};
        end
        
    end
    
end

% Initialize parameter GUI plugin
BpodParameterGUI('init', S);

%% Define trials
MaxTrials = 1000;
TrialTypes = ceil(rand(1,1000)*2);
BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.

%% Initialize plots
%JPL - code for BPod 'SideOutcomePlot' figure

%JPL - Bpod notebook
BpodNotebook('init');

%% Main trial loop
%JPL - this is the StateMatrixSection + Running ection
%'obj' needs to look like this:
%   obj = class(struct, mfilename, soundmanager,sessionmodel,distribui,...
%        soundtable,soundui,reinforcement,clickstable,water,saveload,pokesplot);
%   which used to be called at the top of 'JustinNoDiscrimn' to create an
%   obj and load in some useful Solo plugins

%Can try to pull this manually after given a Solo Protcol directory, but
%lets have a default like below in case we fail
obj = struct('mfilename',mfilename, 'soundmanager',soundmanager,'sessionmodel',sessionmodel,...
    'distribui',distribui,'soundtable',soundtable,'soundui',soundui,...
    'reinforcement',reinforcement,'clickstable',clickstable,'water',water,...
    'saveload',saveload,'pokesplot',pokesplot);

for currentTrial = 1:MaxTrials
    
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    
    %figure out params for next trials
    TrialStructureSection(obj,'choose_next_trial_type');
    
    % JPL - ignoring MotorsSection for now, but at least for Svoboda/Magee
    % protocols, there are serial port calls in here that arent specified
    % in any kind of i/io setting. This will have to be handled manually
    
    %MotorsSection([],'move_next_side');
    
    %JPL -  return sma from the State Matrix Section! This will require the
    % dispatcher('send_assembler', sma, 'final_state') call at the end to be commented out!
    
    sma = StateMatrixSection(obj,'update');
    
    %add the settings obj into the sma for kicks.
    sma=struct(sma);
    sma.settings=settings.settings;
    %translate SMA to bpod-style
    sma = translateSMA(sma); 
    
    %%% Run the trial
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        UpdateSideOutcomePlot(TrialTypes, BpodSystem.Data);
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end
end

function UpdateSideOutcomePlot(TrialTypes, Data)
global BpodSystem
Outcomes = zeros(1,Data.nTrials);
for x = 1:Data.nTrials
    if ~isnan(Data.RawEvents.Trial{x}.States.Drinking(1))
        Outcomes(x) = 1;
    elseif ~isnan(Data.RawEvents.Trial{x}.States.Punish(1))
        Outcomes(x) = 0;
    elseif ~isnan(Data.RawEvents.Trial{x}.States.CorrectEarlyWithdrawal(1))
        Outcomes(x) = 2;
    else
        Outcomes(x) = 3;
    end
end
SideOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,'update',Data.nTrials+1,2-TrialTypes,Outcomes);
