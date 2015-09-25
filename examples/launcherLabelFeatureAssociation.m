%% setting up the architecture (fields, interactions, and inputs)

% parameters shared by multiple elements
fieldSize = 180;
labelSize = 30;

% create simulator object
sim = Simulator();

% create fields and memory traces
sim.addElement(NeuralField('field cl', [fieldSize, labelSize], 10, -4.2, 5));
sim.addElement(NeuralField('field sl', [fieldSize, labelSize], 10, -4.2, 5));
sim.addElement(NeuralField('field l', labelSize, 20, -8.2, 2));
sim.addElement(NeuralField('field c', fieldSize, 10, -3.5, 5));
sim.addElement(NeuralField('field s', fieldSize, 10, -3.5, 5));

sim.addElement(NeuralField('field l_color', labelSize, 20, -3.2, 2));
sim.addElement(NeuralField('field l_size', labelSize, 20, -3.2, 2));

sim.addElement(MemoryTrace('memory trace cl', [fieldSize, labelSize], 100, 10000), 'field cl');
sim.addElement(MemoryTrace('memory trace sl', [fieldSize, labelSize], 100, 10000), 'field sl');

% additional soft sigmoid output functions
sim.addElement(Sigmoid('cl soft', [fieldSize, labelSize], 1, 0), 'field cl', 'activation');
sim.addElement(Sigmoid('sl soft', [fieldSize, labelSize], 1, 0), 'field sl', 'activation');
sim.addElement(Sigmoid('l soft', labelSize, 1, 0), 'field l', 'activation');

% create connections
sim.addElement(LateralInteractions2D('cl -> cl', [fieldSize, labelSize], 5, 0, 1.5, 8, 20, 1, -0.03), ... % c_inh was 4.5 in original
  'field cl', [], 'field cl');
sim.addElement(SumAllDimensions('sum cl soft', [fieldSize, labelSize]), 'cl soft');
sim.addElement(GaussKernel2D('mem_cl -> cl', [fieldSize, labelSize], 1, 0, 0.8), 'memory trace cl', [], 'field cl');

sim.addElement(LateralInteractions2D('sl -> sl', [fieldSize, labelSize], 5, 0, 1.5, 8, 20, 1, -0.03), ...
  'field sl', [], 'field sl');
sim.addElement(SumAllDimensions('sum sl soft', [fieldSize, labelSize]), 'sl soft');
sim.addElement(GaussKernel2D('mem_sl -> sl', [fieldSize, labelSize], 1, 0, 0.8), 'memory trace sl', [], 'field sl');

sim.addElement(LateralInteractions1D('s -> s', fieldSize, 5, 4, 8, 3, 0), 'field s', [], 'field s'); % s_inh was 18 in original
sim.addElement(LateralInteractions1D('c -> c', fieldSize, 5, 4, 8, 3, 0), 'field c', [], 'field c');
sim.addElement(LateralInteractions1D('l -> l', labelSize, 0, 2, 1, 0, -5), 'field l', [], 'field l');

sim.addElement(GaussKernel1D('cl -> c', fieldSize, 5, 3), 'cl -> cl', 'horizontalSum', 'field c');
sim.addElement(ScaleInput('cl -> l', labelSize, 0.2), 'sum cl soft', 'verticalSum', 'field l');

sim.addElement(GaussKernel1D('c -> cl', fieldSize, 5, 1.5), 'field c');
sim.addElement(ScaleInput('l -> cl', labelSize, 1.5), 'l soft');
sim.addElement(ExpandDimension2D('expand c -> cl', 2, [fieldSize, labelSize]), 'c -> cl', [], 'field cl');
sim.addElement(ExpandDimension2D('expand l -> cl', 1, [fieldSize, labelSize]), 'l -> cl', [], 'field cl');

sim.addElement(GaussKernel1D('sl -> s', fieldSize, 5, 3), 'sl -> sl', 'horizontalSum', 'field s');
sim.addElement(ScaleInput('sl -> l', labelSize, 0.2), 'sum sl soft', 'verticalSum', 'field l');

sim.addElement(GaussKernel1D('s -> sl', fieldSize, 5, 1.5), 'field s');
sim.addElement(ScaleInput('l -> sl', labelSize, 1.5), 'l soft');
sim.addElement(ExpandDimension2D('expand s -> sl', 2, [fieldSize, labelSize]), 's -> sl', [], 'field sl');
sim.addElement(ExpandDimension2D('expand l -> sl', 1, [fieldSize, labelSize]), 'l -> sl', [], 'field sl');

sim.addElement(ScaleInput('cl -> l_color', labelSize, 0.6), 'sum cl soft', 'verticalSum', 'field l_color');
sim.addElement(ScaleInput('sl -> l_size', labelSize, 0.6), 'sum sl soft', 'verticalSum', 'field l_size');
sim.addElement(LateralInteractions1D('l_color -> l_color', labelSize, 0, 4, 1, 0, -10), ...
  'field l_color', [], 'field l_color');
