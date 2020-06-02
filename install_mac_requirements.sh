#!/usr/bin/env bash
# Gets the environment's location of bash instead of assuming it to be /bin/bash (Shebang must be the first line). Do NOT change to zsh.

# Prevents the user from executing this script as root as homebrew does not play well with root
if [ "$(whoami)" == "root" ]; then
    printf "This script cannot be run as root. Please try again as the local user or without running commands such as sudo.\n\n";
    exit 1; # Exiting with with a non-zero status to indicate an error
fi

# If there are more than 1 command-line arguments entered, exit the script
if [ "$#" -gt 1 ]; then
    printf "This script only supports up to one command-line arguments.\n\n";
    exit 1; # Exiting with with a non-zero status to indicate an error
# Otherwise, if one command-line argument was entered, throw an error if it is not "-echo" and enable echoing otherwise
elif [ "$#" -eq 1 ]; then
    if [ "$1" != "-echo" ]; then
        printf "The only command line argument accepted is the '-echo' flag.\n\n";
        exit 1; # Exiting with with a non-zero status to indicate an error
    fi
    
    # File descriptor 3 is used to redirect stdout to stdout in this case and 4 to redirect stderr to stderr
    exec 3>&1;
    exec 4>&2;
    echoOn=true;
# If no command-line arguments were entered, don't enable echoing
else
    # File descriptor 3 is used to redirect stdout to /dev/null in this case and 4 to redirect stderr to /dev/null
    exec 3>/dev/null;
    exec 4>&3;
    echoOn=false;
fi

# Installs Xcode Command Line Tools if they are not already installed
if xcode-select -p >/dev/null 2>&1; then
    printf "\nXcode Command Line Tools are installed! ✅\n\n";
else
    printf "\nXcode Command Line Tools were not found. ❌\n\n";
    printf "Installing Xcode Command Line Tools... 🛠️\n";
    printf "Follow the prompt that pops up!\n\n";
    
    if $echoOn; then
        printf "> xcode-select --install\n\n";
    fi
    
    # Installs Xcode Command Line Tools (if the user follows the prompt that shows up)
    xcode-select --install >&3 2>&4;
    
    printf "After the installation of the Xcode Command Line Tools is complete, execute this script again.\n\n";
    exit 1; # Exiting with a non-zero status to indicate that the script did not fully run
fi

# Installs homebrew if it does not already exist or updates it if it does
if brew help >/dev/null 2>&1; then
    printf "Homebrew is installed! ✅\n\n";
    printf "Updating homebrew... (Please be patient. This may take some time.) 🍺\n\n";
    
    if $echoOn; then
        printf "> brew update\n\n";
    fi
    
    # Update homebrew if it already exists
    brew update >&3 2>&4;
    
    if $echoOn; then
        printf "\n";
    fi
    
    printf "Homebrew is updated!\n\n";
else
    printf "Homebrew was not found. ❌\n\n";
    printf "Installing homebrew... (Please be patient. This may take some time.) 🍺\n\n";
    
    if $echoOn; then
        printf "> /usr/bin/ruby -e \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\"\n\n";
    fi
    
    # Install homebrew if it does not exist and exits the script if an error occurs in the installation
    if ! /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null >&3 2>&4; then
        printf "\nAn error occurred in the installation of homebrew.\n";
        printf "Try running the script again, and if the problem still occurs, contact chawl025@umn.edu\n\n";
        exit 1; # Exit if homebrew does not install succesfully
    fi
    
    printf "\nHomebrew is installed! ✅\n\n";
fi

# Installs a higher version of bash through homebrew if not already using homebrew's bash
if brew list bash >/dev/null 2>&1; then
    printf "Homebrew's bash is installed! ✅\n\n";
    printf "Updating bash... (Please be patient. This may take some time.) 📺\n\n";
    
    if $echoOn; then
        printf "> brew upgrade bash\n\n";
    fi
    
    # Upgrades bash
    brew upgrade bash >&3 2>&4;
    
    if $echoOn; then
        printf "\n";
    fi
    
    printf "bash is updated!\n\n";
