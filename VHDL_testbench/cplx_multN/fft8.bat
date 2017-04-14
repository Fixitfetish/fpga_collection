@echo off
:: create work directory
if not exist work\ (
  mkdir work
)
:: create output directory
if not exist output\ (
  mkdir output
)

:: GHDL compiler settings
set VCOM_EXE=%GHDL_PATH%\bin\ghdl.exe
set VCOM_FLAGS=-a --std=93 --workdir=work -Pwork --work=
set COMPILE=%VCOM_EXE% %VCOM_FLAGS%

:: GHDL simulator settings
set VSIM_EXE=%GHDL_PATH%\bin\ghdl.exe
set VSIM_FLAGS=-r --std=93 --workdir=work -Pwork
set SIMULATE=%VSIM_EXE% %VSIM_FLAGS%

:: Waveform viewer
set GTKWAVE=%GTKWAVE_PATH%\bin\gtkwave

:: waveform file
set VCD=output\fft8.vcd
if exist %VCD% (
  del %VCD%
)

set BASEPATH=..\..\VHDL

:: analyze files of fixitfetish library
set LIB=fixitfetish
@echo on
%COMPILE%%LIB% %BASEPATH%\string_conversion_pkg.vhdl
@call %BASEPATH%\dsp\compile.bat
@call %BASEPATH%\dsp\behave\compile.bat
@call %BASEPATH%\cplx\compile.bat

:: analyze testbench
@echo.--------------------------------------------------------------------------
@echo.INFO: Start compiling testbench ...
@set LIB=work
%COMPILE%%LIB% ..\cplx_logger4.vhdl
%COMPILE%%LIB% dftmtx8.vhdl
%COMPILE%%LIB% fft8_v1.vhdl
%COMPILE%%LIB% ifft8_v1.vhdl
%COMPILE%%LIB% fft8_tb.vhdl

@pause

:: run testbench
@echo.--------------------------------------------------------------------------
@echo.INFO: Starting simulation ...
%SIMULATE% fft8_tb --stop-time=500ns --vcd=%VCD%

@pause
@goto END

:: start waveform viewer
::@if not exist %VCD% goto END
::%GTKWAVE% %VCD% fft8.gtkw

:END