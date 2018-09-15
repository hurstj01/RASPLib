classdef soHMC5883L < matlab.System & coder.ExternalDependency
    % soHMC5883L
    % This class will be used to read the state of the gyro
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
        % Constructor
        function obj = soHMC5883L(varargin)
            coder.allowpcode('plain');
            
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
    end

    methods (Access = protected)
        function setupImpl(obj)
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('HMC58X3wrapper.h');
                % initialize the sensor
                coder.ceval('HMC58X3_Init');
            elseif ( coder.target('Sfun') )
                %
            end
        end

        function [xmag,ymag,zmag] = stepImpl(obj)
            % initialize output to a single (float) with the value zero
            out = single(zeros(3,1));
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('HMC58X3wrapper.h');
                % get the current value of the sensor
                coder.ceval('HMC58X3_Read', coder.wref(out));
            elseif ( coder.target('Sfun') )
                %
            end
            % pull the data appart
            xmag = out(1);
            ymag = out(2);
            zmag = out(3);
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
            name = 'Mag';
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
                srcFiles = {'Wire.cpp', 'twi.c', 'I2Cdev.cpp', 'HMC58X3.cpp', 'HMC58X3wrapper.cpp'};
                buildInfo.addSourceFiles(srcFiles);
                
            end
        end
    end
end
