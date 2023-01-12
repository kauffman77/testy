#!/usr/bin/env bash
# Gets the environment's location of bash instead of assuming it to be /bin/bash (Shebang must be
# the first line). Do NOT change to zsh.

# Author: Nikunj Chawla <chawl025@umn.edu>

# Prevents the user from executing this script as root as homebrew does not play well with root
if [ "$(whoami)" == "root" ]; then
    printf "This script cannot be run as root. "
    printf "Please try again as the local user or without running commands such as sudo.\n\n"
    exit 1
fi

# If there are more than 1 command-line arguments entered, exit the script
if [ "$#" -gt 1 ]; then
    printf "This script only supports up to one command-line argument.\n\n"
    exit 1
# Otherwise, if one command-line argument was entered, throw an error if it is not "-v" and enable
# echoing/verbose mode otherwise
elif [ "$#" -eq 1 ]; then
    if [ "$1" != "-v" ]; then
        printf "The only command line argument accepted is the '-v' flag for verbose mode.\n\n"
        exit 1
    fi
    
    # File descriptor 3 is used to redirect stdout to stdout in this case and 4 to redirect stderr
    # to stderr
    if ! exec 3>&1; then
        printf "\nAn error occurred in creating file descriptor 3.\n"
        printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
        exit 1
    fi
    if ! exec 4>&2; then
        printf "\nAn error occurred in creating file descriptor 4.\n"
        printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
        exit 1
    fi
    echo_on=true
# If no command-line arguments were entered, don't enable echoing
else
    # File descriptor 3 is used to redirect stdout to /dev/null in this case and 4 to redirect
    # stderr to /dev/null
    if ! exec 3>/dev/null; then
        printf "\nAn error occurred in creating file descriptor 3.\n"
        printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
        exit 1
    fi
    if ! exec 4>&3; then
        printf "\nAn error occurred in creating file descriptor 4.\n"
        printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
        exit 1
    fi
    echo_on=false
fi

# Installs Xcode Command Line Tools if they are not already installed
if xcode-select -p >/dev/null 2>&1; then
    printf "\nXcode Command Line Tools are installed! ✅\n\n"
else
    printf "\nXcode Command Line Tools were not found. ❌\n\n"
    printf "Installing Xcode Command Line Tools... 🛠️\n"
    printf "Follow the prompt that pops up!\n\n"
    
    if $echo_on; then
        printf "> xcode-select --install\n\n"
    fi
    
    # Installs Xcode Command Line Tools (if the user follows the prompt that shows up)
    xcode-select --install >&3 2>&4
    
    if $echo_on; then
        printf "\n"
    fi
    
    printf "After the installation of the Xcode Command Line Tools is complete, "
    printf "execute this script again.\n\n"
    exit 1
fi

# Installs homebrew if it does not already exist or updates it if it does
if brew help >/dev/null 2>&1; then
    printf "Homebrew is installed! ✅\n\n"
    printf "Updating homebrew... (Please be patient. This may take some time.) 🍺\n\n"
    
    if $echo_on; then
        printf "> brew update\n\n"
    fi
    
    # Update homebrew if it already exists
    brew update >&3 2>&4
    
    if $echo_on; then
        printf "\n"
    fi
    
    printf "Homebrew is updated!\n\n"
else
    printf "Homebrew was not found. ❌\n\n"
    printf "Installing homebrew... (Please be patient. This may take some time.) 🍺\n\n"
    
    if $echo_on; then
        printf "> yes \"\" | INTERACTIVE=1 /bin/bash -c \"\$(curl -fsSL "
        printf "https://raw.githubusercontent.com/Homebrew/install/master/install.sh)\"\n\n"
    fi
    
    # Install homebrew if it does not exist and exits the script if an error occurs in the
    # installation
    if ! yes "" | INTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" >&3 2>&4; \
    then
        printf "\nAn error occurred in the installation of homebrew.\n"
        printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
        exit 1
    fi
    
    printf "\nHomebrew is installed! ✅\n\n"
fi

if brew help >/dev/null 2>&1; then
    usr_bin="/usr/bin"
    brew_bin="$(brew --prefix)/bin"
    remainder_usr_bin="${PATH#*"$usr_bin"}"
    remainder_brew_bin="${PATH#*"$brew_bin"}"
    usr_bin_brew_bin_position_diff="$(( ${#remainder_brew_bin} - ${#remainder_usr_bin} ))"
