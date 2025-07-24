require 'uri'
require 'net/http'

url = URI("https://hackathon.api.qloo.com/v2/insights?filter.type=urn%3Aentity%3Adestination")

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true

request = Net::HTTP::Get.new(url)
request["accept"] = 'application/json'
request["X-Api-Key"] = '0ey-hVJT4VMMeMeJH81malYFMjy31Wok_AupGwI2N3o'

response = http.request(request)
puts response.read_body
