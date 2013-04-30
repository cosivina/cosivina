% Sigmoid (COSIVINA toolbox)
%   Element that applies a sigmoid (logistic) function to the input.
%
% Constructor call:
% Sigmoid(label, size, beta, threshold)
%   label - element label
%   size - size of input and output
%   beta - steepness parameter of the logistic function
%   threshold - threshold for the logistic function


classdef Sigmoid < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'beta', ParameterStatus.Changeable, ...
      'threshold', ParameterStatus.Changeable);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    beta = 1;
    threshold = 0;
    
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = Sigmoid(label, size, beta, threshold)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 3
        obj.beta = beta;
      end
      if nargin >= 4
        obj.threshold = threshold;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = sigmoid(obj.inputElements{1}.(obj.inputComponents{1}), obj.beta, obj.threshold);
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end

  end
end


