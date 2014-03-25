% ShiftInput (COSIVINA toolbox)
%   Element that shifts the content of an input array by a constant value.
%
% Constructor call:
% ShiftInput(label, size, shiftValue, amplitude, circular, fillValue)
%   label - element label
%   size - size of input and output
%   shiftValue - integer value by which array is shifted (two-element
%     vector for two-dimensional shift)
%   amplitude - scaling factor for output
%   circular - flag indicating whether the shift should be circular
%   fillValue - value to fill in empty parts of the output array in
%     non-circular shifts


classdef ShiftInput < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'shiftValue', ParameterStatus.Fixed, ...
      'amplitude', ParameterStatus.Changeable, 'circular', ParameterStatus.Changeable, ...
      'fillValue', ParameterStatus.InitStepRequired);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    shiftValue = [0, 0];
    amplitude = 1.0;
    circular = false;
    fillValue = 0;
        
    % accessible structures
    output
  end
  
  properties (SetAccess = private)
    leftBoundIn = [];
    rightBoundIn = [];
    leftBoundOut = [];
    rightBoundOut = [];
  end
  
  methods
    % constructor
    function obj = ShiftInput(label, size, shiftValue, amplitude, circular, fillValue)
      if nargin > 0
        obj.label = label;
        obj.size = size;
        obj.shiftValue = shiftValue;
      end
      if nargin >= 4
        obj.amplitude = amplitude;
      end
      if nargin >= 5
        obj.circular = circular;
      end
      if nargin >= 6
        obj.fillValue = fillValue;
      end
            
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
      if numel(obj.shiftValue) == 1
        obj.shiftValue = [0, obj.shiftValue];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      if obj.circular
        obj.output = obj.amplitude * ...
          circshift(obj.inputElements{1}.(obj.inputComponents{1}), round(obj.shiftValue));
      else
        obj.output(obj.leftBoundOut(1) : obj.rightBoundOut(1), obj.leftBoundOut(2) : obj.rightBoundOut(2)) ...
          = obj.amplitude * obj.inputElements{1}.(obj.inputComponents{1})(obj.leftBoundIn(1) : obj.rightBoundIn(1), ...
          obj.leftBoundIn(2) : obj.rightBoundIn(2));
      end
    end
    
    
    % initialization
    function obj = init(obj)
      obj.leftBoundOut = 1 + max(0, obj.shiftValue);
      obj.rightBoundOut = obj.size + min(0, obj.shiftValue);
      obj.leftBoundIn = 1 - min(0, obj.shiftValue);
      obj.rightBoundIn = obj.size - max(0, obj.shiftValue);
      
      obj.output = obj.fillValue * ones(obj.size);
    end
  end
end


