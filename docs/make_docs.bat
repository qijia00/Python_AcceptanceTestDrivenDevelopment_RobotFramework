SETLOCAL
SET PYTHONPATH=%PYTHONPATH%;%cd%\..\ecu_tools\ECU_Properties\generatedcode\tools

FOR /d %%d IN (../src/*) DO (
	ECHO Processing %%d
	python -m robot.libdoc ../src/%%d %%d.html
)

ENDLOCAL