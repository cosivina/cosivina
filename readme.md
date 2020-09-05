# Cosivina - Compose, Simulate, and Visualize Neurodynamic Architectures
## An open source toolbox for Matlab

Version 1.3
Written by Sebastian Schneegans at the Institut für Neuroinformatik,  
Ruhr-Universität Bochum, Germany.

Copyright (c) 2012-2020 Sebastian Schneegans <Sebastian@Schneegans.de>  
Published under the Simplified BSD License (see LICENSE_BSD.txt)


## Overview

Cosivina is a free object-oriented framework to construct dynamic field architectures in Matlab, simulate the evolution of activation in these architectures, and create graphical user interfaces to view the activation time course and adjust model parameters online.

It includes a number of example architectures that are also available in compiled form for those who do not have Matlab available. These examples form the basis for most exercises in the book "Dynamic Thinking - A Primer on Dynamic Field Theory". For more information on the book and Dynamic Field Theory in general, please visit [www.dynamicfieldtheory.org](http://www.dynamicfieldtheory.org).

The cosivina framework is hosted as git repository on github and bitbucket:  
https://github.com/sschneegans/cosivina  
https://bitbucket.org/sschneegans/cosivina  
You can clone the repository and keep it updated from there, or download the latest version as zip file. A full documentation for cosivina is available in pdf format. You can also view the documentation online as a wiki.


## Quick installation for Matlab

- Clone the repository or download the code as zipfile. [Clone](https://github.com/fangq/jsonlab) or [download](http://iso2mesh.sourceforge.net/cgi-bin/index.cgi?jsonlab/Download) JSONlab, an additional toolbox used to save and load parameter files. Cosivina has been tested with JSONlab version 0.9.1 to 1.1. If you dowloaded zip archives, unpack them in a folder of your choice (you can rename the folders, e.g. remove automatically generated version numbers and tags).
- Open Matlab, navigate to the cosivina folder (using the 'cd' command or the directory navigation bar), and run the function 'setpath' to add the cosivina and jsonlab folders to the matlab path.
- To test cosivina, run one of the example scripts, such as 'launcherOneLayerField.m'. This should open a GUI window with plots and control buttons.

For later use: The cosivina subfolders and the jsonlab folder have to be included in the Matlab search path in order to use them. You can either run the function 'setpath'  every time you restart Matlab (and want to use cosivina), run the function as 'setpath(true)' once to save the augmented path, or, if you prefer, add the required folders manually to your Matlab search path (be sure to include all subfolders of cosivina).


## Gettting started with cosivina

To get started, run the simulator 'launcherOneLayerField', either by calling the simulator name in the Matlab command window or by selecting it in the dropdown menu in the compiled version. This should open a graphical user interface (GUI) with plots and buttons. If the GUI does not open, see the readme files and the cosivina documentation for help.

The top plot in the GUI shows the field activation in blue, the field output in red, and input to the field in green. The simulation is running as soon as the simulator is starting. This means that the activation distribution is continuously updated according to a differential equation, depending on external inputs and the current activation state of the field.

Initially, the field activation will be near the resting level of -5 everywhere, with some slight fluctuations due random noise that is added to the activation in every simulation step. The blue activation plot will also be partly occluded by the green input plot. The output will be very close to zero for the whole field.

You can now create a localized input to the field. Find the slider for the parameter a_s1 in the lower part of the GUI. When you hover your mouse over this slider, a tooltip will appear informing you that it controls the amplitude of stimulus 1. Increase the value of this parameter. You can either click on the arrow at the right of the slider to increase it in small steps, click on the slider bar for larger steps, or directly move the slider for continuous changes.

The changing input is immediately reflected in the green plot. The field activation will follow the input, but not instanteously. When you increase the input so far that the activation approaches the output threshold at zero, you will see in the red plot that an output signal is created. The output is a sigmoid function of the field activation. It is close to zero for activation levels far below zero, then rises around zero and saturates at a value of one for higher activation values. Note that the red plot shows the output scaled with a factor of 10 for better visibility.

Set the stimulus amplitude to a value of about 6. Now add some lateral interactions to the field. Set both the parameter values 'c_exc' and  'c_inh' to 15. This creates local self-excitation (active regions activates their near surroundings even further) and surround inhibition (active regions suppress their more distant neightboorhand). The bottom plot shows the pattern of these lateral interactions. Note that the interactions are plotted over distance in the field, with zero in the center.

You should now see that the field activation (blue) deviates from the input pattern (green) around the region where an output signal is created. It is higher than the input in the most activated region, but suppressed below the resting level in the surroundings. This activation pattern is a self-stabilized activation peak, a central unit of representation in Dynamic Field Theory.

The activation peak is an attractor state in the dynamics of the field activation that is qualitatively different from the inactive state (where activation is below the output threshold). This can be shown when both attractor states are instantiated simultaneously in different regions of the field. First, slowly decrease the amplitude of stimulus 1 to a value of 3. The activation peak (with non-zero output signal) should remain even though the input signal is now below the output threshold. Now create a second input by increasing the amplitude of stimulus 3 (parameter slider 'a_s3') from 0 to 3.

You now have two different inputs of the same strength. One of them (stimulus 1) should still sustain an activation peak. The activation at the other one (stimulus 3) should simply mirror the input signal, without creating any output. This shows that the system is bistable: For a certain range of input amplitudes, two different stable activation states are possible. The history of activation determines which activation state is actually realized in each part of the field.

You can now continue to explore dynamic field models with this and other simulators. In the present simulator, you can use the sliders to change the field's resting level, noise level, interaction pattern, and stimulus characteristics. You can use the buttons to pause the simulation at any time (e.g. to change parameters simultaneously with respect to simulation time), reset the simulation (returns all field activations to their resting level, but does not change parameters), access more detailed parameters of all elements of the simulation, and save your parameter settings to a file and load them again. Click 'Quit' when you're done.

Other simulators implement more complex architectures, typically with multiple interconnected dynamic fields. See the file 'descriptions.txt' in the examples folder to learn more about the available simulators. Simulators with the term 'preset' in their name provide different pre-specified parameter settings to obtain certain model behaviors without requiring manual tuning of the model. You can access these presets by selecting an entry from dropdown menu (typically at the bottom right of the GUI) and then clicking 'Select'.

See the documentation for further information on how the cosivina can be used to explore existing architecture in different modes of operations, build new architectures, and expand the framework for your specific needs. Visit the [dynamic field theory website](http://www.dynamicfieldtheory.org) for introductory material on dynamic field theory.


## Further resources

### Mailing list

You can subscribe to the cosivina mailing list at  
https://mailman.ini/ruhr-uni-bochum.de/listinfor/ini_cosivina  
to keep you updated on this framework.

### JSONlab

JSONlab is a separate toolbox to encode and decode files in JSON format under Matlab. It is used in cosivina to store parameter files in a format that is capable of representing complex parameter structures, but still easily readable for humans. You can use all other functionality of cosivina without JSONlab, but will only receive a warning message when trying to save or load a parameter file. JSONlab was developed by Qianqian Fang and is published under the BSD license or GPLv3 license (see license files for details). JSONlab is hosted on sourceforge and github, you can find all versions and a documentation here:  
http://iso2mesh.sourceforge.net/jsonlab  
Cosivina has been tested with JSONlab versions 0.9.1 to 1.1. (Note: Using version 0.9.0 or earlier can cause errors when loading parameters for certain architecture elements.)

### Compatibility with earlier version of Matlab

The full functionality of the framework is supported by Matlab R2011a and later. Compatibility with Matlab R2009a and later can be achieved through a small modification: In the file base/Element.m, replace the first line

    classdef Element < matlab.mixin.Copyable

by

    classdef Element < handle

With this modification, there is no longer a straightforward way to create a copy of an element (rather than the element handle). This functionality is not required for basic use of the framework, including creation and use of GUIs (see documentation for further information).


