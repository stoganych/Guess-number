#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
RANDOM_NUMBER=$((1 + RANDOM % 1000))
COUNT=1
echo $RANDOM_NUMBER
echo "Enter your username:"
read USERNAME
GET_USERNAME=$($PSQL "SELECT username FROM users WHERE username = '$USERNAME'")
if [[ -z $GET_USERNAME ]]
then
echo "Welcome, $USERNAME! It looks like this is your first time here."
INSERT_USER=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
USER_ID=$(echo $($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'") | sed 's/ //g')
INSERT_GAME=$($PSQL "INSERT INTO games(user_id, game_count, best_game) VALUES($USER_ID, 0, 999)")
else
USER_ID=$(echo $($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'") | sed 's/ //g')
GAMES=$(echo $($PSQL "SELECT game_count FROM games FULL JOIN users USING(user_id) WHERE user_id = $USER_ID") | sed 's/ //g')
BEST_GAME=$(echo $($PSQL "SELECT best_game FROM games FULL JOIN users USING(user_id) WHERE user_id = $USER_ID") | sed 's/ //g')
echo "Welcome back, $USERNAME! You have played $GAMES games, and your best game took $BEST_GAME guesses."
fi
USER_ID=$(echo $($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'") | sed 's/ //g')
GAMES=$(echo $($PSQL "SELECT game_count FROM games FULL JOIN users USING(user_id) WHERE user_id = $USER_ID") | sed 's/ //g')
BEST_GAME=$(echo $($PSQL "SELECT best_game FROM games FULL JOIN users USING(user_id) WHERE user_id = $USER_ID") | sed 's/ //g')

PLAY_GAME () {
  echo $1
  read USER_GUESS
  if [[ ! $USER_GUESS =~ ^[0-9]+$ ]]
  then
   PLAY_GAME "That is not an integer, guess again:"
  fi
  if [[ $USER_GUESS > $RANDOM_NUMBER ]]
  then
   COUNT=$((COUNT + 1))
   PLAY_GAME "It's higher than that, guess again:"
  elif [[ $USER_GUESS < $RANDOM_NUMBER ]]
  then
   COUNT=$((COUNT + 1))
   PLAY_GAME "It's lower than that, guess again:"
  elif [[ $USER_GUESS = $RANDOM_NUMBER ]]
  then
    if [[ $BEST_GAME > $COUNT ]]
    then
    UPDATE_GAME=$($PSQL "UPDATE games SET game_count = (( $GAMES + 1 )), best_game = $COUNT WHERE user_id = $USER_ID")
    else
    UPDATE_GAME=$($PSQL "UPDATE games SET game_count = (( $GAMES + 1 )), best_game = $BEST_GAME WHERE user_id = $USER_ID")
    fi
    echo "You guessed it in $COUNT tries. The secret number was $RANDOM_NUMBER. Nice job!"
  fi
}

PLAY_GAME "Guess the secret number between 1 and 1000:"