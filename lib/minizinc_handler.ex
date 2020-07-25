defmodule MinizincHandler do
  @moduledoc """
    Behaviour, default implementations and helpers for solution handlers.
  """


  @callback handle_solution(solution :: map())
            :: {:ok, term} | :stop | {:stop, any()}

  @callback handle_summary(summary :: map())
            :: :ok | {:ok, any()}

  @callback handle_minizinc_error(mzn_error :: map()) :: any

  ## Provide stubs for MinizincHandler behaviour
  defmacro __using__(_) do
    quote do
      @behaviour MinizincHandler
      def handle_solution(_solution) do :ok end
      def handle_summary(_summary) do :ok end
      def handle_minizinc_error(_error) do :ok end
      defoverridable MinizincHandler
    end
  end

  @doc false

  # Helpers to call handler callbacks uniformly.

  def handle_solver_event(:solution, solution, solution_handler) do
    handle_solution(solution, solution_handler)
  end

  def handle_solver_event(:summary, summary, solution_handler) do
    handle_summary(summary, solution_handler)
  end

  def handle_solver_event(:minizinc_error, error, solution_handler) do
    handle_minizinc_error(error, solution_handler)
  end

  # The solution handler can be either a function, or a callback module.
  #
  @doc false

  def handle_solution(solution, solution_handler) when is_function(solution_handler) do
    solution_handler.(:solution, solution)
  end

  def handle_solution(solution, solution_handler) do
    solution_handler.handle_solution(solution)
  end

  @doc false
  def handle_summary(summary, solution_handler) when is_function(solution_handler) do
    solution_handler.(:summary, summary)
  end

  def handle_summary(summary, solution_handler) do
    solution_handler.handle_summary(summary)
  end

  @doc false
  def handle_minizinc_error(error, solution_handler) when is_function(solution_handler) do
    solution_handler.(:minizinc_error, error)
  end

  def handle_minizinc_error(error, solution_handler) do
    solution_handler.handle_minizinc_error(error)
  end


end

defmodule MinizincHandler.DefaultAsync do
  @moduledoc false

  require Logger
  use MinizincHandler

  def handle_solution(solution) do
    Logger.info "Solution: #{inspect solution}"
  end

  def handle_summary(summary) do
    Logger.info "Summary: #{inspect summary}"
  end

  def handle_minizinc_error(error) do
    Logger.info "Minizinc error: #{inspect error}"
  end
end

defmodule MinizincHandler.DefaultSync do
  @moduledoc false

  require Logger
  require Record
  use MinizincHandler

  def handle_solution(solution)  do
    {:solution, solution}
  end

  def handle_summary(summary)  do
    {:summary, summary}
  end

  def handle_minizinc_error(error)  do
    {:error, error}
  end
end
