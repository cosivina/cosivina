% RGBImage (COSIVINA toolbox)
%   Plots a 3xMxN matrix as an RGB image using the Matlab image function.
% 
% Constructor call: RGBImage(imageElement, imageComponent, ...
%   axesProperties, imageProperties, title, xlabel, ylabel, position)
%
% Arguments:
% imageElement - label of the element whose component should be
%   visualized
% imageComponent - name of the element component that should be plotted
% axesProperties - cell array containing a list of valid axes settings
%   (as property/value pairs) that can be applied to the axes handle via
%   the set function (optional, see Matlab documentation on axes for 
%   further information)
% imageProperties - cell array containing a list of valid image object
%   settings (as property/value pairs) that can be applied to the image
%   handle via the set function (optional, see Matlab documentation on
%   the image function for further information)
% title - string specifying an axes title (optional)
% xlabel - string specifying an x-axis label (optional)
% ylabel - string specifying a y-axis label (optional)
% position - position of the control in the GUI figure window in relative
%   coordinates (optional, is overwritten when specifying a grid position
%   in the GUI's addVisualization function)
%
% Example:
% h = RGBImage('camera grabber', 'output', {'YDir', 'normal'}, {}, ...
%   'camera image');


classdef RGBImage < Visualization
  properties
    imageElementHandle
    imageElementLabel
    imageComponent
    
    axesHandle
    axesProperties
    
    imageHandle
    imageProperties
    
    title = '';
    xlabel = '';
    ylabel = '';
    
    titleHandle = 0;
    xlabelHandle = 0;
    ylabelHandle = 0;
  end
  
  methods
    % Constructor    
    function obj = RGBImage(imageElement, imageComponent, axesProperties, imageProperties, ...
        title, xlabel, ylabel, position)
      obj.imageElementLabel = imageElement;
      obj.imageComponent = imageComponent;
      obj.axesProperties = {};
      obj.imageProperties = {};
      obj.position = [];
      obj.axesHandle = 0;
      obj.imageHandle = 0;
      
      if nargin >= 3
        obj.axesProperties = axesProperties;
      end
      if nargin >= 4
        obj.imageProperties = imageProperties;
      end
      if nargin >= 5 && ~isempty(title)
        obj.title = title;
      end
      if nargin >= 6 && ~isempty(xlabel)
        obj.xlabel = xlabel;
      end
      if nargin >= 7 && ~isempty(ylabel)
        obj.ylabel = ylabel;
      end
      if nargin >= 8
        obj.position = position;
      end
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      if simulatorHandle.isElement(obj.imageElementLabel)
        obj.imageElementHandle = simulatorHandle.getElement(obj.imageElementLabel);
        if ~obj.imageElementHandle.isComponent(obj.imageComponent) ...
            && ~obj.imageElementHandle.isParameter(obj.imageComponent)
          error('RGBImage:connect:invalidComponent', 'Invalid component %s for element %s in simulator object.', ...
            obj.imageComponent, obj.imageElementLabel);
        end
      else
        error('RGBImage:connect:elementNotFound', 'No element %s in simulator object.', obj.imageElementLabel);
      end
    end
    
    
    % initialization
    function obj = init(obj, figureHandle)
      obj.axesHandle = axes('Parent', figureHandle, 'Position', obj.position);
      obj.imageHandle = image(obj.imageElementHandle.(obj.imageComponent), 'Parent', obj.axesHandle, ...
        obj.imageProperties{:});
      if ~isempty(obj.axesProperties)
        set(obj.axesHandle, obj.axesProperties{:});
      end
      
      if ~isempty(obj.title)
       obj.titleHandle = title(obj.axesHandle, obj.title); %#ok<CPROP>
     end
     if ~isempty(obj.xlabel)
       obj.xlabelHandle = xlabel(obj.axesHandle, obj.xlabel); %#ok<CPROP>
     end
     if ~isempty(obj.ylabel)
       obj.ylabelHandle = ylabel(obj.axesHandle, obj.ylabel); %#ok<CPROP>
     end
    end
    
    
    % update
    function obj = update(obj)
      set(obj.imageHandle, 'CData', obj.imageElementHandle.(obj.imageComponent));
    end
    
  end
  
end