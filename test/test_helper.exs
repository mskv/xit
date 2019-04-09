ExUnit.start()

File.ls!(Path.join(__DIR__, "support"))
|> Enum.filter(fn file ->
  String.ends_with?(file, ".ex")
end)
|> Enum.each(fn file ->
  Code.require_file("support/#{file}", __DIR__)
end)
