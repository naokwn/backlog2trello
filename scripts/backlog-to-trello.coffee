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

    issueUrl = "#{backlogUrl}view/#{body.project.projectKey}-#{body.content.key_id}"
    title = "[#{body.project.projectKey}-#{body.content.key_id}] "
    title += "#{body.content.summary}"
    description = "#{issueUrl}\n"
    description += "#{body.content.description}"

    cardId = false
    trelloInstance.get "/1/boards/#{process.env.HUBOT_TRELLO_BOARD_ID}/cards", {"cards": "visible"}, (err, data) ->
      if (err)
        console.log err
        return
      for card in data
        console.log card.name
        console.log title
        titleTrimed = title.replace(/\s+/g, "")
        cardNameTrimed = card.name.replace(/\s+/g, "")

        pattern = ///#{titleTrimed.trim}///g
          #`/#{hoge}Script/`
        if pattern.test("#{cardNameTrimed}")
          console.log card
          cardId = card.id

    # 1 : 未処理
    # 2 : 処理中
    # 3 : 処理済み
    # 4 : 完了

    console.log("cardId #{cardId}")
    if cardId isnt false
      trelloInstance.delete "1/cards/#{cardId}", (err,data) ->
        if (err)
          console.log err
          return

    try
      switch body.content.status.id
        when 1
          trelloInstance.post "/1/cards/", {
            name: title
            desc: description
            idList: process.env.HUBOT_TRELLO_POST_NEW
          }, (err, data) ->
            if (err)
              console.log err
              return
        when 2
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
#            idList: process.env.HUBOT_TRELLO_POST_DELETE
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
