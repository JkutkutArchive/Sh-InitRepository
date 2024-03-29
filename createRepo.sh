#!/bin/sh

#colors:
NC='\033[0m' # No Color
RED='\033[0;31m'
GREEN='\033[0;32m'
LRED='\033[1;31m'
LGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LBLUE='\033[1;34m'
TITLE='\033[38;5;33m'

echo "${TITLE}
 _      _       _    _____                      _ _                   
| |    (_)     | |  |  __ \                    (_) |                  
| |     _ _ __ | | _| |__) |___ _ __   ___  ___ _| |_ ___  _ __ _   _ 
| |    | | '_ \| |/ /  _  // _ \ '_ \ / _ \/ __| | __/ _ \| '__| | | |
| |____| | | | |   <| | \ \  __/ |_) | (_) \__ \ | || (_) | |  | |_| |
|______|_|_| |_|_|\_\_|  \_\___| .__/ \___/|___/_|\__\___/|_|   \__, |
                               | |                               __/ |
                               |_|                              |___/${NC}";


askResponse=""; #When executing the function ask(), the response will be stored here
ask() { # to do the read in terminal, save the response in askResponse
    text=$1;
    textEnd=$2;
    read -p "$(echo ${LBLUE}"$text"${NC} $textEnd)->" askResponse;
}
error() { # function to generate the error messages. If executed, ends the script.
    err=$1;
    echo "${RED}~~~~~~~~  ERROR ~~~~~~~~
    $1${NC}";
    exit 1
}
addFiles2Repo() {
   (git add * .[^\.]* ||
   error "Not possible to add the files") &&
   (git commit -am "$1" ||
   error "Error at commiting initial files")
}
help() {
    echo "${TITLE}* CreateRepository help *${NC}\n\n
The script can have the following arguments:
  ${LBLUE}-u [*arg]${NC}:\n    Change the user/owner of the repository.
    The parameter ${LBLUE}--user${NC} can also be used.\n
  ${LBLUE}-d [*arg]${NC}:\n    Change the directory to store the local repository (The path is intended to be absolute and should not end in '/').
    The parameters ${LBLUE}--dir${NC} or ${LBLUE}--directory${NC} can also be used.\n
  ${LBLUE}[*repoName]${NC}:\n    The name of the repository. Keep in mind that it should match RegEx '^[a-zA-Z0-9-_]+$'\n
  ${LBLUE}--create${NC}:\n    If the repository should be created on github.\n
  ${LBLUE}--init${NC}:\n    If the script should connect to an already created repository on github and create the initial files.\n
  ${LBLUE}[templates]:${NC}:\n    To use a template, use the arguments ${LBLUE}--web${NC}, .\n    Each one will generate a repository structure with the basic files of the template.\n
  ${LBLUE}--extraFiles${NC}:\n    If the repository should be created with aditional files.\n
  ${LBLUE}--noExtraFiles${NC}:\n    If the repository should not be created with aditional files.\n
  ${LBLUE}--help${NC}:\n    Opens a help menu instead of running the script.\n

${YELLOW}Considerations:${NC}
 - All arguments with ${LBLUE}[*XXX]${NC} expect a single word to follow.\n   If not given, the script will ask for it before execution.
 - All arguments can be concatenated at will.\n   However, only the last ones will have the final desition.\n" | more -d;
    exit 0;
}



repoName=""; # The name of the repository (changed on execution)
u="jkutkut"; # Default user
fullDirectory=~/github; # Default directory
type="create"; # Default type of creation (create or use already created repository)
extraFiles=1; # If extra files should be created (1: true, 0: false).
template="None"; # If special templates selected (Web, None)

