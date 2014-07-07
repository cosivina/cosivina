% Launcher to illustrate coupling of feature spaces via a 2D field.
% The scripts sets up an architecture with two one-dimensional fields
% (field s and field f), that are bidirectionally coupled to a single
% two-dimensionally field (field v). The architecture may be interpreted as
% a simple model of feature extraction and binding in early visual
% processing, with field s being a purely spatial representation, field f a
% pure feature representation (like orientation or color), and field v
% representing the full multi-dimensional visual input.
% The script then creates a GUI for this architecture and
% runs that GUI. Hover over sliders and buttons to see a descrition of
% their function.


%% setting up the simulator

% shared parameters
sizeSpt = 100;
sizeFtr = 100;

sigma_exc = 5;
sigma_inh = 10;

% create simulator
sim = Simulator();

% create inputs
sim.addElement(GaussStimulus2D('stimulus v1', [sizeFtr, sizeSpt], sigma_exc, sigma_exc, 0, ...
  round(1/4*sizeFtr), round(1/4*sizeSpt), 0, 1));
sim.addElement(GaussStimulus2D('stimulus v2', [sizeFtr, sizeSpt], sigma_exc, sigma_exc, 0, ...
  round(3/4*sizeFtr), round(3/4*sizeSpt), 0, 1));

sim.addElement(GaussStimulus1D('stimulus s1', [1, sizeSpt], sigma_exc, 0, round(1/4*sizeSpt), false));
sim.addElement(GaussStimulus1D('stimulus s2', [1, sizeSpt], sigma_exc, 0, round(3/4*sizeSpt), false));
sim.addElement(SumInputs('stimulus sum s', [1, sizeSpt]), {'stimulus s1', 'stimulus s2'});

sim.addElement(GaussStimulus1D('stimulus f1', [1, sizeFtr], sigma_exc, 0, round(1/4*sizeFtr), true));
sim.addElement(GaussStimulus1D('stimulus f2', [1, sizeFtr], sigma_exc, 0, round(3/4*sizeFtr), true));
sim.addElement(SumInputs('stimulus sum f', [1, sizeSpt]), {'stimulus f1', 'stimulus f2'});

% create neural fields
sim.addElement(NeuralField('field v', [sizeFtr, sizeSpt], 20, -5, 4), {'stimulus v1', 'stimulus v2'});
sim.addElement(NeuralField('field s', [1, sizeSpt], 20, -5, 4), 'stimulus sum s');
sim.addElement(NeuralField('field f', [1, sizeFtr], 20, -5, 4), 'stimulus sum f');

% add lateral interactions
sim.addElement(LateralInteractions2D('v -> v', [sizeFtr, sizeSpt], sigma_exc, sigma_exc, 0, sigma_inh, sigma_inh, 0, 0, ...
  false, false, true), 'field v', 'output', 'field v');
sim.addElement(SumAllDimensions('sum v', [sizeFtr, sizeSpt]), 'field v', 'output');
sim.addElement(LateralInteractions1D('s -> s', [1, sizeSpt], sigma_exc, 0, sigma_inh, 0, 0, false, true), ...
  'field s', 'output', 'field s');
sim.addElement(LateralInteractions1D('f -> f', [1, sizeSpt], sigma_exc, 0, sigma_inh, 0, 0, false, true), ...
  'field f', 'output', 'field f');

% projections from field v to 1D fields (uses sum alon one dimension)
sim.addElement(GaussKernel1D('v -> s', [1, sizeSpt], sigma_exc, 0, false), 'sum v', 'verticalSum', 'field s');
sim.addElement(GaussKernel1D('v -> f', [1, sizeFtr], sigma_exc, 0, true), 'sum v', 'horizontalSum', 'field f');

% projections from 1D fields to field v (requires expansion to 2D)
sim.addElement(GaussKernel1D('s -> v', [1, sizeSpt], sigma_exc, 0, false), 'field s', 'output');
sim.addElement(ExpandDimension2D('expand s -> v', 1, [sizeFtr, sizeSpt]), 's -> v', 'output', 'field v');
sim.addElement(GaussKernel1D('f -> v', [1, sizeFtr], sigma_exc, 0, true), 'field f', 'output');
sim.addElement(ExpandDimension2D('expand f -> v', 2, [sizeFtr, sizeSpt]), 'f -> v', 'output', 'field v');

% noise
sim.addElement(NormalNoise('noise s', [1, sizeSpt], 1), [], [], 'field s');
sim.addElement(NormalNoise('noise f', [1, sizeFtr], 1), [], [], 'field f');
sim.addElement(NormalNoise('noise v', [sizeFtr, sizeSpt], 1), [], [], 'field v');


%% setting up the GUI

elementGroupLabels = {'field v', 'field s', 'field f', 'kernel v -> v', 'kernel s -> s', 'kernel f -> f', ...
  'kernel v -> s', 'kernel v -> f', 'kernel s -> v', 'kernel f -> v', ...
  'stimulus v1', 'stimulus v2', 'stimulus s1', 'stimulus s2', 'stimulus f1', 'stimulus f2', ...
  'noise s', 'noise f', 'noise v'};
