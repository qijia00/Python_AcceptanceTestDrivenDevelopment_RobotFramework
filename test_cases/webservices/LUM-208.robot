*** Settings ***
Library         WebServiceLibrary

*** Test Cases ***
Create a new site on master ecu
    Connect to web services   ${IP}   ${user}   ${def_pass}
    Create new site   ${new_site}
    Get database information
    Bring ecu into site   ${IP}
    Get offsets   SITE0   1

Bring a slave ECU onto the site
    Connect to web services   ${slave_IP}   ${user}   ${def_pass}
    Bring ecu into site   ${IP}   OFFSET0

Validate user login from master
    Connect to web services   ${IP}   ${user}   ${pass}
    Logout

Validate user login from slave
    Connect to web services   ${slave_IP}   ${user}   ${pass}
    Logout


*** Variables ***
${IP}   ecu1.localecu
${slave_IP}   ecu2.localecu
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   3nc31ium

${new_site}   SEPARATOR=\n
...     {
...         "name": "Site management test",
...         "version": "Version 4.0.0",
...         "customer": "QA",
...         "project": "Robot",
...         "author": "Alex",
...         "default": true,
...         "date": "06/29/2017 9:54:00 AM",
...         "username": "${user}",
...         "password": "${pass}",
...         "fullname": "System Administrator",
...         "site-type": "lumenade"
...     }

