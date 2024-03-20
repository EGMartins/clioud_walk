require 'minitest/autorun'
require_relative 'game_log_parser'

class GameLogParserTest < Minitest::Test
  def setup
    @matches = []
    @current_match = []
    @match_info = {
      total_kills: 0,
      participants: Set.new,
      kills_per_participant: Hash.new(0),
      ranking_kills: Hash.new(0),
      kills_by_means: Hash.new(0),
      player_ranking: []
    }
  end

  def test_init_game
    @current_match = ['some', 'preliminary', 'data']
    init_game(@matches, @current_match)
    assert_equal 1, @matches.size
    assert_empty @current_match
  end

  def test_add_line_to_match
    line = "Test Line"
    add_line_to_match(@current_match, line)
    assert_includes @current_match, line
  end

  def test_process_match_line_non_kill
    line = "NonKill: 0 0 0: TestLine"
    process_match_line(line, @match_info)
    assert_equal 0, @match_info[:total_kills]
    assert_empty @match_info[:participants]
  end

  def test_process_match_line_kill
    line = "Kill: 1022 2 22: Isgalamido killed Mocinha by MOD_ROCKET"
    process_match_line(line, @match_info)
    assert_equal 1, @match_info[:total_kills]
    assert_includes @match_info[:participants], "Isgalamido"
    assert_equal 1, @match_info[:kills_per_participant]["Isgalamido"]
    assert_equal 1, @match_info[:kills_by_means]["MOD_ROCKET"]
  end

  def test_update_match_info_with_new_participants
    update_match_info(@match_info, 'Isgalamido', 'Mocinha', 'MOD_ROCKET')
    assert_equal Set['Isgalamido', 'Mocinha'], @match_info[:participants]
    assert_equal 1, @match_info[:kills_per_participant]['Isgalamido']
    assert_equal 1, @match_info[:kills_by_means]['MOD_ROCKET']
    assert_equal 1, @match_info[:ranking_kills]['Isgalamido']
  end

  def test_update_match_info_with_existing_participant
    @match_info[:participants].add('Isgalamido')
    @match_info[:kills_per_participant]['Isgalamido'] = 1
    @match_info[:ranking_kills]['Isgalamido'] = 1

    update_match_info(@match_info, 'Isgalamido', 'Mocinha', 'MOD_ROCKET')
    assert_equal 2, @match_info[:kills_per_participant]['Isgalamido'], "Kills for Isgalamido should be incremented"
    assert_equal 2, @match_info[:ranking_kills]['Isgalamido'], "Ranking kills for Isgalamido should be incremented"
  end

  def test_update_match_info_kill_by_world
    update_match_info(@match_info, '<world>', 'Mocinha', 'MOD_ROCKET')
    assert_equal -1, @match_info[:ranking_kills]['Mocinha'], "Ranking kills for Mocinha should be decremented because killed by <world>"
  end

  def test_finalize_match_when_active
    @current_match = ['Kill: 0 1 22: Player1 killed Player2 by MOD_ROCKET']
    is_match_active = true

    finalize_match(@matches, @current_match, is_match_active)

    assert_equal 1, @matches.size, "Matches array should contain one match"
    assert_empty @current_match, "Current match should be cleared after finalizing"
  end

  def test_finalize_match_when_not_active
    @current_match = ['Kill: 0 1 22: Player1 killed Player2 by MOD_ROCKET']
    is_match_active = false
    match_size = @matches.size

    finalize_match(@matches, @current_match, is_match_active)

    assert_empty @matches, "Matches array should be empty when match is not active"
    assert_equal 0, @current_match.size, "Current match should be cleared if match was not active"
  end

  def test_analyze_matches_with_simple_data
    matches = [
      [
        "InitGame: \\sv_floodProtect\\1\\sv_maxPing\\0\\sv_minPing\\0\\sv_maxRate\\10000",
        "Kill: 1022 2 22: Isgalamido killed Mocinha by MOD_ROCKET",
        "Kill: 1022 3 22: Isgalamido killed Dono da bola by MOD_ROCKET",
        "ShutdownGame:"
      ]
    ]

    analyzed_matches = analyze_matches(matches)

    assert_equal 1, analyzed_matches.size
    match_info = analyzed_matches.first
    assert_equal 2, match_info[:total_kills]
    assert_equal Set['Isgalamido', 'Mocinha', 'Dono da bola'], match_info[:participants]
    assert_equal 2, match_info[:kills_per_participant]['Isgalamido']
    assert_equal 2, match_info[:kills_by_means]['MOD_ROCKET']
    assert_includes match_info[:player_ranking], 'Isgalamido'
  end

  def test_analyze_matches_with_world_kill
    matches = [
      [
        "InitGame: \\sv_floodProtect\\1\\sv_maxPing\\0\\sv_minPing\\0\\sv_maxRate\\10000",
        "Kill: 0 2 22: <world> killed Isgalamido by MOD_TRIGGER_HURT",
        "Kill: 1022 2 22: Isgalamido killed Mocinha by MOD_ROCKET",
        "ShutdownGame:"
      ]
    ]

    analyzed_matches = analyze_matches(matches)

    assert_equal 1, analyzed_matches.size
    match_info = analyzed_matches.first
    assert_equal 2, match_info[:total_kills]
    assert_equal Set['Isgalamido', 'Mocinha'], match_info[:participants]
    assert_equal 1, match_info[:kills_per_participant]['Isgalamido']
    assert_equal 0, match_info[:ranking_kills]['Isgalamido'], "Isgalamido should have -1 in ranking kills due to death by <world>"
    assert_equal 1, match_info[:kills_by_means]['MOD_ROCKET']
  end

  def test_print_matches_info
    matches_info = [
      {
        match_number: 1,
        total_kills: 10,
        participants: Set.new(['Player1', 'Player2']),
        kills_per_participant: {'Player1' => 7, 'Player2' => 3},
        kills_by_means: {'MOD_ROCKET' => 5, 'MOD_SHOTGUN' => 5},
        player_ranking: ['Player1', 'Player2'],
        ranking_kills: {'Player1' => 7, 'Player2' => 3}
      }
    ]
    expected_output = <<~OUTPUT
      Match 1:
      Total Kills: 10
      Participants: Player1, Player2
      Kills per Participant:
        Player1: 7
        Player2: 3
      Kills by Means:
        MOD_ROCKET: 5
        MOD_SHOTGUN: 5
      Player Ranking by Kill Points (1 for each dead and -1 if was dead by the world):
        1. Player1: 7 kill points
        2. Player2: 3 kill points
      ----------
    OUTPUT

    output = capture_io do
      print_matches_info(matches_info)
    end.first

    assert_equal expected_output, output
  end
end
