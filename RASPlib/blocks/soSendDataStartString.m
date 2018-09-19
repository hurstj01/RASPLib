classdef soSendDataStartString < realtime.internal.SourceSampleTime ... % Inherits from matlab.System
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.CustomIcon
    %
    %Send a data string at serial connection to allow sychronization of data.  Sends "***Data Start***" at the beginning of data transmission so the SerialPlot block can sychronize data  
    % 
    % abcs
    
    % Copyright 2014 The MathWorks, Inc.
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        % PWMFSelect = 1; % PWM Frequency Selector
        % PWMTimer=3;     % Timer selection
    end
    
    
    properties (Constant, Hidden)
        % AvailablePin specifies the range of values allowed for Pin. You
        % can customize the AvailablePin for a particular board. For
        % example, use AvailablePin = 2:13 for Arduino Uno.
        AvailablePin = 0:53;
    end
    
    methods
        % Constructor
        function obj = soSendDataStartString(varargin)
            coder.allowpcode('plain');
            
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end

    end
    
    methods (Access=protected)
        function setupImpl(obj)

            if coder.target('Rtw')
                coder.cinclude('DataStartString.h');
                coder.ceval('Send_Data_Start_String');
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
            icon = 'Send Data Start String';
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
            name = 'Send Data Start String';
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
                buildInfo.addIncludeFiles('DataStartString.h');
                buildInfo.addSourceFiles('DataStartString.cpp',rootDir);
            end
        end
    end
end
