% Launcher for a DNF model the Dimensional Change Card Sort (DCCS) Task
% (DFT book Chapter 13).


%% setting up the simulator

% shared parameters
fieldSize = 100;

sigma_exc = 5;
sigma_inhexc = 2;
sigma_inh = 12.5;

sigma_mem = 10;
mem_str=.0;

% create simulator
sim = Simulator();

%Target inputs for CS and SS fields
sim.addElement(GaussStimulus2D('stimulus CS1', [fieldSize, fieldSize], sigma_exc, sigma_exc, 1, ...
  round(1/4*fieldSize), round(1/4*fieldSize), 0, 1));
sim.addElement(GaussStimulus2D('stimulus CS2', [fieldSize, fieldSize], sigma_exc, sigma_exc, 1, ...
  round(3/4*fieldSize), round(3/4*fieldSize), 0, 1));

sim.addElement(GaussStimulus2D('stimulus CS3', [fieldSize, fieldSize], sigma_exc, sigma_exc, 0, ...
  round(1/4*fieldSize), round(3/4*fieldSize), 0, 1));
sim.addElement(GaussStimulus2D('stimulus CS4', [fieldSize, fieldSize], sigma_exc, sigma_exc, 0, ...
  round(3/4*fieldSize), round(1/4*fieldSize), 0, 1));

sim.addElement(GaussStimulus2D('stimulus SS1', [fieldSize, fieldSize], sigma_exc, sigma_exc, 1, ...
  round(1/4*fieldSize), round(1/4*fieldSize), 0, 1));
sim.addElement(GaussStimulus2D('stimulus SS2', [fieldSize, fieldSize], sigma_exc, sigma_exc, 1, ...
  round(3/4*fieldSize), round(3/4*fieldSize), 0, 1));

sim.addElement(GaussStimulus2D('stimulus SS3', [fieldSize, fieldSize], sigma_exc, sigma_exc, 0, ...
  round(1/4*fieldSize), round(3/4*fieldSize), 0, 1));
sim.addElement(GaussStimulus2D('stimulus SS4', [fieldSize, fieldSize], sigma_exc, sigma_exc, 0, ...
  round(3/4*fieldSize), round(1/4*fieldSize), 0, 1));

%Test card ridges
sim.addElement(GaussStimulus1D('stimulus1 CS (1d)', fieldSize, sigma_exc, 0, round(1/4*fieldSize), true, false));
sim.addElement(ExpandDimension2D('ridge1 CS', 2, [fieldSize, fieldSize]), 'stimulus1 CS (1d)', 'output');
sim.addElement(GaussStimulus1D('stimulus2 CS (1d)', fieldSize, sigma_exc, 0, round(3/4*fieldSize), true, false));
sim.addElement(ExpandDimension2D('ridge2 CS', 2, [fieldSize, fieldSize]), 'stimulus2 CS (1d)', 'output');

sim.addElement(GaussStimulus1D('stimulus1 SS (1d)', fieldSize, sigma_exc, 0, round(1/4*fieldSize), true, false));
sim.addElement(ExpandDimension2D('ridge1 SS', 2, [fieldSize, fieldSize]), 'stimulus1 SS (1d)', 'output');
sim.addElement(GaussStimulus1D('stimulus2 SS (1d)', fieldSize, sigma_exc, 0, round(3/4*fieldSize), true, false));
sim.addElement(ExpandDimension2D('ridge2 SS', 2, [fieldSize, fieldSize]), 'stimulus2 SS (1d)', 'output');

%1D spatial input
sim.addElement(GaussStimulus1D('stimulus SP (1d)', fieldSize, sigma_exc, 0, round(3/4*fieldSize), true, false));

% create neural fields
sim.addElement(NeuralField('node Color', [1, 1], 10, -5, 1));
sim.addElement(NeuralField('node Shape', [1, 1], 10, -5, 1));

sim.addElement(NeuralField('field SPw', [1, fieldSize], 40, -5, 5),'stimulus SP (1d)');
sim.addElement(NeuralField('field CSw', [fieldSize, fieldSize], 40, -5, 5), {'stimulus CS1' 'stimulus CS2' 'stimulus CS3' 'stimulus CS4' 'ridge1 CS' 'ridge2 CS'});
sim.addElement(NeuralField('field CSv', [fieldSize, fieldSize], 40, -5, 5));

sim.addElement(NeuralField('field SSw', [fieldSize, fieldSize], 40, -5, 5), {'stimulus SS1' 'stimulus SS2' 'stimulus SS3' 'stimulus SS4' 'ridge1 SS' 'ridge2 SS'});
sim.addElement(NeuralField('field SSv', [fieldSize, fieldSize], 40, -5, 5));

