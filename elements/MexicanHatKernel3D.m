% MexicanHatKernel3D (COSIVINA toolbox)
%   Connective element that performs a convolution with a Mexican hat
%   kernel (difference of two Gaussians) over a three-dimensional space.
%
% Constructor call:
% MexicanHatKernel3D(label, size, sigmaExcY, sigmaExcX, sigmaZ,
%     amplitudeExc, sigmaInhX, sigmaInhY, sigmaInhZ, amplitudeInh, ...
%     circularY, circularX, circularZ, normalized, cutoffFactor)
%   label - element label
%   size - size of input and output of the convolution
%   sigmaExcY, sigmaExcX, sigmaExcZ - width parameters of excitatory
%     Gassian component along each dimension
%   amplitudeExc - amplitude of excitatory Gaussian component
%   sigmaInhY, sigmaInhX, sigmaInhZ - width parameters of inhibitory
%     Gaussian component along each dimension
%   amplitudeInh - amplitude of inhibitory Gaussian component
%   circularY, circularX, circularZ - flags indicating whether convolution
%     is circular along each dimension (default is true)
%   normalized - flag indicating whether Gaussian components are normalized
%     before scaling with amplitude (default is true)
%   cutoffFactor - multiple of sigma at which each kernel is cut off
%     (default value is 5)


