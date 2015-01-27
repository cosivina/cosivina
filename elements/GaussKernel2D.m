% GaussKernel2D (COSIVINA toolbox)
%   Connective element that performs a 2D convolution with a Gaussian
%   kernel.
%
% Constructor call:
% GaussKernel2D(label, size, sigmaY, sigmaX, amplitude, circularY, ...
%     circularX, normalized, cutoffFactor)
%   label - element label
%   size - size of input and output of the convolution
%   sigmaY, sigmaX - vertical and horizontal width parameter of Gaussian
%     kernel
%   amplitude - amplitude of kernel
%   circularY, circularX - flags indicating whether convolution is
%     circular along each dimension (default is true)
%   normalized - flag indicating whether kernel is normalized before
%     scaling with amplitude (default is true)
%   cutoffFactor - multiple of sigma at which the kernel is cut off
%     (default value is 5)


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
        % use double transpose since vertical expansion is slow in Matlab
        obj.output = obj.output';
        obj.output = conv2(1, obj.kernelY, obj.output(:, obj.extIndexY), 'valid')';
      else
        obj.output = conv2(obj.kernelY, 1, obj.output, 'same');
      end
    end
    
    
    % initialization
    function obj = init(obj)
      % determine kernel range and extended index depending on circularity
      obj.kernelRangeX = computeKernelRange(obj.sigmaX, obj.cutoffFactor, obj.size(2), obj.circularX);
      obj.kernelRangeY = computeKernelRange(obj.sigmaY, obj.cutoffFactor, obj.size(1), obj.circularY);
      
      if obj.circularX
        obj.extIndexX = createExtendedIndex(obj.size(2), obj.kernelRangeX);
      else
        obj.extIndexX = [];
      end
      
      if obj.circularY
        obj.extIndexY = createExtendedIndex(obj.size(1), obj.kernelRangeY);
      else
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


