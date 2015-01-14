% LateralInteractions2D (COSIVINA toolbox)
%   Connective element that performs a 2D convolution with a Mexican hat
%   kernel (difference of two Gaussians) with a global component. The
%   element also provides the sum of the element's input (typically the
%   output of a neural field) along the horizontal, vertical, and both
%   dimensions, to be used for projections onto lower-dimensional
%   structures.
%
% Constructor call:
% LateralInteractions2D(label, size, sigmaExcY, sigmaExcX, amplitudeExc, ...
%     sigmaInhY, sigmaInhX, amplitudeInh, amplitudeGlobal, ...
%     circularY, circularX, normalized, cutoffFactor)
%   label - element label
%   size - size of input and output of the convolution
%   sigmaExcY, sigmaExcX - vertical and horizontal width parameter of 
%     excitatory Gaussian component
%   amplitudeExc - amplitude of excitatory Gaussian component
%   sigmaInhY, sigmaInhX - vertical and horizontal width parameter of 
%     inhibitory Gaussian component
%   amplitudeInh - amplitude of inhibitory Gaussian component
%   amplitudeGlobal - amplitude of global component (set to negative value
%     to create global inhibition)
%   circularY, circularX - flags indicating whether convolution is circular
%     (default is true)
%   normalized - flag indicating whether Gaussian components are normalized
%     before scaling with amplitude (default is true)
%   cutoffFactor - multiple of sigma at which each kernel is cut off
%     (default value is 5)


