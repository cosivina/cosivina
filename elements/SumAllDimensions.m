% SumAllDimensions (COSIVINA toolbox)
%   Element that computes the horizontal, vertical, and total sum of an
%   input.
%
% Constructor call:
% SumAllDimensions(label, inputSize)
%   inputSize - size of the input


classdef SumAllDimensions < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed); 
    components = {'horizontalSum', 'verticalSum', 'fullSum'};
    defaultOutputComponent = 'fullSum';
  end
  
  properties
    % parameters
    size = [1, 1];
        
    % accessible structures
    horizontalSum
    verticalSum
    fullSum
  end
  
  methods
    % constructor
    function obj = SumAllDimensions(label, inputSize)
      if nargin > 0
        obj.label = label;
        obj.size = inputSize;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.horizontalSum = sum(obj.inputElements{1}.(obj.inputComponents{1}), 2)';
      obj.verticalSum = sum(obj.inputElements{1}.(obj.inputComponents{1}), 1);
      obj.fullSum = sum(obj.verticalSum, 2);
    end
    
    
    % initialization
    function obj = init(obj)
      obj.horizontalSum = zeros(1, obj.size(1));
      obj.verticalSum = zeros(1, obj.size(2));
      obj.fullSum = 0;
    end
      
  end
end


