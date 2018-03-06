#
# Description:
#   Backlog to Trello
#
# Dependencies:
#   "node-trello": "^1.1.1"
#
# Configuration:
#    BACKLOG_TEAM_NAME
#    BACKLOG_USERID
#    TRELLO_BOARD_ID
#    TRELLO_KEY
#    TRELLO_POST_DONE
#    TRELLO_POST_NEW
#    TRELLO_POST_UPDATE
#    TRELLO_TOKEN
#
# Commands:
#
# 参考:
# https://github.com/hubotio/hubot/blob/master/docs/scripting.md
#

# backlog チーム名
backlogTeam = process.env.BACKLOG_TEAM_NAME

module.exports = (robot) ->
  # トレロ操作用の node モジュール
  Trello = require("node-trello")
  # HTTP クライアント
  Request = require 'request'
  # トレロ操作用オブジェクト つくる　
  trelloInstance = new Trello(process.env.TRELLO_KEY, process.env.TRELLO_TOKEN)

  # backlog からのリクエストを受け付ける
  # room で渡ってきた値とリクエストボディを取得
  # 今回はためしに room に Slack チャンネル名 ramdom を渡している(でも使ってない)
  robot.router.post "/:room", (req, res) ->
    # 次の行をコメントアウト解除で Slack 連携
    # room = req.params.room

    # Backlog からのリクエスト取得
    # https://developer.nulab-inc.com/ja/docs/backlog/api/2/get-recent-updates/
    body = if req.body.payload? then JSON.parse req.body.payload else req.body

    # trello に登録するようの内容を整形
    # へろくの環境変数で設定した担当者以外はスキップ
    assigneeUserId = if body.content.assignee? then body.content.assignee.userId else null
    if assigneeUserId isnt null and assigneeUserId isnt process.env.BACKLOG_USERID
      return

    # カードのタイトルに入れる内容 ... 課題の キーと課題の名前
    issueUrl = "https://#{backlogTeam}.backlog.jp/view/#{body.project.projectKey}-#{body.content.key_id}"
    title = "[#{body.project.projectKey}-#{body.content.key_id}] "
    title += "#{body.content.summary}"

    # カードの本文に入れる内容 ... 課題のURL と 内容
    description = "#{issueUrl}\n"
    description += "優先度 : #{body.content.priority.name}\n"
    description += "#{body.content.description}"

    # トレロにGETリクエスト 対象ボードのアーカイブされてないカードたちを取得
    # https://trello.readme.io/v1.0/reference#boardsboardidtest
    trelloInstance.get "/1/boards/#{process.env.TRELLO_BOARD_ID}/cards", {"cards": "visible"}, (err, data) ->
      if err
        console.log err
        return
      for card in data
        titleTrimed = title.replace(/\s+/g, "")
        cardNameTrimed = card.name.replace(/\s+/g, "")
        if "#{titleTrimed}" is "#{cardNameTrimed}"
          cardId = card.id
          Request.delete
            url: "https://api.trello.com/1/cards/#{cardId}"
            qs:
              key: "#{process.env.TRELLO_KEY}",
              token: "#{process.env.TRELLO_TOKEN}"

    # トレロにGETリクエスト 対象ボードのラベル一覧を取得
    # バックログの優先度ID
    # 2 : 高
    # 3 : 中
    # 4 : 低
    # https://developer.nulab-inc.com/ja/docs/backlog/api/2/get-priority-list/
    # https://developers.trello.com/reference/#boardsboardidlabels
    trelloInstance.get "/1/boards/#{process.env.TRELLO_BOARD_ID}/labels", (err, data) ->
      if err
        console.log err
        return
      labelId = null
      for label in data
        switch label.color
          when "red"
            if body.content.priority.id is 2
              labelId = label.id
          when "yellow"
            if body.content.priority.id is 3
              labelId = label.id
          when "green"
            if body.content.priority.id is 4
              labelId = label.id

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
              idList: process.env.TRELLO_POST_NEW
              idLabels: labelId
            }, (err, data) ->
              if err
                console.log err
                return
          when 2
            trelloInstance.post "/1/cards/", {
              name: title
              desc: description
              idList: process.env.TRELLO_POST_UPDATE
              idLabels: labelId
            }, (err, data) ->
              if err
                console.log err
                return
          when 3
            trelloInstance.post "/1/cards/", {
              name: title
              desc: description
              idList: process.env.TRELLO_POST_DONE
              idLabels: labelId
            }, (err, data) ->
              if err
                console.log err
                return
          when 4
            trelloInstance.post "/1/cards/", {
              name: title
              desc: description
              idList: process.env.TRELLO_POST_DONE
              idLabels: labelId
            }, (err, data) ->
              if err
                console.log err
                return
          else
            return

      # カードを追加したら Slack に投稿したい場合はコメントアウト解除
      # if title?
      #   robot.messageRoom room, title
      #   res.end "OK"
      # else
      #   robot.messageRoom room, "Backlog integration error."
      #   res.end "Error"
      #
      catch error
        robot.send
        res.end "Error"
