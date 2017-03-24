% Create and send state matrix.

% Santiago Jaramillo - 2007.08.24
%
%%% CVS version control block - do not edit manually
%%%  $Revision: 1064 $
%%%  $Date: 2008-01-10 16:50:50 -0500 (Thu, 10 Jan 2008) $
%%%  $Source$



function sma = StateMatrixSection(obj, action)

%call to SetStateProgram occurs outside of this function when using
%dispatcher. Make the embedC matrix global
global G %stuff to send to globals
global m %matrix to append to end of statematrix for bitcode

%set in dispatcher, reflects Dout mappins from settings file
global unsorted_channels
global channels

%need to convert the channel mappings for each DOut to binary, then to
%decimal

%%%---OUTPUT SPECIFICATION

bitcode=4;           %binary = 1100,         
%lick_1=16;             %binary = 1001,       
festo_trig=16;        %binary = 100001,      
lick_2=32;            %binary = 10001,       
touch_led=65;        %binary = 100001,      
lick_1=257;         %binary = 10000001,    
ephus_trig=1025;      %binary = 1000000001,   
%embc_touch_out=4097;  %binary = 100000000001, DIO line triggered by embc touch sched wave is chan12
%i2c_sda= 131071;            % chabn 17
%i2c_slc=  262143;              %chabn 18

GetSoloFunctionArgs;

switch action
    case 'update',
        %%%%NEXT TRIAL SETTINGS

        %create bit code
        %------ Signal trial number on digital output given by 'slid':
        % Requires that states 101 through 101+2*numbits be reserved
        % for giving bit signal.

        trialnum = n_completed_trials + 1;
        
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
        %eventually, want next sti,m type to have more options like 'arch'
        %and 'chr2' and 'off' set in a stim section...but fur now, just on
        %of orr
        if strcmp(next_stim_type,'s')
            stim_trial=1;
            stim_epoch = value(next_stim_epoch);
        else
            stim_trial=0;
            stim_epoch = 0;
        end

        %%%%REGULAR STATE MACHINE STUFF

        %SOUNDS
        %IndsAll =  SoundManagerSection([], 'get_sound_id', 'all');
        %IndNoise = SoundManagerSection([], 'get_sound_id', 'noise');
        %IndSoundReward = SoundManagerSection([], 'get_sound_id', 'reward');
        %IndSoundGo = SoundManagerSection([], 'get_sound_id', 'go');
        %IndSoundInit = SoundManagerSection([], 'get_sound_id', 'init');

        %get all sound names
        %soundNames =  SoundManagerSection(obj, 'get_sound_names','all');
        %JPL - hacking this for now
        soundNames={'reward','fai','init','go','cue1','cue2','cue3','cue4',...
                    'cue5', 'cue6', 'cue7', 'cue8'};
        
        %get the id for the pole associated with the current position
        if value(next_cue_mismatch_id)==0
            cueName=active_locations.cue_name(find((strcmp(next_pos_id,...
                active_locations.name))==1));
        else
            cueName=active_locations.cue_name(find(value(next_cue_mismatch_id)==cell2mat(active_locations.cue_id)));
        end
        
        %JPL -hacking this for the moment
        try
            IndCueSound = find(strcmp(soundNames,cueName(1))==1)-1;
        catch
            cueName=active_locations.cue_name;
            IndCueSound = find(strcmp(soundNames,cueName(1))==1)-1;
        end
        
        %randomize pre pole length
        %JPL - temporary hack
        %tmp=get_string(pole_delay);
        tmp={pole_delay};
