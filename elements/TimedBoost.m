% TimedBoost (COSIVINA toolbox)
%   Creates a scalar/boost stimulus that is active at specified periods in 
%   simulation time.
%
% Constructor call:
% TimedGaussStimulus1D(label, amplitude, onTimes)
%   label - element label
%   amplitude - amplitude of boost stimulus (can be either a scalar, or an Nx1
%     vector to obtain different amplitudes for different time periods)
%   onTimes - Nx2 matrix of the form [tStart1, tEnd1; ...; tStartN, tEndN];
%     stimulus is on at simulation time t if tStartK <= t <= tEndK for
%     any K

classdef TimedBoost < Element
  
  properties (Constant)
    parameters = struct('amplitude', bitor(ParameterStatus.InitStepRequired, ParameterStatus.VariableRowsMatrix), ...
      'onTimes', bitor(ParameterStatus.Changeable, ParameterStatus.VariableRowsMatrix));
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    amplitude = 0;
    onTimes = zeros(0, 2);
    
    on = false;
    activeTimePeriod = NaN;
    
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
      if size(obj.amplitude, 2) ~= 1 || size(obj.amplitude, 1) > 1 && size(obj.amplitude, 1) ~= size(obj.onTimes, 1)
        error('TimedBoost:constructor:invalidArgument', ...
            'Argument amplitude must be a scalar or a column vector with number of rows matching onTimes');
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      i = find(time >= obj.onTimes(:, 1) & time <= obj.onTimes(:, 2), 1);
      shouldBeOn = ~isempty(i);
      if shouldBeOn && (~obj.on || obj.activeTimePeriod ~= i)
        obj.output = obj.amplitude(min(i, size(obj.amplitude, 1)));
        obj.on = true;
        obj.activeTimePeriod = i;
      elseif ~shouldBeOn && obj.on
        obj.output = 0;
        obj.on = false;
        obj.activeTimePeriod = NaN;
      end
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = 0;
      obj.on = false;
      obj.activeTimePeriod = NaN;
    end
  end
  
end
