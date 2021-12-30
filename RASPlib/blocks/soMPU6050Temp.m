classdef soMPU6050Temp < matlab.System & coder.ExternalDependency
    % I2C sensor MPU6050 temperature
    % This class will be used to read the state of the MPU6050 temperature
    %
    
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)

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
    end

    methods (Access = protected)
        function setupImpl(obj)
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('MPU6050wrapper.h');
                % initialize the potentiometer
                coder.ceval('MPU6050Accel_Init');
            elseif ( coder.target('Sfun') )
                %
            end
        end

        function [temp] = stepImpl(obj)
            % initialize output to a single (float) with the value zero
            out = int16(zeros(1,1));
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('MPU6050wrapper.h');
                % get the current value of the sensor
                coder.ceval('MPU6050Temp_Read', coder.wref(out));
            elseif ( coder.target('Sfun') )
                %
            end
            % pull the data appart
            temp = out(1);
        end

        function releaseImpl(obj)
            if coder.target('Rtw')% done only for code gen
                %
            elseif ( coder.target('Sfun') )
                %
            end
        end
    end

    methods (Static)
        function name = getDescriptiveName()
            name = 'temperature';
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
                     librarydir = fullfile(hardwaredir, 'arduino', 'avr' , 'libraries');
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
                % 2017a new arduino paths:
                buildInfo.addIncludePaths(fullfile(librarydir, 'Wire','src'));
                buildInfo.addIncludePaths(fullfile(librarydir, 'Wire','src','utility'));
                
				% 2017a new arduino paths:
                %fullfile(librarydir, 'Wire','src'),...
                %fullfile(librarydir, 'Wire','src','utility'),...
				
                % add the source paths
                buildInfo.addSourcePaths(fullfile(librarydir, 'Wire'));
                buildInfo.addSourcePaths(fullfile(librarydir, 'Wire','src'));
                buildInfo.addSourcePaths(fullfile(current_dir,'..','src'));
                if(exist(fullfile(librarydir, 'Wire', 'utility'))), buildInfo.addSourcePaths(fullfile(librarydir, 'Wire', 'utility'));end
                if(exist(fullfile(librarydir, 'Wire','src','utility'))),buildInfo.addSourcePaths(fullfile(librarydir, 'Wire','src','utility'));end
                
                % add the source files
                srcFiles = {'Wire.cpp', 'twi.c', 'I2Cdev.cpp', 'MPU6050.cpp', 'MPU6050wrapper.cpp'};
                buildInfo.addSourceFiles(srcFiles);
                
            end
        end
    end
end