# Change the user and the directory acording to the arguments given.
while [ ! -z $1 ]; do # While the are avalible arguments
    v=""; # Variable to change
    vContent=""; # Value to asing to the variable
    q=""; # Question to tell the user if no further arguments given

    case $1 in
        --help)
            help;
            exit 0;
            ;;
        -u|--user)
            v="u";
            q="Name of the user?";
            ;;
        -d|--dir|--directory)
            q="Directory?";
            v="fullDirectory";
            ;;
        --create|--init)
            type=$(echo $1 | sed -e 's/--//');
            shift;
            continue;
            ;;
        --noExtraFiles|--extraFiles)
            if  [ $(expr match "$1" no ) ]; then
                extraFiles=0;
            else
                extraFiles=1;
            fi
            shift;
            continue;
            ;;
        --web)
            template="web";
            shift;
            continue;
            ;;
        *)
            if [ $(expr match "$1" "^[a-zA-Z0-9_-]*$") -ge 1 ]; then
                repoName=$1;
                shift;
                continue;
            else
                error "Invalid argument: $1";
            fi
    esac

    shift; # -ANY argument removed
        
    if [ $(expr "$1" : "[^-].*") -eq 0 ]; then # If not given
        ask "$q" ""; # Ask for it
        vContent=$askResponse; # The response is the content
    else
        vContent=$1; # Next argument is the content
        shift;
    fi

    eval $v="$vContent";
done


if [ -z "$repoName" ]; then # If repository name not selected yet
    ask "Name of the repository?" "";
    repoName=$askResponse; # Store the name of the Repository.
fi

fullDirectory=$fullDirectory/$repoName; # Update directory based on the name of the repo

echo "\nAtempting to $type a reposititory on ${YELLOW}$fullDirectory${NC}\nand connect it to the user ${YELLOW}$u${NC}.\n";

# Create directory and init repository
(mkdir $fullDirectory || # Make the directory to init the repo
error "Directory is not correct.") && 

cd $fullDirectory && # Go to directory

(git init || # Init repository
error "Not possible to init git") &&


# Create initial files
(echo -e "# $repoName:\n" >> README.md && # Create the README.md file on the repository
touch .gitignore || # Create the .gitignore file on the repository
error "Not posible to create initial files") &&

addFiles2Repo "Initial files created" &&


# If we want to create a repository with extra files
if [ $extraFiles -eq 1 ]; then 
    # Add the extra files
    (mkdir ".info" ||
    error "Not able to create directories on the repository") &&
    (echo -e "# ThingsToDo:\n- " >> ./.info/ThingsToDo.md || # Create the ThingsToDo.md file on the repository
    error "not able to create the extra files")

    addFiles2Repo "Extra files added";
fi &&


# If template, implement it
case $template in
    web)
        (mkdir res res/CSS res/Img res/JS ||
        error "Not able to create the directories of the web template") &&

        (echo -e '<!DOCTYPE html><html>\n\t<head>\n\t\t<meta charset=\"utf-8\">\n\n\t\t<!-- Logo & title -->\n\t\t<title>$repoName</title>\n\t\t<!-- <link rel=\"icon\" href=\"\"> -->\n\n\t\t<!-- CSS -->\n\t\t<link rel=\"stylesheet\" type=\"text/css\" href=\"res/style.css\">\n\n\t\t<!-- JS -->\n\t\t<script src=\"sketch.js\"></script>\n\t</head>\n\t<body>\n\t</body>\n</html>' >> index.html &&
        touch sketch.js Res/CSS/style.css ||
        error "Not able to create the files of the web template")
esac &&

if [ ! $template = "None" ]; then # If template selected, add the files created
    addFiles2Repo "Template $template structure added.";
fi &&


if [ $type = "create" ]; then # If the intention is to create a repository
    echo "Creating repository using hub:";
    echo "TOKEN 2 USE AS PASSWORD!" | xclip -selection clipboard;
    hub create ||
    error "Not able to create repository";
else # Connect to github and update the content to the already created repo
    echo "Linking repository to github account";
    (git remote add origin git@github.com:$u/$repoName.git || # Link the repositories
    error "Could not execute \"git remote add origin git@github.com:$u/$repoName.git\"";) &&

    (sudo -H -u $USER bash -c 'git push -u origin master' || # Upload the new repository
    error "Not able to push the changes")
fi

echo "--------------------------------------\n${LGREEN}\nRepository ready${NC}\n
Code developed by Jkutkut github.com/jkutkut";