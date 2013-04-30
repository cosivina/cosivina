% ScaleInput (COSIVINA toolbox)
%   Element to scale an input with a constant factor
%
% Constructor call:
% ScaleInput(label, size, amplitude)
%   label - element label
%   size - size of input and output
%   amplitude - scaling factor


classdef ScaleInput < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'amplitude', ParameterStatus.Changeable);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    amplitude = 0;
        
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = ScaleInput(label, size, amplitude)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 3
        obj.amplitude = amplitude;
      end

      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = obj.amplitude * obj.inputElements{1}.(obj.inputComponents{1});
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end
      
  end
end


