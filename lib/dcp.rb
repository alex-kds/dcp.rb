require 'httparty'
require 'json'

class DCP
  def self.send_message(key, token)
    body = {
      oAuthToken: token.token,
      expiry: token.expires_at.to_i,
      endpoint: ENV['PROXY_URL']
    }

    message_string = {
      owner: key.address,
      signature: sign(key, body),
      body: body
    }.to_json

    message = {signedMessage: message_string}

    response = HTTParty.post(ENV['PROXY_URL'], body: message)
    reply_body = response.body
    reply = JSON.parse reply_body

    unless reply['success']
      Rails.logger.error "Proxy service returned error #{reply['error']}"
    end

    return reply
  end

  def self.sign(key, body)
    sig = key.personal_sign body.to_json
    r,s,v = Eth::Signature.dissect sig
    {
      r: {
        type: "Buffer",
        data: Eth::Util.hex_to_bin(r).bytes
      },
      s: {
        type: "Buffer",
        data: Eth::Util.hex_to_bin(s).bytes
      },
      v: Eth::Util.hex_to_bin(v).bytes
    }
  end
end
