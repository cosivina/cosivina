% TimedCustomStimulus (COSIVINA toolbox)
%   Creates a custom-defined stimulus pattern that is active at specified
%   periods in simulation time.
% 
% Constructor call:
% TimedCustomStimulus(label, stimulusPattern)
%   label - element label
%   stimulusPattern - full stimulus matrix
%   onTimes - Nx2 matrix of the form [tStart1, tEnd1; ...; tStartN, tEndN];
%     stimulus is on at simulation time t if tStartK <= t <= tEndK for
%     any K
%
% NOTE: The full stimulus pattern will be stored in the parameter file when
% saving parameters. This may lead to bulky parameter files.

classdef TimedCustomStimulus < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'stimulusPattern', ParameterStatus.Fixed, ...
      'onTimes', bitor(ParameterStatus.Changeable, ParameterStatus.VariableRowsMatrix));
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    stimulusPattern = 0;
    onTimes = zeros(0, 2);
    
    on = false;
    
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = TimedCustomStimulus(label, stimulusPattern, onTimes)
      if nargin > 0
        obj.label = label;
        obj.size = size(stimulusPattern); %#ok<CPROP>
        obj.stimulusPattern = stimulusPattern;
        obj.onTimes = onTimes;
      end
      if size(obj.onTimes, 2) ~= 2 %#ok<CPROP>
        error('TimedCustomStimulus:constructor:invalidArgument', 'Argument onTimes must be an Nx2 matrix.');
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      shouldBeOn = any(time >= obj.onTimes(:, 1) & time <= obj.onTimes(:, 2));
      if ~obj.on && shouldBeOn
        obj.output = obj.stimulusPattern;
        obj.on = true;
      elseif obj.on && ~shouldBeOn
        obj.output(:) = 0;
        obj.on = false;
      end
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end
  end
  
end

