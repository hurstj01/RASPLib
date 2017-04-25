Graphical installation instructions are given in the included PDF.

Rensselaer Arduino Support Package - RASPlib installation Instructions V1.02032016.2015a:
Prerequisite: Arduino Support package for Simulink has been installed, Matlab 2015a or later. 

1.	Unzip the contents and copy the “RASPlib” folder and ‘startup.m’ file to your home Matlab directory:
2.	Open Matlab, open the Simulink Library, then Right-Click “Rensselaer Arduino Support Package” and select “Open Rensselaer Arduino Support Package”.  
3.	Open the demo file for your particular hardware (if you have a generic hardware setup you can create a Simulink example using the one of the available blocks in the main library or adopt any of the provided device specific libraries blocks using the indicated pins).  The Mechatronics board is version M1V4.
 
- After opening the Demo save it to your home directory with “save-as”.  From now on you can create Simulink diagrams in any location and just drag the blocks from the library since Matlab knows where all the necessary library files are.

- Run the demo on the hardware by clicking the large 'play' icon

Please read: CHANGE_LOG.txt for some important notices since the last version.

Please contact joshua.hurst.rpi@gmail.com for any issues or suggestions



RASPlib todo:
PWM44,45 etc with standard simulink blocks - elimiate those s-function files as well
transition to system object implementation

