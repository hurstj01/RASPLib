classdef soHCSR04ToneSonar < matlab.System & coder.ExternalDependency
    % soHCSR04Sonar sonar distance sensor
    % 
    %
    
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
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
		
		
    end

	
	
	
	
	
    methods (Access = protected)
        function setupImpl(obj)
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('HCSR04Tonewrapper.h');
                % initialize the potentiometer
                coder.ceval('HCSR04Sonar_Init', obj.TrigPin, obj.EchoPin);
				% coder.ceval('NewPing sonar(7,8,200);');
            elseif ( coder.target('Sfun') )
                %
            end
        end

        function [d_cm] = stepImpl(obj)
            % initialize output to a single (float) with the value zero
            out = single(zeros(1,1));
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('HCSR04Tonewrapper.h');
                % get the current value of the sensor
                coder.ceval('HCSR04Sonar_Read', coder.wref(out), obj.TrigPin, obj.EchoPin);
            elseif ( coder.target('Sfun') )
                %
            end
            % pull the data appart
            d_cm = out(1);
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
                try %codertarget.target.isCoderTarget(buildInfo.ModelName)
                    % we are in 15b
                    [~, hardwaredir] = codertarget.arduinobase.internal.getArduinoIDERoot('hardware');
                    if(strfind(hardwaredir,'aCLI')),disp('New aCLI library structure');librarydir = fullfile(hardwaredir, 'avr', '1.8.3', 'libraries');else,librarydir = fullfile(hardwaredir, 'arduino', 'avr' , 'libraries');end
                catch me
                    % we are pre 15b
                    [~, hardwaredir] = realtime.internal.getArduinoIDERoot('hardware');
                    librarydir = fullfile(hardwaredir, '..', 'libraries');
                 end
                
                % get current directory path
                src_dir = mfilename('fullpath');
                [current_dir] = fileparts(src_dir);
                
                % add the include paths
                buildInfo.addIncludePaths(fullfile(librarydir, 'Wire'));
                buildInfo.addIncludePaths(fullfile(librarydir, 'Wire','utility'));
                buildInfo.addIncludePaths(fullfile(current_dir,'..','include'));
                
                buildInfo.addIncludePaths('C:/ProgramData/MATLAB/SupportPackages/R2017a/3P.instrset/arduinoide.instrset/arduino-1.6.13/hardware/arduino/avr/cores/arduino/')
                
                % add the source paths
                srcPaths = {...
                    fullfile(librarydir, 'Wire'), ...
                    fullfile(librarydir, 'Wire', 'utility'),...
                    fullfile(current_dir,'..','src'),...
                    'C:/ProgramData/MATLAB/SupportPackages/R2017a/3P.instrset/arduinoide.instrset/arduino-1.6.13/hardware/arduino/avr/cores/arduino/'};
                buildInfo.addSourcePaths(srcPaths);
                
                % add the source files
                srcFiles = {'HCSR04Tonewrapper.cpp'};
                buildInfo.addSourceFiles(srcFiles);
                
            end
        end
    end
end
