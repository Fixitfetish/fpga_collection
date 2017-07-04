@echo off

set LIBROOT=..\..

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
set VCD=output\sincos.vcd
if exist %VCD% (
  del %VCD%
)

:: analyze library files
@call %LIBROOT%\baselib\_compile.bat
@call %LIBROOT%\siglib\_compile.bat

:: analyze testbench
@echo.--------------------------------------------------------------------------
@echo.INFO: Starting to compile the testbench ...

@echo on
@set LIB=cplxlib
%COMPILE%%LIB% %LIBROOT%\cplxlib\cplx_pkg_1993.vhdl

@set LIB=work
%COMPILE%%LIB% %LIBROOT%\cplxlib_tb\cplx_logger.vhdl
%COMPILE%%LIB% sincos_tb.vhdl

@echo.
@echo.INFO: Compilation finished - ready to start simulation. 
@pause

:: run testbench
@echo.--------------------------------------------------------------------------
@echo.INFO: Starting simulation ...
%SIMULATE% sincos_tb --vcd=%VCD%
@echo.INFO: Simulation finished.

@pause
@goto END

:: start waveform viewer
::@if not exist %VCD% goto END
::%GTKWAVE% %VCD% sincos.gtkw

:END