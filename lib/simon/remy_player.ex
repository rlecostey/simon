defmodule Simon.RemyPlayer do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    start(opts)

    state = %{
      name: opts[:name],
      game_server: opts[:game_server],
      guess_delay: opts[:guess_delay],
      round_delay: opts[:round_delay],
      sequence_color: []
    }

    {:ok, state}
  end

  def start(opts) do
    GenServer.cast(opts[:game_server], {:join, self(), opts[:name]})
  end

  def handle_info({:sequence_color, round, color}, state) do
    updated_state =
      Map.merge(state, %{round: round, sequence_color: state.sequence_color ++ [color]})

    {:noreply, updated_state}
  end

  def handle_info({:your_round, _round}, state) do
    wait_delay(state.round_delay)
    run_sequence(state.game_server, state.guess_delay, state.sequence_color)
    {:noreply, state}
  end

  def handle_info({:current_player, {player_pid, player_name}}, state) do
    updated_state =
      Map.merge(state, %{
        player: player_pid,
        player_name: player_name,
        round: 0,
        sequence_color: []
      })

    {:noreply, updated_state}
  end

  def handle_info({:guess, _color, _}, state) do
    {:noreply, state}
  end

  def handle_info({:win, _}, state) do
    updated_state = Map.merge(state, %{round: 0, sequence_color: []})
    {:noreply, updated_state}
  end

  def handle_info({:lose}, state) do
    updated_state = Map.merge(state, %{round: 0, sequence_color: []})
    {:noreply, updated_state}
  end

  defp run_sequence(_game_server, _guess_delay, []), do: :ok

  defp run_sequence(game_server, guess_delay, [head | tail]) do
    case color_guess(game_server, head) do
      :ok ->
        wait_delay(guess_delay)
        run_sequence(game_server, guess_delay, tail)

      :bad_guess ->
        {:error, "bad guess"}
    end
  end

  defp color_guess(game_server, color) do
    GenServer.call(game_server, {:color_guess, color}, :infinity)
  end

  defp wait_delay(delay) do
    Process.sleep(delay)
  end
end
