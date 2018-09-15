classdef so_float2bytes < matlab.System & coder.ExternalDependency
    % sofloat2bytes
    % This class will be used to extract the bytes of a single/float
    % for serial transmission
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
                %  jlh coder.cinclude('MPU6050wrapper.h');
                % initialize the sensor
                % jlh coder.ceval('MPU6050Accel_Init');
            elseif ( coder.target('Sfun') )
                %
            end
        end

        function [out] = stepImpl(obj,fin)
            % initialize output to a single (float) with the value zero
            out = uint8(zeros(4,1));
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('float2bytes.h');
                % get the current value of the sensor
                % coder.ceval('float2bytes', coder.wref(out), fin);
				coder.ceval('float2bytes', coder.wref(out), fin);
            elseif ( coder.target('Sfun') )
                %
            end
            % pull the data appart
            % xvel = out(1);
            % yvel = out(2);
            % zvel = out(3);
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
            name = 'Vel';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        % Update the build-time buildInfo
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')                
                % Update buildInfo
                rootDir = fullfile(fileparts(mfilename('fullpath')),'..','src')
                buildInfo.addIncludePaths(rootDir);
                buildInfo.addIncludePaths(fullfile(fileparts(mfilename('fullpath')),'..','include'));
				buildInfo.addIncludeFiles('float2bytes.h');
                buildInfo.addSourceFiles('float2bytes.cpp',rootDir);          
            end
        end
    end
end
