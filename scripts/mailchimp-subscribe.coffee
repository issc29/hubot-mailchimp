# Description:
#   Add email to Mailchimp list
#
# Dependencies:
#   "mailchimp": "1.1.0"
#
# Configuration:
#   MAILCHIMP_API_KEY
#   MAILCHIMP_LIST_ID
#
# Commands:
#   hubot subscribe <email> <firstName> <lastName> <phone> - Add email to list
#   hubot unsubscribe <email> - Remove email from list
#   hubot mailchimp - Get statistics from latest mailing
#
# Author:
#   max, lmarburger, m-baumgartner, sporkmonger, stephenyeargin

Mailchimp = require('mailchimp-api-v3')
md5 = require('md5');

apiKey = process.env.MAILCHIMP_API_KEY
listId = process.env.MAILCHIMP_LIST_ID

mailchimp = new Mailchimp(apiKey);

module.exports = (robot) ->
  robot.respond /\bsubscribe (.+?) (.+?) (.+?) ([^ ]+)(.*)$/i, (message) ->
    subscribeToList message
  robot.respond /\bunsubscribe (.+@.+)/i, (message) ->
    unsubscribeFromList message
  robot.respond /\bmailchimp/i, (message) ->
    latestCampaign message

subscribeToList = (message) ->
  emailAddress = message.match[1]
  firstName = message.match[2]
  lastName = message.match[3]
  phoneNumber = message.match[4]

  message.reply "Attempting to subscribe #{emailAddress}..."

  subscribe_list =
    method : 'post'
    path : "/lists/#{listId}/members"
    body :
      email_address : emailAddress
      status : 'subscribed'
      merge_fields :
        FNAME : firstName
        LNAME : lastName
        PHONE : phoneNumber

  callback = (err, body) ->
    if err
      message.send "Uh oh, something went wrong: #{err}"
    else
      message.send "You successfully subscribed #{emailAddress}."

  mailchimp.request(subscribe_list, callback)

unsubscribeFromList = (message) ->
  emailAddress = message.match[1]
  message.reply "Attempting to unsubscribe #{emailAddress}..."

  email_md5 = md5(emailAddress.toLowerCase());

  unsubscribe_list =
    method : 'delete'
    path : "/lists/#{listId}/members/#{email_md5}"

  callback = (err, body) ->
    if err
      message.send "Uh oh, something went wrong: #{err}"
    else
      message.send "You successfully unsubscribed #{emailAddress}."

  mailchimp.request(unsubscribe_list, callback)

latestCampaign = (message) ->
  get_list_info =
    method : 'get'
    path : '/lists/' + listId

  callback = (err, body) ->
    if err
      message.send "Uh oh, something went wrong: #{err}"

    cid = body['id']
    campaign_name = body['name']
    member_count = body['stats']['member_count']
    campaign_last_sent = body['stats']['campaign_last_sent']
    open_rate = body['stats']['open_rate']
    click_rate = body['stats']['click_rate']
    unsubscribe_count = body['stats']['unsubscribe_count']
    #console.log(data);
    message.send "Last campaign \"#{campaign_name}\" was sent to #{member_count} subscribers on #{campaign_last_sent} \n   Unique Opens Rate: #{open_rate}\n   Click Rate: #{click_rate}\n   Unsubscribed: #{unsubscribe_count}"

  mailchimp.request(get_list_info, callback)
