require 'set'

MEANS_OF_DEATH = %w[
  MOD_UNKNOWN
  MOD_SHOTGUN
  MOD_GAUNTLET
  MOD_MACHINEGUN
  MOD_GRENADE
  MOD_GRENADE_SPLASH
  MOD_ROCKET
  MOD_ROCKET_SPLASH
  MOD_PLASMA
  MOD_PLASMA_SPLASH
  MOD_RAILGUN
  MOD_LIGHTNING
  MOD_BFG
  MOD_BFG_SPLASH
  MOD_WATER
  MOD_SLIME
  MOD_LAVA
  MOD_CRUSH
  MOD_TELEFRAG
  MOD_FALLING
  MOD_SUICIDE
  MOD_TARGET_LASER
  MOD_TRIGGER_HURT
  MOD_NAIL
  MOD_CHAINGUN
  MOD_PROXIMITY_MINE
  MOD_KAMIKAZE
  MOD_JUICED
  MOD_GRAPPLE
].freeze

def run_script(file_path)
  check_file_existence(file_path)

  matches = []
  current_match = []
  is_match_active = false

  File.foreach(file_path) do |line|
    if line.include?('InitGame:')
      init_game(matches, current_match)
      is_match_active = true
    elsif is_match_active
      add_line_to_match(current_match, line)
    end

    if line.include?('ShutdownGame:')
      finalize_match(matches, current_match, is_match_active)
      is_match_active = false
    end
  end

  matches_info = analyze_matches(matches)
  print_matches_info(matches_info)
end

def init_game(matches, current_match)
  matches << current_match.dup unless current_match.empty?
  current_match.clear
end

def add_line_to_match(current_match, line)
  current_match << line
end

def process_match_lines(match, match_info)
  match.each { |line| process_match_line(line, match_info) }
end

def update_match_info(match_info, killer_name, victim_name, weapon_name)
  if killer_name.strip == '<world>'
    decrease_kills(match_info, victim_name)
  else
    update_killer_data(match_info, killer_name)
    increase_kills_by_means(match_info, weapon_name)
  end
  add_participant(match_info, victim_name) unless victim_name.strip == '<world>'
end

def finalize_match(matches, current_match, is_match_active)
  matches << current_match.dup if is_match_active
  current_match.clear
end

def analyze_matches(matches)
  matches.map.with_index(1) do |match, index|
    match_info = initialize_match_info(index)
    process_match_lines(match, match_info)
    update_player_ranking(match_info)
    match_info
  end
end

def initialize_match_info(index)
  {
    match_number: index,
    total_kills: 0,
    participants: Set.new,
    kills_per_participant: Hash.new(0),
    ranking_kills: Hash.new(0),
    kills_by_means: Hash.new(0),
    player_ranking: []
  }
end

def process_match_line(line, match_info)
  return unless line.match?(/\bKill:/)

  match_info[:total_kills] += 1
  kill_details = line.match(/Kill: \d+ \d+ \d+: (.+) killed (.+) by (.+)/)
  return unless kill_details

  update_match_info(match_info, *kill_details.captures)
end

def update_player_ranking(match_info)
  match_info[:player_ranking] = match_info[:ranking_kills].sort_by { |_, kills| -kills }.map(&:first)
end

def update_killer_data(match_info, killer_name)
  add_participant(match_info, killer_name)
  increase_kills_per_participant(match_info, killer_name)
  increase_ranking_kills(match_info, killer_name)
end

def decrease_kills(match_info, victim_name)
  match_info[:ranking_kills][victim_name] -= 1 unless victim_name.strip == '<world>'
end

def add_participant(match_info, player_name)
  match_info[:participants].add(player_name)
end

def increase_kills_per_participant(match_info, player_name)
  match_info[:kills_per_participant][player_name] += 1
end

def increase_ranking_kills(match_info, player_name)
  match_info[:ranking_kills][player_name] += 1
end

def increase_kills_by_means(match_info, weapon_name)
  match_info[:kills_by_means][weapon_name] += 1
end

def print_player_ranking(match_info)
  puts 'Player Ranking by Kill Points (1 for each dead and -1 if was dead by the world):'
  match_info[:player_ranking].each_with_index do |participant, index|
    puts "  #{index + 1}. #{participant}: #{match_info[:ranking_kills][participant]} kill points"
  end
end

def print_kills_by_means(info)
  puts 'Kills by Means:'
  info[:kills_by_means].each { |means, count| puts "  #{means}: #{count}" }
end

def print_kills_per_participant(info)
  puts 'Kills per Participant:'
  info[:kills_per_participant].each { |participant, kills| puts "  #{participant}: #{kills}" }
end

def print_participants(info)
  puts "Participants: #{info[:participants].join(', ')}"
end

def check_file_existence(file_path)
  return if File.exist?(file_path)

  puts "File not found: #{file_path}"
  exit 1
end

def print_matches_info(matches_info)
  matches_info.each do |info|
    puts "Match #{info[:match_number]}:"
    puts "Total Kills: #{info[:total_kills]}"
    print_participants(info)
    print_kills_per_participant(info)
    print_kills_by_means(info)
    print_player_ranking(info)
    puts '----------'
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.length != 1
    puts 'Usage: ruby game_log_parser.rb <path_to_log_file>'
    exit 1
  end
  run_script(ARGV[0])
end
