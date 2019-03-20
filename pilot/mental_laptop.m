function mental_laptop(name_prefix, tgt_file_name_prefix, tgt_set)

Screen('Preference', 'SkipSyncTests', 1);
Priority(1)
PsychDefaultSetup(2);
% Get the screen numbers
screens = Screen('Screens');
screenNumber = max(screens);
dir='/Users/jonathantsay/Dropbox/GitHub/mental-numberline/pilot/';
mm2pixel = 3.00;

%% Screen setup

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black); % can add to minimize screen [], [0 0 680 680]

ListenChar(2)% -rm- no idea what this is
% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
ifi = Screen('GetFlipInterval', window);
Screen('TextFont', window, 'Ariel');
Screen('TextSize', window, 60);
% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

%% Load target file 

cd([dir 'TargetFiles'])

tgt_file = dlmread([tgt_file_name_prefix,tgt_set,'.tgt'], '\t', 1, 0); % start reading in from 2nd row (1), 1st column (0)
trial_num = tgt_file(:,1);
first_op = tgt_file(:, 2); 
sec_op = tgt_file(:, 3); 
operation_neg = tgt_file(:, 4); 
operation_sum = tgt_file(:, 5); 
between_blocks = tgt_file(:,6);
numtrials = size(tgt_file,1);
maxtrialnum = max(numtrials);

%% Define variables

% color variables
gray = [1 1 1]*0.44;
blue = [0 0 255];

% initialize time variables 
insidetime = 0;
curtime = 0;
searchtime = 0; 
pausetime = 0.0;
rt = 0;
mt = 0;
fb_time = 0;
tgtstart = 0; 
gamephase = -1;
trial = 1;
char1 = ' ';
key_isnt_already_down = 1;
            
% stimulus duration  
searchtime_max = 2;
tgttime = 3; 

% store data 
RTs = [];
MTs = [];
SearchTimes = [];
data = [];
problem_report = cell(maxtrialnum,1);

% Define the ESC key
KbName('UnifyKeynames');
esc = KbName('ESCAPE');
space = KbName('SPACE');

% Set the mouse to the center of the screen to start with
HideCursor;

% See Matlab for Behavioral Scientists by David A. Rosenbaum. 
desiredSampleRate = 500;
k = 0;

% Variables that store data -all copied from Ryan's code
MAX_SAMPLES=6e6; %about 1 hour @ 1.6kHz = 60*60*1600
gamephase_move=nan(MAX_SAMPLES,1);
tablet_queue_length=nan(MAX_SAMPLES,1);
thePoints=nan(MAX_SAMPLES,2);
dt_all = nan(MAX_SAMPLES,1);
t = nan(MAX_SAMPLES,1);
trial_time = nan(MAX_SAMPLES,1);
trial_move = nan(MAX_SAMPLES,1);

%% Loop game until over or ESC key press
tic;
begintime = GetSecs;
nextsampletime = begintime;

while trial <= maxtrialnum   
    
    % Exits experiment when ESC key is pressed. 
    [keyIsDown, secs, keyCode] = KbCheck;
    if keyIsDown
        if keyCode(esc)
            break
        end
    end
         
    k = k+1;    % just to stay consistent with Ryan's code
    t(k) = GetSecs - begintime;
    dt = toc-curtime;
    dt_all(k) = dt;
    
    if k == 1
        trial_time(k) = dt;
    else
        trial_time(k) = trial_time(k-1) + dt;
    end
    
    curtime = toc;
    % Flip to the screen
    % last argument - 1: synchronous screen flipping, 2:asynchronous screen flipping
    Screen('Flip', window, 0, 0, 2);
     
    % Record trial number
    trial_move(k) = trial;
        
%% Gamephase -1 = start/pause 
    
    if gamephase == -1
               
            [keyIsDown, secs, keyCode] = KbCheck;
            
            if keyIsDown == 1
                gamephase = 0;
            else
                Screen('DrawText', window, 'Press any Key to Begin', xCenter-350, yCenter, white);  
            end    
            
%% Gamephase 0 = ready cue 

    elseif gamephase == 0  
        
        searchtime = searchtime + dt;
        SearchTimes(trial) = searchtime;
        
        if searchtime <= searchtime_max
            % Draw ready cue
            Screen('DrawText', window, '*', xCenter, yCenter, white);
        else
            gamephase = 1;
        end
        
