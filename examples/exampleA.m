% Example A: Building and Running a Simple DNF Architecture
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


% try initialization and step to see if the architecture runs
% (this procedure is not necessary, but helpful for debugging)
sim.tryInit();
sim.tryStep();


% initialize the simulator
sim.init();


% show initial activation of neural field
figure;
plot(sim.getComponent('field u', 'activation'), 'b');
xlabel('field position'); ylabel('activation');
hold on;


% run the simulation for 10 steps
for i = 1 : 10
  sim.step();
end


% plot field activation again
plot(sim.getComponent('field u', 'activation'), 'g');


% change strength of stimulus B and re-initialize the element
hStimB = sim.getElement('stim B'); % get element handle
hStimB.amplitude = 0; % change element parameter
hStimB.init();


% run the simulation for another 10 steps
for i = 1 : 10
  sim.step();
end


% plot field activation again
plot(sim.getComponent('field u', 'activation'), 'r');


% add legend to the figure
legend('intial state of the field', 'after 10 steps', 'after 20 steps (stim B off)');


% alternative to the above: use the run method
sim.run(10, true); % initialize and run until t = 10

hStimB = sim.getElement('stim B'); % get element handle
hStimB.amplitude = 0; % change element parameter
hStimB.init();

sim.run(20); % run until t = 20;




