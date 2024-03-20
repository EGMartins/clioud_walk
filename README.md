# Game Log Parser

The Game Log Parser is a Ruby application designed to analyze and summarize Quake 3 log files. It extract meaningful information about matches, including details like total kills, participants, and kill methods.

## Features

- **Parse Game Logs**: Efficiently processes Quake 3 game log files to extract match data.
- **Match Summaries**: Generates summaries for each match, including total kills, participant names, and kills per participant.
- **Kills Analysis**: Provides detailed insights into kills by means, helping understand game dynamics.
- **Player Ranking**: Calculates and displays player rankings based on performance.

## Getting Started

### Prerequisites

Ensure you have Ruby installed on your system. The Game Log Parser is tested with Ruby 2.7 and above. You can check your Ruby version by running:

```sh
ruby -v
```
## Installation
Clone the repository to your local machine:
```sh
git clone https://github.com/yourusername/game-log-parser.git
cd game-log-parser
```
## Usage
To run the Game Log Parser, navigate to the project directory and execute:
```sh
ruby game_log_parser.rb path_to_your_log_file.log
```
**Replace path_to_your_log_file.log with the actual path to your game log file.**

## Running Tests
This project uses Minitest for testing. To run the tests, execute:
```sh
ruby game_log_parser_test.rb
```


