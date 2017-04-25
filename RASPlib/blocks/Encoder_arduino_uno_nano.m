classdef Encoder_arduino_uno_nano < matlab.System ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.CustomIcon 
    %
    % Read the position of a quadrature encoder.  Encoder 0: pins 1 & 2 (reverse pins to reverse direction recorded). Encoder 1: pins 18 & 19.  Encoder 2: "pins" value of 6, 7 corresponding to interrupts 6 and 7 (minsegmega).  Encoder 3: pins 15 & 62 corresponding to interrupts for digital pin 15 and analog pin 8. Select the PWM frequency based on the timer for the motor driver pin.  Timer 1: pins 11, 12, Timer 2: pins 9, 10, Timer 3: pins 2, 3, 5, Timer 4: pins 6, 7, 8, Timer 5: pins 44, 45, 46.  Does not do Timer 0: pins 4, 13, since timer 0 affects major timing events.Frequency Selection: 1, 2, 3, 4, 5 coresponds to divisor 1, 8, 64, 256, 1024 corresponding to approximate frequiencies 32000Hz, 4000KHz, 490Hz, 122Hz, 30Hzx. Timer selection -1 makes no changes to PWM timers.
    
    %
    %
    %
    %
    
    % Copyright 2014 The MathWorks, Inc.
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        Encoder = 0
        PinA = 2
        PinB = 3
%         PWMFSelect = 1; % PWM Frequency Selector
%         PWMTimer=3;     % Timer selection
    end
    
    properties (Constant, Hidden)
        % AvailablePin specifies the range of values allowed for Pin. You
        % can customize the AvailablePin for a particular board. For
        % example, use AvailablePin = 2:13 for Arduino Uno.
        AvailablePin = 0:69;  % 0-53 digital pins 54-69 are analog pins
        MaxNumEncoder = 4
    end
    
    methods
        % Constructor
        function obj = Encoder_arduino_uno_nano(varargin)
            coder.allowpcode('plain');
            
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.PinA(obj,value)
            coder.extrinsic('sprintf') % Do not generate code for sprintf
            validateattributes(value,...
                {'numeric'},...
                {'real','nonnegative','integer','scalar'},...
                '', ...
                'PinA');
            assert(any(value == obj.AvailablePin), ...
                'Invalid value for Pin. Pin must be one of the following: %s', ...
                sprintf('%d ', obj.AvailablePin));
            obj.PinA = value;
        end
        
        function set.PinB(obj,value)
            coder.extrinsic('sprintf') % Do not generate code for sprintf
            validateattributes(value,...
                {'numeric'},...
                {'real','nonnegative','integer','scalar'},...
                '', ...
                'PinB');
            assert(any(value == obj.AvailablePin), ...
                'Invalid value for Pin. Pin must be one of the following: %s', ...
                sprintf('%d ', obj.AvailablePin));
            obj.PinB = value;
        end
        
        function set.Encoder(obj,value)
            validateattributes(value,...
                {'numeric'},...
                {'real','nonnegative','integer','scalar','>=',0,'<=',obj.MaxNumEncoder},...
                '', ...
                'Encoder');
            obj.Encoder = value;
        end
        
%         % Constructor
%         function obj = soPWMFSelect(varargin)
%             coder.allowpcode('plain');
%             
%             % Support name-value pair arguments when constructing the object.
%             setProperties(obj,nargin,varargin{:});
%         end
%         
%         function set.PWMFSelect(obj,value)
%             coder.extrinsic('sprintf') % Do not generate code for sprintf
%             validateattributes(value,...
%                 {'numeric'},...
%                 {'real', 'positive', 'integer','scalar'},...
%                 '', ...
%                 'PWMFSelect');
%             obj.PWMFSelect = value;
%         end
%         
%         function set.PWMTimer(obj,value)
%             coder.extrinsic('sprintf') % Do not generate code for sprintf
%             validateattributes(value,...
%                 {'numeric'},...
%                 {'real', 'integer','scalar'},...
%                 '', ...
%                 'PWMTimer');
%             obj.PWMTimer = value;
%         end
    end
    
    methods (Access=protected)
        function setupImpl(obj)
            if coder.target('Rtw')
                %   Call: void enc_init(int enc, int pinA, int pinB)
                coder.cinclude('encoder_arduino.h');
                coder.ceval('enc_init', obj.Encoder, obj.PinA, obj.PinB);
%                 if(obj.PWMTimer> 0)
%                     coder.cinclude('PWMFSelect.h');
%                     coder.ceval('PWM_Select', obj.PWMFSelect, obj.PWMTimer);
%                     disp('skipp!!!')
%                 end
            end
        end
        
        function y = stepImpl(obj)
            y = int32(0);
            if coder.target('Rtw')
                % Call: int enc_output(int enc)
                y = coder.ceval('enc_output', obj.Encoder);
            end
        end
        
        function releaseImpl(obj) %#ok<MANU>
        end
    end
    
	
    methods (Access=protected)
        %% Define output properties
        function num = getNumInputsImpl(~)
            num = 0;
        end
        
        function num = getNumOutputsImpl(~)
            num = 1;
        end
        
        function flag = isOutputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputFixedSizeImpl(~,~)
            varargout{1} = true;
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputComplexImpl(~)
            varargout{1} = false;
        end
        
        function varargout = getOutputSizeImpl(~)
            varargout{1} = [1,1];
        end
        
        function varargout = getOutputDataTypeImpl(~)
            varargout{1} = 'int32';
        end
        
        function icon = getIconImpl(~)
            % Define a string as the icon for the System block in Simulink.
            icon = 'soEncoder';
        end
    end
    
    
    % abc defg gggggggg
    
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
            name = 'Encoder';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                %  Update buildInfo
                rootDir = fullfile(fileparts(mfilename('fullpath')),'..','src')
                buildInfo.addIncludePaths(rootDir);
                buildInfo.addIncludePaths(fullfile(fileparts(mfilename('fullpath')),'..','include'));
				buildInfo.addIncludeFiles('encoder_arduino.h');
                buildInfo.addSourceFiles('encoder_arduino_uno_nano.cpp',rootDir);
                %buildInfo.addIncludeFiles('PWMFSelect.h');
                %buildInfo.addSourceFiles('PWMFSelect.cpp',rootDir);
            end
        end
    end
end