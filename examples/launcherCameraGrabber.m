% Demonstration of the mechanisms to grab images from a camera or from
% file. The architecture fetches images from a camera or from a file and
% performs a color extraction on it (for a subregion of the image,
% integrated over the vertical axis).

%% setting up the simulator

% shared parameters
fieldSize = 100;
sigma_exc = 5;
sigma_inh = 12.5;

% create simulator object
sim = Simulator();

% add elements
% sim.addElement(CameraGrabber('grabber', 0, [240, 320]));
sim.addElement(ImageLoader('grabber', '', 'sceneSnapshot.png', [240, 320], 1));

sim.addElement(ColorExtraction('ce', [1, 320], [1, 240], [3, 640], ...
  [0, 1/6, 1; 1/6, 1/2, 2; 1/2, 5/6, 3; 5/6, inf, 1], 0.4, 0.4), 'grabber', 'image');


%% setting up the GUI

gui = StandardGUI(sim, [50, 50, 600, 500], 0.05, [0.0, 0.0, 2/3, 1], [2, 1], 0.05, [2/3, 0, 1/3, 1/2], [6, 1]);

gui.addVisualization(RGBImage('grabber', 'image', {}, {}), [1, 1]);
gui.addVisualization(SlicePlot('ce', 'output', [1, 2, 3], 'horizontal', 1, 'horizontal', ...
  {'YLim', [0, 50], 'XLim', [1, 640]}, {{'r-'}, {'g-'}, {'b-'}}), [2, 1]);

% add buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [1, 1]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [2, 1]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [3, 1]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, false, 'save parameter settings'), [4, 1]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [5, 1]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [6, 1]);


%% run the simulator in the GUI

gui.run(inf);


