from java.io import FileInputStream
import java.lang
import os
import string

propInputStream = FileInputStream("server.properties")
configProps = Properties()
configProps.load(propInputStream)

ServerUrl = configProps.get("admin.url")
UserName = configProps.get("admin.username")
Password = configProps.get("admin.password")
ServerName = configProps.get("server.name")
DomainName = configProps.get("domain.name")

#############  This method would send the Alert Email  #################
def sendMailString():
        os.system('/usr/bin/mailx -s  ""'+ ServerName +'"("'+ DomainName +'"): Applications are currently NOT in ACTIVE state" -r "WebSphere App Server Admin <SE-WAS-ADMIN-dl@jcp.com>" < currentAppState_file')
        print '*********  ALERT MAIL HAS BEEN SENT  ***********'

redirect('appStateCheck.log','false')
connect(UserName,Password,ServerUrl)
cd ('AppDeployments')
myapps=cmo.getAppDeployments()
print '=============================================='
print 'Following Applications are not in STATE_ACTIVE'
print '=============================================='
for appName in myapps:
        domainConfig()
        cd ('/AppDeployments/'+appName.getName()+'/Targets')
        mytargets = ls(returnMap='true')
        domainRuntime()
        cd('AppRuntimeStateRuntime/AppRuntimeStateRuntime')
        for targetinst in mytargets:
                currentAppState=cmo.getCurrentState(appName.getName(),targetinst)
                if currentAppState != "STATE_ACTIVE":
                        writeInFile ='Application = "'+ appName.getName() +'"  //      Managed Server = "'+str(mytargets)+'"  //       Current STATE = "'+ currentAppState +'"'
                        print '', writeInFile
                        cmd = "echo " + writeInFile + " >> currentAppState_file"
                        os.system(cmd)
print '=============================================='
print''
sendMailString()
cmd = "rm -f appStateCheck.log currentAppState_file"
os.system(cmd)
~
~
