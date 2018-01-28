% TimedBoost (COSIVINA toolbox)
%   Creates a scalar/boost stimulus that is active at specified periods in 
%   simulation time.
%
% Constructor call:
% TimedGaussStimulus1D(label, amplitude, onTimes)
%   label - element label
%   amplitude - amplitude of boost stimulus
%   onTimes - Nx2 matrix of the form [tStart1, tEnd1; ...; tStartN, tEndN];
%     stimulus is on at simulation time t if tStartK <= t <= tEndK for
%     any K

classdef TimedBoost < Element
  
  properties (Constant)
    parameters = struct('amplitude', ParameterStatus.InitStepRequired, ...
      'onTimes', bitor(ParameterStatus.Changeable, ParameterStatus.VariableRowsMatrix));
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    amplitude = 0;
    onTimes = zeros(0, 2);
    
    on = false;
    
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = TimedBoost(label, amplitude, onTimes)
      if nargin > 0
        obj.label = label;
      end
      if nargin >= 2
        obj.amplitude = amplitude;
      end
      if nargin >= 3
        obj.onTimes = onTimes;
      end
      
      if size(obj.onTimes, 2) ~= 2
        error('TimedBoost:constructor:invalidArgument', 'Argument onTimes must be an Nx2 matrix.');
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
%       shouldBeOn = any(time >= obj.onTimes(:, 1) & time <= obj.onTimes(:, 2));
      i = find(time >= obj.onTimes(:, 1) & time <= obj.onTimes(:, 2), 1);
      shouldBeOn = ~isempty(i);
      if ~obj.on && shouldBeOn
        obj.output = obj.amplitude(i);
        obj.on = true;
      elseif obj.on && ~shouldBeOn
        obj.output = 0;
        obj.on = false;
      end
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = 0;
      obj.on = false;
    end
  end
  
end
