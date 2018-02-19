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
  t = new Trello(process.env.HUBOT_TRELLO_KEY, process.env.HUBOT_TRELLO_TOKEN)

  robot.router.post "/:room", (req, res) ->
    room = req.params.room
    body = req.body

    try
      switch body.type
          when 1
              label = '課題の追加'
          else
              # 課題関連以外はスルー
              return

      # 投稿メッセージを整形
      url = "#{backlogUrl}view/#{body.project.projectKey}-#{body.content.key_id}"

      title = "[#{body.project.projectKey}-#{body.content.key_id}] "
      title += "#{body.content.summary}"

      description = "#{url}\n"
      description += "登録者：#{body.createdUser.name}\n\n"
      description += "#{body.content.description}"

      t.post "/1/cards/", {
        name: title
        desc: description
        idList: process.env.HUBOT_TRELLO_POST_LIST_SNK
      }, (err, data) ->
        if (err)
          console.log err
          return

#      # カードを追加したら Slack に投稿したい場合はここを利用
      if title?
          robot.messageRoom room, title
          res.end "OK"
      else
          robot.messageRoom room, "Backlog integration error."
          res.end "Error"

    catch error
      robot.send
      res.end "Error"