%% Gamephase 1 = draw math problem         
        
    elseif gamephase == 1
        
        tgtstart = tgtstart + dt;
        rt = rt + dt; 
        
        [keyIsDown, secs, keyCode] = KbCheck;
        
        if (keyIsDown == 0) & (tgtstart <= tgttime)
            Screen('DrawText', window, int2str(first_op(trial)), xCenter-100, yCenter, white);
            Screen('DrawText', window, '+', xCenter-50, yCenter, white);
            Screen('DrawText', window, int2str(sec_op(trial)), xCenter, yCenter, white); 
            Screen('DrawText', window, '=', xCenter+50, yCenter+10, white); 
            
            if operation_sum(trial) < 10
                Screen('DrawText', window, strcat('0', int2str(operation_sum(trial))), xCenter+100, yCenter, white);   
            else
                Screen('DrawText', window, int2str(operation_sum(trial)), xCenter+100, yCenter, white); 
            end
        elseif (keyIsDown == 1) & (tgtstart <= tgttime)
            
            char1 = KbName(keyCode);
            RTs(trial) = rt;
            problem_report{trial} = char1;
            char1 = ' '; %reset for next trial
            keyIsDown = 0; 
            gamephase = 2;
            
        else
            RTs(trial) = nan;
            problem_report{trial} = nan;
            char1 = ' '; %reset for next trial
            keyIsDown = 0; 
            gamephase = 2; 
        end

                               
%% Gamephase 2 = between block messages         
   
    elseif gamephase == 2
        
        trial_time(k) = 0;
        
        if between_blocks(trial) ~= 0            
            if between_blocks(trial) == 1
                Screen('DrawText', window, 'Answer as quickly and accurately as possible!' , xCenter-700, yCenter, white);  
                Screen('DrawText', window, 'Right Arrow = True, Left Arrow = False.' , xCenter-600, yCenter + 100, white); 
            elseif between_blocks(trial) == 2
                Screen('DrawText', window, 'Answer as quickly and accurately as possible!' , xCenter-700, yCenter, white);  
                Screen('DrawText', window, 'Right Arrow = False, Left Arrow = True.' , xCenter-600, yCenter + 100, white); 
            elseif between_blocks(trial) == 3
                Screen('DrawText', window, 'The experiment is over. Thank you!' , xCenter-550, yCenter, white);                       
            end
            
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(space)
                    gamephase = -0;
                    fb_time = 0;
                    searchtime = 0;
                    rt = 0;
                    mt = 0;
                    timer = 0;
                    beep = 0;
                    trial_time(k) = 0;
                    trial = trial + 1;
                    tgtstart = 0; 
                end
            end
            
        else
 
            gamephase = 0;
            fb_time = 0;
            searchtime = 0;
            rt = 0;
            mt = 0;
            timer = 0;
            beep = 0;
            trial_time(k) = 0;
            trial = trial + 1;
            tgtstart = 0; 
            
        end
      
    end
    
    gamephase_move(k) = gamephase;

    sampletime(k) = GetSecs;
    nextsampletime = nextsampletime + 1/desiredSampleRate;
    
    while GetSecs < nextsampletime
        
    end  
end

%% Save data  

endtime = GetSecs;
elapsedTime = endtime - begintime;
numberOfSamples = k;
actualSampleRate = 1/(elapsedTime / numberOfSamples);


ShowCursor;
% Clear the screen
sca;

ListenChar(0);

cd([dir 'Data'])
% Save data
name_prefix_all = [tgt_file_name_prefix,name_prefix];
disp('Saving...')
if ~exist([name_prefix_all,'.mat'],'file')
    datafile_name = [name_prefix_all,'.mat'];
  
elseif ~exist([name_prefix_all,'_a.mat'],'file'), datafile_name = [name_prefix_all,'_a.mat'];
elseif ~exist([name_prefix_all,'_b.mat'],'file'), datafile_name = [name_prefix_all,'_b.mat'];
else
    char1='c';
    while exist([name_prefix_all,'_',char1,'.mat'],'file'), char1=char(char1+1); end
    datafile_name = [name_prefix_all,'_',char1,'.mat'];
end
save(datafile_name); 
disp(['Saved ', datafile_name]);
%end

% Go back to the experiment directory
cd(dir)

