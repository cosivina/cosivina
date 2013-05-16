% CustomStimulus (COSIVINA toolbox)
%   Element for custom-defined stimulus pattern.
% 
% Constructor call:
% CustomStimulus(label, stimulusPattern)
%   label - element label
%   stimulusPattern - full stimulus matrix
%
% NOTE: The full stimulus pattern will be stored in the parameter file when
% saving parameters. This may lead to bulky parameter files.


classdef CustomStimulus < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'pattern', ParameterStatus.Fixed);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    pattern = 0;
        
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = CustomStimulus(label, stimulusPattern)
      if nargin > 0
        obj.label = label;
        obj.size = size(stimulusPattern); %#ok<PROP,CPROP>
        obj.pattern = stimulusPattern;
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      % nothing to do
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = obj.pattern;
    end
  end
  
end

