Mox.defmock(Api.MailerMock, for: Api.Adapters.MailerPort)
Mox.defmock(Api.ObjectStoreMock, for: Api.Adapters.ObjectStorePort)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)
