classdef soHCSR04Sonar < matlab.System & coder.ExternalDependency
    % soHCSR04Sonar Sonar distance sensor.  After 2015b Tone.cpp needs to modified so it does not define the timer 2 ISR.  You only have to give permission once and Tone.cpp will be modified so the ISR for timer 2 is not redefined allowing NewPing library to be used.
    
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        Sonar = 1;   % Sonar ID (1,2,3)
        TrigPin = 7; % Trigger Pin
        EchoPin = 8; % Echo Pin

    end
    
    properties (Constant, Hidden)
        % AvailablePin specifies the range of values allowed for Pin. You
        % can customize the AvailablePin for a particular board. For
        % example, use AvailablePin = 2:13 for Arduino Uno.
        AvailablePin = 0:53;
    end
      
    properties (Hidden,Transient,Constant)
            
    end
 
    properties (Hidden)
        %         % keeps track of the selected Potentiometer
        %         potNum = 0;
        %         % simSampleNum - tracks which sample we are on in a simulation
        %         simSampleNum = 0;
    end
    
    methods
        % Constructor
        function obj = soHCSR04Sonar(varargin)
            coder.allowpcode('plain');
            
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.TrigPin(obj,value)
            coder.extrinsic('sprintf') % Do not generate code for sprintf
            validateattributes(value,...
                {'numeric'},...
                {'real', 'positive', 'integer','scalar'},...
                '', ...
                'Pin');
            assert(any(value == obj.AvailablePin), ...
                'Invalid value for Pin. Pin must be one of the following: %s', ...
                sprintf('%d ', obj.AvailablePin));
            obj.TrigPin = value;
        end
        
        function set.EchoPin(obj,value)
            coder.extrinsic('sprintf') % Do not generate code for sprintf
            validateattributes(value,...
                {'numeric'},...
                {'real', 'positive', 'integer','scalar'},...
                '', ...
                'Pin');
            assert(any(value == obj.AvailablePin), ...
                'Invalid value for Pin. Pin must be one of the following: %s', ...
                sprintf('%d ', obj.AvailablePin));
            obj.EchoPin = value;
        end
        
        function set.Sonar(obj,value)
            coder.extrinsic('sprintf') % Do not generate code for sprintf
            validateattributes(value,...
                {'numeric'},...
                {'real', 'positive', 'integer','scalar'},...
                '', ...
                'Pin');
            assert(any(value == obj.AvailablePin), ...
                'Invalid value for Pin. Pin must be one of the following: %s', ...
                sprintf('%d ', obj.AvailablePin));
            obj.Sonar = value;
        end
        
%        function set.IgnoreToneCppWarning(obj,value)
%             coder.extrinsic('sprintf') % Do not generate code for sprintf
%             obj.IgnoreToneCppWarning = value;
%         end
        
        
    end

    methods (Access = protected)
        function setupImpl(obj)
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('HCSR04wrapper.h');
                % initialize the potentiometer
                coder.ceval('HCSR04Sonar_Init', obj.TrigPin, obj.EchoPin, obj.Sonar);
                % coder.ceval('NewPing sonar(7,8,200);');
            elseif ( coder.target('Sfun') )
                %
            end
        end
        
        function [d_cm] = stepImpl(obj)
            % initialize output to a single (float) with the value zero
            d_cm= int32(zeros(1,1));
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('HCSR04wrapper.h');
                % get the current value of the sensor
                d_cm = coder.ceval('HCSR04Sonar_Read',obj.Sonar);
            elseif ( coder.target('Sfun') )
                %
            end
            % pull the data appart
            % d_cm = out(1);
        end
        
        function releaseImpl(obj)
            if coder.target('Rtw')% done only for code gen
                %
            elseif ( coder.target('Sfun') )
                %
            end
        end
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'Sonar';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
       
        % Update the build-time buildInfo
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Add include paths and source files for code generation

                % determine path to arduino IDE
                try codertarget.target.isCoderTarget(buildInfo.ModelName)
                    % we are in 15b
                    [~, hardwaredir] = codertarget.arduinobase.internal.getArduinoIDERoot('hardware');
                    librarydir = fullfile(hardwaredir, 'arduino', 'avr' , 'libraries');
                    tonedir = fullfile(hardwaredir, 'arduino', 'avr' , 'cores', 'arduino');
                    tonecpp_file=[tonedir '\Tone.cpp'];
                    
                    if(isfile(tonecpp_file))
                        
                        disp('');
                        disp('To use the ultrasonic block you need to disable Timer 2 in Tone.cpp')
                        disp('Tone.cpp is located here:')
                        disp(tonecpp_file)
                        disp('To disable timer 2 for ultrasonic use')
                        disp('You should <a href="matlab: opentoline(tonecpp_file,537)">open Tone.cpp</a>')
                        disp('Find the line with text #ifdef USE_TIMER2 and change it to #ifdef USE_TIMER2_disabled')
                        disp('Save the file')
                        disable_timer2_in_Tone_cpp(tonecpp_file);
                    end
                    
                    
                catch me
                    % we are pre 15b
                    [~, hardwaredir] = realtime.internal.getArduinoIDERoot('hardware');
                    librarydir = fullfile(hardwaredir, '..', 'libraries');
                end
                
                % get current directory path
                src_dir = mfilename('fullpath');
                [current_dir] = fileparts(src_dir);
                
                % add the include paths
                buildInfo.addIncludePaths(fullfile(current_dir,'..','include'));
                
                % add the source paths
                srcPaths = {...
                    fullfile(current_dir,'..','src')};
                buildInfo.addSourcePaths(srcPaths);
                
                % add the source files
                srcFiles = {'NewPing.cpp', 'HCSR04wrapper.cpp'};
                buildInfo.addSourceFiles(srcFiles);
                
            end
        end
    end
end

function disable_timer2_in_Tone_cpp(file)

% file='Tone.cpp'
% read the file into a cell array
% find the line where it defines the ISR for timer 2
% modify the #ifdef USE_TIMER2 jto #ifdef USE_TIMER2_disabled
% to prevent the redfinition of the ISR for the timer

disp('Checking Tone.cpp for Timer 2 Conflict')
% fid = fopen('Tone.cpp','r');
fid = fopen(file,'r');
i = 1;
tline = fgetl(fid);
A{i} = tline;
while ischar(tline)
    i = i+1;
    tline = fgetl(fid);
    % search for '#ifdef USE_TIMER'
    if(strfind(tline, '#ifdef USE_TIMER2'))
        if(strfind(tline, '#ifdef USE_TIMER2_disabled'))
            disp('Tone.cpp already modified to disable Timer 2 ISR');
            % it has already been modified - nothing to do!
            
            return;
        else
            A{i}='#ifdef USE_TIMER2_disabled';
        end
    else
        A{i} = tline;
    end
end
fclose(fid);

answer = questdlg('Permission to modify Tone.cpp and disable Timer 2 ISR?', ...
    'Modify Tone.cpp', ...
    'Yes','No','Yes');
% Handle response
switch answer
    case 'Yes'
        
    case 'No'
        return;
end

% Change cell A if necessary
% A{69} = sprintf('%d',99);
% Write cell A into txt
% fid = fopen('Tone.cpp', 'w');
fid = fopen(file, 'w');
for i = 1:numel(A)
    if A{i+1} == -1
        fprintf(fid,'%s', A{i});
        break
    else
        fprintf(fid,'%s\n', A{i});
    end
end

end