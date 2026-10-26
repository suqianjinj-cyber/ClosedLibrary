class_name HidingSpot
extends Marker3D
## 躲藏點標記。位置＝玩家躲藏時的位置，朝向＝躲藏時面對的方向。
## 風險不是在這裡設定的：館員能不能看到玩家，是由實際的牆、桌子擋板、書架擋住視線來決定。
## risk_note 只是給設計者看的說明。

enum Mode {
	CROUCH,  ## 蹲下躲在遮蔽物後面，不需要按鍵
	ENTER,  ## 按 E 躲進去（桌底、櫃檯內側、閱讀隔間），再按 E 出來
}

@export var spot_id := 0
@export var mode := Mode.CROUCH
@export var risk_note := ""
## ENTER 模式：躲進去後的眼睛高度（公尺）
@export var eye_height := 0.45
