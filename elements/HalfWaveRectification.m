% HalfWaveRectification (COSIVINA toolbox)
%   Element that applies a positive half-wave rectification to the input:
%   f(x) = x if x > 0
%   f(x) = 0 else
%
% Constructor call:
% HalfWaveRectification(label, size)
%   label - element label
%   size - size of input and output


classdef HalfWaveRectification < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = HalfWaveRectification(label, size)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = max(obj.inputElements{1}.(obj.inputComponents{1}), 0);
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end

  end
end


