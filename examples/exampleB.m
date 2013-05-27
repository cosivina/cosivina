% Example B: Creating and Using a GUI
% (see the documentation for detailed explanation of the script)

% create object sim by constructor call
sim = Simulator();

% add elements
sim.addElement(NeuralField('field u', 100, 10, -5, 4));
sim.addElement(LateralInteractions1D('u -> u', 100, 4, 15, 10, 15, 0), ...
  'field u', 'output', 'field u', 'output');
sim.addElement(GaussStimulus1D('stim A', 100, 5, 6, 25), ...
  [], [], 'field u');
sim.addElement(GaussStimulus1D('stim B', 100, 5, 8, 75), ...
  [], [], 'field u');


% create the gui object
gui = StandardGUI(sim, [50, 50, 700, 500], 0.05, ...
  [0.0, 1/3, 1.0, 2/3], [1, 1], 0.1, ...
  [0.0, 0.0, 1.0, 1/3], [6, 3]);


% add a plot of field u (with activation, output, and inputs)
gui.addVisualization(MultiPlot({'field u', 'field u', 'stim A', 'stim B'}, ...
  {'activation', 'output', 'output', 'output'}, [1, 10, 1, 1], 'horizontal', ...
  {'YLim', [-10, 10], 'Box', 'on'}, ...
  {{'b', 'LineWidth', 2}, {'r'}, {'g'}, {'g'}}, ...
  'field u', 'field position', 'activation/ouput/input'), ...
  [1, 1]);


% creating graphical control elements

% resting level of field u
gui.addControl(ParameterSlider('h', 'field u', 'h', [-10, 0],...
  '%0.1f', 1, 'resting level of field u'), [1, 1]);

% interaction strengths
gui.addControl(ParameterSlider('c_exc', 'u -> u', 'amplitudeExc', [0, 40], '%0.1f', 1, ...
  'strength of lateral excitation'), [2, 1]);
gui.addControl(ParameterSlider('c_inh', 'u -> u', 'amplitudeInh', [0, 40], '%0.1f', 1, ...
  'strength of lateral inhibition'), [2, 2]);
gui.addControl(ParameterSlider('c_gi', 'u -> u', 'amplitudeGlobal', [0, 1], '%0.1f', -1, ...
  'strength of global inhibition'), [3, 1]);

% stimulus settings
gui.addControl(ParameterSlider('p_s1', 'stim A', 'position', [0, 100], '%0.1f', 1, ...
  'position of stimulus 1'), [4, 1]);
gui.addControl(ParameterSlider('c_s1', 'stim A', 'amplitude', [0, 20], '%0.1f', 1, ...
  'stength of stimulus 1'), [4, 2]);

gui.addControl(ParameterSlider('p_s2', 'stim B', 'position', [0, 100], '%0.1f', 1, ...
  'position of stimulus 2'), [5, 1]);
gui.addControl(ParameterSlider('c_s2', 'stim B', 'amplitude', [0, 20], '%0.1f', 1, ...
  'stength of stimulus 2'), [5, 2]);

% % alternative: single slider controlling two parameters
% gui.addControl(ParameterSlider('c_s', {'stim A', 'stim B'}, ...
%   {'amplitude', 'amplitude'}, [0, 20], '%0.1f', 1, ...
%   'stength of both stimuli'), [6, 1]);

% % alternative: button controlling the two stimuli
% gui.addControl(ParameterSwitchButton('stimuli on', ...
%   {'stim A', 'stim B'}, {'amplitude', 'amplitude'}, ...
%   [0, 0], [6, 6], 'toggle between stimuli on and off', true), [6, 2]);

% buttons to control the GUI
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [1, 3]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [2, 3]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [3, 3]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [4, 3]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [5, 3]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [6, 3]);


% run the simulation in the GUI
gui.run();



