set TARS="tarsAdminRegistry,tarsconfig,tarslog,tarsnode,tarsnotify,tarspatch,tarsproperty,tarsqueryproperty,tarsquerystat,tarsregistry,tarsstat"

:loop

@echo off
for /f "Tokens=1,* Delims=," %%a in (%TARS%) do (

    call TARS_PATH\%%a\util\stop.bat
  
    set TARS="%%b"

    goto :loop
)

call pm2 stop tars-node-web
call pm2 stop tars-user-system
