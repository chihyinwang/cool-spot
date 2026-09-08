# 費用與進入條件文案驗證

2026-09-07。範圍：使用者同意的費用選項、Limited access 說明，以及具體入場條件的呈現。

## 已完成

- Cost to use this spot：Free to use／Purchase required／Entry fee／Not sure。提示說明應填寫實際避暑空間的要求，僅在消費是使用條件時選 Purchase required。
- Who can use this spot?：Everyone／Limited access／Not sure。選項旁直接附學生、會員、住戶的例子。Limited access 可補充 Who is it limited to?，欄位保持選填。
- Tickets and booking 獨立記錄免費票、預約等條件，不因選 Everyone 而清除。費用與資格仍不阻止送審。
- 場所頁優先顯示具體身分條件；缺少限制細節時顯示 Requirements not confirmed。修改其他場所資訊、轉為既有場所更新及送審，都會保留原有條件。Saved 的場所摘要同步使用相同資料。
- 原型的費用資料來自 Swift 範例及當次記憶體，沒有把持久化的舊 Ticket required／Purchase expected 答案轉成新的收費事實。現有範例未新增收費或身分限制。

## 驗證結果

**48 passed／0 failed／0 skipped**，見 `test-summary.json`。新增測試涵蓋免費票與費用分離、切換資格後保留訂票資訊、編輯已審核場所時保留具體条件，以及轉更新、送審流程。

| 原生操作 | 結果與證據 |
|---|---|
| iPhone：先點文字欄位、捲動，再開費用選單 | 四個选項完整，背景未跳回上方；`cost-options.png` |
| iPhone：Free to use＋免費票說明，Limited access 改 Everyone | 免費票說明保留；`free-ticket-everyone.png` |
| iPad：深色、最大輔助字級 | 原生 inline 選項完整顯示，說明正常換行；`cost-large-dark.png` |
| iPhone：有具體身分條件的場所頁 | 直接顯示條件與訂票資訊；`place-entry-summary.png` |

場所頁與 iPad 的條件使用 `--preview-entry-requirements` 隔離檢查資料，畫面以 Example 標明，不寫入使用者資料。這不是公開審核發布測試；正式審核及公開地圖更新仍未接通。本輪未做實機或完整 VoiceOver 測試。

測試指令：`xcodebuild test -project cool-spot.xcodeproj -scheme cool-spot -destination 'platform=iOS Simulator,id=8AA009D5-F5E5-4FA7-813D-51E129758BCA' -derivedDataPath /tmp/cool-spot-entry-copy-20260907 CODE_SIGNING_ALLOWED=NO`

紀錄：`/tmp/cool-spot-entry-copy-20260907-tests.log`。結果：`/tmp/cool-spot-entry-copy-20260907/Logs/Test/Test-cool-spot-2026.09.07_23-49-36-+0100.xcresult`。

新版已安裝並啟動於原本 iPhone 17 Pro Max 模擬器，停在 Explore。安裝前後收藏／回報／私人備註所在的 journey snapshot、感謝紀錄及外觀偏好校驗值相同。備份位於 `/Users/chihyinwang/.codex/cool-spot-backup-entry-copy-20260907/`。兩台隔離測試裝置已關閉。

重測入口：`OWNER-JOURNEY-WALKTHROUGH.md` 的 B06。
