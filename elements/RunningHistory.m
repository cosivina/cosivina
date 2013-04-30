% RunningHistory (COSIVINA toolbox)
%   A continuously updated history of the input to this element over 
%   the recent time steps.
% 
% Constructor call:
% RunningHistory(label, inputSize, timeSlots, interval)
%   label - element label
%   inputSize - size of input
%   timeSlots - number of time steps that are stored
%   interval - interval between storing times (a new input is stored
%     if simulation time modulo interval is zero)


classdef RunningHistory < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'timeSlots', ParameterStatus.Fixed, ...
      'interval', ParameterStatus.Fixed);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    timeSlots = 1;
    interval = 1;
    
    dimensionality = 1;
    
    % accessible structures
    output
  end
  

  methods
    % constructor
    function obj = RunningHistory(label, inputSize, timeSlots, interval)
      if nargin > 0
        obj.label = label;
        obj.size = inputSize;
        obj.timeSlots = timeSlots;
      end
      if nargin >= 4
        obj.interval = interval;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT)  %#ok<INUSD>
      if mod(time, obj.interval) == 0
        if obj.dimensionality == 1
          obj.output(2:end, :) = obj.output(1:end-1, :);
          obj.output(1, :) = obj.inputElements{1}.(obj.inputComponents{1});
        else
          obj.output(:, :, 2:end) = obj.output(:, :, 1:end-1);
          obj.output(:, :, 1) = obj.inputElements{1}.(obj.inputComponents{1});
        end
      end
    end
    
    
    % intialization
    function obj = init(obj)
      if obj.size(1) == 1
        obj.dimensionality = 1; % dimensionality of zero not treated separately
      elseif numel(obj.size) == 2
        obj.dimensionality = 2;
      else
        error('RunningHistory:init:unsopportedInputSize', ...
          'The class RunningHistory does currently not support inputs of more than two dimensions');
      end
      
      if obj.dimensionality == 1
        obj.output = NaN(obj.timeSlots, obj.size(2));
      else
        obj.output = NaN(obj.size(1), obj.size(2), obj.timeSlots);
      end
    end
  end
end


