@echo off
color 0F

set n=^&echo.
set SERVER=ftp.batchatssl.hol.es
set USER=u700106098
set PASS=gmR6NE8pgkNO
set FORMAT=binary
set ROOM=room
set SCRIPT=server
if exist cuenta\usuario.txt set /p USRNAME=<cuenta/usuario.txt

:inicio
if "%1"=="" goto sin_argumentos
if "%2"=="" goto un_argumento
::dos argumentos
goto %~1
:un_argumento
goto %~1

:sin_argumentos
cls
echo  ************************************************************************
echo  *   ***      ****    ********     ********       Novus Ordo Seclorum   *
echo  *   ****     ****   ***   ****   ****   ****       (criptonomicon)     *
echo  *   ******   ***    ***  *****   *****              SSL Messenger      *
echo  *   ******** ***    *** ******    *********                            *
echo  *   *** ********    ****** ***         *****                           *
echo  *   ***   ******    *****  ***   ****   ****           By: CMD         *
echo  *   ***     ****     ********      ********                            *
echo  ************************************************************************
echo.
echo  use "nos list" para listar todos los usuario registrados en el room
echo  use "nos read list" para ver la lista de mensajes recibidos
echo  use "nos read <usuario>" para ver el ultimo mensaje recibidos de parte de un usuario
echo  use "nos init <usuario>" para generar nuevas credenciales
echo  use "nos send <usuario>" para enviar un mensaje a un usuario
echo  use "nos reset" para eliminar toda la informacion del programa
echo.
goto eof

:list
::listar todos los usuarios del room
:: ls . listing
echo %USER%>%SCRIPT%
echo %PASS%>>%SCRIPT%
echo %FORMAT%>>%SCRIPT%
echo cd %ROOM%>>%SCRIPT%
echo ls . listing>>%SCRIPT%
echo close%n%bye>>%SCRIPT%
ftp -i -s:%SCRIPT% %SERVER% 
del %SCRIPT%
cls
echo.
echo Usuarios registrados en el room:
type listing
echo.
del listing
goto eof

:init
::borrar viejo
if exist cuenta\nul goto borrar_cuenta
:continuar_borar_cuenta
::crear nuevo
goto setup_llaves
:continuar_llaves
mkdir cuenta
cd cuenta
echo %2>usuario.txt
cd ..
set /p USRNAME=<cuenta/usuario.txt
echo %USER%>%SCRIPT%
echo %PASS%>>%SCRIPT%
echo %FORMAT%>>%SCRIPT%
echo cd %ROOM%>>%SCRIPT%
echo mkdir %USRNAME%>>%SCRIPT%
echo cd %USRNAME%>>%SCRIPT%
echo put keys/publica.key %USRNAME%.key>>%SCRIPT%
echo close%n%bye>>%SCRIPT%
ftp -i -s:%SCRIPT% %SERVER% 
del %SCRIPT%
goto eof

:read
if not exist entrada\nul mkdir entrada
if not exist keys\privada.key goto error_llaves_read
if exist temp\nul rmdir /S /Q temp
mkdir temp
::leer el mensaje de un usuario
::descargar mensajes
echo %USER%>%SCRIPT%
echo %PASS%>>%SCRIPT%
echo %FORMAT%>>%SCRIPT%
echo cd %ROOM%>>%SCRIPT%
echo cd %USRNAME%>>%SCRIPT%
if "%2"=="list" goto lista_entradas
echo get %2.txt entrada/%2.txt>>%SCRIPT%
echo close%n%bye>>%SCRIPT%
ftp -i -s:%SCRIPT% %SERVER% 
del %SCRIPT%
cls
openssl rsautl -decrypt -inkey keys/privada.key -in entrada/%2.txt -out temp/salida.dec
rmdir /S /Q entrada
cd temp
type salida.dec
echo.
cd ..
rmdir /S /Q temp
goto eof

:lista_entradas
echo ls *.txt temp/log.txt>>%SCRIPT%
echo close%n%bye>>%SCRIPT%
ftp -i -s:%SCRIPT% %SERVER% 
del %SCRIPT%
::imprimir
cls
echo Nuevos mensajes de:
cd temp
type log.txt
cd ..
rmdir /S /Q entrada
rmdir /S /Q temp
goto eof

:send
echo mensaje para %2
color a
cls
echo Para terminar el mensaje usa [CTRL]+[Z] y presiona la tecla [Enter].
set file=%USRNAME%.txt
copy con %file%
color 0F
::enviar
::echo comprobando llaves
if not exist keys\nul mkdir keys
if not exist keys\privada.key goto error_llaves
if not exist keys\publica.key goto error_llaves
:continuar_llaves
::echo generando ficheros temporales
if exist temp\nul rmdir /S /Q temp
mkdir temp
if exist salida\nul rmdir /S /Q salida
mkdir salida
::echo %~1> temp/m.txt
copy %USRNAME%.txt temp
del %USRNAME%.txt
echo %USER%>%SCRIPT%
echo %PASS%>>%SCRIPT%
echo %FORMAT%>>%SCRIPT%
echo cd %ROOM%>>%SCRIPT%
echo cd %2>>%SCRIPT%
echo get %2.key temp/%2.key>>%SCRIPT%
echo close%n%bye>>%SCRIPT%
ftp -i -s:%SCRIPT% %SERVER% 
del %SCRIPT%
echo mensaje:
cd temp
type %USRNAME%.txt
cd ..
openssl rsautl -pubin -encrypt -in temp/%USRNAME%.txt -out salida/%USRNAME%.txt -inkey temp/%2.key
::echo Ok, mensaje cifrado
rmdir /S /Q temp
::enviar
move %USRNAME%.txt temp/%USRNAME%.txt
echo %USER%>%SCRIPT%
echo %PASS%>>%SCRIPT%
echo %FORMAT%>>%SCRIPT%
echo cd %ROOM%>>%SCRIPT%
echo cd %2>>%SCRIPT%
echo put salida\%USRNAME%.txt>>%SCRIPT%
echo close%n%bye>>%SCRIPT%
ftp -i -s:%SCRIPT% %SERVER% 
del %SCRIPT%
rmdir /S /Q salida
goto eof

:borrar_cuenta
echo %USER%>%SCRIPT%
echo %PASS%>>%SCRIPT%
echo %FORMAT%>>%SCRIPT%
echo cd %ROOM%>>%SCRIPT%
echo mdelete  %USRNAME%/*>>%SCRIPT%
echo rmdir %USRNAME%>>%SCRIPT%
echo close%n%bye>>%SCRIPT%
ftp -i -s:%SCRIPT% %SERVER% 
del %SCRIPT%
rmdir /S /Q cuenta
goto continuar_borar_cuenta

:setup_llaves
if exist keys\nul rmdir /S /Q keys
mkdir keys
openssl genrsa -out keys/privada.key 4096
if not exist keys\privada.key goto error_al_crear_llave
openssl rsa -in keys/privada.key -pubout -out keys/publica.key
if not exist keys\publica.key goto error_al_crear_llave
goto continuar_llaves

:error_llaves
cls
echo Error, no existen llaves para el cifrado
set /p r=desea generar las llaves ahora? (s/n)
if /I "%r%"=="s" goto setup_llaves
goto eof

:error_al_crear_llave
echo Error, no se pudo crear la llave
goto eof

:error_llaves_read
echo Error, no existen llaves para descifrar el archivo
goto eof

:reset
if exist temp\nul rmdir /S /Q temp
if exist keys\nul rmdir /S /Q keys
if exist salida\nul rmdir /S /Q salida
if exist entrada\nul rmdir /S /Q entrada
goto eof

:eof