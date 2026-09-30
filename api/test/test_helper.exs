Mox.defmock(Api.MailerMock, for: Api.Ports.MailerPort)
Mox.defmock(Api.ObjectStoreMock, for: Api.Ports.ObjectStorePort)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)
