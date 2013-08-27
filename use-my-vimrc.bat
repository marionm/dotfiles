@ECHO off
xcopy /s/e/Y %USERPROFILE%\vimfiles %USERPROFILE%\vimfiles-orig\
copy %USERPROFILE%\_vimrc %USERPROFILE%\_vimrc-orig

del /q %USERPROFILE%\vimfiles
del %USERPROFILE%\_vimrc

xcopy /s/e/Y .vim %USERPROFILE%\vimfiles\
copy /Y .vimrc %USERPROFILE%\_vimrc
