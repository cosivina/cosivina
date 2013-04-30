% Visualization (COSIVINA toolbox)
%   Abstract base class for visualizations (plots etc.) in the GUI.

classdef Visualization < handle
  properties
    position
  end
  
  methods (Abstract)
    obj = connect(obj, simulatorHandle); % links the visualization to the simulator object
    obj = init(obj, figureHandle); % creates and initializes graphics object
    obj = update(obj); % update the visualization
  end
  
end

