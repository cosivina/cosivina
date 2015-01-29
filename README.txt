--------------------------------------------------------------------------------
COSIVINA - Compose, Simulate, and Visualize Neurodynamic Architectures
An open source toolbox for MATLAB
--------------------------------------------------------------------------------

Version 1.3
Written by Sebastian Schneegans at the Institut für Neuroinformatik,
Ruhr-Universität Bochum, Germany. Last updated 2015-01-29.

Copyright (c) 2012-2015 Sebastian Schneegans <Sebastian@Schneegans.de>
Published under the Simplified BSD License (see LICENSE_BSD.txt)


OVERVIEW

COSIVINA is an object-oriented framework to construct Dynamic Neural Field 
architectures in Matlab, simulate the evolution of activation in these
architectures (using the Euler method), and create GUIs to view the activation
and adjust model parameters online.
See the documentation for a detailed description of the framework, a class
reference and examples on creating architectures and GUIs.


INSTALLATION

Unpack the zip file in a folder of your choice. Then add all subfolders to the 
MATLAB path. You can do this by calling the script setpath.m in the COSIVINA
folder or manually via the MATLAB menu ("File" -> "Set Path...", then choose
"Add with Subfolders" and select the COSIVINA folder). You can then run one of 
the scripts from the subfolder "examples" to test the framework, e.g.
"launcherOneLayerField.m".
To save and load parameter files, the framework relies on the open-source 
toolbox JSONlab (you can use all other functionality of COSIVINA without 
JSONlab, but will only receive a warning message when trying to save or load a 
parameter file). You can download JSONlab for free e.g. from here:
http://sourceforge.net/projects/iso2mesh/files/jsonlab/
COSIVINA has been tested with JSONlab versions 0.9.1 to 1.0. (Note: Using 
version 0.9.0 or earlier can cause errors when loading parameters for certain
architecture elements.)


COMPATIBILITY WITH EARLIER VERSIONS OF MATLAB

The full functionality of the framework is supported by Matlab Release 2011a and
later. Compatibility with Matlab Release 2009a and later can be achieved through
a small modification: In the file base/Element.m, replace the first line
classdef Element < matlab.mixin.Copyable
by
classdef Element < handle
With this modification, there is no longer a straightforward way to create a
copy of an element (rather than the element handle). This functionality is not
required for basic use of the framework, including creation and use of GUIs 
(see documentation for further information).


