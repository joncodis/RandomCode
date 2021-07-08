#!/usr/bin/python3
import requests
import argparse
import sys
import os
from os.path import join, dirname
from dotenv import load_dotenv
from getpass import getpass

# Functions
def PrintListJSON(ItemLbl, ThisList, Seperator):
    global indent
    ListCnt = len(ThisList)
    ListCur = 1
    if ( ListCnt >=1 ):
        print(tab*indent + '"%s": [' % ItemLbl)
        indent += 1
        for item in (ThisList):
            if (ListCur == ListCnt):
                print(tab*indent + '"%s"' % item)
            else:
                print(tab*indent + '"%s",' % item)
            ListCur += 1
        indent -= 1
        print(tab*indent + ']%s' % Seperator)
    else:
        print(tab*indent + '"%s": []%s' % (ItemLbl, Seperator))
    return

# Parse cmd line
parser = argparse.ArgumentParser(description='Convert Ansible AWX/Tower Inventory to dynamic JSON inventory')
parser.add_argument('--list', required=False, help='list to console', action="store_true")
parser.add_argument('--host', required=False, help='query specific host')
if len(sys.argv)==1:
    parser.print_help(sys.stderr)
    sys.exit(1)
args = parser.parse_args()

# Load environment
dotenv_path = join(dirname(__file__), '.env')
load_dotenv(dotenv_path)
awx_url = os.environ.get('AWX_URL')
awx_usr = os.environ.get("AWX_USR")
awx_inv = os.environ.get("AWX_INV")
if (( awx_url is None) or (awx_usr is None) or (awx_inv  is None) ):
    print('\nError: You must setup your environment first.')
    print('The following variables are required: AWX_URL, AWX_USR, AWX_INV')
    print('You must set these variables first or add them the the file: %s\n' % dotenv_path)
    sys.exit(1)

# Init globals
awxinvname = []
awxinvname.append(awx_inv)
all_group_done = False
indent = 0
tab = '    '

# Dummy/empty host implementation
if args.host is not None:
    print('{}')
    sys.exit(0)

# Get password for AWX
awx_psw = getpass('Enter Ansible AWX password for "%s" : ' % awx_usr)

# Pull down inventory data from AWX and look for the requested inventory
r = requests.get('{}/api/v2/inventories/'.format(awx_url), auth=(awx_usr, awx_psw))
iid = -1
for inventory in r.json()['results']:
    if inventory['name'] == awxinvname[0]:
        iid = inventory['id']
        break
if iid == -1:
    print("no such inventory")
    sys.exit(1)

# Reqested inventory verified to exist, now pull that specific inventory down
# r = requests.get('{}/api/v2/inventories/{}/script/?hostvars=1&towervars=1&all=1'.format(args.url, iid), auth=(args.username, args.password))
r = requests.get('{}/api/v2/inventories/{}/script/?hostvars=1&towervars=1&all=1'.format(awx_url, iid), auth=(awx_usr, awx_psw))
inventory = r.json()
print('{')

# Track element count for final comma removal
KeyCnt = len(inventory)
KeyCur = 1

# Reqested inventory verified to exist, now pull that specific inventory down
for key in sorted(inventory):

    # Ignore built-in "all" key
    if key == 'all':
        KeyCur += 1
        continue

    # Process the "_meta" Key
    if key == '_meta':
        indent = 1
        print(tab*indent + '"%s": {' % key)
        if 'hostvars' in inventory[key]:
            indent += 1
            print(tab*indent + '"%s": {' % 'hostvars')
            indent += 1
            HvhCnt = len(inventory[key]['hostvars'])
            HvhCur = 1
            for host in sorted(inventory[key]['hostvars']):
                print(tab*indent + '"%s": {' % host)
                indent += 1
                VarCnt = len(inventory[key]['hostvars'][host])
                VarCur = 1
                # Loop through hostvars
                for var in  sorted(inventory[key]['hostvars'][host]):

                    # Process simple strings
                    if type(inventory[key]['hostvars'][host][var]) is str:
                        # Remove this extra variable to match cli plugin output
                        # ToDo - Comment line below to add 'remote_tower_enabled' variable back into the output
                        # if ( var != 'remote_tower_enabled'):
                        print(tab*indent + '"%s": "%s",' % (var, inventory[key]['hostvars'][host][var]))

                    # Process a list
                    if type(inventory[key]['hostvars'][host][var]) is list:
                        if (len(inventory[key]['hostvars'][host][var]) >= 1):
                            if (VarCur == VarCnt):
                                PrintListJSON(var, inventory[key]['hostvars'][host][var],"")
                            else:
                                PrintListJSON(var, inventory[key]['hostvars'][host][var],",")
                        else:
                            if (VarCur == VarCnt):
                                print(tab*indent + '"%s": []' % var)
                            else:
                                print(tab*indent + '"%s": [],' % var)

                    # Increment element counter
                    VarCur += 1

                # Close Hostvar Host
                indent -= 1
                if (HvhCur == HvhCnt):
                    print(tab*indent + '}')
                else:
                    print(tab*indent + '},')
                HvhCur += 1

            # Close Hostvars
            indent -= 1
            print(tab*indent + '}')
        indent -= 1

    # Process the "hosts" Key
    if 'hosts' in inventory[key]:

        # First make the "all" group (skipping "_meta" key)
        if not (all_group_done):
            print(tab*indent + '"all": {')
            indent += 1
            print(tab*indent + '"children": [')
            indent += 1
            for itm in sorted(inventory):
                if (itm != 'all') and (itm != '_meta'):
                    print(tab*indent + '"%s",' % itm)
            print(tab*indent + '"ungrouped"')
            indent -= 1
            print(tab*indent + ']')
            indent -= 1
            print(tab*indent + '},')
            all_group_done = True

        # Then process all individual host lists
        print(tab*indent + '"%s": {' % key)
        indent += 1
        PrintListJSON("hosts", sorted(inventory[key]['hosts']),"")
        indent -= 1

    #  Close Out Key, checking if last
    if (KeyCur == KeyCnt):
        print(tab*indent + '}')
    else:
        print(tab*indent + '},')
    KeyCur += 1

# Close out JSON
print('}')
sys.exit(0)
