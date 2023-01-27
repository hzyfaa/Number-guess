#! /bin/bash

PSQL="psql -q --username=freecodecamp --dbname=number_guess -t --no-align -c"
#Generate random number to guess
RNDM_NUM=$((($RANDOM % 1001) + 1))

MAIN() {
  #Prompt user for username
  echo -e "\nEnter your username: "
  read USERNAME
  #Check if valid username is given
  if [[ -z $USERNAME ]]; then
    while [[ -z $USERNAME ]]; do
      echo -e "\nEnter a valid username: "
      read USERNAME
    done
  fi

  #Look up user in database and display welcome message
  USER_ID="$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")"

  if [[ -z $USER_ID ]]; then
    $PSQL "INSERT INTO users(username) VALUES('$USERNAME')"
    USER_ID="$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")"
    $PSQL "INSERT INTO games(user_id) VALUES($USER_ID)"

    echo -e "\nWelcome, $USERNAME! It looks like this is your first time here.\n"
  else
    GAMES_PLAYED="$($PSQL "SELECT games_played FROM games WHERE user_id=$USER_ID")"
    USER_BEST="$($PSQL "SELECT best_game FROM games WHERE user_id=$USER_ID")"

    echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $USER_BEST guesses.\n"
  fi

  #Prompt user for number
  echo "Guess the secret number between 1 and 1000:"
  read GUESS

  ATTEMPTS=1

  #Evaluate guess and update user game data after correct guess has been made
  if [[ $GUESS -eq $RNDM_NUM ]]; then
    echo -e "\nYou guessed it in $ATTEMPTS tries. The secret number was $RNDM_NUM. Nice job!"
    UPDATE_USER_DATA
  else
    while ! [[ $GUESS == $RNDM_NUM ]]; do
      ATTEMPTS=$(($ATTEMPTS + 1))
      if [[ $GUESS =~ ^[+-]?[0-9]+$ ]]; then
        if [[ $GUESS -lt 1 || $GUESS -gt 1000 ]]; then
          echo "Integer must be within range (1-1000), guess again: "
          read GUESS
        elif [[ $GUESS -lt $RNDM_NUM ]]; then
          echo "It's higher than that, guess again:"
          read GUESS
        elif [[ $GUESS -gt $RNDM_NUM ]]; then
          echo "It's lower than that, guess again:"
          read GUESS
        fi
      else
        echo "That is not an integer, guess again:"
        read GUESS
      fi
    done
    echo -e "\nYou guessed it in $ATTEMPTS tries. The secret number was $RNDM_NUM. Nice job!"
    UPDATE_USER_DATA
  fi

}

UPDATE_USER_DATA() {
  #Update number of games played by user and lowest number of attempts
  if [[ -z $GAMES_PLAYED ]]; then
    $PSQL "UPDATE games SET games_played = 1 WHERE user_id=$USER_ID"
    $PSQL "UPDATE games SET best_game=$ATTEMPTS WHERE user_id=$USER_ID"
  else
    $PSQL "UPDATE  games SET games_played = ($GAMES_PLAYED + 1) WHERE user_id=$USER_ID"

    if [[ $ATTEMPTS < $USER_BEST ]]; then
      $PSQL "UPDATE games SET best_game=$ATTEMPTS WHERE user_id=$USER_ID"
    fi
  fi

}

MAIN
