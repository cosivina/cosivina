% SumInputs (COSIVINA toolbox)
%   Element to compute the sum of several inputs (matrices of equal size or
%   scalars)
%
% Constructor call:
% SumInputs(label, size)
%   label - element label
%   size - size of non-scalar inputs and output


classdef SumInputs < Element
  
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
    function obj = SumInputs(label, size)
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
      obj.output = obj.inputElements{1}.(obj.inputComponents{1});
      for i = 2 : obj.nInputs
        obj.output = obj.output + obj.inputElements{i}.(obj.inputComponents{i});
      end
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end
  end
end


