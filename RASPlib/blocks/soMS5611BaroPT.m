classdef soMS5611BaroPT < matlab.System & coder.ExternalDependency
    % I2C sensor MS5611Baro pressure and temperature. This class will be used to read the state of the MS5611Baro pressure and temperature See MS5611.cpp for more options.  Edit MS5611.cpp, MS5611wrapper.cpp, and soMS5611Baro.m to improve speed if needed.  RAW data is int_32, pres and tempreature floats.   The system object block uses single, so speed can be improved.
    
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
                coder.cinclude('MS5611wrapper.h');
                % initialize the potentiometer
                coder.ceval('MS5611Baro_Init');
            elseif ( coder.target('Sfun') )
                %
            end
        end

        function [pres_Pa, temp_C] = stepImpl(obj)
            % initialize output to a single (float) with the value zero
            out = single(zeros(2,1));
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('MS5611wrapper.h');
                % get the current value of the sensor
                coder.ceval('MS5611Baro_Read', coder.wref(out));
            elseif ( coder.target('Sfun') )
                %
            end
            % pull the data appart
            pres_Pa = out(1);
			temp_C = out(2);
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
            name = 'Baro';
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
                srcPaths = {...
                    fullfile(librarydir, 'Wire'), ...
                    fullfile(librarydir, 'Wire', 'utility'),...
                    fullfile(librarydir, 'Wire','src'),...
                    fullfile(librarydir, 'Wire','src','utility'),...
                    fullfile(current_dir,'..','src')};
                buildInfo.addSourcePaths(srcPaths);
                
                % add the source files
                srcFiles = {'Wire.cpp', 'twi.c', 'I2Cdev.cpp', 'MS5611.cpp', 'MS5611wrapper.cpp'};
                buildInfo.addSourceFiles(srcFiles);
                
            end
        end
    end
end
