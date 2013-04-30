% SumDimension (COSIVINA toolbox)
%   Element that computes sum over one or two dimensions of its input.
%
% Constructor call:
% SumDimension(label, sumDimensions, outputSize, amplitude)
%   sumDimensions - dimension(s) of the input over which sum is computed
%     (can be 1, 2, or [1, 2])
%   outputSize - size of the resulting output
%   amplitude - scalar value that is multiplied with the formed sum


classdef SumDimension < Element
  
  properties (Constant)
    parameters = struct('sumDimensions', ParameterStatus.Fixed, 'amplitude', ParameterStatus.Changeable, ...
      'size', ParameterStatus.Fixed); 
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    sumDimensions = 1;
    amplitude = 0;
    size = [1, 1];
        
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = SumDimension(label, sumDimensions, outputSize, amplitude)
      if nargin > 0
        obj.label = label;
        obj.sumDimensions = sumDimensions;
        obj.size = outputSize;
      end
      if nargin >= 4
        obj.amplitude = amplitude;
      end      

      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = sum(obj.inputElements{1}.(obj.inputComponents{1}), obj.sumDimensions(1));
      for i = 2 : numel(obj.sumDimensions)
        obj.output = sum(obj.output, obj.sumDimensions(i));
      end
      obj.output = obj.amplitude * reshape(obj.output, [obj.size]);
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end
      
  end
end


