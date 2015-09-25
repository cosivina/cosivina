%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COSIVINA Sample File to illustrate Auto and Batch Modes 
% 
% Joseph Ambrose & John Spencer
% 1/16/2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mode = 0; % 1 for auto mode with visualization, 0 for batch mode
n_reps = 5; % repetitions for batch mode, overwritten to 1 for auto
t_stimoff = 1000; % trial begins with the stimulus on, this denotes the end of the target presentation period
t_max = 6000; % total time for the trial - stimulus time (1000) plus delay time (5000)
              % output is recorded at the end of the delay
fieldsize = 397; %should be an odd number -- value taken from Schutte & Spencer (2009)
fieldmidline = 199; % where the midline of the field is considered to be
stimoffset = 20; % how far from the midline the stimulus will be presented
stimamplitude = 45; % the strength of the target stimulus
filename = '3Layer.out';

% create model structure and initialize
create3LayerSim;
sim.init();

% if auto mode, creat GUI for visualization
% If batch mode, GUI excluded for faster computation
if mode
    create3LayerGUI;
    gui.addVisualization(TimeDisplay(), [4, 2], [1, 1], 'control');
    gui.init();
    n_reps = 1;
end

% initialize variables used in output calculations
units = 1:fieldsize;
headerflag = 1; %only write the header to the output file once
savestate_w = zeros(1,fieldsize); %store the state of the w layer
w_drift = 0;

% load selected parameter set to test (from json file)
sim.loadSettings('presetThreeLayerFieldSS_44.json');

% calculate the absolute position of the stimulus and move it appropriately
stimposition = stimoffset*1.2+fieldmidline; % factor of 1.2 converts between units and degrees
sim.setElementParameters('stimulus 2', 'position', stimposition);

% loop through the number of trial repetitions specified by n_reps
for k = 1:n_reps
    
    % reset state of model at the start of each trial
    sim.init();
    
    % loop through the timesteps for each trial specified by t_max
    while sim.t <= t_max
        t = sim.t;
        
        % turn stimulus on at beginning of trial
        if t == 1
            sim.setElementParameters('stimulus 2', 'amplitude', stimamplitude);
            
        % turn stimulus off at end of the target presentation period
        elseif t == t_stimoff
            sim.setElementParameters('stimulus 2', 'amplitude', 0);
            
        % save data at the end of the trial
        elseif t == t_max
            % the data we want to store is from the w layer (WM field)
            savestate_w(1,:) = sim.getComponent('field w', 'activation');
        end
        
        % if in auto mode, monitor pause and quit buttons
        if mode
            if ~gui.pauseSimulation
                sim.step();
            end
            if gui.quitSimulation
                gui.close();
                break;
            end
            
            gui.checkAndUpdateControls();
            gui.updateVisualizations();
            
        % if in batch mode, there are no buttons to monitor
        else
            sim.step();
        end
        
    end % time loop
    
    % after trial is over, calculate peak location from saved data
    % first step is to threshold the field activity with a sharp sigmoid function (beta = 20)
    % and a raised threshold value (0.5 units)
    w = sigmoid(savestate_w(1,:), 20, 0.5);
    
    % compute the weighted average of the thresholded activity in units
    % to determine where the peak is centered in the field
    peakposition = w*units'/sum(w);
    
    % compute the error relative to the target location and translate units into degrees
    % this gives us the amount of drift
    w_drift = (peakposition - stimposition)/1.2;
    
    % output to a space-delimited file for later analysis
    OutFile = fopen(filename,'a');
    if(headerflag)
        headerflag = 0;
        fprintf(OutFile,'Target Drift\n');
    end
    fprintf(OutFile,'%i %6.4f \n', stimoffset, w_drift);
    fclose(OutFile);
    
end % trial loop

% if in auto mode, close the GUI window after the trial is over
if mode
    gui.close();
end