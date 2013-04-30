% NormalNoise (COSIVINA toolbox)
%   Creates a matrix of independent normally distributed random values in
%   each step. Note: The strength of the noise is scaled with
%   1/sqrt(deltaT) so that it will be effectively be scaled with
%   sqrt(deltaT) when used as input in the field equation. Note that
%   the scaling with 1/tau is also applied to all inputs in the field
%   equation, and may have to be compensated for in the noise amplitude.
% 
% Constructor call:
% NormalNoise(label, size, amplitude)
%   label - element label
%   size - size of the output
%   amplitude - factor that random values are scaled with


classdef NormalNoise < Element
  
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
    function obj = NormalNoise(label, size, amplitude)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 3
        obj.amplitude = amplitude;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSL>
      obj.output = 1/sqrt(deltaT) * obj.amplitude * randn(obj.size);
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end
  end
  
end