else
    printf "Homebrew's bash was not found. ❌\n\n";
    printf "Installing homebrew's bash... (Please be patient. This may take some time.) 📺\n\n";
    
    if $echoOn; then
        printf "> brew install bash\n\n";
    fi
    
    # Installs brew if it did not exist and exits the script if an error occurs in the installation
    if ! brew install bash >&3 2>&4; then
        printf "An error occurred in the installation of bash.\n";
        printf "Try running the script again, and if the problem still occurs, contact chawl025@umn.edu\n\n";
        exit 1; # Exiting with with a non-zero status to indicate an error
    fi
    
    if $echoOn; then
        printf "\n";
    fi
    
    printf "Homebrew's bash is installed! ✅\n\n";
fi

# Checks if homebrew's bash is in the list of available Terminal shells and adds it if not
if grep -q "/usr/local/bin/bash" /etc/shells; then
    printf "The updated bash is in the list of available Terminal shells! ✅\n\n";
else
    printf "The updated bash is not in the list of available Terminal shells. ❌\n\n";
    printf "Adding the updated bash to the list of Terminal shells... 📜\n\n";
    
    if $echoOn; then
        printf "> sudo sh -c 'printf \"\\\n/usr/local/bin/bash\\\n\" >> /etc/shells'\n\n";
    fi
    
    # Attempts to add /usr/local/bin/bash or homebrew's bash to /etc/shells or the list of available Terminal shells
    if ! sudo sh -c 'printf "\n/usr/local/bin/bash\n" >> /etc/shells'; then
        printf "\nAn error occurred when trying to add the updated bash to the list of available Terminal shells.\n";
        printf "Try running the script again, and if the problem still occurs, contact chawl025@umn.edu\n\n";
        exit 1; # Exiting with with a non-zero status to indicate an error
    fi
    
    printf "\nThe updated bash is in the list of available Terminal shells! ✅\n\n";
fi

# If your bash version is not 5.0+, link Terminal to the newest version installed if /bin/bash is the default
if [[ ${BASH_VERSION%%.*} -gt 4 ]]; then
    printf "Your bash version is up to date in your current shell! ✅\n\n";
else
    printf "Your current bash is not up to date in your current shell. ❌\n\n";
    printf "Updating your current bash for your shell... 🔼\n\n";
    
    if [ "$SHELL" = "/bin/bash" ]; then
        if $echoOn; then
            printf "> chsh -s /usr/local/bin/bash\n\n";
        fi
        
        # Attempts to set the current default shell to use the updated bash and spits an error if it fails
        if ! chsh -s /usr/local/bin/bash >&3 2>&4; then
            printf "\nAn error occurred when trying to update your terminal shell.\n";
            printf "Try running the script again, and if the problem still occurs, contact chawl025@umn.edu\n\n";
            exit 1; # Exiting with with a non-zero status to indicate an error
        fi
        
        printf "\n";
    fi
    
    printf "Your bash version is up to date for your shell! ✅\n\n";
    printf "Now, please rerun this script so it uses the appropriate version of bash.\n\n"
    exit 1; # Exiting with a non-zero status to indicate that the script did not fully run
fi

