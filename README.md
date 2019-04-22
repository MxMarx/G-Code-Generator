
   _____         _____          _            _____                           _
  / ____|       / ____|        | |          / ____|                         | |
 | |  __ ______| |     ___   __| | ___     | |  __  ___ _ __   ___ _ __ __ _| |_ ___  _ __
 | | |_ |______| |    / _ \ / _` |/ _ \    | | |_ |/ _ \ '_ \ / _ \ '__/ _` | __/ _ \| '__|
 | |__| |      | |___| (_) | (_| |  __/    | |__| |  __/ | | |  __/ | | (_| | || (_) | |
  \_____|       \_____\___/ \__,_|\___|     \_____|\___|_| |_|\___|_|  \__,_|\__\___/|_|

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Created by Russell Marx, 2019 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

This MATLAB class generates g-code files for injections and cannula insertion.

First, add "gCode.m" to the MATLAB path, or change your MATLAB folder to the file's location.

The 'injection' function inserts a needle at the given coordinates, go slightly past the coordinates, and return.
The 'cannula' function inserts a cannula so that a needle that slightly overshoots the tip of the cannula hit the coordinates.
The 'drill' function generates g-code for all previously created injections and cannulas.
The 'brainAtlas' function displays the injections and cannulas overlaid on a Paxinos & Watson mouse or rat brain atlas. The needles are indicated in red, and overshoot in blue.

See below for a full description of the name-pair arguments of each function.

# EXAMPLE 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
g = gCode;
g.injection('AP', 1.7, 'ML', +1, 'DV', 7.3, 'name', 'NAc');
g.injection('AP', 1.7, 'ML', -1, 'DV', 7.3, 'name', 'NAc');
g.injection('AP', 0, 'ML', -2, 'DV', 8.1, 'name', 'VP');
g.injection('AP', 0, 'ML', +2, 'DV', 8.1, 'name', 'VP');
g.drill('skullThickness', 1.8);
g.brainAtlas('rat')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This script generates four files for injections, one file for drilling, and displays the needles in a rat brain atlas.




# EXAMPLE 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
g = gCode;
g.injection('AP', -4.5, 'ML', 0,'DV', 3.25, 'angle', +15, 'name', 'DRN');
g.injection('AP', -4.5, 'ML', 0,'DV', 3.25, 'angle', -15, 'name', 'DRN');
g.injection('AP', -1.85, 'ML', +0.42, 'DV', 2.6, 'angle', 10, 'name', 'LHb');
g.injection('AP', -1.85, 'ML', -0.42, 'DV', 2.6, 'angle', 10, 'name', 'LHb');
g.drill('skullThickness', 0.8);
g.brainAtlas('mouse')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This script generates four files for injections, one file for drilling, and displays the needles in a mouse brain atlas.
Notice that the 'angle' parameter is positive for the LHb injections, but not DRN.
This is because the sign of the angle only effects injections where ML is zero.




# EXAMPLE 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
g = gCode;
g.cannula('AP', -4.5, 'ML', 0, 'DV', 3.25, 'angle', 15, 'name', 'DRN', 'speed', 10, 'overshoot', 0.3);
g.injection('AP', -1.85, 'ML', +0.42, 'DV', 2.6, 'angle', 10, 'name', 'LHb', 'speed', 50, 'overshoot', 0);
g.injection('AP', -1.85, 'ML', -0.42, 'DV', 2.6, 'angle', 10, 'name', 'LHb', 'speed', 50, 'overshoot', 0);
g.drill('skullThickness', 0.8, 'depthPerCycle', 0.4, 'dwellAfterCycle', 1, 'speed', 10);
g.brainAtlas('mouse')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This script inserts a single cannula into the DRN, and injects bilaterally into the LHb.
The cannula is positioned so that a needle that extends 0.3 mm past the tip will reach the coordinates.
The injections have no overshoot.
The injections move at 50% speed, the cannula moves at 10% speed.
0.8 mm holes are drilled with the drill slowly moving down 0.4 mm per cycles, and pausing for 1 second at the bottom.



# NAME-VALUE PARAMTERS
+-------------------------------------------------------------------------------------------------+
|                                       injection / cannula                                       |
+-------------------------------------------------------------------------------------------------+
| Parameter Name      | Description                                                     | Default |
+---------------------+-----------------------------------------------------------------+---------+
| AP                  | Anterior-Posterior coordinates.                                 | -       |
+---------------------+-----------------------------------------------------------------+---------+
| ML                  | Medial-Lateral coordinates. Positive is to the right            | -       |
+---------------------+-----------------------------------------------------------------+---------+
| DV                  | Dorsal-Ventral coordinates. Sign does not matter.               | -       |
+---------------------+-----------------------------------------------------------------+---------+
| angle               | Injection angle. Sign is automatically changed towards medial.  | 0       |
|                     | If ML is zero, positive angles inject from the right.           |         |
+---------------------+-----------------------------------------------------------------+---------+
| name                | Name of the output file.                                        | -       |
|                     | Left or Right is automatically appended.                        |         |
+---------------------+-----------------------------------------------------------------+---------+
| speed               | Speed to insert the needle/cannula.                             | 25      |
+---------------------+-----------------------------------------------------------------+---------+
| overshoot           | For injections: Distance to move the needle past the injection. | 0.25    |
|                     | For cannulas: Length of the needle past the cannula tip.        |         |
+---------------------+-----------------------------------------------------------------+---------+
| dwellBeforeStart    | Duration to pause over the hole before inserting the needle.    | 6.0 s   |
+---------------------+-----------------------------------------------------------------+---------+
| dwellAfterOvershoot | Duration to pause after overshooting the injection site before  | 6.0 s   |
|                     | returning. Does not apply to cannulas.                          |         |
+---------------------+-----------------------------------------------------------------+---------+



+-----------------------------------------------------------------------------+---------+
|                                    drill                                    |         |
+-----------------------------------------------------------------------------+---------+
| Parameter Name   | Description                                              | Default |
+------------------+----------------------------------------------------------+---------+
| skullThickness   | Depth to drill in mm.                                    | 1.0 mm  |
+------------------+----------------------------------------------------------+---------+
| depthPerCycle    | Depth increment per drilling cycle.                      | 0.2 mm  |
+------------------+----------------------------------------------------------+---------+
| speed            | Speed to move while drilling.                            | 50      |
+------------------+----------------------------------------------------------+---------+
| dwellBeforeStart | Duration to pause above the hole before drilling begins. | 4.0 s   |
+------------------+----------------------------------------------------------+---------+
| dwellBeforeCycle | Duration to pause at top of each cycle.                  | 1.0 s   |
+------------------+----------------------------------------------------------+---------+
| dwellAfterCycle  | Duration to pause at bottom of each cycle.               | 0.5 s   |
+------------------+----------------------------------------------------------+---------+



+------------+
| brainAtlas |
+------------+
| 'mouse'    |
+------------+
| 'rat'      |
+------------+
