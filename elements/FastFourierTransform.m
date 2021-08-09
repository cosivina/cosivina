% FastFourierTransform (COSIVINA toolbox)
%   Element that transforms an input into Fourier space, producing an output of
%   the same size. The input may be of any dimensionality. The transformation is
%   typically used when multiple independent convolutions (all in circular
%   space) are to be performed on the input via the FFT method, with the output
%   of this element serving as input to multiple KernelInverseFFT elements. If
%   only a single convolution is to be performed, a KernelFFT element can be
%   used instead to perform the whole operation.
%
% Constructor call:
% FastFourierTransform(label, size)
%   label - element label
%   size - size of input and output of the transformation (an n-element vector
%     for n-dimensional input)

classdef FastFourierTransform < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = FastFourierTransform(label, size)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = fftn(obj.inputElements{1}.(obj.inputComponents{1}));
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end
      
  end
end