fi

# Checks to see if Homebrew's binary directory is in your path (and at least has a higher presence
# than /usr/bin) and puts it at the beginning of your path if not
if ! brew help >/dev/null 2>&1 || [[ "$PATH" != *"$(brew --prefix)/bin"* ]] \
|| [ "$usr_bin_brew_bin_position_diff" -lt "0" ]; then
    printf "\$(brew --prefix)/bin/ is not in your \$PATH. ❌\n\n"
    printf "Adding \$(brew --prefix)/bin/ to your \$PATH... 📝\n\n"
    
    # If ~/.bash_profile does not exist, create it!
    if ! [ -f "$HOME/.bash_profile" ]; then
        # shellcheck disable=SC2088
        # Disabled b/c ~/ is not meant to be expanded here
        printf "~/.bash_profile could not be found. Creating it for you... 📝\n\n"
        
        if $echo_on; then
            printf "> touch \"\$HOME/.bash_profile\"\n\n"
        fi
        
        # Create ~/.bash_profile and spit out an error if it fails
        if ! touch "$HOME/.bash_profile"; then
            printf "An error occurred in creating ~/.bash_profile.\n"
            printf "Try running the script again, and if the problem still occurs, "
            printf "contact chawl025@umn.edu\n\n"
            exit 1
        fi
        
        # shellcheck disable=SC2088
        # Disabled b/c ~/ is not meant to be expanded here
        printf "~/.bash_profile created!\n\n"
    fi
    
    # If ~/.zprofile does not exist, create it!
    if ! [ -f "$HOME/.zprofile" ]; then
        # shellcheck disable=SC2088
        # Disabled b/c ~/ is not meant to be expanded here
        printf "~/.zprofile could not be found. Creating it for you... 📝\n\n"
        
        if $echo_on; then
            printf "> touch \"\$HOME/.zprofile\"\n\n"
        fi
        
        # Create ~/.zprofile and spit out an error if it fails
        if ! touch "$HOME/.zprofile"; then
            printf "An error occurred in creating ~/.zprofile.\n"
            printf "Try running the script again, and if the problem still occurs, "
            printf "contact chawl025@umn.edu\n\n"
            exit 1
        fi
        
        # shellcheck disable=SC2088
        # Disabled b/c ~/ is not meant to be expanded here
        printf "~/.zprofile created!\n\n"
    fi
    
    if $echo_on; then
        printf "> if [ -d \"/opt/homebrew\" ]; then\n"
        printf ">     brew_prefix=\"/opt/homebrew\"\n"
        printf "> else\n"
        printf ">    brew_prefix=\"/usr/local\"\n"
        printf "> fi\n\n"
    fi
    
    # Retrieve brew prefix
    if [ -d "/opt/homebrew" ]; then
        brew_prefix="/opt/homebrew"
    else
        brew_prefix="/usr/local"
    fi
    
    if $echo_on; then
        printf "> printf -v load_homebrew_string \"\\\neval \\\\\"\\\$(\\\\\"%%s/bin/brew\\\\\" "
        printf "shellenv)\\\\\"\\\n\\\" \"\$brew_prefix\"\n\n"
    fi
    
    printf -v load_homebrew_string "\neval \"\$(\"%s/bin/brew\" shellenv)\"\n" "$brew_prefix"
    
    if $echo_on; then
        printf "> printf \"%%s\" \"\$load_homebrew_string\" >> ~/.bash_profile\n\n"
    fi
    
    # Adds Homebrew's binary directory to the beginning of your $PATH variable in your .bash_profile
    # and spits an error if it fails
    if ! printf "%s" "$load_homebrew_string" >> ~/.bash_profile; then
        printf "An error occurred in trying to write to ~/.bash_profile.\n"
        printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
        exit 1
    fi
    
    if $echo_on; then
        printf "printf \"%%s\" \"\$load_homebrew_string\" >> ~/.zprofile\n\n"
    fi
    
    # Adds Homebrew's binary directory to the beginning of your $PATH variable in your .zprofile and
    # spits an error if it fails
    if ! printf "%s" "$load_homebrew_string" >> ~/.zprofile; then
        printf "An error occurred in trying to write to ~/.zprofile.\n"
        printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
        exit 1
    fi
    
    # Add Homebrew's binary directory to path for the purposes of the rest of this script as well
    eval "$("$brew_prefix/bin/brew" shellenv)"
