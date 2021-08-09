% LateralInteractionsShifted1D (COSIVINA toolbox)
%   Connective element that performs a 1D convolution with a Mexican hat
%   kernel (difference of two Gaussians) with a global component. The 
%   center of the two Gaussian components can be shifted, e.g. to generate
%   moving activation peaks.
%
% Constructor call:
% LateralInteractionsShifted1D(label, size, sigmaExc, amplitudeExc, ...
%     sigmaInh, amplitudeInh, amplitudeGlobal, shift, circular, ...
%     normalized, cutoffFactor)
%   size - size of input and output of the convolution
%   sigmaExc - width parameter of excitatory Gaussian
%   amplitudeExc - amplitude of excitatory Gaussian
%   sigmaInh - width parameter of inhibitory Gaussian
%   amplitudeInh - amplitude of inhibitory Gaussian
%   amplitudeGlobal - amplitude of global component
%   shift - amount by which the center of Gaussian kernel components is
%     shifted relative to the center of the kernel
%   circular - flag indicating whether convolution is circular (default is
%     true)
%   normalized - flag indicating whether local kernel components are
%     normalized before scaling with amplitude (default is true)
%   cutoffFactor - multiple of larger sigma at which the kernel is cut off
%     (global component is treated separately; default value is 5)
% 
% NOTE: The shifted kernel may not be plotted correctly by the KernelPlot
%   visualization element.


classdef LateralInteractionsShifted1D < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'sigmaExc', ParameterStatus.InitStepRequired, ...
      'amplitudeExc', ParameterStatus.InitStepRequired, 'sigmaInh', ParameterStatus.InitStepRequired, ...
      'amplitudeInh', ParameterStatus.InitStepRequired, 'amplitudeGlobal', ParameterStatus.Changeable, ...
      'shift', ParameterStatus.InitStepRequired, 'circular', ParameterStatus.InitStepRequired, ...
      'normalized', ParameterStatus.InitStepRequired, 'cutoffFactor', ParameterStatus.InitStepRequired);
    components = {'kernel', 'amplitudeGlobal', 'fullSum', 'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    sigmaExc = 1;
    amplitudeExc = 0;
    sigmaInh = 1;
    amplitudeInh = 0;
    amplitudeGlobal = 0;
    shift = 0;
    circular = true;
    normalized = true;
    cutoffFactor = 5;
    
    % accessible structures
    kernel
    output
    fullSum
  end
  
  properties (SetAccess = protected)
    kernelRangeLeft
    kernelRangeRight
    extIndex
  end
  
  methods
    % constructor
    function obj = LateralInteractionsShifted1D(label, size, sigmaExc, amplitudeExc, sigmaInh, amplitudeInh, ...
        amplitudeGlobal, shift, circular, normalized, cutoffFactor)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 3
        obj.sigmaExc = sigmaExc;
      end
      if nargin >= 4
        obj.amplitudeExc = amplitudeExc;
      end
      if nargin >= 5
        obj.sigmaInh = sigmaInh;
      end
      if nargin >= 6
        obj.amplitudeInh = amplitudeInh;
      end
      if nargin >= 7
        obj.amplitudeGlobal = amplitudeGlobal;
      end
      if nargin >= 8
        obj.shift = shift;
      end
      if nargin >= 9
        obj.circular = circular;
      end
      if nargin >= 10
        obj.normalized = normalized;
      end
      if nargin >= 11
        obj.cutoffFactor = cutoffFactor;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      input = obj.inputElements{1}.(obj.inputComponents{1});
      obj.fullSum = sum(input, 2);
      
      if obj.circular
        obj.output = conv2(1, obj.kernel, input(obj.extIndex), 'valid') ...
          + obj.amplitudeGlobal * obj.fullSum;
      else
        obj.output = conv2(1, obj.kernel, input, 'same') ...
          + obj.amplitudeGlobal * obj.fullSum;
      end
    end
    
    
    % initialization
    function obj = init(obj)
      kernelRange = obj.cutoffFactor ...
          * max( (obj.amplitudeExc ~= 0) * obj.sigmaExc, (obj.amplitudeInh ~= 0) * obj.sigmaInh );
      if obj.circular
        obj.kernelRangeLeft = min(max(ceil(kernelRange - obj.shift), 0), floor((obj.size(2)-1)/2));
        obj.kernelRangeRight = min(max(ceil(kernelRange + obj.shift), 0), ceil((obj.size(2)-1)/2));
        obj.extIndex = [obj.size(2) - obj.kernelRangeRight + 1 : obj.size(2), 1 : obj.size(2), 1 : obj.kernelRangeLeft];
      else
        obj.kernelRangeLeft = min(ceil(kernelRange + abs(obj.shift)), (obj.size(2)-1));
        obj.kernelRangeRight = obj.kernelRangeLeft;
        obj.extIndex = [];
      end
      
      if obj.normalized
        obj.kernel = obj.amplitudeExc * gaussNorm(-obj.kernelRangeLeft : obj.kernelRangeRight, obj.shift, obj.sigmaExc) ...
          - obj.amplitudeInh * gaussNorm(-obj.kernelRangeLeft : obj.kernelRangeRight, obj.shift, obj.sigmaInh);
      else
        obj.kernel = obj.amplitudeExc * gauss(-obj.kernelRangeLeft : obj.kernelRangeRight, obj.shift, obj.sigmaExc) ...
          - obj.amplitudeInh * gauss(-obj.kernelRangeLeft : obj.kernelRangeRight, obj.shift, obj.sigmaInh);
      end
      obj.fullSum = 0;
      obj.output = zeros(obj.size);
      
    end

  end
end