classdef MexicanHatKernel3D < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'sigmaExcY', ParameterStatus.InitStepRequired, ...
      'sigmaExcX', ParameterStatus.InitStepRequired, 'sigmaExcZ', ParameterStatus.InitStepRequired, ...
      'amplitudeExc', ParameterStatus.InitStepRequired, 'sigmaInhY', ParameterStatus.InitStepRequired, ...
      'sigmaInhX', ParameterStatus.InitStepRequired, 'sigmaInhZ', ParameterStatus.InitStepRequired, ...
      'amplitudeInh', ParameterStatus.InitStepRequired, 'circularY', ParameterStatus.InitStepRequired, ...
      'circularX', ParameterStatus.InitStepRequired, 'circularZ', ParameterStatus.InitStepRequired, ...
      'normalized', ParameterStatus.InitStepRequired, 'cutoffFactor', ParameterStatus.InitStepRequired);
    components = {'kernelExcY', 'kernelExcX', 'kernelExcZ', 'kernelInhY', 'kernelInhX', 'kernelInhZ', 'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    sigmaExcY = 1;
    sigmaExcX = 1;
    sigmaExcZ = 1;
    amplitudeExc = 0;
    sigmaInhY = 1;
    sigmaInhX = 1;
    sigmaInhZ = 1;
    amplitudeInh = 0;
    circularY = true;
    circularX = true;
    circularZ = true;
    normalized = true;
    cutoffFactor = 5;
    
    % accessible structures
    kernelExcY
    kernelExcX
    kernelExcZ
    kernelInhY
    kernelInhX
    kernelInhZ
    output
  end
  
  properties (SetAccess = private)
    kernelRangeExcY
    kernelRangeExcX
    kernelRangeExcZ
    kernelRangeInhY
    kernelRangeInhX
    kernelRangeInhZ
    extIndexExcY
    extIndexExcX
    extIndexExcZ
    extIndexInhY
    extIndexInhX
    extIndexInhZ
  end
  
  methods
    % constructor
    function obj = MexicanHatKernel3D(label, size, sigmaExcY, sigmaExcX, sigmaExcZ, amplitudeExc, ...
        sigmaInhY, sigmaInhX, sigmaInhZ, amplitudeInh, circularY, circularX, circularZ, normalized, cutoffFactor)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 5
        obj.sigmaExcY = sigmaExcY;
        obj.sigmaExcX = sigmaExcX;
        obj.sigmaExcZ = sigmaExcZ;
      end
      if nargin >= 6
        obj.amplitudeExc = amplitudeExc;
      end
      if nargin >= 9
        obj.sigmaInhY = sigmaInhY;
        obj.sigmaInhX = sigmaInhX;
        obj.sigmaInhZ = sigmaInhZ;
      end
      if nargin >= 10
        obj.amplitudeInh = amplitudeInh;
      end
      if nargin >= 13
        obj.circularY = circularY;
        obj.circularX = circularX;
        obj.circularZ = circularZ;
      end
      if nargin >= 14
        obj.normalized = normalized;
      end
      if nargin >= 15
        obj.cutoffFactor = cutoffFactor;
      end
      
      if numel(obj.size) ~= 3
        error('MexicanHatKernel3D:Constructor:invalidArgument', 'Argument size must be a three-element vector.');
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      sz = obj.size;
      cnvExc = reshape(shiftdim(obj.inputElements{1}.(obj.inputComponents{1}), 1), [sz(2) * sz(3), sz(1)]);
      
      if obj.circularY
        cnvInh = conv2(1, obj.kernelInhY, cnvExc(:, obj.extIndexInhY), 'valid');
        cnvExc = conv2(1, obj.kernelExcY, cnvExc(:, obj.extIndexExcY), 'valid');
      else
        cnvInh = conv2(1, obj.kernelInhY, cnvExc, 'same');        
        cnvExc = conv2(1, obj.kernelExcY, cnvExc, 'same');
      end
      
      cnvExc = reshape(shiftdim(reshape(cnvExc, [sz(2), sz(3), sz(1)]), 1), [sz(3) * sz(1), sz(2)]);
      cnvInh = reshape(shiftdim(reshape(cnvInh, [sz(2), sz(3), sz(1)]), 1), [sz(3) * sz(1), sz(2)]);
      
      if obj.circularX
        cnvExc = conv2(1, obj.kernelExcX, cnvExc(:, obj.extIndexExcX), 'valid');
        cnvInh = conv2(1, obj.kernelInhX, cnvInh(:, obj.extIndexInhX), 'valid');
      else
        cnvExc = conv2(1, obj.kernelExcX, cnvExc, 'same');
        cnvInh = conv2(1, obj.kernelInhX, cnvInh, 'same');
      end
      
      cnvExc = reshape(shiftdim(reshape(cnvExc, [sz(3), sz(1), sz(2)]), 1), [sz(1) * sz(2), sz(3)]);
      cnvInh = reshape(shiftdim(reshape(cnvInh, [sz(3), sz(1), sz(2)]), 1), [sz(1) * sz(2), sz(3)]);
      
      if obj.circularZ
        cnvExc = conv2(1, obj.kernelExcZ, cnvExc(:, obj.extIndexExcZ), 'valid');
        cnvInh = conv2(1, obj.kernelInhZ, cnvInh(:, obj.extIndexInhZ), 'valid');
      else
        cnvExc = conv2(1, obj.kernelExcZ, cnvExc, 'same');
        cnvInh = conv2(1, obj.kernelInhZ, cnvInh, 'same');
      end
      
      obj.output = reshape(cnvExc - cnvInh, sz);
    end
    
    
    % initialization
    function obj = init(obj)
      % determine kernel range and extended index maps depending on circularity
      obj.kernelRangeExcX = computeKernelRange(obj.sigmaExcX, obj.cutoffFactor, obj.size(2), obj.circularX);
      obj.kernelRangeExcY = computeKernelRange(obj.sigmaExcY, obj.cutoffFactor, obj.size(1), obj.circularY);
      obj.kernelRangeExcZ = computeKernelRange(obj.sigmaExcZ, obj.cutoffFactor, obj.size(3), obj.circularZ);
      
      obj.kernelRangeInhX = computeKernelRange(obj.sigmaInhX, obj.cutoffFactor, obj.size(2), obj.circularX);
      obj.kernelRangeInhY = computeKernelRange(obj.sigmaInhY, obj.cutoffFactor, obj.size(1), obj.circularY);
      obj.kernelRangeInhZ = computeKernelRange(obj.sigmaInhZ, obj.cutoffFactor, obj.size(3), obj.circularZ);
      
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
      if obj.circularZ
        obj.extIndexExcZ = createExtendedIndex(obj.size(3), obj.kernelRangeExcZ);
        obj.extIndexInhZ = createExtendedIndex(obj.size(3), obj.kernelRangeInhZ);
      else
        obj.extIndexExcZ = [];
        obj.extIndexInhZ = [];
      end
      
      % calculate kernel depending on normalization
      if obj.normalized
        obj.kernelExcX = obj.amplitudeExc ...
          * gaussNorm(-obj.kernelRangeExcX(1) : obj.kernelRangeExcX(2), 0, obj.sigmaExcX);
        obj.kernelExcY = gaussNorm(-obj.kernelRangeExcY(1) : obj.kernelRangeExcY(2), 0, obj.sigmaExcY);
        obj.kernelExcZ = gaussNorm(-obj.kernelRangeExcZ(1) : obj.kernelRangeExcZ(2), 0, obj.sigmaExcZ);
        obj.kernelInhX = obj.amplitudeInh ...
          * gaussNorm(-obj.kernelRangeInhX(1) : obj.kernelRangeInhX(2), 0, obj.sigmaInhX);
        obj.kernelInhY = gaussNorm(-obj.kernelRangeInhY(1) : obj.kernelRangeInhY(2), 0, obj.sigmaInhY);
        obj.kernelInhZ = gaussNorm(-obj.kernelRangeInhZ(1) : obj.kernelRangeInhZ(2), 0, obj.sigmaInhZ);
      else
        obj.kernelExcX = obj.amplitudeExc * gauss(-obj.kernelRangeExcX(1) : obj.kernelRangeExcX(2), 0, obj.sigmaExcX);
        obj.kernelExcY = gauss(-obj.kernelRangeExcY(1) : obj.kernelRangeExcY(2), 0, obj.sigmaExcY);
        obj.kernelExcZ = gauss(-obj.kernelRangeExcZ(1) : obj.kernelRangeExcZ(2), 0, obj.sigmaExcZ);
        obj.kernelInhX = obj.amplitudeInh * gauss(-obj.kernelRangeInhX(1) : obj.kernelRangeInhX(2), 0, obj.sigmaInhX);
        obj.kernelInhY = gauss(-obj.kernelRangeInhY(1) : obj.kernelRangeInhY(2), 0, obj.sigmaInhY);
        obj.kernelInhZ = gauss(-obj.kernelRangeInhZ(1) : obj.kernelRangeInhZ(2), 0, obj.sigmaInhZ);
      end
      obj.output = zeros(obj.size);
    end
      
  end
end


