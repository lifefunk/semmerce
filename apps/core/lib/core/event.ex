defmodule Core.Event do
  alias Core.Structure

  @doc """
  Adding new unpublished event to the given existing list of events
  """
  @spec add_event(events :: list(Structure.event()), event :: Structure.event()) :: list(Structure.event())
  def add_event(events, event) do
    [event | events]
  end

end
