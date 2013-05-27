% CustomStimulusSequence (COSIVINA toolbox)
%   Creates a sequence of custom-defined 1D or 2D stimulus patterns that
%   are activated at specified times.
% 
% Constructor call:
% CustomStimulusSequence(label, stimulusPatterns, startTimes)
%   label - element label
%   stimulusPatterns - matrix of custom stimulus patterns, either a [KxN]
%     matrix of K one-dimensional stimuli with size N, or a [MxNxK] matrix
%     of K two-dimensional stimuli with size [MxN]
%   startTimes - optional vector of start times for the specified stimuli;
%     the index of the active stimulus at simulation time t is determined
%     as max_i(t >= startTime_i); values in startTimes must be
%     monotonically increasing; if not specified, startTimes will be set to
%     1:K
%
% NOTE: The full stimulus patterns will be stored in the parameter file when
% saving parameters. This may lead to bulky parameter files.


classdef CustomStimulusSequence < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'stimulusPatterns', ParameterStatus.Fixed, ...
      'startTimes', ParameterStatus.Fixed);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    stimulusSize = [1, 1];
    nStimuli = 0;
    stimulusPatterns = 0;
    startTimes = [];
    
    stimulusDimensions = 1;
    currentStimulus = 0;
    
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = CustomStimulusSequence(label, stimulusPatterns, startTimes)
      if nargin > 0
        obj.label = label;
        obj.stimulusPatterns = stimulusPatterns;
        
        obj.stimulusDimensions = ndims(stimulusPatterns) - 1;
        if obj.stimulusDimensions == 1
          obj.stimulusSize = [1, size(stimulusPatterns, 2)];
          obj.nStimuli = size(stimulusPatterns, 1);
        elseif obj.stimulusDimensions == 2
          obj.stimulusSize = [size(stimulusPatterns, 1), size(stimulusPatterns, 2)];
          obj.nStimuli = size(stimulusPatterns, 3);
        else
          error('CustomStimulusSequence:constructor:invalidArgument', ...
            'Argument stimulusPatterns must be a two- or three-dimensional matrix.');
        end
      end
      if nargin >= 3
        obj.startTimes = startTimes;
      else
        obj.startTimes = 1:obj.nStimuli;
      end
      if numel(obj.startTimes) ~= obj.nStimuli
        error('CustomStimulusSequence:constructor:argumentSizeMismatch', ...
          'Number of entries in argument startTimes must match number of stimuli in matrix stimulusPatterns.');
      end
      if any(diff(obj.startTimes) < 0)
        error('CustomStimulusSequence:constructor:invalidArgument', ...
          'Values in argument startTimes must be monotonically increasing.');
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      i = find(obj.startTimes <= time, 1, 'last');
      if isempty(i)
        obj.currentStimulus = 0;
        obj.output(:) = 0;
      elseif i ~= obj.currentStimulus
        obj.currentStimulus = 0;
        if obj.stimulusDimensions == 1
          obj.output = obj.stimulusPatterns(i, :);
        else
          obj.output = obj.stimulusPatterns(:, :, i);
        end
      end
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.stimulusSize);
      obj.currentStimulus = 0;
    end
  end
  
end

