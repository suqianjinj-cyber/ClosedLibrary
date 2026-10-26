extends Node
## 全域事件：各系統透過這裡互相通知，不直接引用彼此。
## 只宣告訊號，不寫任何邏輯。

## 玩家準心對到可互動物件時送出提示文字；沒有對到時送出空字串
signal interaction_prompt_changed(text: String)

## 要求在畫面下方顯示一句字幕（主角自言自語）
signal subtitle_requested(text: String, duration: float)

## 直播開始
signal stream_started

## 送出一則彈幕到直播畫面
signal chat_message_posted(user: String, text: String)

## 玩家的手機手電筒開關
signal flashlight_toggled(on: bool)

## 手機沒電
signal battery_depleted
