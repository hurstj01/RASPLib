classdef soMPU9250RAW < matlab.System & coder.ExternalDependency
    % soMPU9250
    % This class will be used to read the state of the accel
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
                coder.cinclude('MPU9250wrapper.h');
                % initialize the potentiometer
                coder.ceval('MPU9250_Init');
            elseif ( coder.target('Sfun') )
                %
            end
        end
		
        function [xaccel,yaccel,zaccel,xgyro,ygyro,zgyro,xmag,ymag,zmag,temp] = stepImpl(obj)
            % initialize output to a single (float) with the value zero
            out = int16(zeros(10,1));
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('MPU9250wrapper.h');
                % get the current value of the sensor
                coder.ceval('MPU9250_ReadRAW', coder.wref(out));
            elseif ( coder.target('Sfun') )
                %
            end
            % pull the data appart
            xaccel = out(1);
            yaccel = out(2);
            zaccel = out(3);
			xgyro  = out(4);
            ygyro  = out(5);
            zgyro  = out(6);
			xmag   = out(7);
            ymag   = out(8);
            zmag   = out(9);
			temp   = out(10)
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
            name = 'Accel';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        % Update the build-time buildInfo
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')                
                %  Add include paths and source files for code generation
                                
                % determine path to arduino IDE
                 try %codertarget.target.isCoderTarget(buildInfo.ModelName)
%                     % we are in 15b
                     [~, hardwaredir] = codertarget.arduinobase.internal.getArduinoIDERoot('hardware');
                     librarydir = fullfile(hardwaredir, 'arduino', 'avr' , 'libraries');
                 catch me
                    % we are pre 15b
                    [~, hardwaredir] = realtime.internal.getArduinoIDERoot('hardware');
                    librarydir = fullfile(hardwaredir, '..', 'libraries');
                 end
                
                %  get current directory path
                src_dir = mfilename('fullpath');
                [current_dir] = fileparts(src_dir);
                
                 % add the include paths
                buildInfo.addIncludePaths(fullfile(librarydir, 'Wire'));
                buildInfo.addIncludePaths(fullfile(librarydir, 'Wire','utility'));
                buildInfo.addIncludePaths(fullfile(current_dir,'..','include'));
				buildInfo.addIncludePaths(fullfile(librarydir, 'SPI'));			
                % 2017a new arduino paths:
                buildInfo.addIncludePaths(fullfile(librarydir, 'Wire','src'));
                buildInfo.addIncludePaths(fullfile(librarydir, 'Wire','src','utility'));
				buildInfo.addIncludePaths(fullfile(librarydir, 'SPI','src'));		
                
				% 2017a new arduino paths:
                %fullfile(librarydir, 'Wire','src'),...
                %fullfile(librarydir, 'Wire','src','utility'),...
				%fullfile(librarydir, 'SPI','src'), ...		
				% add the include paths
               
                % add the source paths
				buildInfo.addSourcePaths(fullfile(librarydir, 'SPI'));
				buildInfo.addSourcePaths(fullfile(librarydir, 'SPI','src'));
				buildInfo.addSourcePaths(fullfile(current_dir,'..','src'));
				
                buildInfo.addSourcePaths(fullfile(librarydir, 'Wire'));
                buildInfo.addSourcePaths(fullfile(librarydir, 'Wire','src'));
                buildInfo.addSourcePaths(fullfile(current_dir,'..','src'));
                if(exist(fullfile(librarydir, 'Wire', 'utility'))), buildInfo.addSourcePaths(fullfile(librarydir, 'Wire', 'utility'));end
                if(exist(fullfile(librarydir, 'Wire','src','utility'))),buildInfo.addSourcePaths(fullfile(librarydir, 'Wire','src','utility'));end
                
                % add the source files
                srcFiles = {'SPI.cpp','Wire.cpp', 'twi.c', 'I2Cdev.cpp', 'MPU9250.cpp', 'MPU9250wrapper.cpp'};
                buildInfo.addSourceFiles(srcFiles);
                
            end
        end
    end
end