elementGroups = {'field v', 'field s', 'field f', 'v -> v', 's -> s', 'f -> f', ...
  'v -> s', 'v -> f', 's -> v', 'f -> v', ...
  'stimulus v1', 'stimulus v2', 'stimulus s1', 'stimulus s2', 'stimulus f1', 'stimulus f2', ...
  'noise s', 'noise f', 'noise v'};

gui = StandardGUI(sim, [100, 50, 1000, 720], 0.0, [0.1, 0.3, 0.55, 0.7], [4, 4], 0.03, [0, 0, 1, 1], [28, 4], ...
  elementGroupLabels, elementGroups);

%visualizations
gui.addVisualization(MultiPlot({'stimulus sum s', 'field s', 'field s'}, {'output', 'activation', 'output'}, ...
  [1, 1, 10], 'horizontal', {'XLim', [1, sizeSpt], 'YLim', [-10, 10]}, ...
  {{'g'}, {'b', 'LineWidth', 2}, {'r'}}, [], 'spatial position', 'activation s'), [4, 2], [1, 3]);
gui.addVisualization(MultiPlot({'stimulus sum f', 'field f', 'field f'}, {'output', 'activation', 'output'}, ...
  [1, 1, 10], 'vertical', ...
  {'YLim', [1, sizeFtr], 'XLim', [-10, 10], 'XDir', 'reverse', 'YAxisLocation', 'right'},...
  {{'g'}, {'b', 'LineWidth', 2}, {'r'}}, [], 'activation f', []), [1, 1], [3, 1]);
gui.addVisualization(ScaledImage('field v', 'activation', [-10, 10], {'YDir', 'normal', 'YAxisLocation', 'right'}, ...
  {}, [], [], 'feature value'), ...
  [1, 2], [3, 3]);

% parameter sliders
gui.addControl(ParameterSlider('h_v', 'field v', 'h', [-10, 0], '%0.1f', 1, 'resting level of field v'), [22, 1]);
gui.addControl(ParameterSlider('h_s', 'field s', 'h', [-10, 0], '%0.1f', 1, 'resting level of field s'), [22, 2]);
gui.addControl(ParameterSlider('h_f', 'field f', 'h', [-10, 0], '%0.1f', 1, 'resting level of field f'), [22, 3]);

gui.addControl(ParameterSlider('q_v', 'noise v', 'amplitude', [0, 10], '%0.1f', 1, 'noise level for field v'), [23, 1]);
gui.addControl(ParameterSlider('q_s', 'noise s', 'amplitude', [0, 10], '%0.1f', 1, 'noise level for field f'), [23, 2]);
gui.addControl(ParameterSlider('q_f', 'noise f', 'amplitude', [0, 10], '%0.1f', 1, 'noise level for field s'), [23, 3]);

gui.addControl(ParameterSlider('c_vv_exc', 'v -> v', 'amplitudeExc', [0, 50], '%0.1f', 1, ...
  'strength of lateral excitation in field v'), [24, 1]);
gui.addControl(ParameterSlider('c_vv_inh', 'v -> v', 'amplitudeInh', [0, 50], '%0.1f', 1, ...
  'strength of lateral inhibition in field v'), [24, 2]);
gui.addControl(ParameterSlider('c_vv_glob', 'v -> v', 'amplitudeGlobal', [0, 0.1], '%0.3f', -1, ...
  'strength of global inhibition in field v'), [24, 3]);

gui.addControl(ParameterSlider('c_ss_exc', 's -> s', 'amplitudeExc', [0, 50], '%0.1f', 1, ...
  'strength of lateral excitation in s'), [25, 1]);
gui.addControl(ParameterSlider('c_ss_inh', 's -> s', 'amplitudeInh', [0, 50], '%0.1f', 1, ...
  'strength of lateral inhibiton in s'), [25, 2]);
gui.addControl(ParameterSlider('c_ss_gi', 's -> s', 'amplitudeGlobal', [0, 2], '%0.2f', -1, ...
  'strength of global inhibition in s'), [25, 3]);

gui.addControl(ParameterSlider('c_ff_exc', 'f -> f', 'amplitudeExc', [0, 50], '%0.1f', 1, ...
  'strength of lateral excitation in field f'), [26, 1]);
gui.addControl(ParameterSlider('c_ff_inh', 'f -> f', 'amplitudeInh', [0, 50], '%0.1f', 1, ...
  'strenght of lateral inhibition in field f'), [26, 2]);
gui.addControl(ParameterSlider('c_ff_gi', 'f -> f', 'amplitudeGlobal', [0, 2], '%0.2f', -1, ...
  'strength of global inhibition in field f'), [26, 3]);

gui.addControl(ParameterSlider('c_fv', 'v -> f', 'amplitude', [0, 2.5], '%0.3f', 1, ...
  'projection strength from field v to field f'), [27, 1]);
