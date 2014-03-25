% Launcher for a reference frame transformation simulator. The architecture
% can be used to perform a shift of the peak pattern in the retinal field
% by the position of a single peak in the gaze direction field, by forming
% a combined representation in the 2D transformation field and then
% performing a read-out along the diagonal of that field. The architecture
% can also be used for other related tasks, such as inverse transformation
% (from body-centered position to retinal) or alignment of body-centered
% and retinal position for gaze estimation.


%% setting up the simulator

% shared parameters
fieldRange = 60;
sigma_exc = 5;
sigma_inh = 12.5;

fieldSize = 2 * fieldRange + 1;

% create simulator object
sim = Simulator();

% create inputs
sim.addElement(GaussStimulus1D('stim_r1', fieldSize, sigma_exc, 0, fieldRange + 1 - fieldRange/2, 0, 0));
sim.addElement(GaussStimulus1D('stim_r2', fieldSize, sigma_exc, 0, fieldRange + 1 + fieldRange/2, 0, 0));
sim.addElement(GaussStimulus1D('stim_g', fieldSize, sigma_exc, 0, fieldRange + 1, 0, 0));
sim.addElement(GaussStimulus1D('stim_b1', 2*fieldSize-1, sigma_exc, 0, fieldSize - fieldRange/2, 0, 0));
sim.addElement(GaussStimulus1D('stim_b2', 2*fieldSize-1, sigma_exc, 0, fieldSize + fieldRange/2, 0, 0));

sim.addElement(BoostStimulus('boost_r', 0));
sim.addElement(BoostStimulus('boost_g', 0));
sim.addElement(BoostStimulus('boost_b', 0));
sim.addElement(BoostStimulus('boost_t', 0));

% create neural field
sim.addElement(NeuralField('r', fieldSize, 20, -5, 4), {'stim_r1', 'stim_r2', 'boost_r'});
sim.addElement(NeuralField('g', fieldSize, 20, -5, 4), {'stim_g', 'boost_g'});
sim.addElement(NeuralField('b', 2*fieldSize-1, 20, -5, 4), {'stim_b1', 'stim_b2', 'boost_b'});
sim.addElement(NeuralField('t', [fieldSize, fieldSize], 20, -5, 4), {'boost_t'});

% create interactions

% lateral interactions for field t
sim.addElement(GaussKernel2D('tt_exc', [fieldSize, fieldSize], sigma_exc, sigma_exc, 0, false, false, true), 't', 'output', 't');
sim.addElement(GaussKernel2D('tt_inh', [fieldSize, fieldSize], sigma_inh, sigma_inh, 0, false, false, true), 't', 'output', 't');
sim.addElement(SumAllDimensions('sum_t', [fieldSize, fieldSize]), 't', 'output');
sim.addElement(DiagonalSum('diag_t', [fieldSize, fieldSize], 1), 't', 'output');
sim.addElement(ScaleInput('tt_global', 1, 0.0), 'sum_t', 'fullSum', 't');

% lateral interactions in fields r, g, and b
sim.addElement(LateralInteractions1D('rr', fieldSize, sigma_exc, 0, sigma_inh, 0, 0, false, true), 'r', 'output', 'r');
sim.addElement(LateralInteractions1D('gg', fieldSize, sigma_exc, 0, sigma_inh, 0, 0, false, true), 'g', 'output', 'g');
sim.addElement(LateralInteractions1D('bb', 2*fieldSize-1, sigma_exc, 0, sigma_inh, 0, 0, false, true), 'b', 'output', 'b');

% interactions between fields
sim.addElement(GaussKernel1D('tr', fieldSize, sigma_exc, 0, false, true), 'r', 'output');
sim.addElement(ExpandDimension2D('exp_tr', 1, [fieldSize, fieldSize]), 'tr', 'output', 't');
sim.addElement(GaussKernel1D('tg', fieldSize, sigma_exc, 0, false, true), 'g', 'output');
sim.addElement(ExpandDimension2D('exp_tg', 2, [fieldSize, fieldSize]), 'tg', 'output', 't');
sim.addElement(GaussKernel1D('tb', 2*fieldSize-1, sigma_exc, 0, false, true), 'b', 'output');
sim.addElement(DiagonalExpansion('exp_tb', 2*fieldSize-1, 0), 'tb', 'output', 't');

