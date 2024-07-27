@echo off
REM ****************************************************************************
REM Vivado (TM) v2019.2 (64-bit)
REM
REM Filename    : simulate.bat
REM Simulator   : Xilinx Vivado Simulator
REM Description : Script for simulating the design by launching the simulator
REM
REM Generated by Vivado on Sat Jul 27 17:23:09 +0800 2024
REM SW Build 2708876 on Wed Nov  6 21:40:23 MST 2019
REM
REM Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
REM
REM usage: simulate.bat
REM
REM ****************************************************************************
echo "xsim tb_time_synth -key {Post-Synthesis:sim_1:Timing:tb} -tclbatch tb.tcl -view C:/Users/DELL/Desktop/2024170/tb_behav1.wcfg -log simulate.log"
call xsim  tb_time_synth -key {Post-Synthesis:sim_1:Timing:tb} -tclbatch tb.tcl -view C:/Users/DELL/Desktop/2024170/tb_behav1.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
