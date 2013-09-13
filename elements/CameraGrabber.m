% CameraGrabber (COSIVINA toolbox)
%   Element to retrieve image from connected camera (grabs one image in
%   each step, requires camera-specific mex files).
% 
% Constructor call:
% CameraGrabber(label, deviceNumber, imageSize)
%   label - element label
%   deviceNumber - device number for the connected camera (0 or 1)
%   imageSize - size of output image (camera image is resized if required)


classdef CameraGrabber < Element
  
  properties (Constant)
    parameters = struct('deviceNumber', ParameterStatus.Fixed, 'size', ParameterStatus.Fixed);
    components = {'image'};
    defaultOutputComponent = 'image';
  end
  
  properties
    % parameters
    deviceNumber = 0;
    size = [1, 1];
    
    % accessible structures
    image
  end
  
  properties (SetAccess = protected)
    cameraHandle = 0;
  end
  
  methods
    % constructor
    function obj = CameraGrabber(label, deviceNumber, imageSize)
      if nargin > 0
        obj.label = label;
        obj.deviceNumber = deviceNumber;
        obj.size = imageSize;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.image = grab_frame(obj.cameraHandle);
      if size(obj.image, 1) ~= obj.size(1) || size(obj.image, 2) ~= obj.size(2) %#ok<CPROP>
        obj.image = imresize(obj.image, obj.size);
      end
    end
    
    
    % initialization
    function obj = init(obj)
      if obj.cameraHandle == 0
        obj.cameraHandle = open_camera(obj.deviceNumber);
      end
      
      obj.image = zeros(obj.size(1), obj.size(2), 3);
    end
    
    % close camera conenction
    function obj = close(obj)
      if obj.cameraHandle ~= 0
        close_camera(obj.cameraHandle);
        obj.cameraHandle = 0;
      end
    end

  end
end