fi

printf "%s/bin/ is in your \$PATH! ✅\n\n" "$(brew --prefix)"

# Installs a higher version of bash through homebrew if not already using homebrew's bash
if brew list bash >/dev/null 2>&1; then
    printf "Homebrew's bash is installed! ✅\n\n"
    printf "Updating bash... (Please be patient. This may take some time.) 📺\n\n"
    
    if $echo_on; then
        printf "> brew upgrade bash\n\n"
    fi
    
    # Upgrades bash
    brew upgrade bash >&3 2>&4
    
    if $echo_on; then
        printf "\n"
    fi
    
    printf "bash is updated!\n\n"
else
    printf "Homebrew's bash was not found. ❌\n\n"
    printf "Installing homebrew's bash... (Please be patient. This may take some time.) 📺\n\n"
    
    if $echo_on; then
        printf "> brew install bash\n\n"
    fi
    
    # Installs brew if it did not exist and exits the script if an error occurs in the installation
    if ! brew install bash >&3 2>&4; then
        printf "An error occurred in the installation of bash.\n"
        printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
        exit 1
    fi
    
    if $echo_on; then
        printf "\n"
    fi
    
    printf "Homebrew's bash is installed! ✅\n\n"
fi

# Checks if homebrew's bash is in the list of available Terminal shells and adds it if not
if grep -q "$(brew --prefix)/bin/bash" /etc/shells; then
    printf "The updated bash is in the list of available Terminal shells! ✅\n\n"
else
    printf "The updated bash is not in the list of available Terminal shells. ❌\n\n"
    printf "Adding the updated bash to the list of Terminal shells... 📜\n\n"
    
    if $echo_on; then
        printf "> sudo sh -c 'printf \"\\\n\$(brew --prefix)/bin/bash\\\n\" >> /etc/shells'\n\n"
    fi
    
    # Attempts to add Homebrew's bash to /etc/shells or the list of available Terminal shells
    if ! sudo sh -c 'printf "\n$(brew --prefix)/bin/bash\n" >> /etc/shells'; then
        printf "\nAn error occurred when trying to add the updated bash to the list of available "
        printf "Terminal shells.\n"
        printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
        exit 1
    fi
    
    printf "\nThe updated bash is in the list of available Terminal shells! ✅\n\n"
fi

# If your bash version is not 5.0+, link Terminal to the newest version installed if /bin/bash is
# the default
if [[ ${BASH_VERSION%%.*} -gt 4 ]]; then
    printf "Your bash version is up to date in your current shell! ✅\n\n"
else
    printf "Your current bash is not up to date in your current shell. ❌\n\n"
    printf "Updating your current bash for your shell... 🔼\n\n"
    
    if [ "$SHELL" = "/bin/bash" ]; then
        if $echo_on; then
            printf "> chsh -s \"\$(brew --prefix)/bin/bash\"\n\n"
        fi
        
        # Attempts to set the current default shell to use the updated bash and spits an error if it
        # fails
        if ! chsh -s "$(brew --prefix)/bin/bash" >&3 2>&4; then
            printf "\nAn error occurred when trying to update your terminal shell.\n"
            printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
            exit 1
        fi
        
        printf "\n"
    fi
    
    printf "Your bash version is up to date for your shell! ✅\n\n"
    printf "Now, please quit Terminal and rerun this script so "
    printf "it uses the appropriate version of bash.\n\n"
    exit 1
fi

# Installs the real gcc (not clang) through homebrew if it isn't already installed or update it if
# it is
if brew list gcc >/dev/null 2>&1; then
    printf "gcc is installed! ✅\n\n"
    printf "Updating gcc... (Please be patient. This may take some time.) 🔧\n\n"
    
    if $echo_on; then
        printf "> brew upgrade gcc\n\n"
    fi
    
    # Upgrades gcc
    brew upgrade gcc >&3 2>&4
    
    if $echo_on; then
        printf "\n"
    fi
    
    printf "gcc is updated!\n\n"
