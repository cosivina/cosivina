% Launcher for a two-dimensional neural field simulator.
% The scripts sets up an architecture with a single two-dimensional neural
% field, lateral interactions, and two Gaussian inputs to the field. It
% then creates a GUI for this architecture and starts that GUI.
% Hover over sliders and buttons to see a description of their function.


%% setting up the simulator

% shared parameters
fieldSize = 100;
sigma_exc = 5;
sigma_inh = 10;

% create simulator object
sim = Simulator();

% create inputs
sim.addElement(GaussStimulus2D('stimulus 1', [fieldSize, fieldSize], sigma_exc, sigma_exc, 0, ...
  round(1/4 * fieldSize), round(1/4 * fieldSize)));
sim.addElement(GaussStimulus2D('stimulus 2', [fieldSize, fieldSize], sigma_exc, sigma_exc, 0, ...
  round(3/4 * fieldSize), round(3/4 * fieldSize)));
sim.addElement(GaussStimulus2D('stimulus 3', [fieldSize, fieldSize], sigma_exc, inf, 0, ...
  round(1/4 * fieldSize), round(1/4 * fieldSize)));
sim.addElement(GaussStimulus2D('stimulus 4', [fieldSize, fieldSize], inf, sigma_exc, 0, ...
  round(3/4 * fieldSize), round(3/4 * fieldSize)));

% create neural field
sim.addElement(NeuralField('field u', [fieldSize, fieldSize], 20, -5, 4), ...
  {'stimulus 1', 'stimulus 2', 'stimulus 3', 'stimulus 4'});

% create interactions
sim.addElement(LateralInteractions2D('u -> u', [fieldSize, fieldSize], sigma_exc, sigma_exc, 0, ...
  sigma_inh, sigma_inh, 0, 0), 'field u', [], 'field u');

% create noise stimulus and noise kernel
sim.addElement(NormalNoise('noise', [fieldSize, fieldSize], 1.0));
sim.addElement(GaussKernel2D('noise kernel', [fieldSize, fieldSize], 0, 0, 1.0), 'noise', [], 'field u');


%% setting up the GUI

elementGroupLabels = {'field u', 'kernel u -> u', 'stimulus 1', 'stimulus 2', 'stimulus 3', 'stimulus 4', 'noise kernel'};
elementGroups = {'field u', 'u -> u', 'stimulus 1', 'stimulus 2', 'stimulus 3', 'stimulus 4', 'noise kernel'};

gui = StandardGUI(sim, [50, 50, 1000, 600], 0.01, [0.0, 0.3, 1.0, 0.7], [1, 1], 0.075, ...
  [0.0, 0.0, 1.0, 0.3], [6, 4], elementGroupLabels, elementGroups);

gui.addVisualization(SurfacePlot('field u', 'activation', [-10, 10], 'surface', {}, {}, 'field u activation'), [1, 1]);

% add sliders
% resting level and noise
gui.addControl(ParameterSlider('h', 'field u', 'h', [-10, 0], '%0.1f', 1, 'resting level of field u'), [1, 1]);
gui.addControl(ParameterSlider('q', 'noise kernel', 'amplitude', [0, 10], '%0.1f', 1, ...
  'noise level for field u'), [1, 3]);

% lateral interactions
gui.addControl(ParameterSlider('c_exc', 'u -> u', 'amplitudeExc', [0, 50], '%0.1f', 1, ...
  'strength of lateral excitation'), [2, 1]);
gui.addControl(ParameterSlider('c_inh', 'u -> u', 'amplitudeInh', [0, 50], '%0.1f', 1, ...
  'strength of lateral inhibition'), [2, 2]);
gui.addControl(ParameterSlider('c_glob', 'u -> u', 'amplitudeGlobal', [0, 0.25], '%0.3f', -1, ...
  'strength of global inhibition'), [2, 3]);

% stimuli
gui.addControl(ParameterSlider('px_s1', 'stimulus 1', 'positionX', [0, fieldSize], '%0.1f', 1, ...
  'horizontal position of stimulus 1'), [3, 1]);
gui.addControl(ParameterSlider('py_s1', 'stimulus 1', 'positionY', [0, fieldSize], '%0.1f', 1, ...
  'vertical position of stimulus 1'), [3, 2]);
gui.addControl(ParameterSlider('a_s1', 'stimulus 1', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 1'), [3, 3]);

gui.addControl(ParameterSlider('px_s2', 'stimulus 2', 'positionX', [0, fieldSize], '%0.1f', 1, ...
  'horizontal position of stimulus 2'), [4, 1]);
gui.addControl(ParameterSlider('py_s2', 'stimulus 2', 'positionY', [0, fieldSize], '%0.1f', 1, ...
  'vertical position of stimulus 2'), [4, 2]);
gui.addControl(ParameterSlider('a_s2', 'stimulus 2', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 2'), [4, 3]);

gui.addControl(ParameterSlider('py_s3', 'stimulus 3', 'positionY', [0, fieldSize], '%0.1f', 1, ...
  'vertical position of stimulus 3'), [5, 2]);
gui.addControl(ParameterSlider('a_s3', 'stimulus 3', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 3'), [5, 3]);

gui.addControl(ParameterSlider('px_s4', 'stimulus 4', 'positionX', [0, fieldSize], '%0.1f', 1, ...
  'horizontal position of stimulus 4'), [6, 1]);
gui.addControl(ParameterSlider('a_s4', 'stimulus 4', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 4'), [6, 3]);

% add buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [1, 4]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [2, 4]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [3, 4]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [4, 4]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [5, 4]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [6, 4]);


%% run the simulator in the GUI

gui.run(inf);


