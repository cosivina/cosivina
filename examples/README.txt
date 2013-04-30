INTRODUCTION

This folder contains examples of dynamic neural field simulators that illustrate the functions and capabilities of the COSIVINA toolbox and provide a tool to learn about dynamic field theory. The files exampleA, exampleB, and exampleC accompany the corresponding sections in the documentation. The launcher files each create a basic neural field architecture as well as a matching GUI and run this GUI.

To run the examples, call the setpath function in the COSIVINA folder (or manually add the folder and its subfolders to the Matlab path) and then call one of the launcher files from the Matlab command window. The simulation starts immediately and runs continuously until you quit the GUI. Plots display the current activation states of the dynamic fields in each architecture. Sliders and controls allow you to set inputs or change connection strengths and other parameters of the architecture. The parameter button will open a new window that allows you to access all parameters of the architecture. Hover with the mouse over control elements to see a description of the control.

The one-dimensional plots of dynamic neural fields typically show the following components: The field activation (blue), the field output (red), and external inputs to the field (green). Image plots show field activation or field output as color code, with dark blue corresponding to lowest, dark red to highest activation.


OVERVIEW OVER PROVIDED DNF ARCHITECTURES

launcherTwoNeuronSimulator: Simulates two discrete dynamic nodes (or neurons) that can receive inputs and be coupled to each other in an excitatory or inhibitory fashion. Shows the attractor and repellor states for each individual neuron and the rates of change for all possible activation states. Can be used to illustrate detection, selection, or working memory in a discrete system (without a continuous feature space), or to model a neural oscillator.

launcherOneLayerField and launcherOneLayerField_preset: These create the most basic DNF architecture, a single one-dimensional field that receives external inputs and shows lateral interactions. The GUI shows the neural field in the top plot, the interaction kernel in the bottom plot. Set inputs with the sliders to the bottom right, and change interactions patterns with sliders or by selecting a predefined pattern in the dropdown box (launcherOneLayerField_preset only; click Select to activate the chosen pattern). You can observe detection instability, selection between inputs, and self-sustained peaks in this model.

launcherOneLayerField_runningHistory: The same architecture as above, but shows a running history of field activations in the bottom plot.

launcherTwoLayerField: Model with separate excitatory (field u, top) and inhibitory layer (field v, bottom). The excitatory layer receives external inputs and can excite itself and the inhibitory layer. The inhibitory layer projects inhibition back to the excitatory layer.

launcherThreeLayerField: Model with two excitatory layers (field u and field w) and a shared inhibitory layer (field v). Can be used to implement a change detection model, in which field w serves as working memory and field and field u as contrast field, that forms peaks only when a novel stimulus is presented.

launcherOneLayerField2D and launcherOneLayerField2D_surfacePlot: Creates a two-dimensional neural field with lateral interaction that can receive localized or ridge inputs. Can be used to illustrate stabilized detection, selection and sustained peaks in two-dimensions, and to show selection through ridge inputs or peak formation from intersections of ridges.

launcherCoupling: Creates an architecture of two one-dimensional fields, coupled to the different dimensions of a single two-dimensional field. Can be used to illustrate extraction of lower-dimensional information from a higher-dimensional representation, selection by ridge inputs (e.g. for visual search), and the binding problem.

launcherTransformation: Creates a model that implements a variable shift of a field, e.g. for reference frame transformations. Can be used for forward transformation, backward transformation, or pattern match. Sliders only control inputs to the model, connection strengths have to be set via parameter panel.

launcherImageGrabber: Demonstrates generation of field input from actual image data. Loads image from file, performs a color extraction/classification and summation over the vertical dimension, and feeds the result as input into a stack of three one-dimensional fields, one for each extracted color channel.

launcherRobotAttractorDynamics: Demonstrates the attractor dynamics approach for controlling the orientation of a mobile robot for target acquisition. A neural field is coupled to a uniquely instantiated dynamic variable, reflecting robot heading direction. Peaks in the field set attractors for the dynamic variable.


