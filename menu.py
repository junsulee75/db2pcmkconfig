#!/usr/bin/python3
'''
Reusing Chee Hoe's python program : reading yaml for menu.   
'''
import yaml
import random  # generating random number
import sys
import re   # regular expression   
import os
import time
import configparser  # reading ini style 



# Add in cwd to OS environment PATH.  to ensure that the Python script can find executables or modules located in the current directory
os.environ['PATH'] = ".:" + os.environ['PATH'] 

# Guide : https://stackabuse.com/reading-and-writing-yaml-to-a-file-in-python/
version = "1.0.0"

delay = 0 

class Yaml :  # Class to use for working with YAML configuration files

    def __init__(self, yaml_config ):  # constructor. yaml_config : path to YAML file.

        with open(yaml_config) as file:  # open the yaml file. loads the contents of the YAML file into the self.config 
            self.config = yaml.load(file,Loader=yaml.FullLoader)  # loading the entire YAML

    def ds(self):  # returns the entire YAML configuration stored in the self.config attribute.
        return ( self.config )  #  returns the entire YAML configuration. allows accessing the complete YAML data 

    def get(self,fields):  # retrieves a specific value from the YAML

        ptr = self.config  
        for i in fields:  # It iterates over the elements of fields, which represent a path to the desired value within the YAML structure.
            ptr = ptr[i]    # For each element in fields, it traverses deeper into the YAML structure using dictionary access.

        return ptr

def show_menu ( menu ):

    '''
    # replace all ${X} with os.environ[X]
    for item in menu :
        print ( "menuitem" , item , menu[item] ) 
    '''
    # prepend with option to go back previous menu , and append with option to exit menu
    main = {"..": ".."}
    main.update(menu)
    main.update({"quit": "Quit"})

    # check if DIR exists , if yes , change to that folder
    if ( 'DIR' in main ):
        os.chdir ( main['DIR'] )
        del main['DIR']

    # if NOTE exist, save the string - and display it as part of the menu.  NOTE is not an opton
    note = None
    if ( 'NOTE' in main ):
        note = dollar_replace(main['NOTE'])
        del main['NOTE']

    ''' clear screen only if in prompting mode '''
    
    prompt = os.getenv("PROMPT","1")
    if prompt == "1" :
        os.system("clear")

    print("\n")
    print ( "YAML [%s] : %s , Current working directory = %s" %  (version,yfile,os.getcwd())  )
    print ( f"Note : {note}" ) if ( note ) else None
    print ( f"Last Command : {lastcmd}" ) if ( lastcmd ) else None

    # convert to list and display as X : entry
    as_list = list(main)
    for  i in range ( 0,len(as_list) ) :
        key = as_list[i] 
        folder = ""
        if isinstance( main[key] , dict ) :
            folder = "*"
        print( "  [ %d ] : %s %s" % ( i, dollar_replace(key) , folder ) )
    print("\n")

    if len(keystrokes) > 0 :
        val = keystrokes.pop(0)
        global delay
        try :
            match = re.search("(\d+)d(\d+)",val)
            val   = match[1]
            delay = match[2]
        except :
            delay = 0
        print ( f"Auto pick : option={val}, delay={delay}" ) 
    else :
        val = input("Enter choice : ")

    # catch for bad input
    try :
        idx = int(val)
    except ValueError:
        return "error"

    return "error" if ( idx > len(main)-1 or idx < 0 ) else val,as_list[int(val)]

import re
def run( cmd ) :

    # ------------------------------------------------------------------------------
    # substitute environment variables if it exists , replace ${X} with $env->{X}
    # ------------------------------------------------------------------------------
    # for key in env:
    #     meta = "${" + key + "}"
    #     cmd = re.sub( re.escape(meta) , env[key], cmd )

    '''
    look for [X]-[Y] - if exists , prompt of X, and if no input , set it to Y , otherwise set to input
    '''
    found = re.findall("(\[.*?\]-\[.*?\])", cmd )
    for match in found:
        (qn, ans) = re.findall("\[(.*)\]-\[(.*)\]", match)[0]
        val = input(f"{qn} [{ans}] : ")
        ans = val if (val) else ans
        cmd = re.sub(re.escape(match), ans, cmd )

    # global lastcmd
    # lastcmd = cmd
    # show prompt before running the command
    prompt = os.getenv("PROMPT","1")
    if prompt == "1" :
        input ("\nHit <ENTER> to continue :" )

    os.system(cmd)

    # slight pause after execution to show results
    time.sleep(int(delay))
    if prompt == "1" :
        input ("\nHit <ENTER> to continue :" )