%         for g=1:1:numel(tmp{1})
%             if ~isempty(str2num(tmp{1}{g})) 
%                 rand_pole_delay_pool(g) = str2num(tmp{1}{g});
%             end
%         end
        %JPL hack
        rand_pole_delay_pool = [1 1.5 0];
        %end hack
        if ~strcmp(value(pole_delay), 'random')
            %do nothing
        else
            RandDelay_ind = ceil(length(rand_pole_delay_pool)*rand);
            pole_delay = rand_pole_delay_pool(RandDelay_ind); % set Pole delay time as a random number between 0.5 and 1.5
        end;
  
        %randomize delay period length
        %JPL temp hack
        %tmp=get_string(DelayPeriodTime);
        tmp={DelayPeriodTime};
        rand_delay_period_pool = [1 1.5 0];
        for g=1:1:numel(tmp{1})
            %if ~isempty(str2num(tmp{1}{g})) 
            %    rand_delay_period_pool(g) = str2num(tmp{1}{g});
            %end
        end
        
        %if ~strcmp(value(DelayPeriodTime), 'random')
        %    %do nothing
        %else
        %    RandDelay_ind = ceil(length(rand_delay_period_pool)*rand);
        %    DelayPeriodTime = rand_delay_period_pool(RandDelay_ind); % set Pole delay time as a random number between 0.5 and 1.5
        %end;
        DelayPeriodTime=0;
        %end hack
        
        %JPL - mmore hack
        %randomize answer delaqy
%         tmp=get_string(AnswerDelayDur);
%         for g=1:1:numel(tmp{1})
%             if ~isempty(str2num(tmp{1}{g})) 
%                 rand_delay_answer_pool(g) = str2num(tmp{1}{g});
%             end
%         end
%         
%        if ~strcmp(value(AnswerDelayDur), 'random')
%             %do nothing
%         else
%             RandDelay_ind = ceil(length(rand_delay_answer_pool)*rand);
%             AnswerDelayDur = rand_delay_answer_pool(RandDelay_ind); % set Pole delay time as a random number between 0.5 and 1.5
%         end;
        AnswerDelayDur=0;
        
        %JPL - end hack
        
        %response side / type 
        nxtside=(value(next_side));
        %response type, e.g. 'lick_r', e.g. go or 'none', e.g no go
        %not for now this is limited to go-no until motor gui is fixed
        %JPL this was just easier to do in C with 0 and 1, and for go nogo
        %there are only ever gpoing to be two responses, so tis fine
        nxttype=(value(next_type)); 
        if ~isempty(strmatch(nxttype,'go'))
            nxttype=1;
        else
            nxttype=0;
        end
       
        %how to end the sample period
        sampend_mode=value(SampleEnd);
              
        %%%%PASS VARIABLES TO EmbedC)

        % -- Times Section
        %delays in the state machine are coded as multiples of the duty
        %cycle, which is 6 samples per ms. Here we define any delays we
        %wish to implement on AO or AI lines. For example, if we want to
        %change state 600ms after a touch on an AI line, then this value
        %will be 3600
        
        %if you want randomized values, pass a vector of possible values,
        %and these will be sampled - NOT IMPLEMENTED

        cyclesPerMs=6;
        
        %%%specify delays in ms here - MAKE GUI EDITABLE
        pre_pole_delay=pole_delay*1000;  %wait time after touch
        resonance_delay=value(ResonanceTO)*1000; %from pole up time! MAKE EDITIABLE
        answer_delay=AnswerDelayDur*1000;
        delay_period=DelayPeriodTime*1000;
        sample_period = SamplingPeriodTime*1000;
        answer_period = AnswerPeriodTime*1000;
        drink_period = DrinkTime*1000;
        mean_window_length = value(TouchFiltWinMean)*1000;       %3ms is good,time period to average over for signal measure,12 cycles MAKE EDITABLE
        median_window_length = value(TouchFiltWinMedian)*1000;     % 1/2 ms is good needs to be odd an even factor into mean window length MAKE EDITABLE
        baseline_length = value(TouchBaseline)*1000;       %2x mean window is good time period to average over for baseline measure,
        
        %valve time can be different for different pole positions
                %check if this is a mismatched acxtion xr val trial. if so, puill
        %the value from the mismatch id field. otherwise, use the one in
        %the settings for this pole id
        
        %JPL - more hacks
        
%         if active_locations.mismatchId{strcmp(next_pos_id,active_locations.name)}(2)~=0
%             tt=value(rewXrVals);
%             rewXr=tt(active_locations.mismatchId{find(strcmp(next_pos_id,active_locations.name))}(2));
%         else
%             rewXr=cell2mat(active_locations.rewXr(strcmp(next_pos_id,active_locations.name)));
%         end

       rewXr=1;
