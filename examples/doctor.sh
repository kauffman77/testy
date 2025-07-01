#!/bin/bash

# An interactive program with the prompt 'DOCTOR>';
# 
# If these services # are insufficient, consult with a trained
# professional like `emacs --eval '(DOCTOR)'`
echo "What brings you to the socratic therapist today?"
while true; do
      read -p "DOCTOR> " LINE
      if [[ "$1" == "-echo" ]]; then
          echo "$LINE"
      fi
      if [[ "$?" != "0" ]]; then
          break
      fi
      case "$LINE" in
          "quit") break ;;
          *)  
              echo "Tell me more about that" ;;
      esac
done
echo
echo "Oh, that's time. We'll pick up on that next week."
