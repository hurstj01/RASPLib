classdef soQMC5883L < matlab.System & coder.ExternalDependency
    % soQMC5883
    % This class will be used to read the state of the accel
    %
    
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)

    end
    properties (Hidden,Transient,Constant)

        
    end

    properties (Hidden)

%         % simSampleNum - tracks which sample we are on in a simulation
%         simSampleNum = 0;
    end
    
    methods
    end

    methods (Access = protected)
        function setupImpl(obj)
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('QMC5883wrapper.h');
                coder.ceval('QMC5883_Init');
            elseif ( coder.target('Sfun') )
                %
            end
        end
		
        function [xmag,ymag,zmag] = stepImpl(obj)
            % initialize output to a single (float) with the value zero
            out = int16(zeros(3,1));
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('QMC5883wrapper.h');
                % get the current value of the sensor
                coder.ceval('QMC5883_ReadMag', coder.wref(out));
            elseif ( coder.target('Sfun') )
                %
            end
            % pull the data appart
			xmag   = out(1);
            ymag   = out(2);
            zmag   = out(3);

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
                 try codertarget.target.isCoderTarget(buildInfo.ModelName)
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
                srcPaths = {...
                    fullfile(librarydir, 'Wire'), ...
                    fullfile(librarydir, 'Wire', 'utility'),...
                    fullfile(librarydir, 'Wire','src'),...
                    fullfile(librarydir, 'Wire','src','utility'),...
					fullfile(librarydir, 'SPI'), ...
					fullfile(librarydir, 'SPI','src'), ...					
                    fullfile(current_dir,'..','src')};
                buildInfo.addSourcePaths(srcPaths);
                
                % add the source files
                srcFiles = {'SPI.cpp','Wire.cpp', 'twi.c', 'I2Cdev.cpp', 'QMC5883.cpp', 'QMC5883wrapper.cpp'};
                buildInfo.addSourceFiles(srcFiles);
                
            end
        end
    end
end
