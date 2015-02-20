% AdaptiveWeightMatrix (COSIVINA toolbox)
%   Connective element that multiplies its first input with a weight matrix
%   W, and updates the weight matrix according to a Hebbian learning rule.
%   The output O is computed as
%   O = I1 * W,
%   where both the input I1 and the output O are row vectors.
%   The weight matrix is updated at each position according to the rule
%   dW(i, j) = learningRate * G * [I2(j) - W(i, j)] * I1(i)
%   Here, G is an optional third input (scalar) that gates the learning. I2
%   is the same size as O and should typically be derived from the same
%   structure (such as a neural field) that also receives input from the
%   AdaptiveWeightMatrix. W is initialized as a zero matrix.
%
% Constructor call:
% AdaptiveWeightMatrix(label, size)
%   label - element label
%   size - size of the weight matrix (input size x output size)
%   learningRate - scalar value that scales the rate of weight changes


classdef AdaptiveWeightMatrix < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'learningRate', ParameterStatus.Changeable);
    components = {'output', 'weights'};
    defaultOutputComponent = 'output';
    
  end
  
  properties
    % parameters
    size = [1, 1];
    learningRate = 0.1;
    
    % accessible structures
    output
    weights
  end

  
  methods
    % constructor
    function obj = AdaptiveWeightMatrix(label, size, learningRate)
      obj.label = label;
      obj.size = size;
      obj.learningRate = learningRate;
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = obj.inputElements{1}.(obj.inputComponents{1}) * obj.weights;
      
      if obj.nInputs == 3 % third input for gating weight updates
        obj.weights = obj.weights + obj.inputElements{3}.(obj.inputComponents{3}) * obj.learningRate ...
          * (repmat(obj.inputElements{2}.(obj.inputComponents{2}), [obj.size(1), 1]) - obj.weights) ...
          .* repmat( (obj.inputElements{1}.(obj.inputComponents{2}))', [1, obj.size(2)]);
      else
        obj.weights = obj.weights + obj.learningRate ...
          * (repmat(obj.inputElements{2}.(obj.inputComponents{2}), [obj.size(1), 1]) - obj.weights) ...
          .* repmat( (obj.inputElements{1}.(obj.inputComponents{2}))', [1, obj.size(2)]);
      end
    end
    
    
    % initialization
    function obj = init(obj)
      obj.weights = zeros(obj.size);
      obj.output = zeros(obj.size(2));
    end

  end
end


