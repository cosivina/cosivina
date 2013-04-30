% WeightMatrix (COSIVINA toolbox)
%   Connective element that multiplies its input with a weight matrix:
%   O = I * W
%   Both the input I and the output O are row vectors.
%
% Constructor call:
% WeightMatrix(label, weights)
%   label - element label
%   weights - matrix of connection weights (size of input and output is
%     determined from this)


classdef WeightMatrix < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'weights', ParameterStatus.Fixed);
    components = {'output'};
    defaultOutputComponent = 'output';
    
  end
  
  properties
    % parameters
    size = [1, 1];
    weights = 0;
        
    % accessible structures
    output
  end

  
  methods
    % constructor
    function obj = WeightMatrix(label, weights)
      if nargin > 0
        obj.label = label;
        obj.weights = weights;
        obj.size = size(weights); %#ok<CPROP>
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = obj.inputElements{1}.(obj.inputComponents{1}) * obj.weights;
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(1, obj.size(2));
    end

  end
end


