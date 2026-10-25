extends Node
## 讀取 data/ 資料夾裡的 JSON。劇情文字、彈幕、規則都放在 JSON，程式只用 id 讀取。

var _cache := {}


## 例：DataLoader.load_json("dialogue/intro") 會讀取 res://data/dialogue/intro.json
func load_json(id: String) -> Variant:
	if _cache.has(id):
		return _cache[id]
	var path := "res://data/%s.json" % id
	if not FileAccess.file_exists(path):
		push_error("找不到資料檔：%s" % path)
		return null
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data == null:
		push_error("資料檔格式錯誤（請檢查逗號、引號、括號）：%s" % path)
		return null
	_cache[id] = data
	return data
