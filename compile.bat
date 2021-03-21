@echo off

rem compile C source file with the name and config given below into NES file


set source="nyan"
set config="nrom_256_horz.cfg"



set CC65_HOME=..\

if "%PATH%"=="%PATH:cc65=%" @PATH=%PATH%;%CC65_HOME%bin\

ca65 crt0.s -Ift_drv || goto fail

cc65 -Oi %source%.c --add-source || goto fail

ca65 %source%.s || goto fail

ld65 -C %config% -o %source%.nes crt0.o %source%.o runtime.lib || goto fail

fceux.exe -pal 1 %source%.nes

goto exit

:fail

pause

:exit

del %source%.s
del *.o