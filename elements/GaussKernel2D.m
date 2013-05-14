% GaussKernel2D (COSIVINA toolbox)
%   Connective element that performs a 2D convolution with a Gaussian kernel.
%
% Constructor call:
% GaussKernel2D(label, size, sigmaY, sigmaX, amplitude, circularY, ...
%     circularX, normalized, cutoffFactor)
%   label - element label
%   size - size of input and output of the convolution
%   sigmaY, sigmaX - vertical and horizontal width parameter of Gaussian
%     kernel
%   amplitude - amplitude of kernel
%   circularY, circularX - flags indicating whether convolution is circular
%   normalized - flag indicating whether kernel is normalized before
%     scaling with amplitude
%   cutoffFactor - multiple of sigma at which the kernel is cut off


classdef GaussKernel2D < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'sigmaX', ParameterStatus.InitStepRequired, ...
      'sigmaY', ParameterStatus.InitStepRequired, 'amplitude', ParameterStatus.InitStepRequired, ...
      'circularX', ParameterStatus.InitStepRequired, 'circularY', ParameterStatus.InitStepRequired, ...
      'normalized', ParameterStatus.InitStepRequired, 'cutoffFactor', ParameterStatus.InitStepRequired);
    components = {'kernelX', 'kernelY', 'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    sigmaY = 1;
    sigmaX = 1;
    amplitude = 0;
    circularY = true;
    circularX = true;
    normalized = true;
    cutoffFactor = 5;
    
    % accessible structures
    kernelY
    kernelX
    output
  end
  
  properties (SetAccess = private)
    kernelRangeY
    kernelRangeX
    extIndexY
    extIndexX
  end
  
  methods
    % constructor
    function obj = GaussKernel2D(label, size, sigmaY, sigmaX, amplitude, circularY, circularX, normalized, cutoffFactor)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 4
        obj.sigmaY = sigmaY;
        obj.sigmaX = sigmaX;
      end
      if nargin >= 5
        obj.amplitude = amplitude;
      end
      if nargin >= 7
        obj.circularY = circularY;
        obj.circularX = circularX;
      end
      if nargin >= 8
        obj.normalized = normalized;
      end
      if nargin >= 9
        obj.cutoffFactor = cutoffFactor;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      if obj.circularX
        obj.output = conv2(1, obj.kernelX, obj.inputElements{1}.(obj.inputComponents{1})(:, obj.extIndexX), 'valid');
      else
        obj.output = conv2(1, obj.kernelX, obj.inputElements{1}.(obj.inputComponents{1}), 'same');
      end
      if obj.circularY
        % use double transpose since vertical expansion is slow in current matlab version (2011a)
        obj.output = obj.output';
        obj.output = conv2(1, obj.kernelY, obj.output(:, obj.extIndexY), 'valid')';
      else
        obj.output = conv2(obj.kernelY, 1, obj.output, 'same');
      end
    end
    
    
    % initialization
    function obj = init(obj)
      % determine kernel range and extended index depending on circularity
      if obj.circularX
        obj.kernelRangeX = min(ceil(obj.sigmaX * obj.cutoffFactor), ...
          [floor((obj.size(2)-1)/2), ceil((obj.size(2)-1)/2)]);
        obj.extIndexX = [obj.size(2) - obj.kernelRangeX(2) + 1 : obj.size(2), ...
          1:obj.size(2), 1 : obj.kernelRangeX(1)];
      else
        obj.kernelRangeX = repmat(min(ceil(obj.sigmaX * obj.cutoffFactor), (obj.size(2)-1)), [1, 2]);
        obj.extIndexX = [];
      end
      
      if obj.circularY
        obj.kernelRangeY = min(ceil(obj.sigmaY * obj.cutoffFactor), ...
          [floor((obj.size(1)-1)/2), ceil((obj.size(1)-1)/2)]);
        obj.extIndexY = [obj.size(1) - obj.kernelRangeY(2) + 1 : obj.size(1), ...
          1:obj.size(1), 1 : obj.kernelRangeY(1)];
      else
        obj.kernelRangeY = repmat(min(ceil(obj.sigmaY * obj.cutoffFactor), (obj.size(1)-1)), [1, 2]);
        obj.extIndexY = [];
      end
      
      
      % calculate kernel depending on normalization
      if obj.normalized
        obj.kernelX = obj.amplitude * gaussNorm(-obj.kernelRangeX(1) : obj.kernelRangeX(2), 0, obj.sigmaX);
        obj.kernelY = gaussNorm(-obj.kernelRangeY(1) : obj.kernelRangeY(2), 0, obj.sigmaY);
      else
        obj.kernelX = obj.amplitude * gauss(-obj.kernelRangeX(1) : obj.kernelRangeX(2), 0, obj.sigmaX);
        obj.kernelY = gauss(-obj.kernelRangeY(1) : obj.kernelRangeY(2), 0, obj.sigmaY);
      end
      obj.output = zeros(obj.size);
    end
      
  end
end


