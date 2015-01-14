% GaussKernel1D (COSIVINA toolbox)
%   Connective element that performs a 1D convolution with a Gaussian
%   kernel.
%
% Constructor call:
% GaussKernel1D(label, size, sigma, amplitude, circular, normalized, ...
%     cutoffFactor)
%   label - element label
%   size - size of input and output of the convolution
%   sigma - width parameter of Gaussian kernel
%   amplitude - amplitude of kernel
%   circular - flag indicating whether convolution is circular (default is
%     true)
%   normalized - flag indicating whether kernel is normalized before
%     scaling with amplitude (default is true)
%   cutoffFactor - multiple of sigma at which the kernel is cut off
%     (defautl value is 5)


classdef GaussKernel1D < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'sigma', ParameterStatus.InitStepRequired, ...
      'amplitude', ParameterStatus.InitStepRequired, 'circular', ParameterStatus.InitStepRequired, ...
      'normalized', ParameterStatus.InitStepRequired, 'cutoffFactor', ParameterStatus.InitStepRequired);
    components = {'kernel', 'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    sigma = 1;
    amplitude = 0;
    circular = true;
    normalized = true;
    cutoffFactor = 5;
    
    % accessible structures
    kernel
    output
  end
  
  properties (SetAccess = private)
    kernelRange
    extIndex
  end
  
  methods
    % constructor
    function obj = GaussKernel1D(label, size, sigma, amplitude, circular, normalized, cutoffFactor)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 3
        obj.sigma = sigma;
      end
      if nargin >= 4
        obj.amplitude = amplitude;
      end
      if nargin >= 5
        obj.circular = circular;
      end
      if nargin >= 6
        obj.normalized = normalized;
      end
      if nargin >= 7
        obj.cutoffFactor = cutoffFactor;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      if obj.circular
        obj.output = conv2(1, obj.kernel, obj.inputElements{1}.(obj.inputComponents{1})(obj.extIndex), 'valid');
      else
        obj.output = conv2(1, obj.kernel, obj.inputElements{1}.(obj.inputComponents{1}), 'same');
      end
    end
    
    
    % initialization
    function obj = init(obj)
      obj.kernelRange = computeKernelRange(obj.sigma, obj.cutoffFactor, obj.size(2), obj.circular);
      if obj.circular
        obj.extIndex = createExtendedIndex(obj.size(2), obj.kernelRange);
      else
        obj.extIndex = [];
      end
      
      if obj.normalized
        obj.kernel = obj.amplitude * gaussNorm(-obj.kernelRange(1) : obj.kernelRange(2), 0, obj.sigma);
      else
        obj.kernel = obj.amplitude * gauss(-obj.kernelRange(1) : obj.kernelRange(2), 0, obj.sigma);
      end
      obj.output = zeros(obj.size);
    end

  end
end


