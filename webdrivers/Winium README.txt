Winium webdriver must be called from the root directory of the application to be tested
and not from this directory.  If Winium is called from this directory, it is possible that
there might be some conflicts with permissions and/or webdriver quirks.

For example, if Polaris to be tested and it is located at "C:\Projects\Polaris4\Encelium.Ecs
\Polaris\Polaris\bin\Debug", call the Winium executable from this directory through command
line.

C:\Projects\Automation\core\webdrivers\Winium.Desktop.Driver.exe --verbose