sim.addElement(LateralInteractions1D('l_size -> l_size', labelSize, 0, 4, 1, 0, -10), ...
  'field l_size', [], 'field l_size');

% stimulus settings
colorStrings = {'red', 'yellow', 'green', 'cyan', 'blue'};
colorValues = [30, 60, 90, 120, 150];
sizeStrings = {'tiny', 'small', 'medium', 'large'};
sizeValues = [20, 65, 110, 155];
labelStrings = {'dax', 'modi', 'bubu', 'kiki'};
labelAbbrv = {'d', 'm', 'b', 'k'};
labelValues = [6, 12, 18, 24];

% create stimuli
sim.addElement(GaussStimulus1D('input c', fieldSize, 5, 0, colorValues(1), true), [], [], 'field c');
sim.addElement(GaussStimulus1D('input s', fieldSize, 5, 0, sizeValues(1), true), [], [], 'field s');
sim.addElement(GaussStimulus1D('input l', labelSize, 0, 0, labelValues(1), true), [], [], 'field l');

sim.addElement(BoostStimulus('boost cl', 0), [], [], 'field cl');
sim.addElement(BoostStimulus('boost sl', 0), [], [], 'field sl');
sim.addElement(BoostStimulus('boost c', 0), [], [], 'field c');
sim.addElement(BoostStimulus('boost s', 0), [], [], 'field s');
sim.addElement(BoostStimulus('boost l', 0), [], [], 'field l');

% noise
sim.addElement(NormalNoise('noise cl', [fieldSize, labelSize], 1), [], [], 'field cl');
sim.addElement(NormalNoise('noise sl', [fieldSize, labelSize], 1), [], [], 'field sl');
sim.addElement(NormalNoise('noise c', fieldSize, 1), [], [], 'field c');
sim.addElement(NormalNoise('noise s', fieldSize, 1), [], [], 'field s');
sim.addElement(NormalNoise('noise l', labelSize, 1), [], [], 'field l');


%% setting up the GUI

gui = StandardGUI(sim, [50, 50, 900, 675], 0.01, [0.0, 0.035, 0.75, 0.95], [7, 7], [0.015, 0.03], [0.75, 0, 0.25, 1], [25, 1]);

% label field
gui.addVisualization(MultiPlot({'field l', 'field l', 'input l', 'cl -> l', 'sl -> l'}, ...
  {'activation', 'output', 'output', 'output', 'output'}, [1, 10, 1, 1, 1], ...
  'horizontal', {'YLim', [-12.5, 12.5], 'Box', 'on', 'YGrid', 'on', 'XTick', labelValues, 'XTickLabel', labelAbbrv, ...
  'YTick', [-10, -5, 0, 5, 10], 'YTickLabel', {'-10', '', '0', '', '10'}}, ...
  {{'b', 'LineWidth', 1.5}, {'r', 'LineWidth', 1.5}, {'g', 'LineWidth', 1.5}, ...
  {'m', 'LineWidth', 1.5}, {'c', 'LineWidth', 1.5}}, 'label field'), [1, 3], [1, 2]);

% color field
gui.addVisualization(MultiPlot({'field c', 'field c', 'input c', 'cl -> c'}, ...
  {'activation', 'output', 'output', 'output'}, [1, 10, 1, 1], 'vertical', ...
  {'XLim', [-10, 10], 'Box', 'on', 'XGrid', 'on', 'XDir', 'reverse', 'YAxisLocation', 'right', ...
  'XTick', [-10, -5, 0, 5, 10], 'XTickLabel', {'-10', '', '0', '', '10'}, 'YTickLabel', {}, 'YLim', [0, 180]}, ...
  {{'b', 'LineWidth', 1.5}, {'r', 'LineWidth', 1.5}, {'g', 'LineWidth', 1.5}, {'m', 'LineWidth', 1.5}}, ...
  'color field', [], 'color values'), [2, 5], [3, 1]);
% color-label field
gui.addVisualization(ScaledImage('field cl', 'activation', [-7.5, 7.5], ...
  {'YAxisLocation', 'right', 'YDir', 'normal', 'XTick', labelValues, 'XTickLabel', labelAbbrv}, {},  ...
  'color-label field'), [2, 3], [3, 2]);
% color-label memory trace
gui.addVisualization(ScaledImage('memory trace cl', 'output', [0, 1], ...
  {'YAxisLocation', 'right', 'YDir', 'normal', 'XTick', labelValues, 'XTickLabel', labelAbbrv}, {}, ...
  'color-label memory trace'), [2, 1], [3, 2]);
