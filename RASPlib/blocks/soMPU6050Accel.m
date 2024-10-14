classdef soMPU6050Accel < matlab.System & coder.ExternalDependency
    % soMPU6050Accel
    % This class will be used to read the state of the accel
    %
    
    %#codegen
    %#ok<*EMCA>
    
%     properties (Nontunable)
% 
%     end
%     properties (Hidden,Transient,Constant)
% 
%         
%     end

%     properties (Hidden)
% %         % keeps track of the selected Potentiometer
% %         potNum = 0;
% %         % simSampleNum - tracks which sample we are on in a simulation
% %         simSampleNum = 0;
%     end
    
%     methods
%     end

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

        function [xaccel,yaccel,zaccel] = stepImpl(obj)
            % initialize output to a single (float) with the value zero
             out = int16(zeros(3,1));
            if (coder.target('Rtw'))% done only for code gen
                coder.cinclude('MPU6050wrapper.h');
                % get the current value of the sensor
                coder.ceval('MPU6050Accel_Read', coder.wref(out));
            elseif ( coder.target('Sfun') )
                %
            end
            % pull the data appart
            xaccel = out(1);
            yaccel = out(2);
            zaccel = out(3);

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
                % Add include paths and source files for code generation
                                
                % determine path to arduino IDE

                 try %%codertarget.target.isCoderTarget(buildInfo.ModelName)
%                     % we are in 15b
                     [~, hardwaredir] = codertarget.arduinobase.internal.getArduinoIDERoot('hardware');
                     if(strfind(hardwaredir,'aCLI')),disp('New aCLI library structure');librarydir = fullfile(hardwaredir, 'avr', '1.8.3', 'libraries');else,librarydir = fullfile(hardwaredir, 'arduino', 'avr' , 'libraries');end
                 catch
                    % we are pre 15b
                    [~, hardwaredir] = realtime.internal.getArduinoIDERoot('hardware');
                    librarydir = fullfile(hardwaredir, '..', 'libraries');
                 end
                
                % get current directory path
                src_dir = mfilename('fullpath');
                [current_dir] = fileparts(src_dir);
                
                % add the include paths
                buildInfo.addIncludePaths(fullfile(librarydir, 'Wire'));
                if(exist(fullfile(librarydir, 'Wire','utility'))),buildInfo.addIncludePaths(fullfile(librarydir, 'Wire','utility')); end
                buildInfo.addIncludePaths(fullfile(current_dir,'..','include'));
                % 2017a new arduino paths:
                buildInfo.addIncludePaths(fullfile(librarydir, 'Wire','src'));
                if(exist(fullfile(librarydir, 'Wire','src','utility'))),buildInfo.addIncludePaths(fullfile(librarydir, 'Wire','src','utility'));end
                
				% 2017a new arduino paths:
                %fullfile(librarydir, 'Wire','src'),...
                %fullfile(librarydir, 'Wire','src','utility'),...
				
                % add the source paths
%                 srcPaths = {...
%                     fullfile(librarydir, 'Wire'), ...
%                     fullfile(librarydir, 'Wire', 'utility'),...
%                     fullfile(librarydir, 'Wire','src'),...
%                     fullfile(librarydir, 'Wire','src','utility'),...
%                     fullfile(current_dir,'..','src')};
%                 buildInfo.addSourcePaths(srcPaths);
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
