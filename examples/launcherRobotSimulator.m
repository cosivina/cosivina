% Demonstration of attractor dynamics for generating taxis or avoidance
% behavior on a simulated mobile robot. The robot has a set of sensors that
% can detect targets in a simulated arena (shown in a top-down view in a
% separate window). The noisy sensor response is projected as input to a
% field, and the field output drives an attractor dynamics that controls
% the robot's heading direction. The forward speed of the robot can be
% controlled by a parameter slider. The robot will stop upon collision with
% a target or the boundaries of the arena.
% 
% NOTE: The x-axes of the field plot and dynamics plots can be flipped 
% (going from negative to positive) to make the mapping from the robot view
% to the dynamics more intuitive. Set the reverseAxes parameter below 
% to true to do this.

%% reverse x-axis for plot? 
reverseAxes = false;

%% setting up the simulator
fieldSize = 180;

sim = Simulator;
sim.addElement(NeuralField('field u', fieldSize, 5, -4, 4));
sim.addElement(LateralInteractions1D('u -> u', fieldSize, 5, 8, 12.5, 0, -0.2, true), ...
  'field u', 'output', 'field u');
sim.addElement(MobileRobotArena('robot', fieldSize, fieldSize/2, false));
sim.addElement(AttractorDynamics('attractor dynamics', fieldSize, 0.01, fieldSize/2), ...
  {'field u', 'robot'}, {'output', 'robotPhi'}, 'robot', 'phiDot');

sim.addElement(ScaleInput('input u', fieldSize, 25), 'robot', 'sensorOutput', 'field u');
h = sim.getElement('robot');
h.addTarget([75, 150]);
% h.addTarget([125, 150]);

%% setting up the GUI
gui = StandardGUI(sim, [50, 50, 900, 700], 0.01, [0.0, 1/4, 1.0, 3/4], [2, 1], 0.06, [0.0, 0.0, 1.0, 1/4], [6, 4]);

% add the robot arena control panel (is displayed as a separate window)
gui.addControl(RobotArenaControlPanel('robot', [970, 50, 600, 720]));

% plotting the field and the attractor dynamics over the same angular space
% (need to map the units of the field onto the range [-pi, pi])
vDir = ((1:fieldSize) - fieldSize/2) * 2*pi / fieldSize;
if reverseAxes
    gui.addVisualization(MultiPlot({'field u', 'field u', 'input u'}, {'activation', 'output', 'output'}, ...
        [1, 10, 1], 'horizontal', {'XLim', [-pi, pi], 'YLim', [-15, 15], 'XGrid', 'on', 'YGrid', 'on', 'XDir', 'reverse'}, ...
        {{'b', 'LineWidth', 3, 'XData', vDir}, {'r', 'LineWidth', 2, 'XData', vDir}, ...
        {'Color', [0, 0.75, 0], 'LineWidth', 2, 'XData', vDir}}, ...
        'sensory field', 'direction [rad] (reversed)', 'activation'), [1, 1]);
    gui.addVisualization(XYPlot({[], 'robot'}, {vDir, 'robotPhi'}, ...
        {'attractor dynamics', 'attractor dynamics'}, {'phiDotAll', 'phiDot'}, ...
        {'XLim', [-pi, pi], 'YLim', [-0.5, 0.5], 'XGrid', 'on', 'YGrid', 'on', 'XDir', 'reverse'}, ...
        { {'LineWidth', 2, 'Color', [0.5, 0, 0]}, {'o', 'Color', [0.5, 0, 0], 'LineWidth', 2, 'MarkerSize', 7} }, ...
        'attractor dynamics for robot orientation', 'direction [rad] (reversed)', 'rate of change'), [2, 1]);
else
    gui.addVisualization(MultiPlot({'field u', 'field u', 'input u'}, {'activation', 'output', 'output'}, ...
        [1, 10, 1], 'horizontal', {'XLim', [-pi, pi], 'YLim', [-15, 15], 'XGrid', 'on', 'YGrid', 'on'}, ...
        {{'b', 'LineWidth', 3, 'XData', vDir}, {'r', 'LineWidth', 2, 'XData', vDir}, ...
        {'Color', [0, 0.75, 0], 'LineWidth', 2, 'XData', vDir}}, ...
        'sensory field', 'direction [rad]', 'activation'), [1, 1]);
    gui.addVisualization(XYPlot({[], 'robot'}, {vDir, 'robotPhi'}, ...
        {'attractor dynamics', 'attractor dynamics'}, {'phiDotAll', 'phiDot'}, ...
        {'XLim', [-pi, pi], 'YLim', [-0.5, 0.5], 'XGrid', 'on', 'YGrid', 'on'}, ...
        { {'LineWidth', 2, 'Color', [0.5, 0, 0]}, {'o', 'Color', [0.5, 0, 0], 'LineWidth', 2, 'MarkerSize', 7} }, ...
        'attractor dynamics for robot orientation', 'direction [rad]', 'rate of change'), [2, 1]);
end

% add controls
gui.addControl(ParameterSlider('h', 'field u', 'h', [-10, 0], '%0.1f', 1, 'resting level of field u'), [1, 1]);
gui.addControl(ParameterSlider('c_exc', 'u -> u', 'amplitudeExc', [0, 50], '%0.1f', 1, ...
  'strength of lateral excitation'), [2, 1]);
gui.addControl(ParameterSlider('c_inh', 'u -> u', 'amplitudeInh', [0, 50], '%0.1f', 1, ...
  'strength of lateral inhibition'), [2, 2]);
gui.addControl(ParameterSlider('c_gi', 'u -> u', 'amplitudeGlobal', [0, 2], '%0.2f', -1, ...
  'strength of global inhibition'), [2, 3]);

gui.addControl(ParameterSlider('a_s', 'input u', 'amplitude', [0, 50], '%0.1f', 1, ...
  'amplitude of sensor input to field'), [4, 1]);
gui.addControl(ParameterSlider('a_rot', 'attractor dynamics', 'amplitude', [-0.05, 0.05], '%0.3f', 1, ...
  'amplitude of attractor dynamics for robot rotation'), [4, 2]);
gui.addControl(ParameterSlider('v_r', 'robot', 'forwardSpeed', [0, 1.0], '%0.2f', 1, ...
  'forward speed of simulated robot'), [4, 3]);

% add buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [1, 4]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [2, 4]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [3, 4]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [4, 4]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [5, 4]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [6, 4]);

%% run the simulator in the GUI
gui.run();