else
    printf "gcc (not clang/gcc) was not found. ❌\n\n"
    printf "Installing gcc... (Please be patient. This may take some time.) 🔧\n\n"
    
    if $echo_on; then
        printf "> brew install gcc\n\n"
    fi
    
    # Installs gcc if it did not exist and exits the script if an error occurs in the installation
    if ! brew install gcc >&3 2>&4; then
        printf "An error occurred in the installation of gcc.\n"
        printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
        exit 1
    fi
    
    if $echo_on; then
        printf "\n"
    fi
    
    printf "gcc is installed! ✅\n\n"
fi

# The below pertains to getting brew's newest version of gcc

if $echo_on; then
    printf "> gcc_string=\$(find \"\$(brew --prefix)/bin\" | while read -r f; do if "
    printf "[[ \$(basename \"\$f\") =~ ^gcc-[0-9]+$ ]]; then basename \"\$f\"; fi; done)\n\n"
fi

# Gets all of the files under Homebrew's binary directory, executes the basename command on each
# to get the filename without the path, checks if it matches "gcc-" followed by any number of
# digits, and stores it
gcc_string=$(find "$(brew --prefix)/bin" | while read -r f; \
do if [[ $(basename "$f") =~ ^gcc-[0-9]+$ ]]; then basename "$f"; fi; done)

if $echo_on; then
    printf "> readarray -t gcc_string_array <<< \"\$gcc_string\"\n\n"
fi

# Creates an array and stores all "gcc-" followed by digits strings into it
# (Credit to tinyurl.com/wtgkay2)
readarray -t gcc_string_array <<< "$gcc_string"

# Get the newest version of gcc

if $echo_on; then
    printf "> highest_num = 0\n\n"
fi

# Defines the highest gcc version, which is by default '0'
highest_num=0

if $echo_on; then
    printf "> for (( i=0; i<\${#gcc_string_array[@]}; ++i )); do\n"
    printf ">     if [[ \${gcc_string_array[\$i]##*-} -gt \$highest_num ]]; then\n"
    printf ">         highest_num=\${gcc_string_array[\$i]##*-}\n"
    printf ">     fi\n"
    printf "> done\n\n"
fi

