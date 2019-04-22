% g = gCode;
% 
% g.cannula('AP',-4.5,'ML',0,'DV',3.25,'angle',15,'name','DRN');
% g.injection('AP',-4.5,'ML',0,'DV',3.25,'angle',-15,'name','DRN');
% 
% g.injection('AP',-1.85,'ML',+0.42,'DV',2.6,'angle',10,'name','LHb');
% g.cannula('AP',-1.85,'ML',-0.42,'DV',2.6,'angle',10,'name','LHb');
% 
% g.drill;z
% g.brainAtlas('mouse')


classdef gCode < handle
    % Creates G-Code
    properties
        injections = []
        fid = 1
        moveSpeed = 100
        moveHeight = 3
        folder = fullfile(fileparts(mfilename('fullpath')), 'Output');
    end
    
    methods
        function obj = gCode(obj)
            % Make the output directory
            if ~exist(obj.folder, 'dir')
                mkdir(obj.folder);
            end
        end
        
        function obj = cannula(obj, varargin)
            
            [injection, p] = parseInjection(obj, varargin{:});
            
            injection.overshootML = injection.ML;
            injection.overshootDV = injection.DV;
            injection.ML = injection.ML + sind(injection.angle) * p.Results.overshoot;
            injection.DV = injection.DV - cosd(injection.angle) * p.Results.overshoot;
            
            obj.injections = [obj.injections; injection];
            
            % Open the file for writing
            disp('*******************************************************************************')
            fname = fullfile(obj.folder, [injection.injectionName{:} '_Injection.ncc']);
            [obj.fid, e] = fopen(fname,'w+');
            disp(e)
            
            % Write the code
            obj.writeCannula(p);
            
            % Print the output to the command line
            fprintf(obj.fid, '\n');
            frewind(obj.fid)
            fwrite(1, fread(obj.fid))
            fclose('all');
            disp('*******************************************************************************')
            disp(['Saved as "' fname '"'])
        end
        
        function obj = injection(obj, varargin)
            
            [injection, p] = parseInjection(obj, varargin{:});
            
            injection.overshootML = injection.ML - sind(injection.angle) * p.Results.overshoot;
            injection.overshootDV = injection.DV + cosd(injection.angle) * p.Results.overshoot;
            
            obj.injections = [obj.injections; injection];
            
            % Open the file for writing
            disp('*******************************************************************************')
            fname = fullfile(obj.folder, [injection.injectionName{:} '_Injection.ncc']);
            [obj.fid, e] = fopen(fname,'w+');
            disp(e)
            
            % Write the code
            obj.writeInjection(p);
            
            % Print the output to the command line
            fprintf(obj.fid, '\n');
            frewind(obj.fid)
            fwrite(1, fread(obj.fid))
            fclose('all');
            disp('*******************************************************************************')
            disp(['Saved as "' fname '"'])
        end
             
        function [injection, p] = parseInjection(obj, varargin)
            % Parse and validate the coordinates of the needle
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
        
        function drill(obj,varargin)
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
            [obj.fid, e] = fopen(fname,'w+');
            disp(e)
            
            % Write the comments
            fmt = table2cell(obj.injections(:, {'injectionName', 'ML', 'AP', 'DV', 'angle'}))';
            fprintf(obj.fid, '%% Created %s\n', datestr(now, 'yyyy-mmm-dd'));
            fprintf(obj.fid, '%% Drill %g mm holes at %g mm per cycle\n\n', p.Results.skullThickness, p.Results.depthPerCycle);
            fprintf(obj.fid, '%% %-13.13s %+-7.4s %+-7.4s %+-7.4s %+-.9s\n', 'Injection', ' ML', ' AP', ' DV', ' Angle');
            fprintf(obj.fid, '%% %-13.13s %+-7.4s %+-7.4s %+-7.4s %+-.9s\n', '---------', '----', '----', '----', '-------');
            fprintf(obj.fid, '%% %-13.13s %+-7.4g %+-7.4g %+-7.4g %+-.4g\n', fmt{:});
            fprintf(obj.fid, '\n\n');
            
            % Prepare to move by setting the coordinates to 0 and setting the speed to default
            obj.setPosition(0, 0, 0)
            obj.move('Z', obj.moveHeight, 'F', obj.moveSpeed)
            
            
            for i = 1:height(obj.injections)
                fprintf(obj.fid, '\n%% %s\n', obj.injections.injectionName{i});
                
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
            fprintf(obj.fid, '\n');
            frewind(obj.fid)
            fwrite(1, fread(obj.fid))
            fclose('all');
            disp('*******************************************************************************')
            disp(['Saved as "' fname '"'])
        end
        
        function writeInjection(obj, p)
            
            j = obj.injections(end, :);
            
            % Write the comments
            fprintf(obj.fid, '%% Created %s\n', datestr(now, 'yyyy-mmm-dd'));
            fprintf(obj.fid, '%% Inject with %g mm overshoot\n', p.Results.overshoot);
            fprintf(obj.fid, '%% %-13.13s %+-7.4s %+-7.4s %+-7.4s %+-.9s\n', 'Injection', ' ML', ' AP', ' DV', ' Angle');
            fprintf(obj.fid, '%% %-13.13s %+-7.4s %+-7.4s %+-7.4s %+-.9s\n', '---------', '----', '----', '----', '-------');
            fprintf(obj.fid, '%% %-13.13s %+-7.4g %+-7.4g %+-7.4g %+-.4g\n', j.injectionName{:}, j.ML, j.AP, j.DV, j.angle);
            fprintf(obj.fid, '\n\n');
            
            % Prepare to move by setting the coordinates to 0 and setting the speed to default
            obj.setPosition(0, 0, 0)
            obj.move('Z', obj.moveHeight, 'F', obj.moveSpeed)
            fprintf(obj.fid, '\n');
            
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
            
            j = obj.injections(end, :);
            
            % Write the comments
            fprintf(obj.fid, '%% Created %s\n', datestr(now, 'yyyy-mmm-dd'));
            fprintf(obj.fid, '%% Insert cannula for %g mm needle\n', p.Results.overshoot);
            fprintf(obj.fid, '%% %-13.13s %+-7.4s %+-7.4s %+-7.4s %+-.9s\n', 'Cannula  ', ' ML', ' AP', ' DV', ' Angle');
            fprintf(obj.fid, '%% %-13.13s %+-7.4s %+-7.4s %+-7.4s %+-.9s\n', '---------', '----', '----', '----', '-------');
            fprintf(obj.fid, '%% %-13.13s %+-7.4g %+-7.4g %+-7.4g %+-.4g\n', j.injectionName{:}, j.overshootML, j.AP, j.overshootDV, j.angle);
            fprintf(obj.fid, '\n\n');
            
            % Prepare to move by setting the coordinates to 0 and setting the speed to default
            obj.setPosition(0, 0, 0)
            obj.move('Z', obj.moveHeight, 'F', obj.moveSpeed)
            fprintf(obj.fid, '\n');
            
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
            fprintf(obj.fid, 'G92 X%.4g Y%.4g Z%.4g', X, Y, Z);
            fprintf(obj.fid, '\n');
        end
        
        function setSpeed(obj,speed)
            fprintf(obj.fid, 'F%.4g', speed);
            fprintf(obj.fid, '\n');
        end
        
        function move(obj,varargin)
            fprintf(obj.fid, 'G1');
            for i = 1:2:length(varargin)
                fprintf(obj.fid, ' %c%.4g', varargin{i}, varargin{i+1});
            end
            fprintf(obj.fid, '\n');
        end
        
        function dwell(obj,dwellTime)
            fprintf(obj.fid, 'G4 P%.4g', dwellTime);
            fprintf(obj.fid, '\n');
        end
        
        function stop(obj)
            fprintf(obj.fid, 'M00\n');
        end
        
        
        function brainAtlas(obj, type)
            % type can either be 'rat' or 'mouse'
            p = inputParser;
            p.addOptional('type', 'mouse', @(x) any(validatestring(lower(x), {'mouse', 'rat'})));
            p.parse(type);
            
            switch lower(p.Results.type)
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
    
    methods (Static)
        function download
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