# Checks to see if /usr/local/bin/gcc is in your path (or at least has a higher presence than /usr/bin) and puts it in your path if not
if [[ "$(command -v bash)" != "/usr/local/bin/bash" ]]; then
    printf "/usr/local/bin/ is not in your \$PATH. ❌\n\n";
    printf "Adding /usr/local/bin/ to your \$Path... 📝\n\n";
    
    # If ~/.bash_profile does not exist, create it!
    if ! [ -f "$HOME/.bash_profile" ]; then

        printf "~/.bash_profile could not be found. Creating it for you... 📝\n\n";
        
        if $echoOn; then
            printf "> touch \"\$HOME/.bash_profile\"\n\n";
        fi
        
        # Create ~/.bash_profile and spit out an error if it fails
        if ! touch "$HOME/.bash_profile"; then
            printf "An error occurred in creating ~/.bash_profile.\n";
            printf "Try running the script again, and if the problem still occurs, contact chawl025@umn.edu\n\n";
            exit 1; # Exiting with with a non-zero status to indicate an error
        fi

        printf "~/.bash_profile created!\n\n";
    fi
    
    if $echoOn; then
        printf "> printf \"\\\nexport PATH=/usr/local/bin:\$PATH\\\n\" >> ~/.bash_profile\n\n";
    fi
    
    # Adds /usr/local/bin/ to the beginning of your $PATH variable and spits an error if it fails
    if ! printf "\nexport PATH=/usr/local/bin:\$PATH\n" >> ~/.bash_profile; then
        printf "An error occurred in trying to write to ~/.bash_profile.\n";
        printf "Try running the script again, and if the problem still occurs, contact chawl025@umn.edu\n\n";
        exit 1; # Exiting with with a non-zero status to indicate an error
    fi
    
    # Add /usr/local/bin to path for the purposes of the rest of this script as well
    export PATH=/usr/local/bin:$PATH
fi

printf "/usr/local/bin/ is in your \$PATH! ✅\n\n";

# Installs the real gcc (not clang) through homebrew if it isn't already installed or update it if it is
if brew list gcc >/dev/null 2>&1; then
    printf "gcc is installed! ✅\n\n";
    printf "Updating gcc... (Please be patient. This may take some time.) 🔧\n\n";
    
    if $echoOn; then
        printf "> brew upgrade gcc\n\n";
    fi
    
    # Upgrades gcc
    brew upgrade gcc >&3 2>&4;
    
    if $echoOn; then
        printf "\n";
    fi
    
    printf "gcc is updated!\n\n";
else
    printf "gcc (not clang/gcc) was not found. ❌\n\n";
    printf "Installing gcc... (Please be patient. This may take some time.) 🔧\n\n";
    
    if $echoOn; then
        printf "> brew install gcc\n\n";
    fi
    
    # Installs gcc if it did not exist and exits the script if an error occurs in the installation
    if ! brew install gcc >&3 2>&4; then
        printf "An error occurred in the installation of gcc.\n";
        printf "Try running the script again, and if the problem still occurs, contact chawl025@umn.edu\n\n";
        exit 1; # Exiting with with a non-zero status to indicate an error
    fi
    
    if $echoOn; then
        printf "\n";
    fi
    
    printf "gcc is installed! ✅\n\n";
fi

# Checks to ensure that the brew gcc is symlinked to /usr/local/bin/gcc and, if not, links it (made to be compatible with future versions of gcc)
if [ -f "/usr/local/bin/gcc" ]; then
    printf "gcc is symlinked correctly! ✅\n\n";
