#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Game logic, passing user's guess as an argument
GUESSING_GAME() {
  GAMES_PLAYED_UPDATE=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE username='$USERNAME'")
  if [[ "$GAMES_PLAYED_UPDATE" == "UPDATE 1" ]]
  then
    RANDOM_NUMBER=$((1 + RANDOM % 1000))
    USER_GUESS=$1
    NUM_GUESSES=1

    #loop while wrong
    while [[ "$USER_GUESS" != "$RANDOM_NUMBER" ]]
    do
      #check for int
      if ! [[ "$USER_GUESS" =~ ^[0-9]+$ ]]
      then
        echo -e "That is not an integer, guess again:"
        read USER_GUESS
      elif [[ "$USER_GUESS" -gt "$RANDOM_NUMBER" ]]
      then
        NUM_GUESSES=$((NUM_GUESSES + 1))
        echo -e "\nIt's lower than that, guess again:"
        read USER_GUESS
      elif [[ "$USER_GUESS" -lt "$RANDOM_NUMBER" ]]
      then
        NUM_GUESSES=$((NUM_GUESSES + 1))
        echo -e "\nIt's higher than that, guess again:"
        read USER_GUESS
      fi
    done

    echo -e "\nYou guessed it in $NUM_GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!"

    # Check and update best score if necessary
    BEST_SCORE=$($PSQL "SELECT best_score FROM users WHERE username='$USERNAME'")
    if [[ -z "$BEST_SCORE" ]] || [[ "$NUM_GUESSES" -lt "$BEST_SCORE" ]]
    then
      UPDATE_BEST_SCORE=$($PSQL "UPDATE users SET best_score = $NUM_GUESSES WHERE username='$USERNAME'")
    fi

  else
    echo -e "\nError updating games played!"
  fi
}

# Read username
echo -e "\nEnter your username:"
read USERNAME
USERNAME_RESULT=$($PSQL "SELECT username FROM users WHERE username='$USERNAME'")

# If username doesn't exist
if [[ -z "$USERNAME_RESULT" ]]
then
  USERNAME_INSERT_RESULT=$($PSQL "INSERT INTO users(username) VALUES ('$USERNAME')")
  if [[ "$USERNAME_INSERT_RESULT" == "INSERT 0 1" ]]
  then
    echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
  else
    echo "Error. New user cannot be made."
    exit 0
  fi

  echo -e "\nGuess the secret number between 1 and 1000:"
  read USER_GUESS
  GUESSING_GAME "$USER_GUESS"
else
  # Report on previous games
  USER_DATA_RESULT=$($PSQL "SELECT games_played, best_score FROM users WHERE username='$USERNAME'")
  echo "$USER_DATA_RESULT" | while IFS="|" read GAMES_PLAYED BEST_SCORE
  do
    echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_SCORE guesses."
  done  

  # Run the game
  echo -e "\nGuess the secret number between 1 and 1000:"
  read USER_GUESS
  GUESSING_GAME "$USER_GUESS"
fi
