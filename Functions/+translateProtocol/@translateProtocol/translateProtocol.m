%JPL - 2017 - translateProtocol, now a class
%
%takes Solo/Bcontrol Protocol and translates to a Bpod protocol

classdef translateProtocol < handle
    
    properties
        inSMA                       %SMA to be translated
        outSMA                      %type of SMA to translate to
        funclist                    %olo functions from original protocol
        param_struct                %struct version of 'SoloParam'
        param_vals                  %values for the handles
        owner_classes               %owner classes for the 'SoloParams'
        owner_classes_full          %slightly different format for above. Necessary?
        callbacks                   %callbacks for the 'SoloParams'
        settings                    %actual settings
        settingsFile                %name of settings file
        soloDir                     %main solo directory
        protocolName                %main dir to be translted
        isClass                     %flag for if protocol is a class
    end
    
    methods
        
        function obj=translateProtocol(varargin)
            %main constructor for class
            
            %NOTE: this only handles solo gen2 (dispatcher) stuff for the moment

            %% check inputs are correct
            if numel(varargin)==0
                error('translateSoloParams.getSoloParams:: must be called with at least 1 argument')
            elseif numel(varargin) == 1
                warning('translateSoloParams.getSoloParams:: assuming pwd is your main Solo directory')
                obj.soloDir=pwd;
                obj.protocolName=varargin{2};
                if ~isdir([pwd filesep obj.protocolName]);
                    warning('translateSoloParams.getSoloParams:: protocol directory not on path')
                    warning('translateSoloParams.getSoloParams:: attempting to cd to directory')
                    try
                        cd obj.protocolName
                    catch
                        %let matlab throw the usual errors
                    end
                end
            elseif numel(varargin) == 2
                obj.soloDir=varargin{1};
                obj.protocolName=varargin{2};
                if ~isdir([obj.soloDir filesep obj.protocolName])
                    warning('translateSoloParams.getSoloParams:: protocol directory not on path')
                    warning('translateSoloParams.getSoloParams:: attempting to cd to directory')
                    try
                        cd obj.protocolName
                    catch
                        %let matlab throw the usual errors
                    end
                end
            end
            
            if ~isempty(strfind(obj.protocolName,'@'))
                obj.isClass=1;
            else
                obj.isClass=0;
            end
            
            %%
            %make sure the fill directory structure under obj.soloDir is on
            %the path
            
            
            %% 
            %copy the protcol directory to the Bpod protocol directory
            %then cd to the new protocol directory to avoid confusion with
            %the stuff in the original
            
            %JPL - temporarily disabling this for the moment so I can work
            %without bpod
            
            %JPL - need to have a catch for if the dir already exists, with
            %an option dialog to overwrite 
            
            
            %global BpodSystem
            %try
            %    copyfile([obj.soloDir filesep 'Protocols' filesep obj.protocolName],[BpodSystem.Path.ProtocolFolder filesep obj.protocolName])
            %catch
            %   warning('translateProtocol.translateProtocol::did you start bpod yet?')
            %   return
            %end
            
            %JPL - temporary hard cd
            cd  '/Users/littlej/Documents/github/Bpod/Protocols/@JustinNoDiscrimn'
            
            
            %%
            %try and load a settings file
            
            if numel(varargin) == 3
                %third arg is optional, for specifying a settings file
                obj.settingsFile=varargin{3};
            else
                obj.settingsFile='';
            end
            
            getBControlSettings(obj)

            %%
            
            %port over the soloparam stuff
            %will initialize the gui for the protocol, but close it after
            getSoloParams(obj)
            
            %build protocol m-file for Bpod from main Solo protocol file
            buildMfile(obj)
            
            %copy the protocols files into a the Bpod settings directory,
            %and assignin the vars to the workspace
            assigninParams(obj)
        end
        
        function buildMfile(obj)
            
            %%build struct to mimic a solo protocol object
            %'obj' needs to look like this:
            %   obj = class(struct, mfilename, soundmanager,sessionmodel,distribui,...
            %        soundtable,soundui,reinforcement,clickstable,water,saveload,pokesplot);
            %   which used to be called at the top of 'JustinNoDiscrimn' to create an
            %   obj and load in some useful Solo plugins
            
            %Can try to pull this manually after given a Solo Protcol directory, but
            %lets have a default like below in case we fail
            
            %FYI - NEED TO WRITE THIS IN TO THE NEW PROTOCOL!
            paramObj = struct('mfilename',mfilename, 'soundmanager',soundmanager,'sessionmodel',sessionmodel,...
                'distribui',distribui,'soundtable',soundtable,'soundui',soundui,...
                'reinforcement',reinforcement,'clickstable',clickstable,'water',water,...
                'saveload',saveload,'pokesplot',pokesplot);
            
        end
        
        function assigninParams(obj)
            
            if isempty(strfind('@',obj.protocolName));
                origProtClass=['@' obj.protocolName];
                origProtFunc=obj.protocolName;
            else
                origProtClass=obj.protocolName;
                origProtFunc=obj.protocolName;
            end
            
            
            %first translate the SoloParam fielsd into structures
            for h=1:1:numel(obj.param_struct)
                if strcmp(origProtClass,obj.param_struct{h}.param_owner)
                    obj.param_struct{h}.param_owner=mfilename;
                end
                if ~isempty(strfind(obj.param_struct{h}.param_fullname,origProtFunc))
                    obj.param_struct{h}.param_fullname=[mfilename '_' obj.param_struct{h}.param_name];
                end
            end
            
            %and maintain a seperate list of [SoloParam].values
            for h=1:1:numel(obj.param_vals)
                if isa(obj.param_vals{h},origProtFunc) %sort of a hack
                    obj.param_vals{h}=struct(obj.param_vals{h});
                end
            end
            
            %JPL - saving this for now just in case
            
