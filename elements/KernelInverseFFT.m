% KernelInverseFFT (COSIVINA toolbox)
%   Element to perform a convolution in Fourier space on an input that is
%   already transformed into Fourier space. The element implements an
%   n-dimensional circular convolution with a Mexican hat kernel (difference of
%   two Gaussians) with a global component.
%   
%   This element should typically be used in combination with a separate
%   FastFourierTransform element when multiple independent convolutions are to
%   be performed on the same input, to avoid the same FFT transformation to be
%   executed repeatedly. If only a single convolution is to be performed (or if
%   a non-circular convolution is required), both operations can be performed by
%   a single KernelFFT element (see documentation of that element for properties
%   and advantages of the FFT method for convolutions).
%
% Constructor call:
% KernelFFT(label, size, sigmaExc, amplitudeExc, sigmaInh, ... 
%     amplitudeInh, amplitudeGlobal, normalized)
%   label - element label
%   size - size of input and output of the convolution (an n-element vector
%     for n-dimensional input)
%   sigmaExc - an n-dimensional vector specifying the width of the
%     excitatory Gaussian component in the n dimensions
%   amplitudeExc - a scalar value specifying the strength of the excitatory
%     Gaussian component
%   sigmaInh (optional) - an n-dimensional vector specifying the width of
%     the inhibitory Gaussian component in the n dimensions
%   amplitudeInh (optional) - a scalar value specifying the strength of the
%     inhibitory Gaussian component (larger positive value creates stronger
%     inhibition; default is zero)
%   amplitudeGlobal (optional) - a global (constant) component of the
%     interaction kernel; set to negative value to obtain global inhibition
%     (default is zero)
%   normalized (optional) - a binary value specifying whether the Gaussian
%     kernels are normalized (so their integral over space is one) before
%     scaling with the amplitudes (default is true)



classdef KernelInverseFFT < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, ....
      'sigmaExc', bitor(ParameterStatus.InitStepRequired, ParameterStatus.FixedSizeMatrix), ...
      'amplitudeExc', ParameterStatus.InitStepRequired, ...
      'sigmaInh', bitor(ParameterStatus.InitStepRequired, ParameterStatus.FixedSizeMatrix), ...
      'amplitudeInh', ParameterStatus.InitStepRequired, 'amplitudeGlobal', ParameterStatus.InitStepRequired, ...
      'normalized', ParameterStatus.InitStepRequired);
    components = {'kernelFFT', 'output'};
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
    normalized = true;
    
    % accessible structures
    kernelFFT
    output
  end
  
  properties (SetAccess = private)

  end
  
  methods
    % constructor
    function obj = KernelInverseFFT(label, size, sigmaExc, amplitudeExc, sigmaInh, amplitudeInh, ...
        amplitudeGlobal, normalized)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
      if numel(obj.size) == 2 && any(obj.size == 1)
        nDim = 1;
      else
        nDim = numel(obj.size);
      end
      
      if nargin >= 3
        obj.sigmaExc = reshape(sigmaExc, [], 1);
      else
        obj.sigmaExc = ones(nDim, 1);
      end
      if nargin >= 4
        obj.amplitudeExc = amplitudeExc;
      end
      if nargin >= 5
        obj.sigmaInh = reshape(sigmaInh, [], 1);
      else
        obj.sigmaInh = ones(nDim, 1);
      end
      if nargin >= 6
        obj.amplitudeInh = amplitudeInh;
      end
      if nargin >= 7
        obj.amplitudeGlobal = amplitudeGlobal;
      end
      if nargin >= 8
        obj.normalized = normalized;
      end
      
      if numel(obj.sigmaExc) ~= nDim || numel(obj.sigmaInh) ~= nDim
        error('KernelFFT:Constructor:incosistentArguments', ...
          ['Arguments sigmaExc and sigmaInh must be vectors whose number of entries matches the number of ' ...
          'dimensions in argument size, or scalars if argument size specifies that the input is a vector.']);
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = ifftn(obj.inputElements{1}.(obj.inputComponents{1}) .* obj.kernelFFT, 'symmetric');
    end
    
    
    % initialization
    function obj = init(obj)
      if numel(obj.size) == 2 && any(obj.size == 1)
        nDim = 1;
        dimSizes = max(obj.size);
      else
        nDim = numel(obj.size);
        dimSizes = obj.size;
      end
      
      componentsExc = cell(1, nDim);
      componentsInh = cell(1, nDim);
      for i = 1 : nDim
        if obj.normalized
          componentsExc{i} = gaussNorm([0:floor(dimSizes(i)/2), -floor((dimSizes(i)-1)/2):-1]', 0, obj.sigmaExc(i));
          componentsInh{i} = gaussNorm([0:floor(dimSizes(i)/2), -floor((dimSizes(i)-1)/2):-1]', 0, obj.sigmaInh(i));
        else
          componentsExc{i} = gauss([0:floor(dimSizes(i)/2), -floor((dimSizes(i)-1)/2):-1]', 0, obj.sigmaExc(i));
          componentsInh{i} = gauss([0:floor(dimSizes(i)/2), -floor((dimSizes(i)-1)/2):-1]', 0, obj.sigmaInh(i));
        end
      end
      
      kernel = 0;
      if obj.amplitudeExc ~= 0
        kernel = obj.amplitudeExc * componentsExc{1};
        for i = 2 : nDim
          kernel = repmat(kernel, [ones(1, i-1), dimSizes(i)]) .* ...
            repmat(reshape(componentsExc{i}, [ones(1, i-1), dimSizes(i)]), [dimSizes(1:i-1), 1]);
        end
      end
      
      kernelInh = 0;
      if obj.amplitudeInh ~= 0
        kernelInh = obj.amplitudeInh * componentsInh{1};
        for i = 2 : nDim
          kernelInh = repmat(kernelInh, [ones(1, i-1), dimSizes(i)]) .* ...
            repmat(reshape(componentsInh{i}, [ones(1, i-1), dimSizes(i)]), [dimSizes(1:i-1), 1]);
        end
      end
      
      if obj.amplitudeExc == 0 && obj.amplitudeInh == 0
        kernel = zeros(obj.size);
      else
        kernel = kernel - kernelInh + obj.amplitudeGlobal;
      end
      
      if nDim == 1
        kernel = reshape(kernel, obj.size);
      end
      
      obj.kernelFFT = fftn(kernel);
      obj.output = zeros(obj.size);
    end
      
  end
end