else
    printf "gcc is not symlinked. ❌\n\n";
    printf "Symlinking homebrew's gcc to /usr/local/bin/gcc... 🔗\n\n";
    
    if $echoOn; then
        printf "> gccString=\$(find /usr/local/bin | while read -r f; do if [[ \$(basename \"\$f\") =~ ^gcc-[0-9]+$ ]]; then basename \"\$f\"; fi; done)\n\n";
    fi
    
    # Gets all of the files under /usr/local/bin, executes the basename command on each to get the filename without the path, 
    # checks if it matches "gcc-" followed by any number of digits, and stores it into gccString
    gccString=$(find /usr/local/bin | while read -r f; do if [[ $(basename "$f") =~ ^gcc-[0-9]+$ ]]; then basename "$f"; fi; done);
    
    if $echoOn; then
        printf "> readarray -t gccStringArray <<< \"\$gccString\"\n\n";
    fi
    
    # Creates an array called gccStringArray and stores all "gcc-" followed by digits strings into it (Credits to tinyurl.com/wtgkay2)
    readarray -t gccStringArray <<< "$gccString";
    
    # If there is more than one version of gcc in /usr/local/bin, then get the newest version
    if [ ${#gccStringArray[@]} -ne 1 ]; then
        if $echoOn; then
            printf "> highestNum = 0\n\n";
        fi
        
        # Defines the highest gcc version, which is by default '0'
        highestNum=0;
        
        if $echoOn; then
            printf "> for (( i=0; i<\${#gccStringArray[@]}; ++i )); do\n";
            printf "      if [[ \${gccStringArray[\$i]##*-} -gt \$highestNum ]]; then\n";
            printf "          highestNum=\${gccStringArray[\$i]##*-}\n";
            printf "      fi\n";
            printf "  done\n\n";
        fi
        
        # Iterates through each of the "gcc-" strings
        for (( i=0; i<${#gccStringArray[@]}; ++i )); do
            # If the number following the "gcc-" part of the string is greater than highestNum, set highestNum to that greater value (compared arithmetically, not lexicographically)
            if [[ ${gccStringArray[$i]##*-} -gt $highestNum ]]; then
                highestNum=${gccStringArray[$i]##*-};
            fi
        done
        
        if $echoOn; then
            printf "> gccString=\"gcc-\$highestNum\"\n\n";
        fi
        
        # Sets the gccString to the highest gcc version
        gccString="gcc-$highestNum";
    fi
    
    if $echoOn; then
        printf "> ln -s \"/usr/local/bin/%s\" /usr/local/bin/gcc\n\n" "$gccString";
    fi
    
    # Attempts to symlink the highest gcc version available to /usr/local/bin/gcc and spits an error if it doesn't work
    if ! ln -s "/usr/local/bin/$gccString" /usr/local/bin/gcc >&3 2>&4; then
        printf "An error occurred in the symlinking of gcc.\n";
        printf "Try running the script again, and if the problem still occurs, contact chawl025@umn.edu\n\n";
        exit 1; # Exiting with with a non-zero status to indicate an error
    fi
    
    printf "gcc is now symlinked correctly! ✅\n\n";
fi

# Installs coreutils through homebrew if it isn't already installed or update it if it is
if brew list coreutils >/dev/null 2>&1; then
    printf "coreutils is installed! ✅\n\n";
    printf "Updating coreutils... (Please be patient. This may take some time.) 🎛\n\n";
    
    if $echoOn; then
        printf "> brew upgrade coreutils\n\n";
    fi
    
    # Upgrades coreutils
    brew upgrade coreutils >&3 2>&4;
    
    if $echoOn; then
        printf "\n";
    fi
    
    printf "coreutils is updated!\n\n";
else
    printf "coreutils was not found. ❌\n\n";
    printf "Installing coreutils... (Please be patient. This may take some time.) 🎛\n\n";
    
    if $echoOn; then
        printf "> brew install coreutils\n\n";
    fi
    
    # Installs coreutils if it did not exist and exits the script if an error occurs in the installation
    if ! brew install coreutils >&3 2>&4; then
        printf "An error occurred in the installation of coreutils.\n";
        printf "Try running the script again, and if the problem still occurs, contact chawl025@umn.edu\n\n";
        exit 1; # Exiting with with a non-zero status to indicate an error
    fi
    
    if $echoOn; then
        printf "\n";
    fi
    
    printf "coreutils is installed! ✅\n\n";
fi

# Installs gnu-sed through homebrew if it isn't already installed or update it if it is
if brew list gnu-sed >/dev/null 2>&1; then
    printf "gnu-sed is installed! ✅\n\n";
    printf "Updating gnu-sed... (Please be patient. This may take some time.) 🔨\n\n";
    
    if $echoOn; then
        printf "> brew upgrade gnu-sed\n\n";
    fi
    
    # Upgrades gnu-sed
    brew upgrade gnu-sed >&3 2>&4;
    
    if $echoOn; then
        printf "\n";
    fi
    
    printf "gnu-sed is updated!\n\n";
else
    printf "gnu-sed was not found. ❌\n\n";
    printf "Installing gnu-sed... (Please be patient. This may take some time.) 🔨\n\n";
    
    if $echoOn; then
        printf "> brew install gnu-sed\n\n";
    fi
    
    # Installs gnu-sed if it did not exist and exits the script if an error occurs in the installation
    if ! brew install gnu-sed >&3 2>&4; then
        printf "An error occurred in the installation of gnu-sed.\n";
        printf "Try running the script again, and if the problem still occurs, contact chawl025@umn.edu\n\n";
        exit 1; # Exiting with with a non-zero status to indicate an error
    fi
    
    if $echoOn; then
        printf "\n";
    fi
    
    printf "gnu-sed is installed! ✅\n\n";
fi

# Installs gawk through homebrew if it isn't already installed or update it if it is
if brew list gawk >/dev/null 2>&1; then
    printf "gawk is installed! ✅\n\n";
    printf "Updating gawk... (Please be patient. This may take some time.) 👀\n\n";
    
    if $echoOn; then
        printf "> brew upgrade gawk\n\n";
    fi
    
    # Upgrades gawk
    brew upgrade gawk >&3 2>&4;
    
    if $echoOn; then
        printf "\n";
    fi
    
    printf "gawk is updated!\n\n";
else
    printf "gawk was not found. ❌\n\n";
    printf "Installing gawk... (Please be patient. This may take some time.) 👀\n\n";
    
    if $echoOn; then
        printf "> brew install gawk\n\n";
    fi
    
    # Installs gawk if it did not exist and exits the script if an error occurs in the installation
    if ! brew install gawk >&3 2>&4; then
        printf "An error occurred in the installation of gawk.\n";
        printf "Try running the script again, and if the problem still occurs, contact chawl025@umn.edu\n\n";
        exit 1; # Exiting with with a non-zero status to indicate an error
    fi
    
    printf "gawk is installed! ✅\n\n";
fi

if $echoOn; then
    printf "> macOsVersion=\$(sw_vers -productVersion)\n\n";
fi

# Gets the version of macOS the user has
if ! macOsVersion=$(sw_vers -productVersion); then
    printf "An error occurred when trying to get the macOS version.\n";
    printf "Try running the script again, and if the problem still occurs, contact chawl025@umn.edu\n\n";
    exit 1; # Exiting with with a non-zero status to indicate an error
fi

if $echoOn; then
    printf "> mapfile -t osVersionNumbers < <( tr . '\\\n' <<< \"\$macOsVersion\")\n\n";
fi

# Creates an array called osVersionNumbers and stores each of the version numbers into an array (e.g. 10.14.6 to 10, 14, and 6) (Credits to tinyurl.com/ql7xf8y)
if ! mapfile -t osVersionNumbers < <( tr . '\n' <<< "$macOsVersion"); then
    printf "An error occurred when trying to split up the macOS version.\n";
    printf "Try running the script again, and if the problem still occurs, contact chawl025@umn.edu\n\n";
    exit 1; # Exiting with with a non-zero status to indicate an error
fi

# If you don't have valgrind installed, it attempts to install it if 10.14.x or 10.15.x
if command -v valgrind >/dev/null 2>&1; then
    printf "valgrind is installed/linked! ✅\n\n";
    
    # Attempts to upgrade (through installation, unfortunately) valgrind if on macOS 10.14.x or 10.15.x
    if [ "${osVersionNumbers[1]}" -eq 14 ] || [ "${osVersionNumbers[1]}" -eq 15 ]; then
        printf "Updating valgrind... (Please be patient. This may take some time.) 🧹\n\n";
        
        if $echoOn; then
            printf "> brew install --HEAD https://raw.githubusercontent.com/ssrlive/valgrind/master/valgrind.rb\n\n";
        fi
        
        # Attempts to install (upgrade) valgrind and spits out an error if it doesn't work
        if ! brew install --HEAD https://raw.githubusercontent.com/ssrlive/valgrind/master/valgrind.rb >&3 2>&4; then
            printf "An error occurred when trying to update valgrind.\n\n";
            printf "If you are running macOS 10.14.x – 10.15.1, try running the script again and contact chawl025@umn.edu if you have any problems\n";
            exit 1; # Exiting with with a non-zero status to indicate an error
        fi
    fi
    
    if $echoOn; then
        printf "\n";
    fi
else
    printf "valgrind was not found or was not linked. ❌\n\n";
    printf "Installing/linking valgrind... (Please be patient. This may take some time.) 🧹\n\n";
    
    # If not macOS 10.x.x, spit an error
    if [ "${osVersionNumbers[0]}" -ne 10 ]; then
        printf "Valgrind is only available for macOS 10.x.x. at the time of this script\n";
        printf "Please upgrade your OS or contact chawl025@umn.edu if we have macOS 11+ out\n\n";
        exit 1; # Exiting with with a non-zero status to indicate an error
    fi
    
    if [ "${osVersionNumbers[1]}" -ne 14 ] && [ "${osVersionNumbers[1]}" -ne 15 ]; then
        printf "If you do not have macOS 10.14.x or 10.15.x, please install valgrind manually\n";
        printf "If you need any help, please feel free to reach out to chawl025@umn.edu\n\n";
        exit 1; # Exiting with with a non-zero status to indicate an error
    fi
    
    if $echoOn; then
        printf "> brew install --HEAD https://raw.githubusercontent.com/ssrlive/valgrind/master/valgrind.rb\n\n";
    fi
    
    # Attempts to install valgrind and spits out an error if it doesn't work
    if ! brew install --HEAD https://raw.githubusercontent.com/ssrlive/valgrind/master/valgrind.rb >&3 2>&4; then
        printf "An error occurred when trying to install valgrind.\n\n";
        printf "If you are running macOS 10.14.x – 10.15.1, try running the script again and contact chawl025@umn.edu if you have any problems\n";
        exit 1; # Exiting with with a non-zero status to indicate an error
    else
        if $echoOn; then
            printf "\n> brew link valgrind\n\n";
        fi
        
        # Attempts to link valgrind and spits an error if unsuccessful
        if ! brew link valgrind >&3 2>&4; then
            printf "An error occurred when trying to link valgrind.\n\n";
            printf "If you are running macOS 10.14.x – 10.15.1, try running the script again and contact chawl025@umn.edu if you have any problems\n";
            exit 1; # Exiting with with a non-zero status to indicate an error
        fi
        
        # If the valgrind file was not made, remove the brew valgrind directory
        if ! [ "$(find /usr/local/Cellar/valgrind/ -type f -iname 'valgrind' -print | wc -l)" -eq 1 ]; then
            
            if $echoOn; then
                printf "\n";
            fi
            
            printf "Valgrind was not found in the directory it should have been installed in! ❌\n\n";
            printf "Attempting to remove valgrind directory...\n\n";
            
            if $echoOn; then
                printf "> rm -Rf /usr/local/Cellar/valgrind\n\n";
            fi
            
            # Attempts to remove the directory valgrind is installed in
            rm -Rf /usr/local/Cellar/valgrind;
            
            printf "Attempted removal complete!\n\n"
            printf "Retry this script, and if the issue occurs again, please contact chawl025@umn.edu\n\n";
            exit 1; # Exiting with with a non-zero status to indicate an error
        fi
    fi
    
    if $echoOn; then
        printf "\n";
    fi
    
    printf "valgrind is installed/linked! ✅\n\n";
fi

printf "Congratulations! Your computer should be completely set up! 💻\n\n";
