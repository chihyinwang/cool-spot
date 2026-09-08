# 兩題文案與排列

2026-09-08，依使用者確認實作。

- Who can use this spot?：Everyone／Limited access／Not sure。
- Cost to use：Free to use／Purchase required／Entry fee／Not sure。
- 移除費用解釋；資格說明縮為 E.g. students, members or residents.；未恢復已移除的兩個文字輸入區塊。
- 兩題共用同一個原生 Picker 排列：ViewThatFits 在寬度足夠時呈現同列，否則上下排列；輔助字級保留完整 inline 選項。第一輪发现額外 HStack 間距造成提早換行，已移除重複間距並確認。

## 驗證

最終編譯成功：`/tmp/cool-spot-entry-layout-20260908-final-build.log`。

iPhone 一般字級確認 Who can use this spot?＋Limited access、Cost to use＋Purchase required 皆同列，選單選值正確且沒有恢復兩個輸入欄；見 `phone-inline.png`。輔助工具樹中的選單名稱仍包含各題完整標題。

iPad 深色、最大輔助字級確認四個費用選項完整、資格例子正常換行；見 `tablet-large-dark.png`。此畫面於第一輪取得，後續修正僅涉及非輔助字級的間距。未逐一驗證所有裝置寬度，未做實機或完整 VoiceOver 檢查。

這次為文案與排版調整，沒有新增模型測試，也沒有重跑上一輪的 48 項測試。B06、现行流程文件及既有測試中的費用標題已同步。

原本 iPhone 模擬器已安裝並啟動最終版本；安裝前後 journey snapshot、感謝紀錄、外觀偏好校驗值相同。備份：`/Users/chihyinwang/.codex/cool-spot-backup-entry-layout-20260908/`。兩台隔離測試裝置已關閉。
