% ColorExtraction (COSIVINA toolbox)
%   Element that extracts 1D color salience patterns for different hue
%   ranges from 2D color image.
% 
% Constructor call:
% ColorExtraction(label, imageRangeX, imageRangeY, outputSize, ...
%     hueToIndexMap, saturationThreshold, valueThreshold)
%   label - element label
%   imageRangeX, imageRangeY - region in the image from which color
%     information is extracted
%   outputSize - size of output (one row for each hue range)
%   hueToIndexMap - array specifying hue ranges and associated index
%   saturationThreshold, valueThreshold - thresholds on saturation and
%     value for pixel to be counted color salience map


classdef ColorExtraction < Element
  
  properties (Constant)
    parameters = struct('roi', ParameterStatus.Fixed, 'size', ParameterStatus.Fixed, ...
      'hueToIndexMap', ParameterStatus.Fixed, 'saturationThreshold', ParameterStatus.Changeable, ...
      'valueThreshold', ParameterStatus.Changeable);
    components= {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    roi = [];
    size = 0;
    hueToIndexMap = [];
    saturationThreshold = 0;
    valueThreshold = 0;
    
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = ColorExtraction(label, imageRangeX, imageRangeY, outputSize, hueToIndexMap, saturationThreshold, ...
        valueThreshold)
      if nargin > 0
        obj.label = label;
        obj.roi = [reshape(imageRangeY, [1, 2]), reshape(imageRangeX, [1, 2])];
        obj.size = outputSize;
        obj.hueToIndexMap = hueToIndexMap;
      end
      if nargin >= 6
        obj.saturationThreshold = saturationThreshold;
      end
      if nargin >= 7
        obj.valueThreshold = valueThreshold;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      if size(obj.inputElements{1}.(obj.inputComponents{1}), 2) == obj.size(2) %#ok<CPROP>
        hsvImage = rgb2hsv( obj.inputElements{1}.(obj.inputComponents{1})( ...
          obj.roi(1) : obj.roi(2), obj.roi(3) : obj.roi(4), :));
      else
        hsvImage = rgb2hsv(imresize( obj.inputElements{1}.(obj.inputComponents{1})( ...
          obj.roi(1) : obj.roi(2), obj.roi(3) : obj.roi(4), :), ...
          [obj.roi(2) - obj.roi(1) + 1, obj.size(2)]));
      end
      
      mask = hsvImage(:, :, 2) >= obj.saturationThreshold & hsvImage(:, :, 3) >= obj.valueThreshold;
      obj.output(:) = 0;
      for i = 1 : size(obj.hueToIndexMap, 1) %#ok<CPROP>
        obj.output(obj.hueToIndexMap(i, 3), :) = obj.output(obj.hueToIndexMap(i, 3), :) ...
          + sum( mask & hsvImage(:, :, 1) >= obj.hueToIndexMap(i, 1) & hsvImage(:, :, 1) < obj.hueToIndexMap(i, 2));
      end
    end
    
  end
end


