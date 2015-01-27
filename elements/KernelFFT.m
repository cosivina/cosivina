% KernelFFT (COSIVINA toolbox)
%   Connective element that performs an n-dimensional convolution with a
%   Mexican hat kernel (difference of two Gaussians) with a global
%   component, using the FFT method (the kernel and the input are
%   transformed into Fourier space, multiplied, and the result is
%   transformed back). This is often faster than the direct convolution
%   method implemented in elements like GaussKernel1D or
%   LateralInteractions2D.
%   
%   This element can be used for all convolutions with Gaussian kernels or
%   difference-of-Gaussian kernels (with or without global component). The
%   computational cost is the same for all of these, and depends only on
%   the size of the input, not the width of the kernel. It is therefore
%   especially suited if the kernel is large (high sigma-value) relative to
%   the size of the input. The input may be of any dimensionality.
%
%   By default, the convolution in the FFT method is always performed in a
%   circular fashion along all dimensions. The element allows an emulation
%   of a non-circular convolution by automatically padding the input with
%   zeros and then cutting off the borders from the result. Note that this
%   can become extremely slow for higher-dimensional inputs; elements with
%   direct convolution should be used in these cases.
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
%   circular (optional) - and n-dimensional vector of binary values,
%     specifying for each dimension whether the convolution should be
%     performed in a circular fashion (default is true for all dimensions,
%     non-circular convolution can be very slow for large inputs)
%   normalized (optional) - a binary value specifying whether the Gaussian
%     kernels are normalized (so their integral over space is one) before
%     scaling with the amplitudes (default is true)
%   paddingFactor (optional) - scalar value determining how much padding is
%     appended to the input for non-circular convolution (as a multiple of
%     the larger sigma value along each dimension; default value is 5)


classdef KernelFFT < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, ....
      'sigmaExc', bitor(ParameterStatus.InitStepRequired, ParameterStatus.FixedSizeMatrix), ...
      'amplitudeExc', ParameterStatus.InitStepRequired, ...
      'sigmaInh', bitor(ParameterStatus.InitStepRequired, ParameterStatus.FixedSizeMatrix), ...
      'amplitudeInh', ParameterStatus.InitStepRequired, 'amplitudeGlobal', ParameterStatus.InitStepRequired, ...
      'circular', bitor(ParameterStatus.InitStepRequired, ParameterStatus.FixedSizeMatrix), ...
      'normalized', ParameterStatus.InitStepRequired, 'paddingFactor', ParameterStatus.InitStepRequired);
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
    circular = true;
    normalized = true;
    paddingFactor = 5;
    
    % accessible structures
    kernelFFT
    output
  end
  
  properties (SetAccess = private)
    paddingSize
    extIndices
    extSize
    extInput
  end
  
  methods
    % constructor
    function obj = KernelFFT(label, size, sigmaExc, amplitudeExc, sigmaInh, amplitudeInh, ...
        amplitudeGlobal, circular, normalized, paddingFactor)
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
        obj.circular = reshape(circular, [], 1);
      else
        obj.circular = true(nDim, 1);
      end
      if nargin >= 9
        obj.normalized = normalized;
      end
      if nargin >= 10
        obj.paddingFactor = paddingFactor;
      end
      
      if numel(obj.sigmaExc) ~= nDim || numel(obj.sigmaInh) ~= nDim || numel(obj.circular) ~= nDim
        error('KernelFFT:Constructor:incosistentArguments', ...
          ['Arguments sigmaExc, sigmaInh, and circular (if specified) must be vectors whose number of entries ' ...
          'matches the number of dimensions in argument size, or scalars if argument size specifies that the ' ...
          'input is a vector.']);
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      if any(~obj.circular)
        obj.extInput(obj.extIndices{:}) = obj.inputElements{1}.(obj.inputComponents{1});
        cnv = ifftn(fftn(obj.extInput) .* obj.kernelFFT, 'symmetric');
        obj.output = cnv(obj.extIndices{:});
      else
        obj.output = ifftn(fftn(obj.inputElements{1}.(obj.inputComponents{1})) .* obj.kernelFFT, 'symmetric');
      end
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
      
      obj.paddingSize = obj.paddingFactor ...
        * ((~obj.circular) .* max( (obj.amplitudeExc ~= 0) * obj.sigmaExc, (obj.amplitudeInh ~= 0) * obj.sigmaInh ))';
      extDimSizes = dimSizes + 2*obj.paddingSize;
      obj.extIndices = cell(1, nDim);
      for i = 1 : nDim
        if obj.circular(i)
          obj.extIndices{i} = ':';
        else
          obj.extIndices{i} = (1:dimSizes(i)) + obj.paddingSize(i);
        end
      end
      
      obj.extSize = dimSizes + 2 * obj.paddingSize;
      if nDim == 1
        if obj.size(1) == 1
          obj.extSize = [1, obj.extSize];
        else
          obj.extSize = [obj.extSize, 1];
        end
      end
      
      componentsExc = cell(1, nDim);
      componentsInh = cell(1, nDim);
      for i = 1 : nDim
        if obj.normalized
          componentsExc{i} = gaussNorm([0:floor(extDimSizes(i)/2), -floor((extDimSizes(i)-1)/2):-1]', 0, obj.sigmaExc(i));
          componentsInh{i} = gaussNorm([0:floor(extDimSizes(i)/2), -floor((extDimSizes(i)-1)/2):-1]', 0, obj.sigmaInh(i));
        else
          componentsExc{i} = gauss([0:floor(extDimSizes(i)/2), -floor((extDimSizes(i)-1)/2):-1]', 0, obj.sigmaExc(i));
          componentsInh{i} = gauss([0:floor(extDimSizes(i)/2), -floor((extDimSizes(i)-1)/2):-1]', 0, obj.sigmaInh(i));
        end
      end
      
      kernel = 0;
      if obj.amplitudeExc ~= 0
        kernel = obj.amplitudeExc * componentsExc{1};
        for i = 2 : nDim
          kernel = repmat(kernel, [ones(1, i-1), extDimSizes(i)]) .* ...
            repmat(reshape(componentsExc{i}, [ones(1, i-1), extDimSizes(i)]), [extDimSizes(1:i-1), 1]);
        end
      end
      
      kernelInh = 0;
      if obj.amplitudeInh ~= 0
        kernelInh = obj.amplitudeInh * componentsInh{1};
        for i = 2 : nDim
          kernelInh = repmat(kernelInh, [ones(1, i-1), extDimSizes(i)]) .* ...
            repmat(reshape(componentsInh{i}, [ones(1, i-1), extDimSizes(i)]), [extDimSizes(1:i-1), 1]);
        end
      end
      
      if obj.amplitudeExc == 0 && obj.amplitudeInh == 0;
        kernel = zeros(obj.size);
      end
      
      kernel = kernel - kernelInh + obj.amplitudeGlobal;
      clear kernelInh;
      
      if nDim == 1
        kernel = reshape(kernel, obj.extSize);
      end
      
      
      obj.kernelFFT = fftn(kernel);
      
      if any(~obj.circular)
        obj.extInput = zeros(obj.extSize);
      else
        obj.extInput = [];
      end
      obj.output = zeros(obj.size);
    end
      
  end
end


