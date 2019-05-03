Application.ensure_all_started(:ex_machina)

ExUnit.configure(exclude: [:pending, :ignore])
ExUnit.start()
