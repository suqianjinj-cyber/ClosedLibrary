# M2 手動測試：開場關卡地圖

對照：設計平面圖 `docs/images/prologue_plan_v3.png`、實際俯視圖 `docs/images/prologue_map.png`、各區截圖 `docs/images/prologue_views.jpg`。

在 Godot 開啟 `levels/00_prologue/prologue.tscn`，按 **F6** 直接進入關卡（或按 F5 從主選單開始）。

| # | 操作 | 預期結果 | 通過 |
|---|---|---|---|
| 1 | 進入關卡 | 站在入口旁的還書推車邊，面向北方的閱覽區；**看不到手機直播介面** | ☐ |
| 2 | 按 F | 手機手電筒打開，前方出現光圈；再按一次關掉 | ☐ |
| 3 | 走到南牆入口 | 有鐵門（捲在上方）與上鎖的玻璃門，出不去 | ☐ |
| 4 | 繞服務櫃檯一圈 | L 形櫃檯，前板朝西與朝北；從南端缺口可進入櫃檯內側 | ☐ |
| 5 | 在櫃檯內側蹲下，走到桌面下方 | 可以蹲進去，放開 Ctrl 站不起來 | ☐ |
| 6 | 閱覽區 | 6 張桌子，長邊有擋板、兩端只有桌腳；2 盞桌燈亮著 | ☐ |
| 7 | 西側書架區 | 8 排書架，走道窄；有一排中間有缺口（放紙箱）；靠西牆的窄道被推車堵住 | ☐ |
| 8 | 北側書架區 | 8 排高書架，走道窄；東北角只能從最北邊的窄道走進去 | ☐ |
| 9 | 走進東北角死角 | 很暗，需要手電筒；看著書架角落出現「按 E 開始直播」 | ☐ |
| 10 | 按 E | 這時才出現手機直播介面與彈幕 | ☐ |
| 11 | 偵錯器 → 監視器 → FPS | 1280×720 下 ≥ 30 | ☐ |

躲藏點（10 個）與巡邏路線目前只是標記，要到 M3、M4 才會有作用。在編輯器的場景樹中可以看到 `HidingSpots`（H01～H10）與 `PatrolRoute`（W01～W13、A01～A04）節點。

## 自動檢查

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/auto/test_m2_map.tscn
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/auto/test_m1_player.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/auto/test_flow.gd
```

`test_m2_map` 是場景（不加 `--script`），因為導航需要正常的遊戲迴圈。
