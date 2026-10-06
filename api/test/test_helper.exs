Mox.defmock(Api.MailerMock, for: Api.Adapters.MailerPort)
Mox.defmock(Api.ObjectStoreMock, for: Api.Adapters.ObjectStorePort)
Mox.defmock(Api.CommunityHealthMock, for: Api.Adapters.CommunityHealthPort)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)
