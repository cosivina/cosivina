% PointwiseProduct (COSIVINA toolbox)
%   Element that computes the pointswise product between two inputs.
%
% Constructor call:
% PointwiseProduct(label, size)
%   label - element label
%   size - size of inputs and output (one of the inputs may be a scalar)


classdef PointwiseProduct < Element
  
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
    function obj = PointwiseProduct(label, size)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
           
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = obj.inputElements{1}.(obj.inputComponents{1}) .* obj.inputElements{2}.(obj.inputComponents{2});
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end
  end
end


