% LFP (COSIVINA toolbox)
%   A continuously updated history of Local Field Potential over 
%   recent time steps.
%   (written by Joe Ambrose and Sebastian Schneegans)
% 
% Constructor call:
% LFP(label, timeSlots, interval)
%   label - element label
%   timeSlots - number of time steps that are stored
%   interval - interval between storing times (a new input is stored
%     if simulation time modulo interval is zero)
%
% Alternative constructor call (automatically add all inputs from 
% another element as inputs):
% LFP(label, timeSlots, interval, sim, targetLabel)
%   sim - the Simulator object to which the element is added
%   targetLabel - label of the element whose inputs should be copied
% When using this constructor, typically no further inputs should be 
% defined in the Simulator.addElement method.
%
% WARNING - No elements that combine positive and negative inputs (such
%   as MexicanHatKernel or LaterlInteractions) should be used in 
%   conjunction with LFP element, since these do not allow proper 
%   computation of the total LFP signal.


classdef LFP < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'timeSlots', ParameterStatus.Fixed, ...
      'interval', ParameterStatus.Fixed);
    components = {'output', 'flipoutput'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    timeSlots = 1;
    interval = 1;
    
    % accessible structures
    output
    flipoutput
  end
  

  methods
    % constructor
    function obj = LFP(label, timeSlots, interval, sim, targetLabel)
      if nargin > 0
        obj.label = label;
        obj.timeSlots = timeSlots;
      end
      if nargin >= 3
        obj.interval = interval;
      end
      if nargin >= 4
          if ~isa(sim, 'Simulator') || nargin < 5 || ~ischar(targetLabel) || ~sim.isElement(targetLabel)
              error('LFP:Constructor:invalidArguments', ...
                  ['Argument SIMULATOR must be the simulator handle to which the LFP element is linked, '...
                  'and ELEMENTLABEL must be an existing element label in this simulator']);
          end
          obj.setInputs(sim, targetLabel);
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT)  %#ok<INUSD>
      if mod(time, obj.interval) == 0
        obj.output(2:end) = obj.output(1:end-1);
        input = 0;
        for i = 1 : obj.nInputs
            % each input must be normalized by its size
            n = numel(obj.inputElements{i}.(obj.inputComponents{i}));
            input = input + sum(abs(obj.inputElements{i}.(obj.inputComponents{i})(:)))/n;
        end
        obj.output(1) = input;
        obj.flipoutput = obj.output(obj.timeSlots:-1:1);
      end
    end
    
    
    % intialization
    function obj = init(obj)
      obj.output = NaN(1, obj.timeSlots);
      obj.flipoutput = NaN(1, obj.timeSlots);
    end
    
    
    % set all inputs to designated element as inputs to LFP
    function obj = setInputs(obj, sim, elementLabel)
        targetElement = sim.getElement(elementLabel);
        
        obj.nInputs = targetElement.nInputs;
        obj.inputElements = targetElement.inputElements;
        obj.inputComponents = targetElement.inputComponents;
    end
  end
end


