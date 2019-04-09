defmodule Support.Fs do
  @initial_cwd File.cwd!()
  @mock_project_path Path.join(__DIR__, "_tmp")

  def setup() do
    File.mkdir_p!(@mock_project_path)
    File.cd!(@mock_project_path)
  end

  def cleanup() do
    File.cd!(@initial_cwd)
    File.rm_rf!(@mock_project_path)
  end
end
