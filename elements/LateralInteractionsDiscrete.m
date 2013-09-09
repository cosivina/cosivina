% LateralInteractionsDiscrete (COSIVINA toolbox)
%   Connective element that computes self-excitation and global inhibition
%   as typical lateral interaction pattern for sets of discrete nodes.
%   The output is computed as amplitudeExc * input + amplitudeGlobal *
%   sum(input), where the sum is taken over all dimensions of the input.
%
% Constructor call:
% LateralInteractionsDiscrete(label, size, amplitudeExc, amplitudeGlobal)
%   size - size of input and output (may be of any dimensionality)
%   amplitudeExc - amplitude of self-excitation
%   amplitudeGlobal - amplitude of global component (set to a negative
%     value to obtain global inhibition)


classdef LateralInteractionsDiscrete < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'amplitudeExc', ParameterStatus.InitStepRequired, ...
      'amplitudeGlobal', ParameterStatus.Changeable);
    components = {'amplitudeExc', 'amplitudeGlobal', 'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    amplitudeExc = 0;
    amplitudeGlobal = 0;
    
    % accessible structures
    output
  end
  
  
  methods
    % constructor
    function obj = LateralInteractionsDiscrete(label, size, amplitudeExc, amplitudeGlobal)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 3
        obj.amplitudeExc = amplitudeExc;
      end
      if nargin >= 4
        obj.amplitudeGlobal = amplitudeGlobal;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      input = obj.inputElements{1}.(obj.inputComponents{1});
      obj.output = obj.amplitudeExc * input + obj.amplitudeGlobal * sum(reshape(input, [numel(input), 1]));
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end

  end
end


