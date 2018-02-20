#
# Description:
#   Backlog to Trello
#
# Dependencies:
#   "node-trello": "^1.1.1"
#
# Configuration:
#    HUBOT_TRELLO_KEY
#    HUBOT_TRELLO_TOKEN
#    HUBOT_TRELLO_POST_LIST
#    ※heroku 環境設定
#
# Commands:
#
#

backlogUrl = 'https://testam.backlog.jp/'

module.exports = (robot) ->
  Trello = require("node-trello")
  trelloInstance = new Trello(process.env.HUBOT_TRELLO_KEY, process.env.HUBOT_TRELLO_TOKEN)

  robot.router.post "/trello/:room", (req, res) ->
    room = req.params.room
    body = req.body

    console.log(body)

    issueUrl = "#{backlogUrl}view/#{body.project.projectKey}-#{body.content.key_id}"
    title = "[#{body.project.projectKey}-#{body.content.key_id}] "
    title += "#{body.content.summary}"
    description = "#{issueUrl}\n"
    description += "#{body.content.description}"

    #1:課題の追加
    #2:課題の更新
    #4:課題の削除

    try
      switch body.type
        when 1
          label = '課題の追加'
          trelloInstance.post "/1/cards/", {
            name: title
            desc: description
            idList: process.env.HUBOT_TRELLO_POST_NEW
          }, (err, data) ->
            if (err)
              console.log err
              return
        when 2
          label = '課題の更新'
          trelloInstance.post "/1/cards/", {
            name: title
            desc: description
            idList: process.env.HUBOT_TRELLO_POST_UPDATE
          }, (err, data) ->
            if (err)
              console.log err
              return
#        when 4
#          label = '課題の削除'
#          trelloInstance.post "/1/cards/", {
#            name: title
#            desc: description
#            idList: process.env.HUBOT_TRELLO_POST_LIST_DELETE
#          }, (err, data) ->
#            if (err)
#              console.log err
#              return
        else
          return

#      # カードを追加したら Slack に投稿したい場合はここを利用
#      if title?
#        robot.messageRoom room, title
#        res.end "OK"
#      else
#        robot.messageRoom room, "Backlog integration error."
#        res.end "Error"
#
    catch error
      robot.send
      res.end "Error"
