% Launcher for serial order model, consisting of groups of nodes
% (ordinal and memory nodes) that reflect each step in sequence, intention
% field, and condition-of-satisfaction (CoS) field. The projections from
% the ordinal nodes to the intention field are learned through an adaptive
% weight matrix.

% shared parameters
fieldSize = 100;
nOrdinalNodes = 5;
sigma_exc = 5;
sigma_inh = 10;


%% set up the architecture

% create simulator object
sim = Simulator();

% create inputs to intention and CoS field, go signal for ordinal nodes
sim.addElement(GaussStimulus1D('stimulus int', fieldSize, sigma_exc, 0, round(1/4*fieldSize), true, false));
sim.addElement(GaussStimulus1D('stimulus cos', fieldSize, sigma_exc, 3, round(1/2*fieldSize), true, false));
sim.addElement(BoostStimulus('go', 0));
sim.addElement(WeightMatrix('go -> m', [1, zeros(1, nOrdinalNodes-1)]), 'go');
sim.addElement(BoostStimulus('learn', 0));
sim.addElement(BoostStimulus('boost cos', 0));

% create neural fields and nodes
sim.addElement(NeuralField('field int', fieldSize, 10, -5, 4), 'stimulus int');
sim.addElement(NeuralField('field cos', fieldSize, 10, -5, 4), 'stimulus cos');

sim.addElement(NeuralField('nodes d', nOrdinalNodes, 10, -2, 4));
sim.addElement(NeuralField('nodes m', nOrdinalNodes, 10, -2, 4), 'go -> m');
sim.addElement(NeuralField('node c', 1, 10, -2, 4), 'boost cos');

% create connectivity for ordinal node dynamics
sim.addElement(LateralInteractionsDiscrete('d -> d', nOrdinalNodes, 12, -7), 'nodes d', [], 'nodes d');
sim.addElement(LateralInteractionsDiscrete('m -> m', nOrdinalNodes, 5, 0), 'nodes m', [], 'nodes m');
sim.addElement(ScaleInput('c -> c', 1, 0.5), 'node c', [], 'node c');

sim.addElement(ScaleInput('d -> m', nOrdinalNodes, 4), 'nodes d', [], 'nodes m');
sim.addElement(ScaleInput('m -> d', nOrdinalNodes, -3), 'nodes m', [], 'nodes d');
sim.addElement(ShiftInput('m -> d (shift)', nOrdinalNodes, 1, 3, 0, 0), 'nodes m', [], 'nodes d');
sim.addElement(ScaleInput('c -> d', 1, -5), 'node c', [], 'nodes d');

% interactions between fields
sim.addElement(LateralInteractions1D('int -> int', fieldSize, sigma_exc, 12, sigma_inh, 5, -0.25, true), ...
  'field int', [], 'field int');
sim.addElement(LateralInteractions1D('cos -> cos', fieldSize, sigma_exc, 12, sigma_inh, 5, -0.25, true), ...
  'field cos', [], 'field cos');
sim.addElement(GaussKernel1D('int -> cos', fieldSize, sigma_exc, 3, true), 'field int', [], 'field cos');

% coupling between fields and ordinal dynamics
sim.addElement(AdaptiveWeightMatrix('d -> int (learned)', [nOrdinalNodes, fieldSize], 0.05), ...
  {'nodes d', 'field int', 'learn'});
sim.addElement(ScaleInput('d -> int (scaling)', fieldSize, 6), 'd -> int (learned)', [], 'field int');
sim.addElement(SumDimension('cos -> c (sum)', 2, [1, 1], 0.5), 'field cos', [], 'node c');


%% create GUI
gui = StandardGUI(sim, [50, 50, 900, 750], 0.05, [0.0, 1/4, 1.0, 3/4], [2, 2], 0.06, [0.0, 0.0, 1.0, 1/4], [6, 4]);

