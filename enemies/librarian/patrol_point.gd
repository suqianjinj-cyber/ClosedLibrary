class_name PatrolPoint
extends Marker3D
## 館員巡邏路線上的一個點。館員會依照節點順序走，走完最後一點再回到第一點。

## 抵達後停留幾秒（0 = 不停留）
@export var wait_time := 0.0
## 停留時用手電筒左右掃視的角度（度）；掃視方向以這個點的朝向為中心
@export var sweep_angle := 0.0
## 勾選後只在「替代路線」那一圈才會走（例如偶爾繞進櫃檯內側）
@export var alternate_only := false
