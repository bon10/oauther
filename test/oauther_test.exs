defmodule OAutherTest do
  use ExUnit.Case

  test "HMAC-SHA1 signature" do
    creds = OAuther.credentials(consumer_secret: "kd94hf93k423kf44", token_secret: "pfkkdhi9sl3r4s00", consumer_key: "dpf43f3p2l4k3l03", token: "nnch734d00sl2jdk")
    params = protocol_params(creds)
    assert signature(params, creds, "/photos") == "16DDt0Q6wqlGr/PbOnPh6LnxyY0="
  end

  test "RSA-SHA1 signature" do
    creds = OAuther.credentials(method: :rsa_sha1, consumer_secret: fixture_path("private_key.pem"), consumer_key: "dpf43f3p2l4k3l03")
    params = protocol_params(creds)
    assert signature(params, creds, "/photos") == "rg7JWzaxn0bLwynemCJ6K1IEPgTjX0Cg5xjpkWTDtrJfuPkX5w6YoJljeBo4+qNdojEYSfmOHXEYLIYmcm0+Di35KqJY2PfQVwe0EdEfaTzCBXYkauFhfOeoxSACID8FKJjN0N9UXXyYlLeeRnY7mb3gEHQhNbocqidchti1ASE="

    private_key = File.read!(fixture_path("private_key.pem"))
    creds = OAuther.credentials(method: :rsa_sha1, consumer_secret: private_key, consumer_key: "dpf43f3p2l4k3l03")
    params = protocol_params(creds)
    assert signature(params, creds, "/photos") == "rg7JWzaxn0bLwynemCJ6K1IEPgTjX0Cg5xjpkWTDtrJfuPkX5w6YoJljeBo4+qNdojEYSfmOHXEYLIYmcm0+Di35KqJY2PfQVwe0EdEfaTzCBXYkauFhfOeoxSACID8FKJjN0N9UXXyYlLeeRnY7mb3gEHQhNbocqidchti1ASE="
  end

  test "PLAINTEXT signature" do
    creds = OAuther.credentials(method: :plaintext, consumer_secret: "kd94hf93k423kf44", consumer_key: "dpf43f3p2l4k3l03")

    assert signature([], creds, "/photos") == "kd94hf93k423kf44&"
  end

  test "signature with query params" do
    creds = OAuther.credentials(consumer_secret: "kd94hf93k423kf44", token_secret: "pfkkdhi9sl3r4s00", consumer_key: "dpf43f3p2l4k3l03", token: "nnch734d00sl2jdk")
    params = protocol_params(creds)
    assert signature(params, creds, "/photos?size=large") == "75PnucagDoUF3Ilr5SuN7Lpa12g="
  end

  test "Authorization header" do
    {header, req_params} = OAuther.header [
      {"oauth_consumer_key",     "dpf43f3p2l4k3l03"},
      {"oauth_signature_method", "PLAINTEXT"},
      {"oauth_signature",        "kd94hf93k423kf44&"},
      {"build",                  "Luna Park"}
    ]
    assert header == {"Authorization", ~S(OAuth oauth_consumer_key="dpf43f3p2l4k3l03", oauth_signature_method="PLAINTEXT", oauth_signature="kd94hf93k423kf44%26")}
    assert req_params == [{"build", "Luna Park"}]
  end

  defp fixture_path(file_path) do
    Path.expand("fixtures", __DIR__)
    |> Path.join(file_path)
  end

  defp protocol_params(creds) do
    OAuther.protocol_params([file: "vacation.jpg", size: "original"], creds)
    |> rewrite()
  end

  defp rewrite(params) do
    for param <- params do
      case param do
        {"oauth_nonce", _} ->
          put_elem(param, 1, "kllo9940pd9333jh")

        {"oauth_timestamp", _} ->
          put_elem(param, 1, 1191242096)

        _otherwise -> param
      end
    end
  end

  defp signature(params, creds, path) do
    url = "http://photos.example.net" <> path
    OAuther.signature("get", url, params, creds)
  end
end
