% TilePlot (COSIVINA toolbox)
%   Visualization for 3D or 4D matrices. Plots two-dimensional cuts through
%   the higher-dimensional matrix as individual tiles in a larger plot.
%
% Constructor call:
% TilePlot(plotElement, plotComponent, inputSize, gridSize, imageRange, ...
%   axesProperties, plotProperties, title, xlabel, ylabel, position)
%
% Arguments:
% plotElement - label of the element whose component should be
%   visualized
% plotComponent - name of the element component that should be plotted
% inputSize - size of the component to be plotted (a vector with three or
%   four elements)
% gridSize - two-element vector specifying the size of the grid of tiles 
%   to be plotted (for 3D input: product of entries must be greater or
%   equal to third entry in inputSize; for 4D input: entries must match 3rd
%   and 4th entry of inputSize)
% imageRange - two-element vector specifying the range of the image's
%   color code
% axesProperties - cell array containing a list of valid axes settings
%   (as property/value pairs) that can be applied to the axes handle via
%   the set function (optional, see Matlab documentation on axes for 
%   further information)
% plotProperties - cell array containing a list of valid image object
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
% h = TilePlot('field u', 'activation', [sizeY, sizeX, sizeZ], [5, 5], ...
%   [-10, 10], {}, {}, 'three-dimensional field');
% (plots a 5x5 grid of tiles; sizeZ must not be greater than 25)

classdef TilePlot < Visualization
  properties
    plotElementHandle = 0;
    plotElementLabel
    plotComponent
    
    inputSize
    nDim
    gridSize
    
    gridColor
    imageRange
        
    axesHandle = 0;
    axesProperties = {};
    
    plotHandle = 0;
    plotProperties = {};
    
    title = '';
    xlabel = '';
    ylabel = '';
    
    titleHandle = 0;
    xlabelHandle = 0;
    ylabelHandle = 0;
  end
  
  
  methods
    % Constructor
    function obj = TilePlot(plotElement, plotComponent, inputSize, gridSize, imageRange, ...
        axesProperties, plotProperties, title, xlabel, ylabel, position)
      obj.plotElementLabel = plotElement;
      obj.plotComponent = plotComponent;
      obj.inputSize = reshape(inputSize, [1, numel(inputSize)]);
      obj.gridSize = reshape(gridSize, [1, numel(gridSize)]);
      obj.imageRange = imageRange;

      if nargin >= 6
        obj.axesProperties = axesProperties;
      end
      if nargin >= 7
        obj.plotProperties = plotProperties;
      end
      if nargin >= 8 && ~isempty(title)
        obj.title = title;
      end
      if nargin >= 9 && ~isempty(xlabel)
        obj.xlabel = xlabel;
      end
      if nargin >= 10 && ~isempty(ylabel)
        obj.ylabel = ylabel;
      end
      if nargin >= 11
        obj.position = position;
      end
      
      obj.nDim = numel(obj.inputSize);
      if obj.nDim < 3 || obj.nDim > 4
        error('TilePlot:Constructor:invalidArgument', 'Input must be an array of three or four dimensions.');
      end
      if obj.nDim == 4 && any(obj.grid ~= obj.inputSize(3, 4))
        error('TilePlot:Constructor:inconsistentArguments', ...
        'For four-dimensional inputs, argument gridSize must match the third an fourth entry in argument inputSize.');
      elseif obj.nDim == 3 && obj.inputSize(3) > prod(obj.gridSize)
        error('TilePlot:Constructor:inconsistentArguments', ['For three-dimensional inputs, the third entry '...
          'in argument inputSize must not be greater than the total number of tiles specified by argument gridSize.']);
      end
      
      if numel(obj.gridSize) ~= 2
        error('TilePlot:Constructor:invalidArgument', 'Argument gridSize must be a two-element vector.');
      end
      
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      if simulatorHandle.isElement(obj.plotElementLabel)
        obj.plotElementHandle = simulatorHandle.getElement(obj.plotElementLabel);
        if ~obj.plotElementHandle.isComponent(obj.plotComponent) ...
            && ~obj.plotElementHandle.isParameter(obj.plotComponent)
          error('TilePlot:connect:invalidComponent', 'Invalid component %s for element %s in simulator object.', ...
            obj.plotComponent, obj.plotElementLabel);
        end
      else
        error('TilePlot:connect:elementNotFound', 'No element %s in simulator object.', obj.plotElementLabel);
      end
    end
    
    
    % initialization
    function obj = init(obj, figureHandle)
      obj.axesHandle = axes('Parent', figureHandle, 'Position', obj.position);
      
      sz = size(obj.plotElementHandle.(obj.plotComponent));
      if numel(sz) ~= numel(obj.inputSize) || any(sz ~= obj.inputSize)
        error('TilePlot:init:inputSizeMismatch', ...
          'Size of the input array must match the argument inputSize specified in the constructor call.')
      end
      
      if obj.nDim == 3
        obj.plotHandle = image(reshape(permute(reshape( ...
          cat(3, obj.plotElementHandle.(obj.plotComponent), ...
          NaN([obj.inputSize(1:2), prod(obj.gridSize) - obj.inputSize(3)])), ...
          [obj.inputSize(1:2), obj.gridSize]), [1, 3, 2, 4]), obj.inputSize(1:2) .* obj.gridSize), ...
          'Parent', obj.axesHandle, 'CDataMapping', 'scaled', obj.plotProperties{:});
      else
        obj.plotHandle = image(reshape(permute(obj.plotElementHandle.(obj.plotComponent), [1, 3, 2, 4]), ...
          obj.inputSize(1:2) .* obj.gridSize), 'Parent', obj.axesHandle, 'CDataMapping', 'scaled', ...
          obj.plotProperties{:});
      end
      
      set(obj.axesHandle, 'CLim', obj.imageRange, 'GridLineStyle', '-', ...
        'XTick', 0.5:obj.inputSize(2):obj.inputSize(2)^2+0.5, 'XTickLabel', [], 'XGrid', 'on',  ...
        'YTick', 0.5:obj.inputSize(1):obj.inputSize(1)^2+0.5, 'YTickLabel', [], 'YGrid', 'on', ...
        obj.axesProperties{:});
      colormap(jet(256));
      
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
      if obj.nDim == 3
        set(obj.plotHandle, 'CData', reshape(permute(reshape( ...
          cat(3, obj.plotElementHandle.(obj.plotComponent), ...
          NaN([obj.inputSize(1:2), prod(obj.gridSize) - obj.inputSize(3)])), ...
          [obj.inputSize(1:2), obj.gridSize]), [1, 3, 2, 4]), obj.inputSize(1:2) .* obj.gridSize));
      else
        set(obj.plotHandle, 'CData', reshape(permute(obj.plotElementHandle.(obj.plotComponent), [1, 3, 2, 4]), ...
          obj.inputSize(1:2) .* obj.gridSize), 'Parent', obj.axesHandle, 'CDataMapping', 'scaled', ...
          obj.plotProperties{:});
      end
    end
    
  end
  
end


