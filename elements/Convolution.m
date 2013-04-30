% Convolution (COSIVINA toolbox)
%   Element to perform a convolution between two inputs. Either input may
%   be flipped to effectively compute a correlation.
%
% Constructor call:
% Convolution(label, outputSize, flipFirst, flipSecond, convolutionShape)
%   label - element label
%   outputSize - size of the result of the convolution
%   flipFirst - flag indicating whether first input should be flipped
%   flipSecond - flag indicating whether second input should be flipped
%   convolutionShape - shape of the convolution (as in MATLAB function
%     conv2)

classdef Convolution < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'flipInputs', ParameterStatus.Changeable, ...
      'shape', ParameterStatus.Fixed);
    components = {'output'};
    defaultOutputComponent = 'output';
    
    FlipNone = 0;
    FlipFirst = 1;
    FlipSecond = 2;
    FlipBoth = 3;
  end
  
  properties
    % parameters
    size = [1, 1];
    flipInputs = Convolution.FlipNone;
    shape = 'same';
    
    % accessible structures
    output
  end

  
  methods
    % constructor
    function obj = Convolution(label, outputSize, flipFirst, flipSecond, convolutionShape)
      if nargin > 0
        obj.label = label;
        obj.size = outputSize;
      end
      if nargin >= 4
        if flipFirst
          obj.flipInputs = Convolution.FlipFirst;
        elseif flipSecond
          obj.flipInputs = Convolution.FlipSecond;
        end
        if flipFirst && flipSecond
          obj.flipInputs = Convolution.FlipBoth;
        end
      end
      if nargin >= 5
        obj.shape = convolutionShape;
      end
           
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      switch obj.flipInputs
        case Convolution.FlipNone
          obj.output = conv2(obj.inputElements{1}.(obj.inputComponents{1}), ...
            obj.inputElements{2}.(obj.inputComponents{2}), obj.shape);
        case Convolution.FlipFirst
          obj.output = conv2(rot90(obj.inputElements{1}.(obj.inputComponents{1}), 2), ...
            obj.inputElements{2}.(obj.inputComponents{2}), obj.shape);
        case Convolution.FlipSecond
          obj.output = conv2(obj.inputElements{1}.(obj.inputComponents{1}), ...
            rot90(obj.inputElements{2}.(obj.inputComponents{2}), 2), obj.shape);
        case Convolution.FlipBoth
          obj.output = rot90(conv2(obj.inputElements{1}.(obj.inputComponents{1}), ...
            obj.inputElements{2}.(obj.inputComponents{2}), obj.shape), 2);
      end
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end

  end
end


