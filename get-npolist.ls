'use strict'
# scrape the data in http://www.npo.org.tw/npolist.asp
# ~6471 entries

require! <[ http cheerio fs ]>

npo-detail-url = 'http://www.npo.org.tw/npolist_detail.asp?id=%id'

output-filename = \data/npolist.json

delay = 1000

failure =
  count: 0
  max: 20

get-npo-detail = (id, on-detail, done) ->
  res <- http.get npo-detail-url.replace /\%id/, id
  if res.status-code != 200
    console.log " ! #id (#{res.status-code})"
    ++failure.count if id > 6600  # set a hard lower bound of IDs to try
    return done res.status-code if failure.count > failure.max
    return set-timeout (-> get-npo-detail id + 1, on-detail, done), delay
  console.log " . #id"
  body = ''
  res.on \data, -> body += it
  <- res.on \end
  $ = (cheerio.load body)
  detail = {id}
  $ 'section table tr' .map -> detail[$ @ .children \th .text!] = $ @ .children \td .text! .replace /(^[\s\n]+|[\s\n]+$)/g, ''
  detail.\機構代碼 = +detail.\機構代碼
  detail.\服務項目 = detail.\服務項目 ?.split /\s+/
  if detail.\成立日期
    found-date = new Date detail.\成立日期
    detail.\成立日期 =
      year: found-date?.get-year! + 1900
      month: found-date?.get-month! + 1
      day: found-date?.get-date!
  on-detail null, detail
  set-timeout (-> get-npo-detail id + 1, on-detail, done), delay

npo-data = []

status <- get-npo-detail 1, (error, data) ->
  throw error if error
  npo-data.push data
error <- fs.write-file output-filename, JSON.stringify npo-data
throw error if error
process.exit 0
