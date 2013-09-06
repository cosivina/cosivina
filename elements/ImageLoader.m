% ImageLoader (COSIVINA toolbox)
%   Element to load images from file and switch between them.
% 
% Constructor call:
% ImageLoader(label, filePath, fileNames, imageSize, currentSelection)
%   label - element label
%   filePath - path to the image files
%   fileNames - cell array of image file names
%   imageSize - size of output image (camera image is resized if required)
%   currentSelection - index of initially selected image


classdef ImageLoader < Element
  
  properties (Constant)
    parameters = struct('fileNames', ParameterStatus.Fixed, 'size', ParameterStatus.Fixed, ...
      'currentSelection', ParameterStatus.InitRequired);
    components = {'image'};
    defaultOutputComponent = 'image';
  end
  
  properties
    % parameters
    filePath = '';
    fileNames = {};
    size = [1, 1];
    currentSelection = 1;
        
    % accessible structures
    image
  end
  
  methods
    % constructor
    function obj = ImageLoader(label, filePath, fileNames, imageSize, currentSelection)
      if nargin > 0
        obj.label = label;
        obj.fileNames = fileNames;
        if ~iscell(obj.fileNames)
          obj.fileNames = cellstr(obj.fileNames);
        end
        obj.size = imageSize;
      end
      if nargin >= 5
        obj.currentSelection = currentSelection;
      end
      
      for i = 1 : numel(obj.fileNames)
        obj.fileNames{i} = fullfile(filePath, obj.fileNames{i});
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      % nothing to do
    end
    
    
    % initialization
    function obj = init(obj)
      if mod(obj.currentSelection, 1) == 0 && obj.currentSelection > 0 && obj.currentSelection <= numel(obj.fileNames)
        obj.image = imread(obj.fileNames{obj.currentSelection});
        if size(obj.image, 1) ~= obj.size(1) || size(obj.image, 2) ~= obj.size(2) %#ok<CPROP>
          obj.image = resizeImage(obj.image, obj.size);
        end
      else
        obj.image = zeros(obj.size(1), obj.size(2), 3);
      end
    end

  end
end


