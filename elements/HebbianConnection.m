% HebbianConnection (COSIVINA toolbox)
%   Connective element that extends the AdaptiveWeightMatrix step. The
%   steps default behavior mirrors that of the AdaptiveWeightMatrix.
%   Additionally you can set different buildup and decay time scales,
%   switch between instar and outstar learning rule, gate learning with a
%   reward signal and defined learning periods and you can make the step
%   bidirectional. You can also set parameters for a manual weight matrix
%   for a gaussian connection profile. 

%   The step was made to be compatible with the HebbiaConnection step in
%   Cedar: https://cedar.ini.rub.de/

%   Please refer to the exampleHebbian.Connection.m file in the examples
%   folder for examples of how to use this step.
%
% Constructor call:
% HebbianConnection(label, learningRate, rewardDuration, tau, tauDecay, bidirectional, instar, manualWeights)
%   label - element label
%   learningRate - scalar value that scales the rate of weight changes
%   rewardDuration - fixed duration of reward after a reward signal is
%                    detected. An optional delay can be added. ([reward delay,reward duration], 
%                    default value of [-1,-1] = no fixed duration and no check for reward signal)
%   tau            - Time scale for build up of weights.
%   tauDecay       - Time scale for decay of weights.
%   bidirectional  - flag indicating if the step is bidirectional ['TRUE', 'FALSE']
%   instar         - flag indicating if the step uses instar or outstar
%                    learning rules
%   manualWeights - sets gaussian weight matrix as optional manual weights.
%                   Weigths are specified as parameters of the gaussian. [mu_y, mu_x, sigma_y, sigma_x]
%                   (no 3-dimensional or higher dimensional weights are supported right now)


