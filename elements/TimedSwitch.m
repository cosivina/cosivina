% TimedSwitch (COSIVINA toolbox)
%   Creates an element whose output is either zero or matches the input,
%   with switches occuring at specified simulation times.
%
% Constructor call:
% TimedSwitch(label, size, onTimes)
%   label - element label
%   size - size of the output matrix or vector
%   onTimes - Nx2 matrix of the form [tStart1, tEnd1; ...; tStartN, tEndN];
%     switch is active at simulation time t if tStartK <= t <= tEndK for
%     any K


classdef TimedSwitch < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, ...
      'onTimes', bitor(ParameterStatus.Changeable, ParameterStatus.VariableRowsMatrix));
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    onTimes = zeros(0, 2);
    
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = TimedSwitch(label, inputSize, onTimes)
      if nargin > 0
        obj.label = label;
        obj.size = inputSize;
        obj.onTimes = onTimes;
      end
      
      if size(obj.onTimes, 2) ~= 2 %#ok<CPROP>
        error('TimedSwitch:constructor:invalidArgument', 'Argument onTimes must be an Nx2 matrix.');
      end
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      if any(time >= obj.onTimes(:, 1) & time <= obj.onTimes(:, 2))
        obj.output = obj.inputElements{1}.(obj.inputComponents{1});
      else
        obj.output(:) = 0;
      end
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end
  end
  
end