classdef LateralInteractions2D < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'sigmaExcY', ParameterStatus.InitStepRequired, ...
      'sigmaExcX', ParameterStatus.InitStepRequired, 'amplitudeExc', ParameterStatus.InitStepRequired, ...
      'sigmaInhY', ParameterStatus.InitStepRequired, 'sigmaInhX', ParameterStatus.InitStepRequired, ...
      'amplitudeInh', ParameterStatus.InitStepRequired, 'amplitudeGlobal', ParameterStatus.Changeable, ...
      'circularY', ParameterStatus.InitStepRequired, 'circularX', ParameterStatus.InitStepRequired, ...
      'normalized', ParameterStatus.InitStepRequired, 'cutoffFactor', ParameterStatus.InitStepRequired);
    components = {'kernelExcY', 'kernelExcX', 'kernelInhY', 'kernelInhX', 'amplitudeGlobal', ...
      'output', 'horizontalSum', 'verticalSum', 'fullSum'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    sigmaExcY = 1;
    sigmaExcX = 1;
    amplitudeExc = 0;
    sigmaInhY = 1;
    sigmaInhX = 1;
    amplitudeInh = 0;
    amplitudeGlobal = 0;
    circularY = true;
    circularX = true;
    normalized = true;
    cutoffFactor = 5;
    
    % accessible structures
    kernelExcY
    kernelExcX
    kernelInhY
    kernelInhX
    output
    verticalSum
    horizontalSum
    fullSum
  end
  
  properties (SetAccess = private)
    kernelRangeExcY
    kernelRangeExcX
    kernelRangeInhY
    kernelRangeInhX
    extIndexExcY
    extIndexExcX
    extIndexInhY
    extIndexInhX
  end
  
  methods
    % constructor
    function obj = LateralInteractions2D(label, size, sigmaExcY, sigmaExcX, amplitudeExc, ...
        sigmaInhY, sigmaInhX, amplitudeInh, amplitudeGlobal, circularY, circularX, normalized, cutoffFactor)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 4
        obj.sigmaExcY = sigmaExcY;
        obj.sigmaExcX = sigmaExcX;
      end
      if nargin >= 5
        obj.amplitudeExc = amplitudeExc;
      end
      if nargin >= 7
        obj.sigmaInhY = sigmaInhY;
        obj.sigmaInhX = sigmaInhX;
      end
      if nargin >= 8
        obj.amplitudeInh = amplitudeInh;
      end
      if nargin >= 9
        obj.amplitudeGlobal = amplitudeGlobal;
      end
      
      if nargin >= 11
        obj.circularY = circularY;
        obj.circularX = circularX;
      end
      if nargin >= 12
        obj.normalized = normalized;
      end
      if nargin >= 13
        obj.cutoffFactor = cutoffFactor;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      input = obj.inputElements{1}.(obj.inputComponents{1});
      if obj.circularX
        outputExc = conv2(1, obj.kernelExcX, input(:, obj.extIndexExcX), 'valid');
        outputInh = conv2(1, obj.kernelInhX, input(:, obj.extIndexInhX), 'valid');
      else
        outputExc = conv2(1, obj.kernelExcX, input, 'same');
        outputInh = conv2(1, obj.kernelInhX, input, 'same');
      end
      if obj.circularY
        % use double transpose since vertical expansion is slow in current matlab version (2013a)
        outputExc = outputExc';
        outputExc = conv2(1, obj.kernelExcY, outputExc(:, obj.extIndexExcY), 'valid')';
        outputInh = outputInh';
        outputInh = conv2(1, obj.kernelInhY, outputInh(:, obj.extIndexInhY), 'valid')';
      else
        outputExc = conv2(obj.kernelExcY, 1, outputExc, 'same');
        outputInh = conv2(obj.kernelInhY, 1, outputInh, 'same');
      end
      
      obj.verticalSum = sum(input, 1);
      obj.horizontalSum = sum(input, 2)';
      obj.fullSum = sum(obj.verticalSum);
      
      obj.output = outputExc - outputInh + obj.amplitudeGlobal * obj.fullSum;
    end
    
    
    % initialization
    function obj = init(obj)
      % determine kernel range and extended index maps depending on circularity
      obj.kernelRangeExcX = computeKernelRange(obj.sigmaExcX, obj.cutoffFactor, obj.size(2), obj.circularX);
      obj.kernelRangeExcY = computeKernelRange(obj.sigmaExcY, obj.cutoffFactor, obj.size(1), obj.circularY);
      obj.kernelRangeInhX = computeKernelRange(obj.sigmaInhX, obj.cutoffFactor, obj.size(2), obj.circularX);
      obj.kernelRangeInhY = computeKernelRange(obj.sigmaInhY, obj.cutoffFactor, obj.size(1), obj.circularY);
      
      if obj.circularX
        obj.extIndexExcX = createExtendedIndex(obj.size(2), obj.kernelRangeExcX);
        obj.extIndexInhX = createExtendedIndex(obj.size(2), obj.kernelRangeInhX);
      else
        obj.extIndexExcX = [];
        obj.extIndexInhX = [];
      end
      if obj.circularY
        obj.extIndexExcY = createExtendedIndex(obj.size(1), obj.kernelRangeExcY);
        obj.extIndexInhY = createExtendedIndex(obj.size(1), obj.kernelRangeInhY);
      else
        obj.extIndexExcY = [];
        obj.extIndexInhY = [];
      end
      
      % calculate kernel depending on normalization
      if obj.normalized
        obj.kernelExcX = obj.amplitudeExc ...
          * gaussNorm(-obj.kernelRangeExcX(1) : obj.kernelRangeExcX(2), 0, obj.sigmaExcX);
        obj.kernelExcY = gaussNorm(-obj.kernelRangeExcY(1) : obj.kernelRangeExcY(2), 0, obj.sigmaExcY);
        obj.kernelInhX = obj.amplitudeInh ...
          * gaussNorm(-obj.kernelRangeInhX(1) : obj.kernelRangeInhX(2), 0, obj.sigmaInhX);
        obj.kernelInhY = gaussNorm(-obj.kernelRangeInhY(1) : obj.kernelRangeInhY(2), 0, obj.sigmaInhY);
      else
        obj.kernelExcX = obj.amplitudeExc * gauss(-obj.kernelRangeExcX(1) : obj.kernelRangeExcX(2), 0, obj.sigmaExcX);
        obj.kernelExcY = gauss(-obj.kernelRangeExcY(1) : obj.kernelRangeExcY(2), 0, obj.sigmaExcY);
        obj.kernelInhX = obj.amplitudeInh * gauss(-obj.kernelRangeInhX(1) : obj.kernelRangeInhX(2), 0, obj.sigmaInhX);
        obj.kernelInhY = gauss(-obj.kernelRangeInhY(1) : obj.kernelRangeInhY(2), 0, obj.sigmaInhY);
      end
      
      obj.output = zeros(obj.size);
      obj.verticalSum = zeros(1, obj.size(2));
      obj.horizontalSum = zeros(1, obj.size(1));
      obj.fullSum = 0;
    end
      
  end
end


