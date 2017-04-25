function blkStruct = slblocks
  % Specify that the product should appear in the library browser
  % and be cached in its repository
  
  blkStruct.OpenFcn  = 'RASPlib';
  blkStruct.MaskDisplay = '';

  Browser(1).Library = 'RASPlib';
  Browser(1).Name    = 'Rensselaer Arduino Support Package';
  %Browser(1).Type       = 'Palette';
  %Browser(1).Children   = { 'MinSegLibrary_M1V4',...% ...
  %                          'MinSeg Common Blocks'};  % and so on
  
  blkStruct.Browser = Browser;