gui.addControl(ParameterSlider('c_vf', 'f -> v', 'amplitude', [0, 10], '%0.1f', 1, ...
  'projection strength from field f to field v'), [27, 2]);

gui.addControl(ParameterSlider('c_sv', 'v -> s', 'amplitude', [0, 2.5], '%0.3f', 1, ...
  'projection strength from field v to field s'), [28, 1]);
gui.addControl(ParameterSlider('c_vs', 's -> v', 'amplitude', [0, 10], '%0.1f', 1, ...
  'projection strength from field s to field v'), [28, 2]);

% stimuli
gui.addVisualization(StaticText('Stimuli for field v'), [1, 4], [1, 1], 'control');
gui.addControl(ParameterSlider('px_s1', 'stimulus v1', 'positionX', [0, sizeSpt], '%0.1f', 1, ...
  'horizontal position of stimulus 1 for field v'), [2, 4]);
gui.addControl(ParameterSlider('py_s1', 'stimulus v1', 'positionY', [0, sizeFtr], '%0.1f', 1, ...
  'vertical position of stimulus 1 for field v'), [3, 4]);
gui.addControl(ParameterSlider('a_s1', 'stimulus v1', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 1 for field v'), [4, 4]);
gui.addControl(ParameterSlider('px_s2', 'stimulus v2', 'positionX', [0, sizeSpt], '%0.1f', 1, ...
  'horizontal position of stimulus 2 for field v'), [6, 4]);
gui.addControl(ParameterSlider('py_s2', 'stimulus v2', 'positionY', [0, sizeFtr], '%0.1f', 1, ...
  'vertical position of stimulus 2 for field v'), [7, 4]);
gui.addControl(ParameterSlider('a_s2', 'stimulus v2', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 2 for field v'), [8, 4]);

gui.addVisualization(StaticText('Stimuli for field s'), [10, 4], [1, 1], 'control');
gui.addControl(ParameterSlider('p_s1', 'stimulus s1', 'position', [0, sizeSpt], '%0.1f', 1, ...
  'horizontal position of stimulus 1 for field s'), [11, 4]);
gui.addControl(ParameterSlider('a_s1', 'stimulus s1', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 1 for field s'), [12, 4]);

gui.addControl(ParameterSlider('p_s2', 'stimulus s2', 'position', [0, sizeSpt], '%0.1f', 1, ...
  'horizontal position of stimulus 2 for field s'), [13, 4]);
gui.addControl(ParameterSlider('a_s2', 'stimulus s2', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 2 for field s'), [14, 4]);

gui.addVisualization(StaticText('Stimuli for field f'), [16, 4], [1, 1], 'control');
gui.addControl(ParameterSlider('p_s1', 'stimulus f1', 'position', [0, sizeSpt], '%0.1f', 1, ...
  'horizontal position of stimulus 1 for field f'), [17, 4]);
gui.addControl(ParameterSlider('a_s1', 'stimulus f1', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 1 for field f'), [18, 4]);

gui.addControl(ParameterSlider('p_s2', 'stimulus f2', 'position', [0, sizeSpt], '%0.1f', 1, ...
  'horizontal position of stimulus 2 for field f'), [19, 4]);
gui.addControl(ParameterSlider('a_s2', 'stimulus f2', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 2 for field f'), [20, 4]);

% gui.addControl(ParameterSlider('px_s1', 'stimulus v1', 'amplitude', [0, 10], '%0.1f', 1, ...
%   'amplitude of first stimulus to field v'), [2, 4]);
% gui.addControl(ParameterSlider('py_s1', 'stimulus v1', 'amplitude', [0, 10], '%0.1f', 1, ...
%   'amplitude of first stimulus to field v'), [2, 4]);
% gui.addControl(ParameterSlider('v2', 'stimulus v2', 'amplitude', [0, 10], '%0.1f', 1, ...
%   'amplitude of second stimulus to field v'), [3, 4]);
% 
% gui.addControl(ParameterSlider('f1', 'stimulus f1', 'amplitude', [0, 10], '%0.1f', 1, ...
%   'amplitude of first stimulus to field f'), [4, 4]);
% gui.addControl(ParameterSlider('f2', 'stimulus f2', 'amplitude', [0, 10], '%0.1f', 1, ...
%   'amplitude of second stimulus to field f'), [5, 4]);
% 
% gui.addControl(ParameterSlider('s1', 'stimulus s1', 'amplitude', [0, 10], '%0.1f', 1, ...
%   'amplitude of first stimulus to field s'), [7, 4]);
% gui.addControl(ParameterSlider('s2', 'stimulus s2', 'amplitude', [0, 10], '%0.1f', 1, ...
%   'amplitude of second stimulus to field s'), [8, 4]);

% global control buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [22, 4]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [23, 4]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [24, 4]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [25, 4]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [26, 4]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [27, 4]);


%% run the simulation

gui.run();


