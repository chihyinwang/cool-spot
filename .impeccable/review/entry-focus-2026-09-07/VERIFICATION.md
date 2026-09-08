# 進入資格與選單跳位修正 — 2026-09-07

本輪接續使用者的 12:32:52 錄影與「那你去改吧」授權。只修改公開場所表單及相關驗證，保留現有原地選單與自訂時長操作。

## 已實作

- 原本的 `Can visitors enter this spot?` Yes／No 必填門檻已移除。`Who can use this spot?` 統一放在 Entry and seating 選填區：Everyone／Certain people only／Not sure。
- 限定身分可補充 Entry requirements，例如學生證；此欄也可略過。改成 Everyone／Not sure 時，清除不再適用的身分說明，避免把隱藏的限制送進提案。
- Entry cost 與使用資格分開。學生限定與免費可以同時成立。資格、身分說明皆會保留在送審提案與重複地點轉更新的資料中。
- 未命名地點仍需要可解碼的識別照片，但不因未知或限定身分而阻止送審。照片規則與室內／戶外無關。
- 表單的文字欄位現在有明確的 FocusState；捲動立即結束鍵盤輸入，互動捲動時清除文字焦點，導覽切換及提交文字時也會清除。保留原生 Picker，沒有為所有短答案新增子頁。
- 大字級使用原生 inline Picker 完整顯示三個資格選項；一般字級保留選單。這修正了第一輪檢查發現的 Certain people only 被截短問題。

## 跳位的證據與回歸檢查

使用者錄影約 4.75–5.25 秒：點開 Entry，答案尚未改變、鍵盤未顯示，背景就由 Entry and seating 跳回名稱區。不是新增小時／分鐘列造成。

修正前已在隔離 iPhone 重現：同一份無名室內表單、相同瀑布範例照片，沒有先點名稱時開 Entry 正常；點過 Place name、往下捲，再開 Entry 就跳回名稱區。截圖保留於 `before/focus-jump.png`。

修正後以相同路徑實際操作：

| 情境 | 結果 |
|---|---|
| 名稱留白、加照片，不回答使用資格 | Send for review 可用，不需猜測 Yes |
| 點 Place name → 向下捲 → 開 Entry cost | 背景保持在選單列位置；`entry-menu-after-name-focus.png` |
| 再次點 Place name → 向下捲 → 開 Time limit | 背景保持原位；`time-menu-after-name-focus.png` |
| 選 Certain people only＋Free to enter，填 TEST STUDENT CARD | 兩種資訊可並存，文字保留，送審按鈕可用 |
| 從學生證說明切到 Time limit → Other duration → Minutes 35 | 正常操作，顯示 1 hr 35 min；未跳回名稱區 |
| iPad 深色、最大輔助字級 | 三個選項完整顯示且可選，Certain people only 換行而不截短；`entry-options-large-dark.png` |

原生操作使用 Cool Spot Journey QA（iPhone 17 Pro Max）與 Cool Spot Tablet QA（iPad Pro 11-inch），皆為 iOS 26.4 模擬器。一般字級的焦點回歸在最終大字級樣式修正前完成；後續修改只針對資格選項的大字級顯示及相同 Picker 的抽取，焦點處理未變。

## 自動測試與交付

最終版本 **46 passed／0 failed／0 skipped**，詳見 `test-summary.json`。新增與更新的回歸檢查涵蓋：所有使用資格皆能送審、有效照片仍必需、學生證條件與免費可並存、轉更新與送審不遺失條件、資格修改算有效更正、移除過時的隱藏限制。

指令：`xcodebuild test -project cool-spot.xcodeproj -scheme cool-spot -destination 'platform=iOS Simulator,id=8AA009D5-F5E5-4FA7-813D-51E129758BCA' -derivedDataPath /tmp/cool-spot-entry-focus-20260907 CODE_SIGNING_ALLOWED=NO`

最終紀錄：`/tmp/cool-spot-entry-focus-20260907-tests-final.log`；結果：`/tmp/cool-spot-entry-focus-20260907/Logs/Test/Test-cool-spot-2026.09.07_12-49-58-+0100.xcresult`。捲動問題使用原生操作及截圖驗收，沒有把模型測試宣稱成自動 UI 回歸測試。

新版已安裝並啟動於使用者原本的 iPhone 17 Pro Max 模擬器。安装前後 journey snapshot（含收藏、私人備註、草稿及回報）、感謝紀錄和外觀偏好的校驗值相同。隔離測試裝置已關閉。原模擬器有 Maps 小工具的系統定位詢問遮住 App；未替使用者選擇定位權限。

真實審核／公開地圖更新仍未接通；本輪沒有新增「場所已關閉」的回報流程，也未進行實機或完整 VoiceOver 測試。

技術參考：[Apple scrollDismissesKeyboard](https://developer.apple.com/documentation/swiftui/view/scrolldismisseskeyboard(_:)) 說明立即結束鍵盤互動的原生行為；本次殘留焦點的觸發條件來自錄影及實際對照測試，並非聲稱 Apple 已確認特定系統缺陷。