classdef HebbianConnection < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'learningRate', ParameterStatus.Changeable);
    components = {'output', 'reverse_output', 'weights'};
    defaultOutputComponent = 'output';
    
  end
  
  properties
    % parameters
    inputDim = 1;
    outputDim = 1;
    inputSize = [1,1];
    outputSize = [1,1];

    learningRate = 0.1;
    rewardDuration = [-1,-1];
    rewardTimer = 0;
    onsetDetection = 0;

    biDirectional = 'FALSE';

    tau = 1;
    tauDecay = 1;
    weightsParameters = [];

    instar = 0;
    
    % accessible structures
    output
    reverse_output
    weights
  end

  methods
    % constructor
    function obj = HebbianConnection(label, learningRate, rewardDuration, tau, tauDecay, biDirectional, instar, manualWeights)
      obj.label = label;
      if nargin >= 2
        obj.learningRate = learningRate;
      end
      if nargin >= 3
        obj.rewardDuration=rewardDuration;
      end
      if nargin >= 4
          if tau == 0
              warning('HebbianConnection:Constructor:invalidParameter','Tau of 0 is invalid. Continue using defualt of 20.');
              obj.tau = 20;
          else
              obj.tau = tau;
          end
      end
      if nargin >= 5
          if tauDecay == 0
              warning('HebbianConnection:Constructor:invalidParameter','TauDecay of 0 is invalid. Continue using defualt of 20.');
              obj.tauDecay = 20;
          else
            obj.tauDecay = tauDecay;
          end
      end
      if nargin >= 6
          obj.biDirectional = biDirectional;
      end
      if nargin >= 7
          obj.instar = instar;
      end
      if nargin >= 8
        obj.weightsParameters = manualWeights;
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      % Update output
      obj.output = tensorprod(obj.weights, obj.inputElements{1}.(obj.inputComponents{1}), 1:obj.inputDim, 1:obj.inputDim);
      if (strcmp(obj.biDirectional,'TRUE'))
        obj.reverse_output = tensorprod(permute(obj.weights, [(1:size(obj.outputSize,2))+size(obj.inputSize,2),1:size(obj.inputSize,2)]), obj.inputElements{2}.(obj.inputComponents{2}), 1:obj.outputDim, 1:obj.outputDim);
      end

      %Check Reward Status
      isRewarded = 0;
      if (all(obj.rewardDuration == -1) && (obj.nInputs < 3))
        % No duration and no reward signal
        isRewarded = 1;
      end
      if (all(obj.rewardDuration == -1) && obj.nInputs == 3)
          % Gating reward signal but no reward duration
          isRewarded = 1 * ( obj.inputElements{3}.(obj.inputComponents{3}) > 0.9 );
      end

      if (all(obj.rewardDuration ~= -1) && obj.nInputs == 3 && obj.onsetDetection == 0)
          % Reward onset detection
          if obj.inputElements{3}.(obj.inputComponents{3}) > 0.9
              obj.rewardTimer = time;
              obj.onsetDetection = 1;
          end
      end
      if (all(obj.rewardDuration ~= -1) && obj.nInputs == 3 && obj.onsetDetection == 1)
        % Duration and gating reward signal
        isRewarded = 1 * ( (time > (obj.rewardTimer + obj.rewardDuration(1))) && ...
            (time < (obj.rewardTimer + obj.rewardDuration(2) + obj.rewardDuration(1))) );
        
        % Reward offset
        if (time >= (obj.rewardTimer + obj.rewardDuration(2) + obj.rewardDuration(1)))
            obj.onsetDetection = 0;
        end
      end

      % Update weights if necessary
      if isRewarded
        timeFactor1 = obj.inputElements{2}.(obj.inputComponents{2}) .* (deltaT/obj.tau);
        timeFactor2 = (1-obj.inputElements{2}.(obj.inputComponents{2})) .* (deltaT/obj.tauDecay);

        % expand timefactor, input and output to match weight dimension...
        expandOutput = repmat(obj.inputElements{2}.(obj.inputComponents{2}), [ones(1,obj.outputDim), obj.inputSize]);
        expandOutput = permute(expandOutput, [obj.outputDim+1:obj.outputDim+obj.inputDim, 1:obj.outputDim]);
        expandInput = repmat((obj.inputElements{1}.(obj.inputComponents{1})), [ones(1,obj.inputDim), obj.outputSize]);
        timeFactor = repmat(timeFactor1 + timeFactor2, [ones(1,obj.outputDim), obj.inputSize]);
        timeFactor = permute(timeFactor, [obj.outputDim+1:obj.outputDim+obj.inputDim, 1:obj.outputDim]);

        if obj.instar == 1
            obj.weights = obj.weights + timeFactor .* (isRewarded * obj.learningRate * (expandOutput- obj.weights) .* expandInput);
        else
            obj.weights = obj.weights + timeFactor .* (isRewarded * obj.learningRate * (expandInput- obj.weights) .* expandOutput);
        end

      end

    end
    
    
    % initialization
    function obj = init(obj)
      obj.inputSize = size(obj.inputElements{1}.(obj.inputComponents{1}));
      obj.inputDim = numel(obj.inputSize);
      obj.outputSize = size(obj.inputElements{2}.(obj.inputComponents{2}));
      obj.outputDim = numel(obj.outputSize);

      obj.weights = zeros([obj.inputSize, obj.outputSize]);
      if size(obj.weightsParameters) > 0
          % manual weights (Only 1d and 2d gauß supported right now)
          if size(obj.weightsParameters,2) == 4
            real_dim_idx = find([obj.inputSize, obj.outputSize]>1); % there are some rogue dimensions of size 1 flying around, because of matlab math
            gauss_size = size(obj.weights, real_dim_idx);
            index = repmat({':'}, 1, ndims(obj.weights));
            for i = 1:length(real_dim_idx)
                index{real_dim_idx(i)} = 1:gauss_size(i);
            end
            obj.weights(index{:}) = gauss2d(1:gauss_size(2), 1:gauss_size(1), obj.weightsParameters(1), obj.weightsParameters(2), obj.weightsParameters(3), obj.weightsParameters(4));
          elseif size(obj.weightsParameters,2) == 2
            real_dim_idx = find([obj.inputSize, obj.outputSize]>1); % there are some rogue dimensions of size 1 flying around, because of matlab math
            gauss_size = size(obj.weights, real_dim_idx);
            index = repmat({':'}, 1, ndims(obj.weights));
            for i = 1:length(real_dim_idx)
                index{real_dim_idx(i)} = 1:gauss_size(i);
            end
            obj.weights(index{:}) = gauss(1:gauss_size, obj.weightsParameters(1), obj.weightsParameters(2));
          end
      end


      obj.output = zeros(obj.outputSize);
      obj.reverse_output = zeros(obj.inputSize);
    end

  end
end


