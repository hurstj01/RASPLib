classdef PWMselect_uno_nano < matlab.System ... % Inherits from matlab.System
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.CustomIcon
    %
    %Selects the ATmega328P PWM frequency based on the timer for the pin.  Timer 1: pins 9, 10, Timer 2: pins 3, 11.  Does not do Timer 0: pins 5, 6, since timer 0 affects major timing events.Frequency Selection: 1, 2, 3, 4, 5 coresponds to divisor 1, 8, 64, 256, 1024 corresponding to approximate frequiencies 32000Hz, 4000KHz, 490Hz, 122Hz, 30Hz.  Sample time should be left to 0 so it will be sampled only once, since this block only effects initization.   
    % 
    % abcs
    
    % Copyright 2014 The MathWorks, Inc.
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        PWMFSelect = 1; % PWM Frequency Selector
        PWMTimer=3;     % Timer selection
    end
 
    methods
        % Constructor
        function obj = soPWMFSelect(varargin)
            coder.allowpcode('plain');
            
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.PWMFSelect(obj,value)
            coder.extrinsic('sprintf') % Do not generate code for sprintf
            validateattributes(value,...
                {'numeric'},...
                {'real', 'positive', 'integer','scalar'},...
                '', ...
                'PWMFSelect');
            
            obj.PWMFSelect = value;
        end
        
        function set.PWMTimer(obj,value)
            coder.extrinsic('sprintf') % Do not generate code for sprintf
            validateattributes(value,...
                {'numeric'},...
                {'real', 'positive', 'integer','scalar'},...
                '', ...
                'PWMTimer')
            obj.PWMTimer = value;
        end
        
    end
    
    methods (Access=protected)
        function setupImpl(obj)

            if coder.target('Rtw')
                coder.cinclude('PWMFSelect.h');
                coder.ceval('PWM_Select', obj.PWMFSelect, obj.PWMTimer);
            end
        end
        
        function y=stepImpl(obj)
           y = true;
        end
        
        
        function releaseImpl(obj) %#ok<MANU>
        end
    end
    
    methods (Access=protected)

        function num = getNumInputsImpl(~)
            num = 0;
        end
        
        %% Define output properties
        
        function num = getNumOutputsImpl(~)
            num = 1;
        end
        
        function flag = isOutputSizeLockedImpl(~,~)
            flag = false;
        end
        
        function varargout = isOutputFixedSizeImpl(~,~)
            varargout{1}= true;
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = false;
        end
        
        function varargout = isOutputComplexImpl(~)
            varargout{1} = false;
        end
         
        function varargout = getOutputSizeImpl(~)
            varargout{1} = 1;
        end
         
        function varargout = getOutputDataTypeImpl(~)
            varargout{1} = 'logical';
        end
        
        function icon = getIconImpl(~)
            % Define a string as the icon for the System block in Simulink.
            icon = 'ATmega328P PWM Frequency Select';
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
            name = 'ATmega328P PWM Frequency Select';
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
                buildInfo.addIncludeFiles('PWMFSelect.h');
                buildInfo.addSourceFiles('PWMFSelect_uno_nano.cpp',rootDir);
            end
        end
    end
end