sim.addElement(GaussKernel1D('rt', fieldSize, sigma_exc, 0, false, true), 'sum_t', 'verticalSum', 'r');
sim.addElement(GaussKernel1D('gt', fieldSize, sigma_exc, 0, false, true), 'sum_t', 'horizontalSum', 'g');
sim.addElement(GaussKernel1D('bt', 2*fieldSize-1, sigma_exc, 0, false, true), 'diag_t', 'output', 'b');


%% setting up the GUI

elementGroups = {'field r', 'field g', 'field b', 'field t', ...
  'r -> r', 'g -> g', 'b -> b', 't -> t (narrow)', 't -> t (wide)', 't -> t (global)', ...
  'r -> t', 'g -> t', 'b -> t', 't -> r', 't -> g', 't -> b', ...
  'stimulus r1', 'stimulus r2', 'stimulus g', 'stimulus b1', 'stimulus b2', 'boost r', 'boost g', 'boost b', 'boost t'};
elementsInGroup = {'r', 'g', 'b', 't', ...
  'rr', 'gg', 'bb', 'tt_exc', 'tt_inh', 'tt_global', ...
  'tr', 'tg', 'tb', 'rt', 'gt', 'bt', ...
  'stim_r1', 'stim_r2', 'stim_g', 'stim_b1', 'stim_b2', 'boost_r', 'boost_g', 'boost_b', 'boost_t'};

figureWidth = 900;
figureHeight = 4/5 * figureWidth;
S = diag([figureHeight/figureWidth, 1, figureHeight/figureWidth, 1]);

% create GUI object
gui = StandardGUI(sim, [50, 50, figureWidth, figureHeight], 0.01, [0.0, 0.0, 0.8, 1.0], [1, 1], 0.05, ...
  [0.8, 0.0, 0.2, 1.0], [25, 1], elementGroups, elementsInGroup);


w = 0.4; h = 0.125; m = 0.05;
gui.addVisualization(ScaledImage('t', 'activation', [-7.5, 7.5], ...
  {'YAxisLocation', 'right', 'YDir', 'normal', 'XTick', -40:20:40, 'YTick', -40:20:40}, ...
  {'XData', -fieldRange:fieldRange, 'YData', -fieldRange:fieldRange}, ...
  '', 'retinal position', 'gaze direction', [h+2*m, 1-w-h-2*m, w, w] * S));
gui.addVisualization(MultiPlot({'r', 'r', 'stim_r1', 'stim_r2'}, {'activation', 'output', 'output', 'output'}, ...
  [1, 10, 1, 1], 'horizontal', ...
  {'YLim', [-10, 10], 'XLim', [-fieldRange, fieldRange], 'Box', 'on', 'YGrid', 'on', 'XTick', -40:20:40}, ...
  {{'Color', 'b', 'LineWidth', 2, 'XDataMode', 'manual', 'XData', -fieldRange:fieldRange}, ...
  {'Color', 'r', 'XDataMode', 'manual', 'XData', -fieldRange:fieldRange}, ...
  {'Color', [0, 0.75, 0], 'XDataMode', 'manual', 'XData', -fieldRange:fieldRange}, ...
  {'Color', [0, 0.75, 0], 'XDataMode', 'manual', 'XData', -fieldRange:fieldRange}}, ...
  'retinal field', '', 'activation', [h+2*m, 1-h-m, w, h] * S));
gui.addVisualization(MultiPlot({'g', 'g', 'stim_g'}, {'activation', 'output', 'output'}, ...
  [1, 10, 1, 1], 'vertical', ...
  {'XLim', [-10, 10], 'XDir', 'reverse', 'YLim', [-fieldRange, fieldRange], 'YAxisLocation', 'right', 'Box', 'on', ...
  'XGrid', 'on', 'YTick', -40:20:40}, ...
  {{'Color', 'b', 'LineWidth', 2, 'XDataMode', 'manual', 'YData', -fieldRange:fieldRange}, ...
  {'Color', 'r', 'XDataMode', 'manual', 'YData', -fieldRange:fieldRange}, ...
  {'Color', [0, 0.75, 0], 'XDataMode', 'manual', 'YData', -fieldRange:fieldRange}}, ...
  'gaze direction field', 'activation', '', [m, 1-w-h-2*m, h, w] * S));

