% MemoryTrace (COSIVINA toolbox)
%   Memory trace that accumulates activation where it receives input, and
%   decays to zero in regions that do not receive input.
%
% Constructor call:
% MemoryTrace(label, size, tauBuild, tauDecay, threshold)
%   size - size of memory trace
%   tauBuild - time constant of activation build-up
%   tauDecay - time constant for decay of activation
%   threshold - input threshold for activation build-up


classdef MemoryTrace < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'tauBuild', ParameterStatus.Changeable, ...
      'tauDecay', ParameterStatus.Changeable, 'threshold', ParameterStatus.Changeable);
    components = {'activeRegions', 'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    tauBuild = 100;
    tauDecay = 100;
    threshold = 0.5;
        
    % accessible structures
    activeRegions
    output
  end
  
  methods
    % constructor
    function obj = MemoryTrace(label, size, tauBuild, tauDecay, threshold)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 3
        obj.tauBuild = tauBuild;
      end
      if nargin >= 4
        obj.tauDecay = tauDecay;
      else
        obj.tauDecay = obj.tauBuild;
      end
      if nargin >= 5
        obj.threshold = threshold;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.activeRegions = obj.inputElements{1}.(obj.inputComponents{1}) > obj.threshold;
      if any(obj.activeRegions)
        obj.output = obj.output ...
          + 1/obj.tauBuild * (-obj.output + obj.inputElements{1}.(obj.inputComponents{1})) .* obj.activeRegions ...
          + 1/obj.tauDecay * (-obj.output) .* ~obj.activeRegions;
      end
    end
    
    
    % intialization
    function obj = init(obj)
      obj.activeRegions = zeros(obj.size);
      obj.output = zeros(obj.size);
    end
  end
end