% plots
gui.addVisualization(MultiPlot({'nodes d', 'nodes m', 'go', 'node c'}, ...
  {'activation', 'activation', 'output', 'activation'}, ...
  [1, 1, 1, 1], 'horizontal', {'YLim', [-15, 15], 'XLim', [0, nOrdinalNodes + 2], 'XGrid', 'on', 'YGrid', 'on', ...
  'XTick', [1:nOrdinalNodes, nOrdinalNodes + 1.5], 'XTickLabel', [strtrim(num2cell(int2str((1:nOrdinalNodes)'), 2)); 'CoS']}, ...
  {{'bo', 'LineWidth', 1, 'MarkerFaceColor', 'b'}, ...
  {'ro', 'LineWidth', 3}, {'ko', 'LineWidth', 3, 'XDataMode', 'manual', 'XData', 1}, ...
  {'ko', 'LineWidth', 3, 'XDataMode', 'manual', 'XData', nOrdinalNodes+1.5} }, ...
  'ordinal dynamics (blue - ordinal, red - memory, black - go/CoS)', 'ordinal position', 'activation'), [1, 1]);

gui.addVisualization(ScaledImage('d -> int (learned)', 'weights', [0, 1], {}, {}, ...
  'adaptive weights (ordinal nodes to inention field)', 'feature space', 'ordinal position'), [1, 2]);

gui.addVisualization(MultiPlot({'field int', 'field int'}, ...
  {'activation', 'output'}, ...
  [1, 10], 'horizontal', {'YLim', [-15, 15], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 3}, {'r', 'LineWidth', 2}}, ...
  'intention field', 'feature space', 'activation/output'), [2, 1]);

gui.addVisualization(MultiPlot({'field cos', 'field cos'}, {'activation', 'output'}, ...
  [1, 10], 'horizontal', {'YLim', [-15, 15], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 3}, {'r', 'LineWidth', 2}}, ...
  'CoS field', 'feature space', 'activation/output'), [2, 2]);

% sliders and buttons for parameter control
gui.addControl(ParameterSwitchButton('Go', 'go', 'amplitude', 0, 5, 'go signal to start ordinal dynamics', false), [1, 1]);
gui.addControl(ParameterSwitchButton('Learn', 'learn', 'amplitude', 0, 1, 'activate learning', false), [1, 2]);
gui.addControl(ParameterSwitchButton('De-boost nodes', {'nodes m', 'nodes d'}, {'h', 'h'}, [-2, -2], [-10, -10], ...
  'de-boost nodes to reset ordinal dynamics', false), [1, 3]);


gui.addControl(ParameterSlider('i_cos', 'boost cos', 'amplitude', [0, 10], '%0.1f', 1, ...
  'direct input to CoS node'), [2, 1]);

gui.addControl(ParameterSlider('ord -> int', 'd -> int (scaling)', 'amplitude', [0, 20], '%0.1f', 1, ...
  'strength of excitation from ordinal nodes to intention field'), [3, 1]);
gui.addControl(ParameterSlider('int -> cos', 'int -> cos', 'amplitude', [0, 20], '%0.1f', 1, ...
  'strength of excitation from intention field to cos field'), [3, 2]);
gui.addControl(ParameterSlider('cos -> ord', 'c -> d', 'amplitude', [0, 20], '%0.1f', -1, ...
  'strength of inhibition from CoS node to ordinal nodes'), [3, 3]);

gui.addControl(ParameterSlider('w_int', 'stimulus int', 'sigma', [0, 20], '%0.1f', 1, ...
  'width of stimulus for intention field'), [5, 1]);
gui.addControl(ParameterSlider('p_int', 'stimulus int', 'position', [0, fieldSize], '%0.1f', 1, ...
  'position of stimulus for intention field'), [5, 2]);
gui.addControl(ParameterSlider('a_int', 'stimulus int', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus for intention field'), [5, 3]);

gui.addControl(ParameterSlider('w_cos', 'stimulus cos', 'sigma', [0, 20], '%0.1f', 1, ...
  'width of stimulus for CoS field'), [6, 1]);
gui.addControl(ParameterSlider('p_cos', 'stimulus cos', 'position', [0, fieldSize], '%0.1f', 1, ...
  'position of stimulus for CoS field'), [6, 2]);
gui.addControl(ParameterSlider('a_cos', 'stimulus cos', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus CoS field'), [6, 3]);

% global control buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [1, 4]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [2, 4]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [3, 4]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [4, 4]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [5, 4]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [6, 4]);


%% run the simulation
gui.run(inf);