%             %now translate the Solofunction data
%             idx=find(strcmp(origProtClass,private_solofunction_list(:,1))); %index of functions matching our orig protocol class name
%             for h=1:1:numel(idx)
%                 private_solofunction_list(idx(h),1) = {newProtName};
%                 %now index function files that match our original protcol;
%                 %second column has function names
%                 idx2=find(strcmp(origProtFunc,private_solofunction_list{idx(h),2}(:,1)));
%                 for b=1:1:numel(idx2)
%                     private_solofunction_list{idx(h),2}(idx2(b),1) = {newProtName};
%                 end
%                 
%             end

             %now translate the Solofunction data
             idx=find(strcmp(origProtClass,obj.funclist(:,1))); %index of functions matching our orig protocol class name
             for h=1:1:numel(idx)
                 obj.funclist(idx(h),1) = {newProtName};
                 %now index function files that match our original protcol;
                 %second column has function names
                 idx2=find(strcmp(origProtFunc,obj.funclist{idx(h),2}(:,1)));
                 for b=1:1:numel(idx2)
                     obj.funclist{idx(h),2}(idx2(b),1) = {newProtName};
                 end
                 
             end

            
            %for any ui that has a callback (which will be go through
            %'generic_callback', set to 'translation_callback', which will call the
            %appropriate m-file with the proper string arg, from the 'callbacks' struct
            
            %assignin the new non-Solo handles
            
            GetSoloFunctionArgs;
            
            
        end
        
        function obj=translateSMA(varargin)
            %begin translation of the SMA for the protocol.
            %will depend on the type of the input SMA and output SMA.
            
            if isempty(varargin)
                obj.outSMA = [];
                obj.inSMA = [];
            else
                %probably want some checks here
                inSMA=varargin{1};
                outSMA=varargin{2};
            end
            
            %get sma type
            in_sma_type=get_sma_type(inSMA);
            
            switch in_sma_type
                case 'Bpod'
                    
                case 'Solo'
                    
                case 'Bcontrol'
                    outSMA=BCtoBpod(inSMA);
                otherwise
                    error('translateSMA::dont know this SMA type. Add a new SMA config file');
            end
            
        end
        
        function getBControlSettings(obj)

            %get settings. if multiple, use the default.
            BControl_Settings=SettingsObject();
            
            if exist([obj.soloDir filesep obj.settingsFile],'file') %make sure the specified settings file exists
                display(['translateProtocol.translateProtcol.getSoloParams::using settings file "' obj.settingsFile '"'])
            else
                
                if isdir([obj.soloDir filesep 'Settings'])
                    confFiles=dir([obj.soloDir filesep 'Settings']);
                    if numel(confFiles>1)
                        %search for 'default' in title
                        idx=find(cell2mat(cellfun(@(x) strfind(x,'Default'),{confFiles.name},'UniformOutput',false)));
                        if idx
                            display('translateProtocol.translateProtcol.getSoloParams::founding a default settings file. Using that')
                            settings=confFiles(idx).name;
                        else
                            error('translateProtocol.translateProtcol.getSoloParams::could not locate a settings file! Need a settings file to determine IO map for BControl SMAs!')
                        end
                    else
                        settings=confFiles.name;
                    end
                else
                    error('translateProtocol.translateProtcol.getSoloParams::couldnt locate a "Settings" dir. Please provide full path')
                end
            end
        end
        
        function getSoloParams(obj,varargin)
            
            %%%main function to transfer handles from solo/bcontrol to bpod
            
            %use: getSoloParams(soloDir,protocol_name,settings)
            
            %where 'soloDir' is the full path to the main Solo/Bcontrol dir,
            %where 'protocol_name' is the name of a protocol in the
            %    Protocols subdir you want transleted. Can also be a full
            %    path, e.g. if there isnt a protocol director
            % [OPTIONAL] where 'settings' is the name of the .config
            %    settings file you want use. If not provided, use anything
            %    matching 'default', or the only file in the directory
            
            
            %%
            
            % create  dispatcher obj, and attempt to load settings files
            dispatcher_obj=dispatcher('empty');
            
            %load the protocol
            
            %create empty protocol object
            SoloParamHandle(dispatcher_obj, 'OpenProtocolObject', 'value', '');
            
            SoloFunctionAddVars('RunningSection',  'ro_args', 'OpenProtocolObject');
            SoloFunctionAddVars('MachinesSection', 'ro_args', 'OpenProtocolObject');
            
            % Get an empty object just to assign ownership of vars we will create

            if obj.isClass
                [~,str]=obj.asFunction(obj.protocolName);
                OpenProtocolObject.value = feval(str, 'empty');
            else
                OpenProtocolObject.value = feval(obj.protocolName, 'empty');
            end
            
            % Now make sure all old variables owned by this class are smoked away:
            delete_sphandle('owner', ['^@', class(value(OpenProtocolObject)) '$']);
            
            % Make a set of global read_only vars that all protocol objects
            % will have and give them to the protocol object. First col is
            % varname, second is init value, third is 1 if rw for
            % RunningSection, 0 if rw for MachinesSection. All vars will be ro
            % for other section (other of RunningSection and MachineSection, that is).
            guys = { ...
                'raw_events'             []    0  ; ...
                'parsed_events'          []    0  ; ...
                'latest_parsed_events',  []    0  ; ...
                'n_done_trials'           0    0  ; ...
                'n_started_trials'        0    0  ; ...
                'n_completed_trials'      0    0  ; ...
                'current_assembler'      []    1  ; ...
                'prepare_next_trial_set' {}    1  ; ...
                };
            
            for i=1:size(guys,1),
                % Make all of these variables:
                SoloParamHandle(dispatcher_obj, guys{i,1}, 'value', guys{i,2});
                % Give them to the open protocol
                set_owner(eval(guys{i,1}), value(OpenProtocolObject));
            end;
            % And amke them read-onlies of the open protocol
            DeclareGlobals(value(OpenProtocolObject), 'ro_args', guys(:,1)');
            
            % Now some ro and some rw for RunningSection and MachinesSection here, too:
            runners = find(cell2mat(guys(:,3))==0); machiners = find(cell2mat(guys(:,3))==1);
            SoloFunctionAddVars('RunningSection',  'func_owner', ['@' class(dispatcher_obj)], 'ro_args', guys(machiners,1)');
            SoloFunctionAddVars('RunningSection',  'func_owner', ['@' class(dispatcher_obj)], 'rw_args', guys(runners,1)');
            
            SoloFunctionAddVars('MachinesSection', 'func_owner', ['@' class(dispatcher_obj)], 'ro_args', guys(runners,1)');
            SoloFunctionAddVars('MachinesSection', 'func_owner', ['@' class(dispatcher_obj)], 'rw_args', guys(machiners,1)');
            
            % Ok, we're ready-- actually open the protocol:
            % we load really only so 'private_soloparam_list' gets created
            [~,str]=obj.asFunction(obj.protocolName);
            feval(str, 'init');
            
            %some temp global defs for compatability with SoloParams.
            %these will not persist in the fully translated protocol
            global private_solofunction_list;  %this is populated by SoloFunction/SoloFunctionAddVars, etc
            global private_soloparam_list;     %this is populated by SoloParamHandle/SoloParam, etc
            global BControl_Settings
            
            %load the settings
            %need to cd back to the original directory...
            BControl_Settings=SettingsObject();
            [BControl_Settings errID_internal errmsg_internal] = LoadSettings(BControl_Settings, obj.settingsFile);
            
            obj.settings=struct(BControl_Settings); %
            
            %NOTE: for old solo, we should be able to get the physical port numbers (but not names)
            %straight from the stm, which is built in 'make_and_upload_state_matrix
            
            %%
            
            %%%%Deal with SoloFunc list
            
            % private_solofunction_list is a cell array with three columns. The
            % first column contains owner ids. Each row is unique. For each row
            % with an owner id, the second column contains a cell array that
            % corresponds to the set of function names that are registered for that
            % owner. The third row contains the globals declared for that owner.
            % so,we need to crawl through cell arrays in columns 2 and 3, look at the
            % second columns of the resulting columns for SoloParamHandle types, and
            % turn these into structures
            %ideally would want to do this recursively but I think the cell arrays only
            %go 2 or 3 deep, so lets just loop
            
            % TODO this is really ugly since I dont know if the construction of these nested
            %cell arrays is in any way systematic
            %what I know is that there are nested cell arrays of either 2 or 3 columns,
            %so we
            
            obj.funclist=private_solofunction_list;
            
            %loop through this stupid data structure
            columns=[2 3];
            for g=1:1:size(private_solofunction_list,1) %loop through functions
                for v=1:1:numel(columns) %loop through data columns, depth of 1
                    for z=1:1:numel(columns) %loop through data columns, depth of 2
                        for c=1:1:size(private_solofunction_list{g,columns(v)},1)
                            %second and third columns have slightly different internal
                            %structures, and dont really know if its systematic or not
                            try
                                if columns(z)<= numel(private_solofunction_list{g,columns(v)}(c,:))
                                    for x=1:1:size(private_solofunction_list{g,columns(v)}{c,columns(z)},1)
                                        if x>0
                                            tmp = value(private_solofunction_list{g,columns(v)}{c,columns(z)}{x,2});
                                            obj.funclist{g,columns(v)}{c,columns(z)}{x,2} = tmp;
                                        end
                                    end
                                end
                            catch %some peices of the structure dont know rows of cells. catch them here
                                for x=1:1:size(private_solofunction_list{g,columns(v)}{c},1)
                                    if x>0
                                        tmp = value(private_solofunction_list{g,columns(v)}{c}{x,2});
                                        obj.funclist{g,columns(v)}{c}{x,2} = tmp;
                                    end
                                end
                                
                            end
                        end
                    end
                end
            end
            
            %%
            
            %%%%Deal with SoloParam list
            
            %main loop through SoloParamHandles. Will auto-create the Matlab obj
            %version of everything for each
            
            %the 'BpodObject' class has 'GUIHandle' and 'GUIData' properties.
            %I assume this is where most of the SoloParam info needs to go
            
            %list of unique param owner funcs.
            obj.owner_classes{1}=[];
            obj.owner_classes_full{1}=[];
            
            %list of allmfile names for callbacks and 'methods'. Dont care about
            %uniqueness for now
            obj.callbacks{1}= struct('mfiles','','methods','');
            
            %count=1;
            for i=1:1:numel(private_soloparam_list)
                %convert SoloParams to structures
                obj.param_struct{i} = struct(private_soloparam_list{i});
                %also keep their values
                obj.param_vals{i} = value(private_soloparam_list{i});
                
                %check that param owner m-files are accesible to us
                %if strcmp(owners,param_struct{i}.param_owner)
                %owners{count}=param_struct{i}.param_owner;
                %count=count+1;
                %end

                obj.owner_classes{i}=obj.param_struct{i}.param_owner;
                obj.owner_classes_full{i}=obj.param_struct{i}.param_fullname; %
                
                %check that param callbacks m-files are accesible to us
                %Callbacks are an n x m cell array, where rows (n) are the name of
                %an m-file, and columns (m) are a string index into a switch statement
                %inside that m-function. This is how SoloParamHandles worked.
                
                tmp=obj.param_struct{i}.callback_fn;
                if ~iscell(tmp)
                    tmp={tmp};
                end
                
                for g = 1:1:size(tmp,1) %loop through m-files
                    obj.callbacks{i}.mfiles{g,1}=tmp{g,1};
                    if ~isempty(strmatch(tmp{g,1},''))
                        obj.callbacks{i}.methods{g,2}=tmp{g,1};
                    else
                        for b = 1:1:size(tmp,2)-1 %loop through 'methods'
                            obj.callbacks{i}.methods{g,b}=tmp{g,b+1};
                        end
                    end
                    %finally, set the callback to 'translation_callback'
                    %param_struct{i}.callback_fn='translation_callback';
                    obj.param_struct{i}.ghandle.Callback='translation_callback';
                    
                end
                
            end
            
            %%
            
            %clear solo stuff
            flush;
            close all;
            
        end
        
        function [obj,strOut]=asFunction(obj,strIn)
           %helper function to translate between Protcol name as a class, and as a function
           idx=strfind(strIn,'@');
           strOut=strIn;
           strOut(idx)=[];
        end
        
        function smaType=get_sma_type(inSMA)
            
            %load config files for the approporate sma type...should be a file which
            %returns an empty sma struct. This is easy
            
            smaType=['Bcontrol'];
        end
        
        function outSMA=BCtoBpod(inSMA)
            
            %%% main method handles translation of the SMA
            
            global BpodSystem
            
            %NOTE - BControl SMA looks like this:
            %row initialized to the max current number, +1
            %rows 1 - n: names of states to transition TO on events 1 - n being triggered
            %row n+1:    name of Tup trans
            %row n+2:    Tup time
            %row n+3:    Event channel ID (+/-)
            %row n+4:    SoundId
            %row n+5:    SchedWaveId
            
            
            % %%%%%Here are the fields in a Bpod SMA, with their default values:
            % nStates: 0
            % nStatesInManifest: 9
            % Manifest: {1x127 cell}
            % StateNames: {1x9 cell}
            % InputMatrix: [9x40 double]
            % OutputMatrix: [9x17 double]
            % GlobalTimerMatrix: [9x5 double]
            % GlobalTimers: [0 0 0 0 0]
            % GlobalTimerSet: [0 0 0 0 0]
            % GlobalCounterMatrix: [9x5 double]
            % GlobalCounterEvents: [255 255 255 255 255]
            % GlobalCounterThresholds: [0 0 0 0 0]
            % GlobalCounterSet: [0 0 0 0 0]
            % StateTimers: [0 0 0.5000 5 0 2 0.0300 2 10]
            % StatesDefined: [1 1 1 1 1 1 1 1 1]
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%%%Here are the default In events and ids defined in 'BPodSystem' object%%%
            %NOTE, we will need to assign our Bcontrol input lines to these
            %
            %
            % 1.  'Port1In'     17. 'BNC1High     21. 'Wire1High'     29. 'SoftCode1'     39. 'Unused'
            % 2.  'Port1Out'    18. 'BNC1Low'     22. 'Wire1Low'      30. 'SoftCode2'     40. 'Tup'
            % 3.  'Port2In'     19. 'BNC2High'    23. 'Wire2High'     31. 'SoftCode3'
            % 4.  'Port2Out'    20. 'BNC2Low'     24. 'Wire2Low''     32. 'SoftCode4'
            % 5.  'Port3In'                       25. 'Wire3High'     33. 'SoftCode5'
            % 6.  'Port3Out'                      26. 'Wire3Low'      34. 'SoftCode6'
            % 7.  'Port4In'                       27. 'Wire4High'     35. 'SoftCode7'
            % 8.  'Port4Out'                      28. 'Wire4Low'      36. 'SoftCode8'
            % 9.  'Port5In'                                           37. 'SoftCode9'
            % 10. 'Port5Out'                                          38. 'SoftCode10'
            % 11. 'Port6In'
            % 12. 'Port6Out'
            % 13. 'Port7In'
            % 14. 'Port7Out'
            % 15. 'Port8In'
            % 16. 'Port8Out'
            
            
            %and here are the ouputs:
            
            % 1.  'ValveState'
            % 2.  'BNCState'
            % 3.  'WireState'
            % 4.  'Serial1Code'
            % 5.  'Serial2Code'
            % 6.  'SoftCode'
            % 7.  'GlobalTimerTrig'
            % 8.  'GlobalTimerCancel'
            % 9.  'GlobalCounterReset'
            % 10. 'PWM1'
            % 11. 'PWM2'
            % 12. 'PWM3'
            % 13. 'PWM4'
            % 14. 'PWM5'
            % 15. 'PWM6'
            % 16. 'PWM7'
            % 17. 'PWM8'
            
            %there are also 'MetaActions' as ouputs:
            
            %MetaActions = {'Valve', 'LED', 'LEDState'}; % Valve is an alternate syntax for "ValveState", specifying one valve to open (1-8)
            % LED is an alternate syntax for PWM1-8,specifying one LED to set to max brightness (1-8)
            % LEDState is an alternate syntax for PWM1-8. A byte coding for binary sets which LEDs are at max brightness
            
            %NOTE need to look here to understand what VALUE to give an output
            %action!It very much depends on which event type you want to use
            %https://sites.google.com/site/bpoddocumentation/bpod-user-guide/using-state-matrices/outputactioncodes
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%%%% Setup some easy stuff
            %make empty Bpod sma
            outSMA = NewStateMachine(); %this should eventually be called by a 'BpodStateTemplate()' or something
            
            % 'Manifest' is the name of states in order added
            % 'StateNames' is the order they were referenced...THIS IS INCOMPLETE
            outSMA.StateNames = inSMA.state_name_list;
            outSMA.Manifest(1:numel(inSMA.state_name_list(:,1))) = inSMA.state_name_list(:,1);
            outSMA.nStatesInManifest = sum(cellfun(@(x) ~isempty(x), outSMA.Manifest));
            %confused by this next one. At just before run time, this is 0. Does it
            %increment by the number of total states that have been run? Stay tuned..
            %0 is the init state, so im not doing anything here, just noting the fact
            outSMA.nStates=0;
            
            %extract state numbers for each inState
            %state name list has 3 columns: state name, state number, and iti state
            %number
            state_name_list=inSMA.state_name_list;
            
            %%%%%%% some formatting
            statecols=cell2mat(inSMA.input_map(:,2)); %columns contaning state values
            %subtract 39 from all numbers in the array: BControl
            %has a default first state of 40, but we want to start from one in
            %BControl, since we have a hard limit on states
            tmp=inSMA.states(:,statecols);
            for i=1:1:numel(tmp)
                if isnumeric(tmp{i})
                    tmp{i} = tmp{i}-39;
                end
            end
            inSMA.states(:,statecols)=tmp;
            
            %and delete rows that now have states less than 1
            idx=1;
            for i=1:1:size(inSMA.states,1)
                if any(cell2mat(inSMA.states(i,1:statecols))<=0)
                    idx=[idx i];
                end
            end
            inSMA.states(idx,:)=[];
            
            %%%%%%% deal with Tup timers%%%%%%
            
            %get the row in the statematrix that belongs to timers
            %for me, this always just 1x2, saying {'Timer' 5}. Can there be multiple
            %timers defined? If so, will need to change this presumably based on
            %different versions of 'Tup' that this state uses
            timerRow=inSMA.self_timer_map{2};
            outSMA.stateTimers=inSMA.states{:,timerRow};
            
            %%%%%%% input/ouput line remapping%%%%%%
            
            %loop through defined inputs, map to ports going down the line...eventually
            %need a gui or table or something
            count=1;
            newInputMapping={'Tup','Tup'};
            for i=1:1:size(inSMA.input_map,1)
                if ~strcmp('Tup',inSMA.input_map{i,1})
                    newInputMapping=[newInputMapping; {inSMA.input_map{i,1},BpodSystem.StateMachineInfo.EventNames{count}}];
                end
                count=count+1;
            end
            
            %%%%%%% reassign the input matrix%%%%%%
            
            %replace the state string names in the Bcontrol SMA with proper Bpod state ids
            tmpInputMatrix=inSMA.states;
            %JPL - do i need this below?
            %input_map=inSMA.input_line_map(cell2mat(inSMA.input_line_map(:,2))>0,:);% some ins, like sched waves, are internal. exclude these
            for i=1:1:numel(tmpInputMatrix)
                if ~isnumeric(tmpInputMatrix{i})
                    %find the proper replacement id for this string
                    idx = strcmp(tmpInputMatrix{i},inSMA.state_name_list(:,1));
                    if idx > 1
                        keyboard
                    elseif idx==0
                        %this is probably a shed wave if is in the matrix and doesnt
                        %have a state name.
                    else
                        tmpInputMatrix{i} = state_name_list(idx,2);
                    end
                end
            end
            
            %JPL- maybe have a visual check here before assigning
            inSMA.states=tmpInputMatrix;
            
            %%%%%%% ouput line remapping%%%%%%
            
            %NOTE: need a gui!
            
            %see notes above, but specific types of output have a specific number of
            %bytes associated with them (enough to cover the number of those type of
            %output)
            %when specifying an OutputAction, to make a BINARY mask for the ports you
            %want to activate, and then TRANSLATE to a decimal! Thus, a code of 3 would
            %acticate TWO ports, since the bitmask is [1 1]
            %
            %For reference, here are the names and n-bits for different outs
            %all other outs are numeric serial codes whos instructions are determined
            %in the firmware (right?)
            %
            %%%Solenoid valve control (8 lines)
            %8 Bits, name = 'ValveState'
            %%%BNC output logic control
            %2 Bits, name = 'BNCState'
            %%%Wire output logic control
            %3 Bits, name =	'WireState'"
            
            %we dont need to worry about serial port outs, since there was no such
            %functionality in BControl, UNLESS they connect to another device that
            %opens up more ports for us
            
            valveBytes=zeros(1,2^3); %init bitmask for valves (8 lines)
            BNCBytes=zeros(1,2^2);   %init bitmask for BNCs   (3 lines)
            wireBytes=zeros(1,2^2);  %init bitmask for wires  (4 lines)
            
            newOutputMapping={1,'ValveState',''}; %three fields: device id, output type, port number
            %the device determines the config/types of
            %ports available and the commuuncation (e.g.
            %none, serial, etc). output type is the names
            %of the outputs that have been configured for
            %that device, and the final elemn is an
            %address
            
            occupiedValveLinesIDs=0;
            occupiedBNCLinesIDs=0;
            occupiedWireLinesIDs=0;
            i=1;
            j=1;
            firstBNCidx=5; %jpl hack for now
            %cases=[]; auto-build cases for the swtich below
            cases = BpodSystem.StateMachineInfo.OutputChannelNames;
            
            %in solo, could have the output types of 'DOut', 'SoundOut', and a
            %'SchedWaveTrig' for each Sched wave triggering an ouput
            
            while i < size(inSMA.output_map,1)
                %choose a line
                newOutputMapping{i,2}=BpodSystem.StateMachineInfo.OutputChannelNames{firstBNCidx+j}; %just go in order for now until GUI is functional
                %value of line{i,2} deoends on the output type
                switch newOutputMapping{i,2}
                    %JPL - this info about the n bits per port type should be codified
                    %in a settings file somewhere...
                    case cases{firstBNCidx+1}
                        %choose one of 8 valve lines
                        %jpl - temp hack until GUI, find first available line
                        occupiedValveLinesIDs=[occupiedValveLinesIDs occupiedValveLinesIDs+1];
                        if max(occupiedValveLinesIDs) == 8
                            warning('All Valve lines occupied, switching to BNC line')
                            newOutputMapping{i,2}='BNCState';
                            j=j+1;
                        else
                            valveline=max(occupiedValveLinesIDs);
                            newOutputMapping{i,1}=dec2bin(valveline);
                            newOutputMapping{i,3}=inSMA.output_map(i,1); %original sma name
                            
                            i=i+1;
                        end
                    case cases{firstBNCidx+2}
                        %choose one of 2 bnc lines
                        occupiedBNCLinesIDs=[occupiedBNCLinesIDs occupiedBNCLinesIDs+1];
                        if max(occupiedBNCLinesIDs) == 2
                            warning('All BNC lines occupied, switching to wire line')
                            newOutputMapping{i,2}='WireState';
                            j=j+1;
                        else
                            bncline=max(occupiedBNCLinesIDs);
                            newOutputMapping{i,1}=dec2bin(bncline);
                            newOutputMapping{i,3}=inSMA.output_map(i,1); %original sma name
                            
                            i=i+1;
                        end
                    case cases{firstBNCidx+3}
                        %choose one of 4 wire lines
                        occupiedWireLinesIDs=[occupiedWireLinesIDs occupiedWireLinesIDs+1];
                        if max(occupiedWireLinesIDs) == 2
                            warning('translateSMA::All Wire lines occupied, and im not comfortable switching to serial lines')
                            error('translateSMA::not enough sensible output lines on Bpod to translate')
                        else
                            wireline=max(occupiedWireLinesIDs)+1;
                            newOutputMapping{i,1}=dec2bin(wireline);
                            newOutputMapping{i,3}=inSMA.output_map(i,1); %original sma name
                            
                            i=i+1;
                        end
                        %JPL - these will be selected 'under the hood' when the user
                        %selects an AO module by name in the GUI
                    case cases{firstBNCidx+4}
                        %choose 1st serial port
                    case cases{firstBNCidx+5}
                        %choose 2nd serial port
                    case cases{firstBNCidx+6}
                        %choose 3rd serial port
                        
                    case cases{firstBNCidx+7}
                        
                    case cases{firstBNCidx+8}
                        
                    otherwise
                        error('translateSMA::cannot identify this type of output line.')
                end
                
            end
            
            %%%%%%%deal with output actions%%%%%%
            %read the new outputs into the output matrix
            
            %%%%%%% deal with ScheduledWaves (Bpod 'GlobalTimers')
            
            %can set via SetGlobalTimer(), with the following arguments pairs:
            
            %TimerNumber: The number of the timer you are setting (an integer, 1-5).
            %TimerDuration: The duration of the timer, following timer start (0-3600 seconds)
            %OnsetDelay: A fixed interval following timer trigger, before the timer start event (default = 0 seconds)
            %   If set to 0, the timer starts immediately on trigger and no separate start event is generated.
            %OutputChannel: A string specifying an output channel to link to the timer (default = none)
            %    Valid output channels are listed in BpodSystem.StateMachineInfo.OutputChannelNames
            %OnsetValue: The value to write to the output channel on timer start (default = none)
            %   If the linked output channel is a digital output (BNC, Wire), set to 1 = High; 5V or 0 = Low, 0V
            %   If the linked output channel is a pulse width modulated line (port LED), set between 0-255.
            %   If the linked output channel is a serial module, OnsetValue specifies a byte message to send on timer start.
            %OffsetValue: The value to write to the output channel on timer end (default = none)
            
            %syntax translation notes:
            
            % Scheduled Wave -> Global Timer
            % name           -> Name
            % preamble       -> 'OnsetDelay'
            % sustain        -> 'Duration'
            % dio_line       -> 'Channel' , note in Solo could have '-1' as internal
            
            % n/a            -> timerId
            % n/a            -> 'onsetValue'
            % n/a            -> 'offsetValue'
            
            % sound_trig     -> n/a, but could make this happen via the teensy server
            % refraction     -> n/a,
            
            %loop through ScheduledWaves, and set corresponding GlobalTimers
            if numel(inSMA.sched_waves)>numel(outSMA.GlobalTimers)
                warning(['translateSMA::you have ' ...
                    sprintf('%0.1f',numel(inSMA.sched_waves)) ' Scheduled Waves'])
                warning(['translateSMA::current Bpod setting allow only ' ...
                    sprintf('%0.1f',numel(outSMA.GlobalTimers)) ' Global Timers'])
                warning(['translateSMA::translating the first ' ...
                    sprintf('%0.1f',numel(outSMA.GlobalTimers)-numel(outSMA.GlobalTimers))...
                    ' Scheduled Waves to Global Timers'])
                
                nswaves=numel(outSMA.GlobalTimers);
            else
                nswaves=numel(inSMA.sched_waves);
            end
            
            dio_sched_col=inSMA.dio_sched_wave_cols;
            for m=1:1:nswaves
                %udpate outSMA.GlobalTimer according to inSMA's sched waves
                
                %NOTE sched wave creation in solo automatically creates two columns in
                %the input matrix per sched wave: one for the start of the wave, and
                %one for the end of the wave
                
                %we will have to determine which state transitions depended on these
                %events, and change them to depend on Bpod Global Timer events
                
                %solo also created one output column per sched wave, holding the name
                %(NOT the numerical id) of the wave
                
                in_col=inSMA.sched_waves(m).in_column;
                out_col=inSMA.sched_waves(m).out_column;
                dio_line = inSMA.sched_waves(m).dio_line;
                
                %create the wave
                
                %bpod wants names, not ids/numbers...need to do the remapper first
                outSMA = SetGlobalTimer(outSMA, 'TimerID', inSMA.sched_waves(m).id,...
                    'Duration',   inSMA.sched_waves(m).sustain,...  % sustain
                    'OnsetDelay', inSMA.sched_waves(m).preamble,... % premable
                    'Channel',    inSMA.sched_waves(m).dio_line,... % output channel, by string! e.g. 'BNC1'
                    'OnsetValue', 0,...                             %
                    'OffsetValue',0);                               %
                
            end
            
            if exist('SchedWaveRows','var')
                for b=1:1:size(schedWaveRows,1)
                    %JPL - is this the right thing to set
                    outSMA.globalTimers(b)=schedWaveRows{b,2};
                end
            end
            
            %%%%%%%other stuff%%%%%%%%%%%
            
            %these is 1 or 0, depending on ...what? whether the timer is used or not?
            outSMA.GlobalTimerSet;
            
            %%%%Global counters are a new feature (right?) and have no equivalent in
            %Bcontrol
            %outSMA.GlobalCounterEvents;
            %outSMA.GlobalCounterSet;
            
            % Referenced states are set to 0. Defined states are set to 1. Both occur with AddState
            % ...but what is the difference between a 'referenced; and a 'defined' ?
            outSMA.StatesDefined;
            
        end
        
        
        function outSMA=toBcontrol(inSMA)
            
            %make empty Bcontrol sma...but there are multiple types!
            outSMA = StateMachineAssembler('full_trial_structure');
            
            
        end
    end
end