%   end hack

        valve_time = (WaterValveTime * rewXr) * 1000;
       
        log_analog_freq = 100;         %log analog values this often, so we dont overload the memory MAKE EDITABLE
        time_out_time = TimeOutWaitDur*1000;
        init_hold_time = InitHoldTime*1000;

        %this is an attempt tp make the delaty period = delay period +
        %resonance, w/ overlap, so poikes plot is accurate. howver, in
        %globals, things got messed up, so disabling for now
        if delay_period>resonance_delay
            %delay_period=resonance_delay+(delay_period-resonance_delay);
        else
            %delay_period=resonance_delay;
            warning('delay period duration is shorter than the resonance TO period!')
        end

        %%%convert
        pre_pole_delay=floor(pre_pole_delay.*cyclesPerMs);
        resonance_delay=floor(resonance_delay.*cyclesPerMs);
        answer_delay=floor(answer_delay.*cyclesPerMs);
        delay_period=floor(delay_period.*cyclesPerMs);
        drink_period=floor(drink_period.*cyclesPerMs);
        
        sample_period=floor(sample_period.*cyclesPerMs);
        answer_period=floor(answer_period.*cyclesPerMs);
        mean_window_length=floor(mean_window_length.*cyclesPerMs);
        median_window_length=floor(median_window_length.*cyclesPerMs);
        baseline_length=floor(baseline_length.*cyclesPerMs);
        log_analog_freq=floor(log_analog_freq.*cyclesPerMs);
        valve_time=floor(valve_time.*cyclesPerMs);
       
        % -- Thresholds Section
        %need so specofcy threshold logic,a s well as state/states in
        %which to apply this threshold
        touch_thresh=value(TouchThreshHigh);   %units of absolute difference mV
        
        %check if this is a mismatched acxtion xr val trial. if so, puill
        %the value from the mismatch id field. otherwise, use the one in
        %the settings for this pole id
        
        %JPL - more hacks
