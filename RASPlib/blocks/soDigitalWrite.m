classdef soDigitalWrite < matlab.System ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.CustomIcon
    %
    % Set the logical state of an analog pin as a digital output pin.
    %
    
    
    
    
    % Copyright 2014 The MathWorks, Inc.
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        Pin = 3 % Digital Pin
    end
    
    properties (Constant, Hidden)
        % AvailablePin specifies the range of values allowed for Pin. You
        % can customize the AvailablePin for a particular board. For
        % example, use AvailablePin = 2:13 for Arduino Uno.
        AvailablePin = 0:63;
    end
    
    methods
        % Constructor
        function obj = soDAnalogWrite(varargin)
            coder.allowpcode('plain');
            
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.Pin(obj,value)
            coder.extrinsic('sprintf') % Do not generate code for sprintf
            validateattributes(value,...
                {'numeric'},...
                {'real', 'positive', 'integer','scalar'},...
                '', ...
                'Pin');
            assert(any(value == obj.AvailablePin), ...
                'Invalid value for Pin. Pin must be one of the following: %s', ...
                sprintf('%d ', obj.AvailablePin));
            obj.Pin = value;
        end
    end
    
    methods (Access=protected)
        function setupImpl(obj)
            if coder.target('Rtw')
                %coder.cinclude('digitalio_arduino.h');
                coder.ceval('digitalIOSetup', obj.Pin, 1);  % analog # are analog pin # + 54 for mega
            end
        end
        
        function stepImpl(obj,u)
            if coder.target('Rtw')
                coder.ceval('writeDigitalPin', obj.Pin, u);  % analog # are analog pin # + 54 for mega  %writeDigitalPin
            end
        end
        
        function releaseImpl(obj) %#ok<MANU>
        end
    end
    
    methods (Access=protected)
        %% Define input properties
        function num = getNumInputsImpl(~)
            num = 1;
        end
        
        function num = getNumOutputsImpl(~)
            num = 0;
        end
        
        function flag = isInputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isInputFixedSizeImpl(~,~)
            varargout{1} = true;
        end
        
        function flag = isInputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isInputComplexImpl(~)
            varargout{1} = false;
        end
        
        function validateInputsImpl(~, u)
            if isempty(coder.target)
                % Run this always in Simulation
                % validateattributes(u,{'logical','double','uint8'},{'scalar','binary'},'','u');
            end
        end
        
        function icon = getIconImpl(~)
            % Define a string as the icon for the System block in Simulink.
            icon = 'Digital Write';
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
            name = 'Digital Write';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Update buildInfo
                rootDir = fullfile(fileparts(mfilename('fullpath')),'..','src');
                buildInfo.addIncludePaths(rootDir);
				buildInfo.addIncludePaths(fullfile(fileparts(mfilename('fullpath')),'..','include'));

				% 2016b or later - fine the installed arduino library directory to use the source files in that location
                ard_lib=which('arduinorootlib');V=strfind(ard_lib, 'R20');ver=ard_lib(V:V+5);veryr=ver(2:5);
				%is2016b=~isempty(strmatch(ver,'R2016b'));  % version is 2016b
                is2016b=(strcmp(ver,'R2016b'));            % version is 2016b
                is2016plus=str2num(veryr)>=2017;           % version is 2017a or later
                if(is2016b||is2016plus) %  version is 2016b or later
					file_seps=strfind(ard_lib, filesep);% fullfile(ard_lib(1:file_seps(end-1)))
					buildInfo.addSourceFiles('MW_digitalio.cpp',fullfile(ard_lib(1:file_seps(end-1)), 'src'));
					buildInfo.addIncludeFiles('MW_digitalio.h');
				else
					buildInfo.addIncludeFiles('digitalio_arduino.h');
					buildInfo.addSourceFiles('digitalio_arduino.cpp',rootDir);
				end

            
            end
        end
    end
end