# Iterates through each of the "gcc-" strings
for (( i=0; i<${#gcc_string_array[@]}; ++i )); do
    # If the number following the "gcc-" part of the string is greater than highest_num, set
    # highest_num to that greater value (compared arithmetically, not lexicographically)
    if [[ ${gcc_string_array[$i]##*-} -gt $highest_num ]]; then
        highest_num=${gcc_string_array[$i]##*-}
    fi
done

if $echo_on; then
    printf "> gcc_string=\"gcc-\$highest_num\"\n\n"
fi

# Sets the gcc string to the highest gcc version
gcc_string="gcc-$highest_num"

if $echo_on; then
    printf "> gcc_major_version=\"\$(gcc --version | grep \"^gcc\" | head -n 1 | sed \"s/.* //\" | "
    printf "sed \"s/\..*//\")\"\n\n"
fi

gcc_major_version="$(gcc --version | grep "^gcc" | head -n 1 | sed "s/.* //" | sed "s/\..*//")"

# Checks to ensure that the brew gcc is symlinked, and if not, links it (made to be compatible with
# future versions of gcc)
if [ -f "$(brew --prefix)/bin/gcc" ] && [ "$gcc_major_version" -ge "$highest_num" ]; then
    printf "gcc is symlinked correctly! ✅\n\n"
else
    if [ -f "$(brew --prefix)/bin/gcc" ]; then
        printf "An old version of gcc is symlinked. ❌\n\n"
        printf "Removing old symlink... 🗑️\n\n"
        
        if $echo_on; then
            printf "> rm \"\$(brew --prefix)/bin/gcc\"\n\n"
        fi
        
        if ! rm "$(brew --prefix)/bin/gcc" >&3 2>&4; then
            printf "An error occurred in the removal of the old symlink.\n"
            printf "Try running the script again, and if the problem still occurs, "
            printf "contact chawl025@umn.edu\n\n"
            exit 1
        fi
    else
        printf "gcc is not symlinked. ❌\n\n"
    fi
    
    printf "Symlinking homebrew's gcc to %s/bin/gcc... 🔗\n\n" "$(brew --prefix)"
    
    if $echo_on; then
        printf "> ln -s \"\$(brew --prefix)/bin/%s\" \$(brew --prefix)/bin/gcc\n\n" "$gcc_string"
    fi
    
    # Attempts to symlink the highest gcc version available and spits an error if it doesn't work
    if ! ln -s "$(brew --prefix)/bin/$gcc_string" "$(brew --prefix)/bin/gcc" >&3 2>&4; then
        printf "An error occurred in the symlinking of gcc.\n"
        printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
        exit 1
    fi
    
    printf "gcc is now symlinked correctly! ✅\n\n"
fi

# Installs coreutils through homebrew if it isn't already installed or update it if it is
if brew list coreutils >/dev/null 2>&1; then
    printf "coreutils is installed! ✅\n\n"
    printf "Updating coreutils... (Please be patient. This may take some time.) 🎛\n\n"
    
    if $echo_on; then
        printf "> brew upgrade coreutils\n\n"
    fi
    
    # Upgrades coreutils
    brew upgrade coreutils >&3 2>&4
    
    if $echo_on; then
        printf "\n"
    fi
    
    printf "coreutils is updated!\n\n"
else
    printf "coreutils was not found. ❌\n\n"
    printf "Installing coreutils... (Please be patient. This may take some time.) 🎛\n\n"
    
    if $echo_on; then
        printf "> brew install coreutils\n\n"
    fi
    
    # Installs coreutils if it did not exist and exits the script if an error occurs in the
    # installation
    if ! brew install coreutils >&3 2>&4; then
        printf "An error occurred in the installation of coreutils.\n"
        printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
        exit 1
    fi
    
    if $echo_on; then
        printf "\n"
    fi
    
    printf "coreutils is installed! ✅\n\n"
fi

# Installs gnu-sed through homebrew if it isn't already installed or update it if it is
if brew list gnu-sed >/dev/null 2>&1; then
    printf "gnu-sed is installed! ✅\n\n"
    printf "Updating gnu-sed... (Please be patient. This may take some time.) 🔨\n\n"
    
    if $echo_on; then
        printf "> brew upgrade gnu-sed\n\n"
    fi
    
    # Upgrades gnu-sed
    brew upgrade gnu-sed >&3 2>&4
    
    if $echo_on; then
        printf "\n"
    fi
    
    printf "gnu-sed is updated!\n\n"
else
    printf "gnu-sed was not found. ❌\n\n"
    printf "Installing gnu-sed... (Please be patient. This may take some time.) 🔨\n\n"
    
    if $echo_on; then
        printf "> brew install gnu-sed\n\n"
    fi
    
    # Installs gnu-sed if it did not exist and exits the script if an error occurs in the
    # installation
    if ! brew install gnu-sed >&3 2>&4; then
        printf "An error occurred in the installation of gnu-sed.\n"
        printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
        exit 1
    fi
    
    if $echo_on; then
        printf "\n"
    fi
    
    printf "gnu-sed is installed! ✅\n\n"
fi

# Installs gawk through homebrew if it isn't already installed or update it if it is
if brew list gawk >/dev/null 2>&1; then
    printf "gawk is installed! ✅\n\n"
    printf "Updating gawk... (Please be patient. This may take some time.) 👀\n\n"
    
    if $echo_on; then
        printf "> brew upgrade gawk\n\n"
    fi
    
    # Upgrades gawk
    brew upgrade gawk >&3 2>&4
    
    if $echo_on; then
        printf "\n"
    fi
    
    printf "gawk is updated!\n\n"
else
    printf "gawk was not found. ❌\n\n"
    printf "Installing gawk... (Please be patient. This may take some time.) 👀\n\n"
    
    if $echo_on; then
        printf "> brew install gawk\n\n"
    fi
    
    # Installs gawk if it did not exist and exits the script if an error occurs in the installation
    if ! brew install gawk >&3 2>&4; then
        printf "An error occurred in the installation of gawk.\n"
        printf "Try running the script again, and if the problem still occurs, "
        printf "contact chawl025@umn.edu\n\n"
        exit 1
    fi
    
    printf "gawk is installed! ✅\n\n"
fi

# Edit: Previously, I had an experimental version of valgrind installed on macOS here. However, it
# had too many issues for me to consider worth it. Use valgrind on a CSE labs machine or Ubuntu
# machine/VM

printf "Congratulations! Your computer should be completely set up! 💻\n\n"
printf "Please quit and reopen the Terminal to finalize the process.\n\n"