%         if active_locations.mismatchId{strcmp(next_pos_id,active_locations.name)}(3)~=0
%             tt=value(actionXrVals);
%            actionXr=tt(active_locations.mismatchId{strcmp(next_pos_id,active_locations.name)}(3));
%         else
%             actionXr=cell2mat(active_locations.actionThreshXr(strcmp(next_pos_id,active_locations.name)));
%         end
        actionXr=1;
        %end hack
        
        try
            lick_thresh=value(LickThresh);   %units of V   
        catch
            lick_thresh=3; %default TTL logic
        end
        
        %whisker Angle. on fpga, retractgions are 0 to -180, protractions
        %arte 0 to 180. This is converted to 0 to +1.66 V for protraction
        %and 0 to -1.66V for retraction
        try
            whiskang_thresh=value(WhiskAngThresh);   %units of V   
        catch
            whiskang_thresh=5; %5V - this will never cross
        end 

        %whisker velocity, derived on rt from diff of angle, units of
        %dTheta (rtypically xDegrees/s
        try
            whiskvel_thresh=value(WhiskVelThresh);   %units of V   
        catch
            whiskvel_thresh=500; %500 degress per second - this will never cross
        end 
        %----Punishment Section
        intfail=value(InitFail);
        sampdlyfail=value(SampleDelayFail);
        sampfail=value(SampleFail);
        ansdlyfail=value(AnswerDelayFail);
        ansfail=value(AnswerFail);
        
        punishOn=cell2mat(active_locations.punishOn(find((strcmp(next_pos_id,...
                        active_locations.name))==1)));
        %---Which responses are allowed at different periods
        sampleAction=cell2mat(active_locations.sampleAction(find((strcmp(next_pos_id,...
            active_locations.name))==1)));
        answerAction=cell2mat(active_locations.answerAction(find((strcmp(next_pos_id,...
            active_locations.name))==1)));
        
        %provide ids for each sound.
        %JPL HACK
        %rew_cue=IndSoundReward;
        %go_cue=IndSoundGo;
        %fail_cue=IndNoise;
        %pole_cue=IndCueSound;
        rew_cue=1;
        go_cue=2;
        fail_cue=3;
        pole_cue=4;
        
        %end hack
        
        %%%%PREPARE STATEMATRIX
        sma = StateMachineAssembler('full_trial_structure');
        %switch for different behavior types
        switch SessionType
            case 'Touch_Test'
                
                %%%------SCHEDULED WAVES SECTION-----------------
                [sma] = add_scheduled_wave(sma,...
                    'name','touch_onsets',...
                    'sustain', 0.1,...
                    'dio_line', 12);

                sma = add_scheduled_wave(sma,'name', 'goWave',...
                    'sustain',GoCueDur,...
                    'sound_trig', IndSoundGo);

                %%%------SMA SECTION-----------------
                %play a sound every time a touch is detected
                sma = add_state(sma, 'name', 'start', ...
                    'input_to_statechange', {'touch_onsets_In', 'play_sound'});

                sma = add_state(sma, 'name', 'play_sound', ...
                    'output_actions', {'SchedWaveTrig','goWave'}, ...
                    'input_to_statechange', {'Tup','final_state'});

                sma = add_state(sma, 'name', 'final_state', ...
                    'self_timer', 0.01,...
                    'input_to_statechange', {'Tup', 'check_next_trial_ready'});
                
            case 'Licking'
                
                %G=[];
                
                %%%------SMA SECTION-----------------

                %send bitcode and start
                sma = add_state(sma, 'name', 'start', ...
                    'input_to_statechange', {lickOut, 'valve';'Tup', 'final_state'});
                
                sma = add_state(sma, 'name', 'valve', ...
                    'self_timer', WaterValveTime,...
                    'output_actions',{'DOut',lick_1},...
                    'input_to_statechange', {'Tup', 'final_state'});

                sma = add_state(sma, 'name', 'final_state', ...
                    'self_timer', 0.01,...
                    'input_to_statechange', {'Tup', 'check_next_trial_ready'});

            case 'noDiscrim'

                %MAIN STATE MACHINE DEFINITION
                
                %%%------SCHEDULED WAVES SECTION-----------------
                [sma] = add_scheduled_wave(sma,...
                    'name','touch_onsets',...
                    'sustain', 0.1,...,
                    'preamble',0.6,...
                    'dio_line', 1);

                [sma] = add_scheduled_wave(sma,...
                    'name','go_wave',...
                    'sustain', 0.2,...,
                    'preamble',0.7,...
                    'dio_line', 2);

                sma = add_state(sma, 'name', 'start', ...
                    'input_to_statechange', {'Cin', 'pre_pole_time'});
                
                sma = add_state(sma, 'name', 'pre_pole_time', ...
                    'self_timer', 10,...
                    'output_actions',{'DOut',3},...
                    'input_to_statechange',...
                    {'go_wave_Out','resonance_timeout';...
                    'Tup', 'raise_pole'});
                
                sma = add_state(sma, 'name', 'raise_pole', ...
                    'output_actions', {'SchedWaveTrig',1}, ...
                    'input_to_statechange', ...
                        {'Tup','resonance_timeout';...
                        'Rin','delay'});
                
                sma = add_state(sma, 'name', 'delay', ...
                    'output_actions', {'DOut',2}, ...
                    'input_to_statechange', ...
                        {'Tup','final_state';...
                        'Rin','cue_and_sample'});
                    
                sma = add_state(sma, 'name', 'resonance_timeout', ...
                    'output_actions', {'SchedWaveTrig','touch_onsets'}, ...
                    'input_to_statechange', ...
                        {'Tup','final_state';...
                        'Lin','cue_and_sample'});
                
                sma = add_state(sma, 'name', 'cue_and_sample', ...
                    'input_to_statechange',...
                    {'Tup','final_state';...
                    'touch_onsets_In','delay',});
                    

                sma = add_state(sma, 'name', 'final_state', ...     
                    'self_timer', 0.5,...
                    'input_to_statechange',...
                    {'Tup', 'check_next_trial_ready'});

        case 'test'

                %MAIN STATE MACHINE DEFINITION
                
                %-----------SCHED WAVES
                [sma] = add_scheduled_wave(sma,...
                    'name','lickport_1',...
                    'sustain', WaterValveTime,...
                    'dio_line', 0);

                %%-----START------------------------------------------------------
                %send bitcode and start
                
                sma = add_state(sma, 'name', 'start');              %40
                    
                %add bitcode / i2c states
                
                %states 41:60
                %bitcode/i2c triggering takes 28ms
                
                for i=1:size(m,1)-1,

                    %ouput actions are:
                    %bitcode bit m,
                    
                    sma = add_state(sma, 'name', ['bitcode_' num2str(i)],...
                        'self_timer', m(i,8),...
                        'output_actions',{'DOut',m(i,9)},...
                        'input_to_statechange',{'Tup',['bitcode_' num2str(i+1)]});
                end
                sma = add_state(sma, 'name', ['bitcode_' num2str(i+1)]);

                %resume 
                sma = add_state(sma, 'name', 'pre_pole_time');      %61
                sma = add_state(sma, 'name', 'raise_pole');         %62
                sma = add_state(sma, 'name', 'resonance_timeout');  %63
                sma = add_state(sma, 'name', 'delay');              %64
                sma = add_state(sma, 'name', 'cue_and_sample');     %65
                sma = add_state(sma, 'name', 'answer_delay');       %66
                
                %from here we let state control go back to matlab to
                %control the delivery of the reward and decide on hit and
                %miss states.
                sma = add_state(sma, 'name', 'answer_period');      %67
                
                %upon exiting state 47, the dout bypass in embedc gets
                %turned off, so now matlab can trigger the lickport              
                
                sma = add_state(sma, 'name', 'valve');              %68
                
                sma = add_state(sma, 'name', 'drink');              %69     
                
                sma = add_state(sma, 'name', 'response');  
               
                sma = add_state(sma, 'name', 'noresponse');  
                
                sma = add_state(sma, 'name', 'hit');  
               
                sma = add_state(sma, 'name', 'miss');                 
                
                sma = add_state(sma, 'name', 'final_state', ...     %74
                    'self_timer', 0.5,...
                    'input_to_statechange',...
                    {'Tup', 'check_next_trial_ready'});
                
            case 'Water_Valve_Calibration'
                % On beam break (eg, by hand), trigger ndrops water deliveries
                % with delay second delays.
                ndrops = 100; delay = 1; valve=lick_1;
                
                for b=1:1:ndrops;
                    sma = add_state(sma, 'name', ['openvalve_' num2str(b)], ...
                        'self_timer', WaterValveTime,...
                        'output_actions',{'DOut',valve},...
                        'input_to_statechange', {'Tup', ['delayToNextDrop_' num2str(b)]});
                    if b==ndrops
                        sma = add_state(sma, 'name', ['delayToNextDrop_' num2str(b)], ...
                            'self_timer', delay,...
                            'output_actions', {'SoundOut',IndSoundGo},...  %play a cue so we know when its over
                            'input_to_statechange', {'Tup', 'final_state'});

                        sma = add_state(sma, 'name', 'final_state', ...
                            'self_timer', 0.01,...
                            'input_to_statechange', {'Tup', 'check_next_trial_ready'});
                    else
                        sma = add_state(sma, 'name', ['delayToNextDrop_' num2str(b)], ...
                            'self_timer', delay,...
                            'input_to_statechange', {'Tup', ['openvalve_' num2str(b+1)]});
                    end
                end

            case 'Sound_Calibration'
                %Play a series of sounds (defined in SoundSection.m) at
                %diff frequecnies and volumes

                cindex=1;
                windex=1;
                for p=2:1:numel(soundNames)
                    if ~isempty(cell2mat(strfind(soundNames(p),'c_')))
                        calibNameIndex(cindex)=p;
                        calibName{cindex}=soundNames(p);
                        cindex=cindex+1;
                    elseif ~isempty(cell2mat(strfind(soundNames(p),'white_')))
                        whiteNameIndex(windex)=p;
                        whiteName{windex}=soundNames(p);
                        windex=windex+1;
                    end
                end

                IndsAll=[calibNameIndex whiteNameIndex];
                cindex=1;
                windex=1;

                %calibration volumes...copied from SoundSection
                minVol=1;
                maxVol=100000;
                volInterval=10000;
                volVec=[minVol:volInterval:maxVol];
                
                %loop through freuqnecies / defined sounds
                g=1;
                for b=1:1:numel(calibNameIndex)+numel(whiteNameIndex);
                    %get the sound name
                    if b<=numel(calibNameIndex)
                        soundName=[calibName{cindex} '_' num2str(b*g)];
                    elseif b>numel(calibNameIndex)
                        soundName=[whiteName{windex} '_' num2str(b*g)];
                    end

                    %volume changing loop
                    for g=1:1:numel(volVec)-1

                        if g>1

                            SoundSection(obj,'update_volume',soundName,volVec(g))

                        end

                        %first, trigger ephus to record the mic input
                        sma = add_state(sma, 'name', ['ephus_trig_' num2str(b*g)], ...
                            'self_timer', 0.01,...
                            'output_actions',{'DOut',ephus_trig},...
                            'input_to_statechange', {'Tup', ['baseline_' soundName{:}]});

                        %if this isnt the last iteration...
                        if b~=numel(calibNameIndex)+numel(whiteNameIndex)
                            sma = add_state(sma, 'name', ['baseline_' soundName{:}], ...
                                'self_timer', 0.1,... %pause
                                'input_to_statechange', {'Tup', ['playSound_' soundName{:}]});
                            %if this is the last calibration sound
                            if b==numel(calibNameIndex)
                                soundName1=calibName{cindex};
                                %soundName2=whiteName{windex};
                                sma = add_state(sma, 'name', ['playSound_' soundName1{:}], ...
                                    'output_actions',{'SoundOut',calibNameIndex(cindex)},...
                                    'self_timer', 0.2,... %play sounds (should be 100ms long
                                    'input_to_statechange', {'Tup', ['ephus_trig_' num2str(b+1)]});
                                %if this is a white noise sound
                            elseif b>numel(calibNameIndex)
                                soundName1=whiteName{windex};
                                %soundName2=whiteName{windex+1};
                                sma = add_state(sma, 'name', ['playSound_' soundName1{:}], ...
                                    'output_actions',{'SoundOut',whiteNameIndex(windex)},...
                                    'self_timer', 0.2,... %play sounds (should be 100ms long
                                    'input_to_statechange', {'Tup', ['ephus_trig_' num2str(b+1)]});

                                windex=windex+1;
                                %if this any calibation sound but the last
                            else
                                soundName1=calibName{cindex};
                                %soundName2=calibName{cindex+1};
                                sma = add_state(sma, 'name', ['playSound_' soundName1{:}], ...
                                    'output_actions',{'SoundOut',calibNameIndex(cindex)},...
                                    'self_timer', 0.2,... %play sounds (should be 100ms long
                                    'input_to_statechange', {'Tup', ['ephus_trig_' num2str(b+1)]});

                                cindex=cindex+1;
                            end

                            %on the last iteration...
                        else
                            soundName=whiteName{windex};
                            sma = add_state(sma, 'name', ['baseline_' soundName{:}], ...
                                'self_timer', 0.01,... %pause
                                'input_to_statechange', {'Tup', ['playSound_' soundName{:}]});

                            sma = add_state(sma, 'name', ['playSound_' soundName{:}], ...
                                'output_actions',{'SoundOut',whiteNameIndex(windex)},...
                                'self_timer', 0.01,... %play sounds (should be 100ms long
                                'input_to_statechange', {'Tup', ['final_state']});

                            sma = add_state(sma, 'name', 'final_state', ...
                                'self_timer', 0.01,...
                                'input_to_statechange', {'Tup', 'check_next_trial_ready'});
                        end
                    end
                end

            otherwise
        end
        %JPL - will need to delete/comment this automatically when doing
        %transfers
        %dispatcher('send_assembler', sma, 'final_state');
end %%% SWITCH action
