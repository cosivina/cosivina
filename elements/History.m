% History (COSIVINA toolbox)
%   Element that stores its input at specified times. A vector of
%   simulation times [t_1, ..., t_K] must be specified. The input to the
%   element at those times is then stored in a K x N matrix if the input is
%   a vector of size n, or in a N x M x K matrix if the input is a matrix
%   of size N x M.
% 
% Constructor call:
% History(label, inputSize, storingTimes)
%   label - element label
%   inputSize - size of input
%   storingTimes - vector of simulation times at which the input is stored


classdef History < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'storingTimes', ParameterStatus.Fixed);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    storingTimes = [];
    
    dimensionality = 1;
    
    % accessible structures
    output
  end
  

  methods
    % constructor
    function obj = History(label, inputSize, storingTimes)
      if nargin > 0
        obj.label = label;
        obj.size = inputSize;
        obj.storingTimes = storingTimes;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT)  %#ok<INUSD>
      for j = find(obj.storingTimes == time)
        if obj.dimensionality == 1
          obj.output(j, :) = obj.inputElements{1}.(obj.inputComponents{1});
        elseif obj.dimensionality == 2
          obj.output(:, :, j) = obj.inputElements{1}.(obj.inputComponents{1});
        end
      end
    end
    
    
    % intialization
    function obj = init(obj)
      if obj.size(1) == 1
        obj.dimensionality = 1; % dimensionality of zero not treated separately
      elseif numel(obj.size) == 2
        obj.dimensionality = 2;
      else
        error('History:init:unsopportedInputSize', ...
          'The class History does currently not support inputs of more than two dimensions');
      end
      
      if obj.dimensionality == 1
        obj.output = NaN(numel(obj.storingTimes), obj.size(2));
      else
        obj.output = NaN(obj.size(1), obj.size(2), numel(obj.storingTimes));
      end
    end
  end
end