def cfgparser (file ) :

    # Read config.ini file
    config = configparser.ConfigParser()
    config.optionxform = str
    config.read(file)
    rec = {}
    # do this to suppore interpolation
    for key in config.sections() :
        for inner_key in dict(config.items(key) ) :
            rec[inner_key] = config.get(key,inner_key)
            os.environ[inner_key] = config.get(key,inner_key)
    return rec

def shellconfig ( file ) :
    f = open( file , "r" )
    for line in f.readlines() :

        line = line.rstrip()
        if line.startswith("#") or re.match("^$",line)  :
            continue

        line = line.replace("export ","")

        for match in re.findall( "(.*?)=(.*)",line):
            os.environ[match[0]] = dollar_replace ( match[1] ) 

    f.close()

# -----------------------------------------------------------------------------------------------------------
# this replaces ${host} with the value of os.environ['host'].  avoid using str cos it is a built in function
# -----------------------------------------------------------------------------------------------------------
def dollar_replace ( tstr ) :

    found = re.findall("\$\{(.*?)\}", tstr )
    for match in found:
        meta = "${" + match + "}"
        if match not in os.environ :
            print ( f"Value %s is used in YAML but not defined in ENV , SHELLCONFIG , nor CONFIGPARSER" % ( match ) )
            sys.exit(0)
        tstr = re.sub(re.escape(meta), os.environ[match] , tstr )

    return tstr

# ------------------------------------------------------------------------------
# substitute environment variables if it exists , replace ${X} with $env->{X}
# ------------------------------------------------------------------------------
def envreplace ( obj ):

    for item in obj:
        value = obj[item]
        if ( type(value) == str ):
            for key in env:
                if key.startswith ("BASH_FUNC" ):   # ignore if the environment variable has this key. no use for it here.
                    continue
                meta = "${" + key + "}"
                # print ("META",meta)
                value = re.sub(re.escape(meta), env[key], value)
                obj[item] = value
        if ( type(value) == dict ):
            envreplace ( value )


if __name__ == '__main__':  # ensure that the code inside it only runs if the script is executed directly and not imported as a module into another script.
# __name__ : the name of the current module. only execute if the script is the main program being run.
# 
    lastcmd = None
    # Priority - argument , local , environment variable
    '''
    if ( len(sys.argv) > 1 ):
        yfile = sys.argv[1]
    elif os.path.isfile('menu.yaml') :
        yfile = "menu.yaml"
    elif os.environ.get('YAMLFILE') :
        yfile = os.environ.get('YAMLFILE')
    else :
        print ("Cannot find YAML file")
    '''

    # keystrokes like 2,1,6 - for autopilot
    try :
        keystrokes= list ( map(lambda x: x.strip() ,  sys.argv[1].split(",") ) )
        prompt=0  # If there is keystrokes, no prompt  
    except :
        prompt=1
        keystrokes = []
    
    print ( "Keystrokes", keystrokes ) 

    yfile = "menu.yaml"   # Read file name 'menu.yaml'    
    y = Yaml(yfile)
    top = y.get([])

    # read in environment variables
    if ( 'CONFIGPARSER' in top ):
        cfgparser( top['CONFIGPARSER'] )
        del top['CONFIGPARSER']

    # read in environment variables
    if ( 'SHELLCONFIG' in top ):
        shellconfig ( top['SHELLCONFIG'] )
        del top['SHELLCONFIG']

    # merge the environment variable and this YAML ENV variables
    if ( 'ENV' in top ):
        # assign the pointer to the ENV entry env2 and then delete ENV from menu.yaml
        env2 = y.get(['ENV'])
        for v in env2:
            os.environ[v] = str(env2[v])
        del top['ENV']

    env = os.environ

    # subsitute all options with environment variables , is this still needed since everything goes into os.environ now ?
    # envreplace ( top )

    menu = top      # set menu from the top level
    stack = []      # stack to track menu navigation
    while True:

        val , choice = show_menu ( menu )

        if ( choice == "error" ):
            print("Not a valid number")
            continue

        sys.exit(0) if ( choice == 'quit'  ) else None

        if ( choice == ".." ) :
            menu = stack.pop() if ( stack ) else menu
            continue

        if ( type(menu[choice]) == dict ):
            stack.append ( menu )             # save the parent and show the submenu
            menu = menu[choice]
            continue


        if (type(menu[choice]) == str ):    # no submenu.
            torun = dollar_replace ( menu[choice] )
            prompt = os.getenv("PROMPT","1")
            print( f"prompt={prompt}  parsing : {torun}" )
            lastcmd = f"[{val}] {choice} => {menu[choice]}"
            run ( torun )
            continue
