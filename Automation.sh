#! /bin/bash

#JWT login

# Key Variables

HUBORG="dxpilot+anbalagan.elangovan@accenture.com"
CONNECTED_APP_CONSUMER_KEY="3MVG9YDQS5WtC11pWi_GyYnepWRkE5ksP1pQSaX.HxQtZbrwGGLuGJXiKfgFtlXsKTR4.eAubAB33.47sd9_p"
SFDC_HOST="https://login.salesforce.com"
KEY_FILE="C:\Anbu\Innovation\SalesforceDX\Pilot\server.key"

# HUB Org Authorization

echo "Authorizing Hub Org..."

sfdx force:auth:jwt:grant --clientid ${CONNECTED_APP_CONSUMER_KEY} --username ${HUBORG} --jwtkeyfile ${KEY_FILE}  --setdefaultdevhubusername --instanceurl ${SFDC_HOST}
if [ $? -eq 0 ]; then
	echo "Successfully Authorized the Hub Org"
else
	echo "Problem Authorizing the Hub Org" >&2
	exit 1
fi

# Scratch Org Creation

echo "Creating Scratch Org..."

created="$(sfdx force:org:create --definitionfile config/workspace-org-def.json --json --setdefaultusername)"

if [ $? -ne 0 ]; then
echo "Scratch Org Creation Failed." 
exit 1
fi

echo $created

orgId="$(echo ${created} | jq -r .orgId)"
username="$(echo ${created} | jq -r .username)"
echo "User Name is: "
echo  ${username}

# Push the code to Scratch Org
echo -n
echo -n "Pushing Components to Scratch Org..."
sfdx force:source:push --targetusername ${username}
if [ $? -ne 0 ]; then
echo "Push Failed" 
exit 1
fi

# Assign Permission Set

echo "Assigning Permission Set..."


sfdx force:user:permset:assign --targetusername ${username} --permsetname DreamHouse
if [ $? -ne 0 ]; then
echo "permset:assign failed" 
exit 1
fi

# Open Scratch Org...

echo -n "Opening Scratch Org..."

sfdx force:org:open -u ${username}

# Run Test Classes

echo -n "Running Test Classes"

jobid="$(sfdx force:apex:test:run --json)"

echo $jobid

testRunId="$(echo ${jobid} | jq -r .testRunId)"

echo -n ${testRunId}

sfdx force:apex:test:report -i ${testRunId}





            