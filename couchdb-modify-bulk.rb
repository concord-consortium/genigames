#!/usr/bin/env ruby

require 'net/http'
require 'uri'

COUCH_USER='user'
COUCH_PASS='password'
COUCH_DB='genigames'

def save(url, doc)
  uri = URI(URI.escape(url))
  http = Net::HTTP.new(uri.host, uri.port)
  post = Net::HTTP::Put.new(uri.request_uri)
  post.basic_auth(COUCH_USER,COUCH_PASS)
  post.body = doc

  response = http.request(post)
  puts "saved:\n#{response.body}"
end

def get(url)
  res = Net::HTTP.get_response(URI(URI.escape(url)))
  return res.body if res.is_a? Net::HTTPSuccess
  raise "invalid url"
end

def modify(doc)
  modified = false
  new_doc = doc.gsub(/"position":\{"([xy])":(\d+),"([xy])":(\d+)\},/) do |match|
    new_x = ($1 == "x" ? $2 : $4).to_i - 20
    new_y = ($3 == "y" ? $4 : $2).to_i - 60
    modified = true
    %!"position":{"x":#{new_x},"y":#{new_y}},!
  end
  return {:doc => new_doc, :modified => modified}
end

# get the list of all docs
all = get("http://genigames.dev.concord.org/couchdb/#{COUCH_DB}/_design/show/_view/all")
all.scan(/"_id":"([^"]*)"/) do |ids|
  if ids && ids.size > 0
    id = ids[0]
    puts "Modifying: #{id}"
    doc_url = "http://genigames.dev.concord.org/couchdb/#{COUCH_DB}/#{id}"
    doc = get(doc_url)
    modified_doc = modify(doc)
    if modified_doc[:modified]
      puts "Saving modified doc: #{id}"
      save(doc_url, modified_doc[:doc])
    end
  end
end