% add lateral interactions
sim.addElement(MexicanHatKernel1D('SPw -> SPw',[1,fieldSize],sigma_exc,0,sigma_inh,0,1,1),'field SPw','output','field SPw');
sim.addElement(SumDimension('SPwv (global)', 2, 1, 0), 'field SPw', 'output', 'field SPw');

sim.addElement(GaussKernel2D('CSw -> CSw (exc)', [fieldSize, fieldSize], sigma_exc, sigma_exc, 0, 0, 1, 1), ...
  'field CSw', 'output', 'field CSw');
sim.addElement(GaussKernel2D('CSw -> CSv', [fieldSize, fieldSize], sigma_inhexc, sigma_inhexc, 0, 0, 1, 1), ...
  'field CSw', 'output', 'field CSv');
sim.addElement(GaussKernel2D('CSv -> CSw', [fieldSize, fieldSize], sigma_inh, sigma_inh, 0, 0, 1, 1), ...
  'field CSv', 'output', 'field CSw');
sim.addElement(SumAllDimensions('sum CSv', [fieldSize, fieldSize]), 'field CSv', 'output');
sim.addElement(ScaleInput('CSv -> CSw (global)', [1, 1], 0), 'sum CSv', 'fullSum', 'field CSw');

sim.addElement(ScaleInput('CNode -> CSw', [1, 1], 0), 'node Color', 'output', 'field CSw');
sim.addElement(ScaleInput('CNode -> CNode', [1, 1], 0), 'node Color', 'output', 'node Color');
sim.addElement(ScaleInput('CNode -> SNode', [1, 1], 0), 'node Color', 'output', 'node Shape');

sim.addElement(GaussKernel2D('SSw -> SSw (exc)', [fieldSize, fieldSize], sigma_exc, sigma_exc, 0, 0, 1, 1), ...
  'field SSw', 'output', 'field SSw');
sim.addElement(GaussKernel2D('SSw -> SSv', [fieldSize, fieldSize], sigma_inhexc, sigma_inhexc, 0, 0, 1, 1), ...
  'field SSw', 'output', 'field SSv');
sim.addElement(GaussKernel2D('SSv -> SSw', [fieldSize, fieldSize], sigma_inh, sigma_inh, 0, 0, 1, 1), ...
  'field SSv', 'output', 'field SSw');
sim.addElement(SumAllDimensions('sum SSv', [fieldSize, fieldSize]), 'field SSv', 'output');
sim.addElement(ScaleInput('SSv -> SSw (global)', [1, 1], 0), 'sum SSv', 'fullSum', 'field SSw');

sim.addElement(ScaleInput('SNode -> SSw', [1, 1], 0), 'node Shape', 'output', 'field SSw');
sim.addElement(ScaleInput('SNode -> SNode', [1, 1], 0), 'node Shape', 'output', 'node Shape');
sim.addElement(ScaleInput('SNode -> CNode', [1, 1], 0), 'node Shape', 'output', 'node Color');

% add dimensional interactions between w fields
sim.addElement(SumAllDimensions('sum CSw', [fieldSize, fieldSize]), 'field CSw', 'output');
sim.addElement(SumAllDimensions('sum SSw', [fieldSize, fieldSize]), 'field SSw', 'output');

sim.addElement(ScaleInput('CSw -> CNode', [1, 1], 0), 'sum CSw', 'fullSum', 'node Color');
sim.addElement(ScaleInput('SSw -> SNode', [1, 1], 0), 'sum SSw', 'fullSum', 'node Shape');

sim.addElement(GaussKernel1D('CSw -> SSw (1d)', [1, fieldSize], sigma_exc, 0, 0), 'sum CSw', 'verticalSum');
sim.addElement(GaussKernel1D('SSw -> CSw (1d)', [1, fieldSize], sigma_exc, 0, 0), 'sum SSw', 'verticalSum');

sim.addElement(GaussKernel1D('CSw -> CLw (1d)', [1,fieldSize], sigma_exc, 0, 0), 'sum CSw', 'horizontalSum');
sim.addElement(GaussKernel1D('SSw -> SLw (1d)', [1,fieldSize], sigma_exc, 0, 0), 'sum SSw', 'horizontalSum');

sim.addElement(GaussKernel1D('CSw -> SPw (1d)', [1, fieldSize], sigma_exc, 0, 0), 'sum CSw', 'verticalSum', 'field SPw');
sim.addElement(GaussKernel1D('SSw -> SPw (1d)', [1, fieldSize], sigma_exc, 0, 0), 'sum SSw', 'verticalSum', 'field SPw');
sim.addElement(GaussKernel1D('SPw -> fSw (1d)', [1, fieldSize], sigma_exc, 0, 0), 'field SPw', 'output');
sim.addElement(ExpandDimension2D('expand SPw -> fSw', 1, [fieldSize, fieldSize]), 'SPw -> fSw (1d)', 'output', {'field CSw' 'field SSw'});

