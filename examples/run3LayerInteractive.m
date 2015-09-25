% Launcher for a three-layer neural field simulator.
% The scripts sets up an architecture with three one-dimensional neural
% fields: two excitatory fields, u and w, and a shared inhibitory field, v.
% Fields u and w feature local self-excitation and project to each other
% and to field v in a local excitatory fashion. Field v inhibits both
% excitatory fields, either locally or globally. 
% The script then creates a GUI for this architecture and
% runs that GUI. Hover over sliders and buttons to see a descrition of
% their function.


%% setting up the simulator
create3LayerSim;

%% setting up the GUI and controls
create3LayerGUI;

%% run the simulator in the GUI
gui.run(inf);