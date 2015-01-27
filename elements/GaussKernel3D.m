% GaussKernel3D (COSIVINA toolbox)
%   Connective element that performs a convolution with a Gaussian kernel
%   over three-dimensional space.
%
% Constructor call:
% GaussKernel3D(label, size, sigmaY, sigmaX, sigmaZ, amplitude, circularY, ...
%     circularX, circularZ, normalized, cutoffFactor)
%   label - element label
%   size - size of input and output of the convolution
%   sigmaY, sigmaX, sigmaZ - width parameter of Gaussian kernel along the
%     three dimensions
%   amplitude - amplitude of kernel
%   circularY, circularX, circularZ - flags indicating whether convolution
%     is circular along each dimensions (default is true)
%   normalized - flag indicating whether kernel is normalized before
%     scaling with amplitude (default is true)
%   cutoffFactor - multiple of sigma at which the kernel is cut off
%     (default values is 5)


classdef GaussKernel3D < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'sigmaX', ParameterStatus.InitStepRequired, ...
      'sigmaY', ParameterStatus.InitStepRequired, 'sigmaZ', ParameterStatus.InitStepRequired, ...
      'amplitude', ParameterStatus.InitStepRequired, 'circularX', ParameterStatus.InitStepRequired, ...
      'circularY', ParameterStatus.InitStepRequired, 'circularZ', ParameterStatus.InitStepRequired, ...
      'normalized', ParameterStatus.InitStepRequired, 'cutoffFactor', ParameterStatus.InitStepRequired);
    components = {'kernelX', 'kernelY', 'kernelZ', 'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    sigmaY = 1;
    sigmaX = 1;
    sigmaZ = 1;
    amplitude = 0;
    circularY = true;
    circularX = true;
    circularZ = true;
    normalized = true;
    cutoffFactor = 5;
    
    % accessible structures
    kernelY
    kernelX
    kernelZ
    output
  end
  
  properties (SetAccess = private)
    kernelRangeY
    kernelRangeX
    kernelRangeZ
    extIndexY
    extIndexX
    extIndexZ
  end
  
  methods
    % constructor
    function obj = GaussKernel3D(label, size, sigmaY, sigmaX, sigmaZ, amplitude, circularY, circularX, circularZ, ...
        normalized, cutoffFactor)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 5
        obj.sigmaY = sigmaY;
        obj.sigmaX = sigmaX;
        obj.sigmaZ = sigmaZ;
      end
      if nargin >= 6
        obj.amplitude = amplitude;
      end
      if nargin >= 9
        obj.circularY = circularY;
        obj.circularX = circularX;
        obj.circularZ = circularZ;
      end
      if nargin >= 10
        obj.normalized = normalized;
      end
      if nargin >= 11
        obj.cutoffFactor = cutoffFactor;
      end
      
      if numel(obj.size) ~= 3
        error('GaussKernel3D:Constructor:invalidArgument', 'Argument size must be a three-element vector.');
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      sz = obj.size;
      cnv = reshape(shiftdim(obj.inputElements{1}.(obj.inputComponents{1}), 1), [sz(2) * sz(3), sz(1)]);
      
      if obj.circularY
        cnv = conv2(1, obj.kernelY, cnv(:, obj.extIndexY), 'valid');
      else
        cnv = conv2(1, obj.kernelY, cnv, 'same');
      end
      
      cnv = reshape(shiftdim(reshape(cnv, [sz(2), sz(3), sz(1)]), 1), [sz(3) * sz(1), sz(2)]);
      
      if obj.circularY
        cnv = conv2(1, obj.kernelX, cnv(:, obj.extIndexX), 'valid');
      else
        cnv = conv2(1, obj.kernelX, cnv, 'same');
      end
      
      cnv = reshape(shiftdim(reshape(cnv, [sz(3), sz(1), sz(2)]), 1), [sz(1) * sz(2), sz(3)]);
      
      if obj.circularZ
        cnv = conv2(1, obj.kernelZ, cnv(:, obj.extIndexZ), 'valid');
      else
        cnv = conv2(1, obj.kernelZ, cnv, 'same');
      end
      
      obj.output = reshape(cnv, sz);
    end
    
    
    % initialization
    function obj = init(obj)
      % determine kernel ranges and extended indices depending on circularity
      obj.kernelRangeX = computeKernelRange(obj.sigmaX, obj.cutoffFactor, obj.size(2), obj.circularX);
      obj.kernelRangeY = computeKernelRange(obj.sigmaY, obj.cutoffFactor, obj.size(1), obj.circularY);
      obj.kernelRangeZ = computeKernelRange(obj.sigmaZ, obj.cutoffFactor, obj.size(3), obj.circularZ);
      
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
      
      if obj.circularZ
        obj.extIndexZ = createExtendedIndex(obj.size(3), obj.kernelRangeZ);
      else
        obj.extIndexZ = [];
      end
      
      % calculate kernels depending on normalization
      if obj.normalized
        obj.kernelX = obj.amplitude * gaussNorm(-obj.kernelRangeX(1) : obj.kernelRangeX(2), 0, obj.sigmaX);
        obj.kernelY = gaussNorm(-obj.kernelRangeY(1) : obj.kernelRangeY(2), 0, obj.sigmaY);
        obj.kernelZ = gaussNorm(-obj.kernelRangeZ(1) : obj.kernelRangeZ(2), 0, obj.sigmaZ);
      else
        obj.kernelX = obj.amplitude * gauss(-obj.kernelRangeX(1) : obj.kernelRangeX(2), 0, obj.sigmaX);
        obj.kernelY = gauss(-obj.kernelRangeY(1) : obj.kernelRangeY(2), 0, obj.sigmaY);
        obj.kernelZ = gauss(-obj.kernelRangeZ(1) : obj.kernelRangeZ(2), 0, obj.sigmaZ);
      end
      
      obj.output = zeros(obj.size);
    end
      
  end
end


