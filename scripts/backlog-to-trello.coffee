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
# 参考:
# https://github.com/hubotio/hubot/blob/master/docs/scripting.md
#

# backlog チーム名
backlogTeam = 'testam'

module.exports = (robot) ->
  # 色々操作するための初期準備
  # トレロ操作用の node モジュール
  Trello = require("node-trello")
  # HTTP クライアント
  Request = require 'request'
  # トレロ操作用オブジェクト つくる　
  # へろくの環境変数にあらかじめセットしといた トレロのキーと トレロのトークンを渡す
  trelloInstance = new Trello(process.env.HUBOT_TRELLO_KEY, process.env.HUBOT_TRELLO_TOKEN)

  # backlog からのリクエストを受け付ける
  # `express` ... という framework の仕組みを使ったHTTPリスナ
  # /trello/というエンドポイントと、:room というパラメタをデフォルト8080ポートで待ち構えている
  # room で渡ってきた値とリクエストボディを取得
  # 今回はためしに room に Slack チャンネル名 ramdom を渡している(でも使ってない)
  robot.router.post "/trello/:room", (req, res) ->
    # room = req.params.room
    # body には backlog から次のように JSON が入ってくる
    # https://developer.nulab-inc.com/ja/docs/backlog/api/2/get-recent-updates/
    body = if req.body.payload? then JSON.parse req.body.payload else req.body

    # trello に登録するようの内容を整形
    # 課題のURL
    issueUrl = "https://#{backlogTeam}.backlog.jp/view/#{body.project.projectKey}-#{body.content.key_id}"
    # カードのタイトルに入れる内容 ... 課題の キーと課題の名前
    title = "[#{body.project.projectKey}-#{body.content.key_id}] "
    title += "#{body.content.summary}"
    # カードの本文に入れる内容 ... 課題のURL と 内容
    description = "#{issueUrl}\n"
    description = "優先度 : #{body.content.priority.name}\n"
    description += "#{body.content.description}"

    # トレロにGETリクエスト 対象ボードのラベル一覧を取得
    # バックログの優先度ID
    # 2 : 高
    # 3 : 中
    # 4 : 低
    # https://developer.nulab-inc.com/ja/docs/backlog/api/2/get-priority-list/
    # https://developers.trello.com/reference/#boardsboardidlabels
    rep = trelloInstance.get "/1/boards/id/labels", (err, data) ->
      if err
        console.log.err
        return
      for label in data
        switch "#{body.content.priority.id}"
          when 2
            if label.color == 'red'
              return label.id
          when 3
            if label.color == 'yellow'
              return label.id
          when 4
            if label.color == 'green'
              return label.id
          else
            return

    console.log(body)
    console.log(rep)

    # トレロにGETリクエスト 対象ボードのアーカイブされてないカードたちを取得
    # https://trello.readme.io/v1.0/reference#boardsboardidtest
    trelloInstance.get "/1/boards/#{process.env.HUBOT_TRELLO_BOARD_ID}/cards", {"cards": "visible"}, (err, data) ->
      if err
        console.log err
        return
      for card in data
        titleTrimed = title.replace(/\s+/g, "")
        cardNameTrimed = card.name.replace(/\s+/g, "")
#        console.log titleTrimed
#        console.log cardNameTrimed
        if "#{titleTrimed}" is "#{cardNameTrimed}"
          cardId = card.id
          Request.delete
            url: "https://api.trello.com/1/cards/#{cardId}"
            qs:
              key: "#{process.env.HUBOT_TRELLO_KEY}",
              token: "#{process.env.HUBOT_TRELLO_TOKEN}"

    # バックログの課題のステータスによって分岐
    # ステータスによって、事前に設定して置いたリストにカードが入る(好みで処理済みと完了はあえて同じにしてる)
    # ステータスIDと操作は次の通り
    # 1 : 未処理
    # 2 : 処理中
    # 3 : 処理済み
    # 4 : 完了
    # https://developers.trello.com/reference/#cards-2
    try
      switch body.content.status.id
        when 1
          trelloInstance.post "/1/cards/", {
            name: title
            desc: description
            idList: process.env.HUBOT_TRELLO_POST_NEW
#            idLabels: labelId
          }, (err, data) ->
            if (err)
              console.log err
              return
        when 2
          trelloInstance.post "/1/cards/", {
            name: title
            desc: description
            idList: process.env.HUBOT_TRELLO_POST_UPDATE
#            idLabels: labelId
          }, (err, data) ->
            if (err)
              console.log err
              return
        when 3
          trelloInstance.post "/1/cards/", {
            name: title
            desc: description
            idList: process.env.HUBOT_TRELLO_POST_DONE
#            idLabels: labelId
          }, (err, data) ->
            if (err)
              console.log err
              return
        when 4
          trelloInstance.post "/1/cards/", {
            name: title
            desc: description
            idList: process.env.HUBOT_TRELLO_POST_DONE
#            idLabels: labelId
          }, (err, data) ->
            if (err)
              console.log err
              return
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
