require 'set'

MEANS_OF_DEATH = %w(
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
).freeze

def init_game(matches, current_match)
  matches << current_match.dup unless current_match.empty?
  current_match.clear
end

def add_line_to_match(current_match, line)
  current_match << line
end

def process_match_line(line, match_info)
  return unless line.match?(/\bKill:/)

  match_info[:total_kills] += 1
  kill_details = line.match(/Kill: \d+ \d+ \d+: (.+) killed (.+) by (.+)/)
  return unless kill_details

  update_match_info(match_info, *kill_details.captures)
end

def update_match_info(match_info, killer_name, victim_name, weapon_name)
  unless killer_name.strip == "<world>"
    match_info[:participants].add(killer_name)
    match_info[:kills_per_participant][killer_name] += 1
    match_info[:ranking_kills][killer_name] += 1
    match_info[:kills_by_means][weapon_name] += 1
  else
    match_info[:ranking_kills][victim_name] -= 1 unless victim_name.strip == "<world>"
  end
  match_info[:participants].add(victim_name) unless victim_name.strip == "<world>"
end

def finalize_match(matches, current_match, is_match_active)
  matches << current_match.dup if is_match_active
  current_match.clear
end

def analyze_matches(matches)
  matches.map.with_index(1) do |match, index|
    match_info = {
      match_number: index,
      total_kills: 0,
      participants: Set.new,
      kills_per_participant: Hash.new(0),
      ranking_kills: Hash.new(0),
      kills_by_means: Hash.new(0),
      player_ranking: []
    }

    match.each { |line| process_match_line(line, match_info) }

    match_info[:player_ranking] = match_info[:ranking_kills].sort_by { |_, kills| -kills }.map(&:first)
    match_info
  end
end

def print_matches_info(matches_info)
  matches_info.each do |info|
    puts "Match #{info[:match_number]}:"
    puts "Total Kills: #{info[:total_kills]}"
    puts "Participants: #{info[:participants].join(', ')}"
    puts "Kills per Participant:"
    info[:kills_per_participant].each { |participant, kills| puts "  #{participant}: #{kills}" }
    puts "Kills by Means:"
    info[:kills_by_means].each { |means, count| puts "  #{means}: #{count}" }
    puts "Player Ranking by Kill Points (1 for each dead and -1 if was dead by the world):"
    info[:player_ranking].each_with_index { |participant, index| puts "  #{index + 1}. #{participant}: #{info[:ranking_kills][participant]} kill points" }
    puts "----------"
  end
end

def run_script(file_path)
  unless File.exist?(file_path)
    puts "File not found: #{file_path}"
    exit 1
  end

  matches = []
  current_match = []
  is_match_active = false

  File.foreach(file_path) do |line|
    if line.include?("InitGame:")
      init_game(matches, current_match)
      is_match_active = true
    elsif is_match_active
      add_line_to_match(current_match, line)
    end

    if line.include?("ShutdownGame:")
      finalize_match(matches, current_match, is_match_active)
      is_match_active = false
    end
  end

  matches_info = analyze_matches(matches)
  print_matches_info(matches_info)
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.length != 1
    puts "Usage: ruby game_log_parser.rb <path_to_log_file>"
    exit 1
  end
  run_script(ARGV[0])
end