% plot diagonal axes
ylim_b = [-10, 10];
d = h/sqrt(2) + w; % size of diagonal axes
up = [(2*fieldSize-1)/(w*sqrt(2))-2, diff(ylim_b)/h, 0]; % "up vector" for diagonal axes
up = up/norm(up, 2);
pbar = [sqrt(2)*w, h, 1]; % "plot box aspect ratio" for diagonal axes
gui.addVisualization(MultiPlot({'b', 'b', 'stim_b1', 'stim_b2'}, {'activation', 'output', 'output', 'output'}, ...
  [1, 10, 1, 1], 'horizontal', ...
  {'XLim', [-fieldSize+1, fieldSize-1], 'YLim', ylim_b, 'PlotBoxAspectRatio', pbar, 'CameraUpVector', up, 'Box', 'on', ...
  'XTick', -120:20:120, 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 2, 'XDataMode', 'manual', 'XData', -fieldSize+1:fieldSize-1}, ...
  {'r', 'XDataMode', 'manual', 'XData', -fieldSize+1:fieldSize-1}, ...
  {'Color', [0, 0.75, 0], 'XDataMode', 'manual', 'XData', -fieldSize+1:fieldSize-1}, ...
  {'Color', [0, 0.75, 0], 'XDataMode', 'manual', 'XData', -fieldSize+1:fieldSize-1}}, ...
  '', 'body-centered position', '', [w+h+3.5*m-d/2, 1-w-h-3.5*m-d/2, d, d] * S));


% add sliders
gui.addControl(ParameterSlider('p_r1', 'stim_r1', 'position', [1, fieldSize], '%0.1f', 1, 'position of retinal stimulus 1'), [1, 1]);
gui.addControl(ParameterSlider('c_r1', 'stim_r1', 'amplitude', [0, 10], '%0.1f', 1, 'strength of retinal stimulus 1'), [2, 1]);
gui.addControl(ParameterSlider('p_r2', 'stim_r2', 'position', [1, fieldSize], '%0.1f', 1, 'position of retinal stimulus 2'), [3, 1]);
gui.addControl(ParameterSlider('c_r2', 'stim_r2', 'amplitude', [0, 10], '%0.1f', 1, 'strength of retinal stimulus 2'), [4, 1]);
gui.addControl(ParameterSlider('bst_r', 'boost_r', 'amplitude', [0, 10], '%0.1f', 1, 'boost of retinal field'), [5, 1]);

gui.addControl(ParameterSlider('p_g', 'stim_g', 'position', [1, fieldSize], '%0.1f', 1, 'position of gaze field stimulus'), [7, 1]);
gui.addControl(ParameterSlider('c_g', 'stim_g', 'amplitude', [0, 10], '%0.1f', 1, 'strength of gaze field stimulus'), [8, 1]);
gui.addControl(ParameterSlider('bst_g', 'boost_g', 'amplitude', [0, 10], '%0.1f', 1, 'boost of gaze field'), [9, 1]);

gui.addControl(ParameterSlider('p_b1', 'stim_b1', 'position', [1, 2*fieldSize-1], '%0.1f', 1, 'position of body-centered stimulus 1'), [11, 1]);
gui.addControl(ParameterSlider('c_b1', 'stim_b1', 'amplitude', [0, 10], '%0.1f', 1, 'strength of body-centered stimulus 1'), [12, 1]);
gui.addControl(ParameterSlider('p_b2', 'stim_b2', 'position', [1, 2*fieldSize-1], '%0.1f', 1, 'position of body-centered stimulus 2'), [13, 1]);
gui.addControl(ParameterSlider('c_b2', 'stim_b2', 'amplitude', [0, 10], '%0.1f', 1, 'strength of body-centered stimulus 2'), [14, 1]);
gui.addControl(ParameterSlider('bst_b', 'boost_b', 'amplitude', [0, 10], '%0.1f', 1, 'boost of body-centered field'), [15, 1]);

gui.addControl(ParameterSlider('bst_t', 'boost_t', 'amplitude', [0, 10], '%0.1f', 1, 'boost of transformation field'), [17, 1]);


% add buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [20, 1]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [21, 1]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [22, 1]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [23, 1]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [24, 1]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [25, 1]);

%% run the simulator in the GUI

gui.run(inf);


