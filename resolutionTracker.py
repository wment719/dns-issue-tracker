from os import system
from time import localtime, sleep
from subprocess import check_output, DEVNULL
import re

ippattern= re.compile(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})')

targetMachine = input("enter target host: \n")
username = input("enter username: \n")

validIP=False
while not validIP:
    rightIP = input("enter correct IP: \n")
    if ippattern.search(rightIP):
        validIP=True
    else:
        print("Invalid IP. ")

trackedIPs=[]

def currentTime():
    return str(localtime()[3])+':'+str(localtime()[4])

def determinePinging(targetIP):
    global pinging
    if system("ping "+targetIP+" | findstr 'Reply'"):
        for knownIP in trackedIPs:
            if knownIP['Address'] == targetIP:
                knownIP['LastPinged'] = currentTime()
        return True,None
    else:
        for knownIP in trackedIPs:
            if knownIP['Address'] == targetIP:  
                lastping=knownIP['LastPinged']
        return False, lastping

def determineNSResolution():
    global currentResolution
    addresses =[]
    for line in check_output("nslookup "+targetMachine, stderr=DEVNULL).splitlines()[4:]:
        try:
            addresses.append(ippattern.search(str(line))[0])
        except:
            pass
        for justSeenIP in addresses:
            unique=True
            for knownIP in trackedIPs:
                if knownIP['Address'] == justSeenIP:
                    knownIP['LastResolved'] = currentTime()
                    unique=False
            if unique:
                trackedIPs.append({'Address':justSeenIP, 'LastResolved':currentTime(), 'LastPinged':'never'})
    currentResolution = (addresses)

system('cls')
firstrun=True
#Begin Main loop


while True:
    if not firstrun:
        print('previously resolved IPs below. IPs are only ping-tested if they are currently resolved by nameserver.')
        for item in trackedIPs:
            print(item['Address']+'\n    last ping: '+item['LastPinged']+'\n    last dns:  '+item['LastResolved'])
        print('\n\n\nCURRENT RESULTS:')

    determineNSResolution()
    if len(currentResolution) == 0:
        print("hostname "+targetMachine+" is not resolving to any ip addresses")

    elif len(currentResolution) == 1:
        print("hostname "+targetMachine+" Resolving to "+currentResolution[0]+", pinging...")
        pingResults=determinePinging(currentResolution[0])
        if pingResults[0]:
            print(currentResolution[0]+" is pinging")
        else:
            print(currentResolution[0]+" is NOT pinging. last successful ping was at "+pingResults[1])   


    elif len(currentResolution) > 1:
        print("hostname "+targetMachine+" Resolving to multiple ips:\n")
        for ip in currentResolution:
            print(ip)
        print('\n\n\nPing testing resolved IPs...\n')
        for ip in currentResolution:
            pingResults=determinePinging(ip)
            if pingResults[0]:
                print(ip+" is pinging")
            else:
                print(ip+" is NOT pinging. last successful ping was at "+pingResults[1])

    
    
    sleep(25)
    system('cls')
    firstrun=False