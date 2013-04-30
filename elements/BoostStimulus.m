% BoostStimulus (COSIVINA toolbox)
%   Creates a constant scalar stimulus.
% 
% Constructor call:
% BoostStimulus(label, amplitude)
%   label - element label
%   amplitude - value of the scalar stimulus


classdef BoostStimulus < Element
  
  properties (Constant)
    parameters = struct('amplitude', ParameterStatus.InitRequired);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    amplitude = 0;
    size = [1, 1];
        
    % accessible structures
    output = [];
  end
  
  methods
    % constructor
    function obj = BoostStimulus(label, amplitude)
      if nargin > 0
        obj.label = label;
      end
      if nargin >= 2
        obj.amplitude = amplitude;
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      % nothing to do
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = obj.amplitude;
    end
  end
  
end