sim.addElement(ExpandDimension2D('expand CSw -> SSw', 1, [fieldSize, fieldSize]), 'CSw -> SSw (1d)', 'output', 'field SSw');
sim.addElement(ExpandDimension2D('expand SSw -> CSw', 1, [fieldSize, fieldSize]), 'SSw -> CSw (1d)', 'output', 'field CSw');

% noise
sim.addElement(NormalNoise('noise CSw', [fieldSize, fieldSize], 1), [], [], 'field CSw');
sim.addElement(NormalNoise('noise CSv', [fieldSize, fieldSize], 1), [], [], 'field CSv');

sim.addElement(NormalNoise('noise SSw', [fieldSize, fieldSize], 1), [], [], 'field SSw');
sim.addElement(NormalNoise('noise SSv', [fieldSize, fieldSize], 1), [], [], 'field SSv');

sim.addElement(NormalNoise('noise SPw', [1, fieldSize], 1), [], [], 'field SPw');




%% setting up the GUI

gui = StandardGUI(sim, [100, 50, 1000, 720], 0.01, [0, 0, 0.5, 1.0], [5, 3], [0.06, 0.05], [0.5, 0, 0.5, 1], [25, 2]);

%visualizations
gui.addVisualization(MultiPlot('field SPw', 'activation', 1, 'horizontal', {'Ylim',[-10 10],'Xlim',[1 fieldSize]}, ... 
  {}, 'spatial field (SPw)', 'space', 'activation'), [1, 1], [1, 2]);
gui.addVisualization(ScaledImage('field CSw', 'activation', [-10, 10], {'YDir', 'normal', 'YAxisLocation', 'right'}, ...
  {}, 'color-space field (CSw)', [], 'feature value color'), ...
  [2, 1], [2, 2]);
gui.addVisualization(ScaledImage('field SSw', 'activation', [-10, 10], {'YDir', 'normal', 'YAxisLocation', 'right'}, ...
  {}, 'shape-space field (SSw)', [], 'feature value shape'), ...
  [4, 1], [2, 2]);

gui.addVisualization(MultiPlot('node Color', 'activation', 1, 'horizontal', ...
  {'Ylim', [-50 50], 'Xlim', [0 2], 'XTickLabel', {}, 'Box', 'on', 'YTick', [-50, 0, 50], 'YGrid', 'on'}, ... 
  { {'bo', 'MarkerSize', 4, 'MarkerFaceColor', 'b'} }, 'color node', '', 'activation'), [2, 3], [2, 1]);
gui.addVisualization(MultiPlot('node Shape', 'activation', 1, 'horizontal',  ...
  {'Ylim', [-50 50], 'Xlim', [0 2], 'XTickLabel', {}, 'Box', 'on', 'YTick', [-50, 0, 50], 'YGrid', 'on'}, ... 
  { {'bo', 'MarkerSize', 4, 'MarkerFaceColor', 'b'} }, 'shape node', '', 'activation'), [4, 3], [2, 1]);

gui.addControl(ParameterSlider('c_ww(2D)', {'CSw -> CSw (exc)' 'SSw -> SSw (exc)'}, {'amplitude' 'amplitude'}, [0, 10], '%0.1f', 1, ...
  'strength of lateral excitation in fields CS and SS'), [1, 1]);
gui.addControl(ParameterSlider('c_vw(2D)', {'CSw -> CSv' 'SSw -> SSv'}, {'amplitude' 'amplitude'}, [0, 50], '%0.1f', 1, ...
  'strength of projection to inhibitory layer in fields CS and SS'), [2, 1]);
gui.addControl(ParameterSlider('c_wv(2D)', {'CSv -> CSw' 'SSv -> SSw'}, {'amplitude' 'amplitude'}, [0, 10], '%0.1f', -1, ...
  'strength of local inhibition in fields CS and SS'), [3, 1]);
gui.addControl(ParameterSlider('c_glob(2D)', {'CSv -> CSw (global)' 'SSv -> SSw (global)'}, {'amplitude' 'amplitude'}, [0 .5], '%0.2f', -1, ...
  'strength of global inhibition in fields CS and SS'), [4, 1]);

gui.addControl(ParameterSlider('c_ww(1D)', {'SPw -> SPw'}, {'amplitudeExc'}, [0, 15], '%0.1f', 1, ...
  'strength of local excitation in 1D spatial field'), [6, 1]);
gui.addControl(ParameterSlider('c_wv(1D)', {'SPw -> SPw'}, {'amplitudeInh'}, [0, 25], '%0.1f', 1, ...
  'strength of lateral inhibition in 1D spatial'), [7, 1]);