% label field (color only)
gui.addVisualization(MultiPlot({'field l_color', 'field l_color', 'cl -> l_color'}, {'activation', 'output', 'output'}, ...
  [1, 10, 1], 'horizontal', {'YLim', [-12.5, 12.5], 'Box', 'on', 'YGrid', 'on', 'XTick', labelValues, ...
  'XTickLabel', labelAbbrv, 'YTick', [-10, -5, 0, 5, 10], 'YTickLabel', {'-10', '', '0', '', '10'}}, ...
  {{'b', 'LineWidth', 1.5}, {'r', 'LineWidth', 1.5}, {'m', 'LineWidth', 1.5}}, 'label field (color only)'), ...
  [4, 6], [1, 2]);

% color field
gui.addVisualization(MultiPlot({'field s', 'field s', 'input s', 'sl -> s'}, ...
  {'activation', 'output', 'output', 'output'}, [1, 10, 1, 1], 'vertical', ...
  {'XLim', [-10, 10], 'Box', 'on', 'XGrid', 'on', 'XDir', 'reverse', 'YAxisLocation', 'right', ...
  'XTick', [-10, -5, 0, 5, 10], 'XTickLabel', {'-10', '', '0', '', '10'}, 'YTickLabel', {}, 'YLim', [0, 180]}, ...
  {{'b', 'LineWidth', 1.5}, {'r', 'LineWidth', 1.5}, {'g', 'LineWidth', 1.5}, {'m', 'LineWidth', 1.5}}, ...
  'size field', [], 'size values'), [5, 5], [3, 1]);
% color-label field
gui.addVisualization(ScaledImage('field sl', 'activation', [-7.5, 7.5], ...
  {'YAxisLocation', 'right', 'YDir', 'normal', 'XTick', labelValues, 'XTickLabel', labelAbbrv}, {},  ...
  'size-label field'), [5, 3], [3, 2]);
% color-label memory trace
gui.addVisualization(ScaledImage('memory trace sl', 'output', [0, 1], ...
  {'YAxisLocation', 'right', 'YDir', 'normal', 'XTick', labelValues, 'XTickLabel', labelAbbrv}, {}, ...
  'size-label memory trace'), [5, 1], [3, 2]);
% label field (color only)
gui.addVisualization(MultiPlot({'field l_size', 'field l_size', 'sl -> l_size'}, {'activation', 'output', 'output'}, ...
  [1, 10, 1], 'horizontal', {'YLim', [-12.5, 12.5], 'Box', 'on', 'YGrid', 'on', 'XTick', labelValues, ...
  'XTickLabel', labelAbbrv, 'YTick', [-10, -5, 0, 5, 10], 'YTickLabel', {'-10', '', '0', '', '10'}}, ...
  {{'b', 'LineWidth', 1.5}, {'r', 'LineWidth', 1.5}, {'m', 'LineWidth', 1.5}}, 'label field (size only)'), ...
  [7, 6], [1, 2]);


% input controls
gui.addControl(ParameterDropdownSelector('label', 'input l', 'position', labelValues, labelStrings, 1, 'color'), [1, 1]);
gui.addControl(ParameterSwitchButton('label input on', 'input l', 'amplitude', 0, 10), [2, 1]);

gui.addControl(ParameterDropdownSelector('color', 'input c', 'position', colorValues, colorStrings, 1, 'color'), [4, 1]);
gui.addControl(ParameterSlider('pos', 'input c', 'position', [0, fieldSize], '%0.0f', 1, 'position of color input'), [5, 1]);
gui.addControl(ParameterSwitchButton('color input on', 'input c', 'amplitude', 0, 10), [6, 1]);

gui.addControl(ParameterDropdownSelector('size', 'input s', 'position', sizeValues, sizeStrings, 1, 'color'), [8, 1]);
gui.addControl(ParameterSlider('pos', 'input s', 'position', [0, fieldSize], '%0.0f', 1, 'position of size input'), [9, 1]);
gui.addControl(ParameterSwitchButton('size input on', 'input s', 'amplitude', 0, 10), [10, 1]);

% boost controls
% gui.addControl(ParameterSwitchButton('boost for recognition', {'boost cl', 'boost sl', 'boost l'}, ...
%   {'amplitude', 'amplitude','amplitude'}, [0, 0, 0], [1.3, 1.3, 1.3]), [12, 1]);
gui.addControl(ParameterSwitchButton('boost for production', {'boost cl', 'boost sl', 'boost c', 'boost s'}, ...
  {'amplitude', 'amplitude', 'amplitude', 'amplitude'}, [0, 0, 0, 0], [2.6, 2.6, 1.0, 1.0]), [13, 1]);

% coupling control
gui.addControl(ParameterSlider('coupling', {'l -> cl', 'l -> sl'}, {'amplitude', 'amplitude'}, [0, 1.5], '%0.1f', 1, ...
  'coupling of features via label field'), [15, 1]);

% global control buttons
yButton = 19;
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [1+yButton, 1]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [2+yButton, 1]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [3+yButton, 1]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [4+yButton, 1]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [5+yButton, 1]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [6+yButton, 1]);


%% run the simulation
gui.run(inf);


