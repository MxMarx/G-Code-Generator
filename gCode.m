classdef gCode < handle
    % GCODE generates g-code for a stereotaxic surgery robot.
    %{
    
       _____         _____          _            _____                           _
      / ____|       / ____|        | |          / ____|                         | |
     | |  __ ______| |     ___   __| | ___     | |  __  ___ _ __   ___ _ __ __ _| |_ ___  _ __
     | | |_ |______| |    / _ \ / _` |/ _ \    | | |_ |/ _ \ '_ \ / _ \ '__/ _` | __/ _ \| '__|
     | |__| |      | |___| (_) | (_| |  __/    | |__| |  __/ | | |  __/ | | (_| | || (_) | |
      \_____|       \_____\___/ \__,_|\___|     \_____|\___|_| |_|\___|_|  \__,_|\__\___/|_|

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    || Created by Russell Marx, 2019 ||
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  This MATLAB class generates g-code files for injections and cannula insertion with a stereotaxic surgery robot.
  To build the robot, see https://github.com/MxMarx/Stereotaxic-Surgery-Robot
    
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
    %}
    
    
    properties
        moveSpeed = 100 % Movement speed in mm/minute
        moveHeight = 3 % Height above to skull for moving the drill/needle
        folder = fullfile(fileparts(mfilename('fullpath')), 'Output') % Output folder
    end
    properties (Access=private)
        injections = [] % table containing the injection coordinates
        file_id = 1 % file ID
    end
    
    methods (Access=public)
        function obj = gCode(obj)
            % Make the output directory
            if ~exist(obj.folder, 'dir')
                mkdir(obj.folder);
            end
        end
        
        function obj = cannula(obj, varargin)
            % cannula generates g-code for inserting a cannula.
            %
            % gCode.cannula inserts a cannula so that a needle that
            % slightly overshoots the tip of the cannula hits the given
            % coordinates.
            % Use the name-pair arguments to set the cannula parameters.
            
            [injection, p] = parseInjection(obj, varargin{:});
            
            injection.overshootML = injection.ML;
            injection.overshootDV = injection.DV;
            injection.ML = injection.ML + sind(injection.angle) * p.Results.overshoot;
            injection.DV = injection.DV - cosd(injection.angle) * p.Results.overshoot;
            
            obj.injections = [obj.injections; injection];
            
            % Open the file for writing
            disp('*******************************************************************************')
            fname = fullfile(obj.folder, [injection.injectionName{:} '_Injection.ncc']);
            [obj.file_id, e] = fopen(fname,'w+');
            disp(e)
            
            % Write the code
            obj.writeCannula(p);
            
            % Print the output to the command line
            fprintf(obj.file_id, '\r\n');
            frewind(obj.file_id)
            fwrite(1, fread(obj.file_id))
            fclose('all');
            disp('*******************************************************************************')
            disp(['Saved as "' fname '"'])
        end
        
        function obj = injection(obj, varargin)
            % injection generates g-code for a viral injection.
            %
            % gCode.injection inserts a needle at the given coordinates,
            % goes slightly past the coordinates, and returns.
            % Use the name-pair arguments to set the injection parameters.
            
            [injection, p] = parseInjection(obj, varargin{:});
            
            injection.overshootML = injection.ML - sind(injection.angle) * p.Results.overshoot;
            injection.overshootDV = injection.DV + cosd(injection.angle) * p.Results.overshoot;
            
            obj.injections = [obj.injections; injection];
            
            % Open the file for writing
            disp('*******************************************************************************')
            fname = fullfile(obj.folder, [injection.injectionName{:} '_Injection.ncc']);
            [obj.file_id, e] = fopen(fname,'w+');
            disp(e)
            
            % Write the code
            obj.writeInjection(p);
            
            % Print the output to the command line
            fprintf(obj.file_id, '\r\n');
            frewind(obj.file_id)
            fwrite(1, fread(obj.file_id))
            fclose('all');
            disp('*******************************************************************************')
            disp(['Saved as "' fname '"'])
        end
        
        function drill(obj,varargin)
            % drill Drills holes for all the previously given injections
            % and/or cannulas.
            %
            % Use the name-pair arguments to set the drilling parameters.
            
            val = @(x) validateattributes(x, {'double'}, {'scalar'});
            valP = @(x) validateattributes(x, {'double'}, {'scalar', 'nonnegative'});
            p=inputParser;
            addParameter(p, 'skullThickness', 1, val); % Depth to drill in mm.
            addParameter(p, 'depthPerCycle', 0.2, valP); % Depth increment per drilling cycle.
            addParameter(p, 'speed', 50, valP); % Speed to move while drilling.
            addParameter(p, 'dwellBeforeStart', 4, valP); % Duration to pause above the hole before drilling begins.
            addParameter(p, 'dwellBeforeCycle', 1, valP); % Duration to pause at top of each cycle.
            addParameter(p, 'dwellAfterCycle', 0.5, valP); % Duration to pause at bottom of each cycle.
            parse(p, varargin{:});
            
            % Sort the table so left anterier holes are drilled first
            obj.injections = sortrows(obj.injections, {'AP', 'ML'}, {'descend', 'ascend'});
            
            disp('*******************************************************************************')
            fname = strjoin(unique(obj.injections.name), '_');
            fname = fullfile(obj.folder, [fname '_Holes.ncc']);
            [obj.file_id, e] = fopen(fname,'w+');
            disp(e)
            
            % Write the comments
            fmt = table2cell(obj.injections(:, {'injectionName', 'ML', 'AP', 'DV', 'angle'}))';
            fprintf(obj.file_id, '%% Created %s\r\n', datestr(now, 'yyyy-mmm-dd'));
            fprintf(obj.file_id, '%% Drill %g mm holes at %g mm per cycle\r\n\r\n', p.Results.skullThickness, p.Results.depthPerCycle);
            fprintf(obj.file_id, '%% %-13.13s %+-7.4s %+-7.4s %+-7.4s %+-.9s\r\n', 'Injection', ' ML', ' AP', ' DV', ' Angle');
            fprintf(obj.file_id, '%% %-13.13s %+-7.4s %+-7.4s %+-7.4s %+-.9s\r\n', '---------', '----', '----', '----', '-------');
            fprintf(obj.file_id, '%% %-13.13s %+-7.4g %+-7.4g %+-7.4g %+-.4g\r\n', fmt{:});
            fprintf(obj.file_id, '\r\n\r\n');
            
            % Prepare to move by setting the coordinates to 0 and setting the speed to default
            obj.setPosition(0, 0, 0)
            obj.move('Z', obj.moveHeight, 'F', obj.moveSpeed)
            
            
            for i = 1:height(obj.injections)
                fprintf(obj.file_id, '\r\n%% %s\r\n', obj.injections.injectionName{i});
                
                % goto hole coordinates
                obj.move('X', obj.injections.holeML(i), 'Y', obj.injections.AP(i), 'Z', obj.moveHeight,'F',obj.moveSpeed)
                
                % Set speed for drilling
                obj.setSpeed(p.Results.speed)
                
                % Dwell
                obj.dwell(p.Results.dwellBeforeStart)
                
                % Touch the skull
                obj.move('Z', 0)
                
                % Drill
                drillDepth = 0;
                while (drillDepth - p.Results.depthPerCycle) > -abs(p.Results.skullThickness)
                    obj.dwell(p.Results.dwellBeforeCycle)
                    
                    drillDepth = drillDepth - p.Results.depthPerCycle;
                    obj.move('Z', drillDepth)
                    
                    obj.dwell(p.Results.dwellAfterCycle)
                    obj.move('Z', 0)
                end
                % Final drill cycle
                obj.dwell(p.Results.dwellBeforeCycle)
                obj.move('Z', -abs(p.Results.skullThickness))
                obj.dwell(p.Results.dwellAfterCycle)
                obj.move('Z', 0)
                obj.move('Z', obj.moveHeight, 'F', obj.moveSpeed)
                obj.stop
                
            end
            
            % Print the output to the command line
            fprintf(obj.file_id, '\r\n');
            frewind(obj.file_id)
            fwrite(1, fread(obj.file_id))
            fclose('all');
            disp('*******************************************************************************')
            disp(['Saved as "' fname '"'])
        end
        
        function brainAtlas(obj, atlas_type)
            % brainAtlas plots the injection site on a Paxinos brain atlas.
            % atlas_type can either be 'rat' or 'mouse'
            
            atlas_type = validatestring(atlas_type,{'mouse','rat'});
            switch atlas_type
                case 'mouse'
                    atlasFolder = fullfile(fileparts(mfilename('fullpath')),'Brain Atlas','Mouse');
                    tableName = fullfile(fileparts(mfilename('fullpath')),'Brain Atlas','mouse-brain-atlas.csv');
                case 'rat'
                    atlasFolder = fullfile(fileparts(mfilename('fullpath')),'Brain Atlas','Rat');
                    tableName = fullfile(fileparts(mfilename('fullpath')),'Brain Atlas','rat-brain-atlas.csv');
            end
            
            t = readtable(tableName);
            coronal  = t(strcmp(t.plane,'coronal'),:);
            sagittal = t(strcmp(t.plane,'sagittal'),:);
            
            [~,~,ia] = unique(obj.injections.AP);
            
            obj.injections.holeDV = zeros(height(obj.injections),1);
            
            for i = 1:max(ia)
                
                in = obj.injections(ia == i, :);
                
                % Coronol
                [~, idx] = min(abs(coronal.coordinates - in.AP(1)));
                
                offset = coronal{idx,{'xOffset','yOffset','xOffset','yOffset'}};
                scale  = coronal{idx,{'xPixelsPerMM','yPixelsPerMM','xPixelsPerMM','yPixelsPerMM'}};
                
                needles = [in.holeML, in.holeDV, in.ML, in.DV];
                needles = needles .* scale + offset;
                overShoot = [in.ML, in.DV, in.overshootML, in.overshootDV] .* scale + offset;
                
                
                %  needleWidth = round(coronal.xPixelsPerMM(idx) * 0.4;
                needleWidth = 5;
                
                im_c = imread(fullfile(atlasFolder,[num2str(coronal.id(idx)) '.jpg']));
                im_c = insertShape(im_c,'Line',overShoot,'Color','blue','LineWidth',2);
                im_c = insertShape(im_c,'Line',needles,'Color','red','LineWidth',needleWidth);
                
                
                % Sagital
                [~, idx] = min(abs(sagittal.coordinates - max(in.ML)));
                offset = sagittal{idx,{'xOffset','yOffset','xOffset','yOffset'}};
                scale  = sagittal{idx,{'xPixelsPerMM','yPixelsPerMM','xPixelsPerMM','yPixelsPerMM'}};
                
                needles = [-in.AP, in.holeDV, -in.AP, in.DV];
                needles = needles .* scale + offset;
                overShoot = [-in.AP, in.DV, -in.AP, in.overshootDV] .* scale + offset;
                
                im_s = imread(fullfile(atlasFolder,[num2str(sagittal.id(idx)) '.jpg']));
                im_s = insertShape(im_s,'Line',overShoot,'Color','blue','LineWidth',2);
                im_s = insertShape(im_s,'Line',needles,'Color','red','LineWidth',5);
                
                figure('Color','w')
                imshow([im_c; im_s])
            end
        end
        
    end
    
    methods (Access=private)
        function [injection, p] = parseInjection(obj, varargin)
            % parseInjection Parse and validate the coordinates of the needle
            
            val = @(x) validateattributes(x, {'double'}, {'scalar'});
            valP = @(x) validateattributes(x, {'double'}, {'scalar', 'nonnegative'});
            p=inputParser;
            addParameter(p,'ML',0,val); % Anterior-Posterior coordinates.
            addParameter(p,'AP',0,val); % Medial-Lateral coordinates. Positive is to the right
            addParameter(p,'DV',0,val); % Dorsal-Ventral coordinates. Sign does not matter.
            addParameter(p,'angle',0,val); % Injection angle. Sign is automatically changed towards medial. If ML is zero, positive angles inject from the right.
            addParameter(p,'name', num2str(size(obj.injections,1)+1)); % Name for file creation. Left or Right is automatically appended.
            
            addParameter(p,'speed',25,valP); % Speed to insert the needle/cannula.
            addParameter(p,'overshoot',0.25,valP); % For injections: Distance to move the needle past the injection. For cannulas: Length of the needle past the cannula tip.
            addParameter(p,'dwellBeforeStart',6,valP); % Duration to pause over the hole before inserting the needle.
            addParameter(p,'dwellAfterOvershoot',6,valP); % Duration to pause after overshooting the injection site before returning
            
            parse(p, varargin{:});
            
            ML = p.Results.ML;
            AP = p.Results.AP;
            DV = p.Results.DV;
            angle = p.Results.angle;
            name = p.Results.name;
            
            
            % Make sure DV is positive
            DV = abs(DV);
            
            % Make sure the angle is towards medial
            if sign(ML) > 0
                angle = abs(angle);
            elseif sign(ML) < 0
                angle = -abs(angle);
            end
            
            % Calculate ML of the hole
            holeML = tand(angle) * DV + ML;
            
            % Append "left" or "right" to the name
            injectionName = name;
            if sign(holeML) > 0
                injectionName = [injectionName, '_Right'];
            elseif sign(holeML) < 0
                injectionName = [injectionName, '_Left'];
            end
            
            injection = table(ML, AP, DV, angle, {name}, holeML, {injectionName}, 'VariableNames', {'ML', 'AP', 'DV', 'angle', 'name', 'holeML', 'injectionName'});
            
        end
        
        function writeInjection(obj, p)
            % writeInjection writes the g-code to a file
            j = obj.injections(end, :);
            
            % Write the comments
            fprintf(obj.file_id, '%% Created %s\r\n', datestr(now, 'yyyy-mmm-dd'));
            fprintf(obj.file_id, '%% Inject with %g mm overshoot\r\n', p.Results.overshoot);
            fprintf(obj.file_id, '%% %-13.13s %+-7.4s %+-7.4s %+-7.4s %+-.9s\r\n', 'Injection', ' ML', ' AP', ' DV', ' Angle');
            fprintf(obj.file_id, '%% %-13.13s %+-7.4s %+-7.4s %+-7.4s %+-.9s\r\n', '---------', '----', '----', '----', '-------');
            fprintf(obj.file_id, '%% %-13.13s %+-7.4g %+-7.4g %+-7.4g %+-.4g\r\n', j.injectionName{:}, j.ML, j.AP, j.DV, j.angle);
            fprintf(obj.file_id, '\r\n\r\n');
            
            % Prepare to move by setting the coordinates to 0 and setting the speed to default
            obj.setPosition(0, 0, 0)
            obj.move('Z', obj.moveHeight, 'F', obj.moveSpeed)
            fprintf(obj.file_id, '\r\n');
            
            % goto hole coordinates
            obj.move('X', j.holeML, 'Y', j.AP);
            
            % Touch the skull
            obj.move('Z', 0)
            
            % Dwell
            obj.dwell(p.Results.dwellBeforeStart)
            
            % Overshoot
            obj.move('X', j.overshootML, 'Y', j.AP, 'Z', -j.overshootDV,'F', p.Results.speed);
            obj.dwell(p.Results.dwellAfterOvershoot)
            
            % Move to injection site
            obj.move('X', j.ML, 'Y', j.AP, 'Z', -j.DV);
            obj.stop
            
            % get out of the brain
            obj.move('X', j.holeML, 'Y', j.AP, 'Z', 0,'F', p.Results.speed);
            obj.move('Z', obj.moveHeight, 'F', obj.moveSpeed)
            
        end
        
        function writeCannula(obj, p)
            % writeCannula writes the g-code to a file
            
            j = obj.injections(end, :);
            
            % Write the comments
            fprintf(obj.file_id, '%% Created %s\r\n', datestr(now, 'yyyy-mmm-dd'));
            fprintf(obj.file_id, '%% Insert cannula for %g mm needle\r\n', p.Results.overshoot);
            fprintf(obj.file_id, '%% %-13.13s %+-7.4s %+-7.4s %+-7.4s %+-.9s\r\n', 'Cannula  ', ' ML', ' AP', ' DV', ' Angle');
            fprintf(obj.file_id, '%% %-13.13s %+-7.4s %+-7.4s %+-7.4s %+-.9s\r\n', '---------', '----', '----', '----', '-------');
            fprintf(obj.file_id, '%% %-13.13s %+-7.4g %+-7.4g %+-7.4g %+-.4g\r\n', j.injectionName{:}, j.overshootML, j.AP, j.overshootDV, j.angle);
            fprintf(obj.file_id, '\r\n\r\n');
            
            % Prepare to move by setting the coordinates to 0 and setting the speed to default
            obj.setPosition(0, 0, 0)
            obj.move('Z', obj.moveHeight, 'F', obj.moveSpeed)
            fprintf(obj.file_id, '\r\n');
            
            % goto hole coordinates
            obj.move('X', j.holeML, 'Y', j.AP);
            
            % Touch the skull
            obj.move('Z', 0)
            
            % Dwell
            obj.dwell(p.Results.dwellBeforeStart)
            
            % Insert Cannula
            obj.move('X', j.ML, 'Y', j.AP, 'Z', -j.DV,'F', p.Results.speed);
            
            % Reset speed and stop
            obj.move('F', obj.moveSpeed);
            obj.stop
        end
        
        function setPosition(obj,X,Y,Z)
            % setPosition g-code to set the tool's current position
            fprintf(obj.file_id, 'G92 X%.4g Y%.4g Z%.4g', X, Y, Z);
            fprintf(obj.file_id, '\r\n');
        end
        
        function setSpeed(obj,speed)
            %setSpeed sets the speed in mm/minute
            fprintf(obj.file_id, 'F%.4g', speed);
            fprintf(obj.file_id, '\r\n');
        end
        
        function move(obj,varargin)
            % move Moves to the given coordinates
            fprintf(obj.file_id, 'G1');
            for i = 1:2:length(varargin)
                fprintf(obj.file_id, ' %c%.4g', varargin{i}, varargin{i+1});
            end
            fprintf(obj.file_id, '\r\n');
        end
        
        function dwell(obj,dwellTime)
            % dwell pauses the machine for X seconds
            fprintf(obj.file_id, 'G4 P%.4g', dwellTime);
            fprintf(obj.file_id, '\r\n');
        end
        
        function stop(obj)
            % stop halts movement and waits for user to continue
            fprintf(obj.file_id, 'M00\r\n');
        end
        
        
    end
    
    methods (Static)
        function downloadBrainAtlas
            % downloadBrainAtlas downloads the rat and mouse brain atlas
            % with pixels/mm compiled by Matt Gaidica
            t = readtable('mouse-brain-atlas.csv');
            for i = 1:height(t)
                fname = [num2str(i) '.jpg'];
                im = websave(['Brain Atlas\Mouse\' fname],['http://labs.gaidi.ca/mouse-brain-atlas/images/Mouse_Brain_Atlas_' fname]);
                disp(i)
            end
            
            t = readtable('rat-brain-atlas.csv');
            for i = 1:height(t)
                fname = [num2str(i) '.jpg'];
                im = websave(['Brain Atlas\Rat\' fname],['http://labs.gaidi.ca/rat-brain-atlas/images/Rat_Brain_Atlas_' fname]);
                disp(i)
            end
        end
    end
end