gui.addControl(ParameterSlider('c_glob(1D)', {'SPwv (global)'}, {'amplitude'}, [0, 2], '%0.1f', -1, ...
  'strength of global inhibition in 1D spatial field'), [8, 1]);

gui.addControl(ParameterSlider('q', {'noise SPw' 'noise CSw' 'noise CSv' 'noise SSw' 'noise SSv' 'noise CSv'}, ...
  {'amplitude' 'amplitude' 'amplitude' 'amplitude' 'amplitude' 'amplitude'}, ...
  [0, 10], '%0.1f', 1, 'noise level in all fields'), [10, 1]);

gui.addControl(ParameterSlider('CS/SS->SP', {'CSw -> SPw (1d)' 'SSw -> SPw (1d)'}, {'amplitude' 'amplitude'}, [0, 3], '%0.1f', 1, ...
  'strength of projection from 2D fields to 1D spatial field'), [12, 1]);
gui.addControl(ParameterSlider('SP->CS/SS', 'SPw -> fSw (1d)', 'amplitude', [0, 5], '%0.1f', 1, ...
  'strength of projection from 1D spatial field to 2D fields'), [13, 1]);
gui.addControl(ParameterSlider('CS<->SS', {'CSw -> SSw (1d)' 'SSw -> CSw (1d)'}, {'amplitude' 'amplitude'}, [0, 1], '%0.1f', 1, ...
  'strength of projection between 2D fields (along spatial dimension)'), [14, 1]);

gui.addControl(ParameterSlider('Node->Field', {'CNode -> CSw' 'SNode -> SSw'}, {'amplitude' 'amplitude'}, [0, 4], '%0.1f', 1, ...
  'strength of projection from nodes to fields'), [16, 1]);
gui.addControl(ParameterSlider('Field->Node', {'CSw -> CNode' 'SSw -> SNode'}, {'amplitude' 'amplitude'}, [0, 1], '%0.1f', 1, ...
  'strength of projection from fields to nodes'), [17, 1]);
gui.addControl(ParameterSlider('c_exc(Node)', {'CNode -> CNode' 'SNode -> SNode'}, {'amplitude' 'amplitude'}, [0, 10], '%0.1f', 1, ...
  'strength of node self excitation'), [18, 1]);
gui.addControl(ParameterSlider('c_inh(Node)', {'CNode -> SNode' 'SNode -> CNode'}, {'amplitude' 'amplitude'}, [-50, 0], '%0.1f', 1, ...
  'strength of inhibition between nodes'), [19, 1]);

gui.addControl(ParameterSwitchButton('Card1', {'stimulus1 CS (1d)', 'stimulus2 SS (1d)'}, {'amplitude', 'amplitude'}, ...
  [0, 0], [5, 5], 'activate inputs CS1 and SS2', false), [1, 2]);
gui.addControl(ParameterSwitchButton('Card2', {'stimulus2 CS (1d)', 'stimulus1 SS (1d)'}, {'amplitude', 'amplitude'}, ...
  [0, 0], [5, 5], 'activate inputs CS2 and SS1', false), [2, 2]);

gui.addControl(ParameterSwitchButton('Color Coop', {'stimulus CS1', 'stimulus CS2'}, {'amplitude', 'amplitude'}, ...
  [.5, .5], [.504, .504], 'activate memory inputs CS1 and CS2', false), [4, 2]);
gui.addControl(ParameterSwitchButton('Shape Coop', {'stimulus SS1', 'stimulus SS2'}, {'amplitude', 'amplitude'}, ...
  [.5, .5], [.504, .504], 'activate memory inputs SS1 and SS2', false), [5, 2]);
gui.addControl(ParameterSwitchButton('Color Comp', {'stimulus CS3', 'stimulus CS4'}, {'amplitude', 'amplitude'}, ...
  [0, 0], [.04, .04], 'activate memory inputs CS3 and CS4', false), [6, 2]);
gui.addControl(ParameterSwitchButton('Shape Comp', {'stimulus SS3', 'stimulus SS4'}, {'amplitude', 'amplitude'}, ...
  [0, 0], [.04, .04], 'activate memory inputs SS3 and SS4', false), [7, 2]);

gui.addControl(ParameterSwitchButton('Color Game', 'node Color', 'h', ...
  -5, -3.5, 'boost color node', false), [9, 2]);
gui.addControl(ParameterSwitchButton('Shape Game', 'node Shape', 'h', ...
  -5, -3.5, 'boost shape node', false), [10, 2]);


k = 20;

% global control buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [k, 2]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [k+1, 2]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [k+2, 2]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [k+3, 2]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [k+4, 2]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [k+5, 2]);


%% run the simulation

gui.run();


