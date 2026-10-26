# 閉館後，請勿入館

第一人稱 3D 恐怖遊戲，使用 Godot 製作。

## 開發環境

- Godot **4.7.2-stable**（請固定使用這個版本開啟專案）
- 渲染器：Compatibility（目標為沒有獨立顯示卡的文書筆電）
- 語言：GDScript
- 介面語言：繁體中文（字型：Noto Sans TC，OFL 授權）

## 資料夾說明

| 資料夾 | 內容 |
|---|---|
| `assets/` | 模型、貼圖、音效、字型等素材 |
| `data/` | 劇情文字與規則資料（JSON），改劇情只改這裡 |
| `core/` | 全域系統（Autoload） |
| `player/` | 玩家控制 |
| `interaction/` | 可互動物件、躲藏區、聲音 |
| `props/` | 家具（目前為佔位模型，之後換成 Tripo 模型，見 [docs/01_模型清單.md](docs/01_模型清單.md)） |
| `enemies/` | 敵人與共用感知元件 |
| `levels/` | 教學關、四個關卡、轉場、結局 |
| `ui/` | HUD、直播彈幕、告示、QTE、選單 |
| `docs/` | 設計與規劃文件 |
| `tests/` | 手動測試清單 |

`.gitkeep` 是空白檔案，只是為了讓 Git 保留空資料夾，放入其他檔案後可以刪除。

## 操作

| 按鍵 | 動作 |
|---|---|
| W A S D／方向鍵 | 移動 |
| 滑鼠 | 轉視角 |
| Shift | 奔跑（往前時） |
| Ctrl／C | 蹲下 |
| E | 互動 |
| F | 手機手電筒 |
| ESC | 放開滑鼠 |

## 素材授權

見 [assets/CREDITS.md](assets/CREDITS.md)。

## 規劃

見 [docs/00_專案初始化規劃.md](docs/00_專案初始化規劃.md)。
