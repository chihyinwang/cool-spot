---
target: About the place 區塊，截圖 2026-09-08 10.22.24
total_score: 17
max_score: 28
na_heuristics: 1,3,9
p0_count: 0
p1_count: 0
timestamp: 2026-09-08T09-33-57Z
slug: cool-spot-contributionview-swift
---
⚠️ DEGRADED: single-context (sub-agents declined by user)

本次由單一評估者先完成設計判斷，再執行工具檢查。範圍是 About the place 截圖與對應 SwiftUI 區塊；未修改介面。

**有問題。主要是資訊的重要性與視覺份量不一致，讓四個簡單欄位看起來比實際更費力。** 原生分組表單適合這個產品；問題不在白色圓角框，也不需要靠增加裝飾解決。

**1. [P2] 必填的 Setting，反而最不顯眼。**

前兩個選填欄位有粗體標題、例子和說明；新增地點必須回答的 Setting 卻只佔一個普通列。而且 Setting 只是一個分類名稱，使用者要打開選單才知道是在問室內或室外。

建議改成「Indoors or outdoors?」，明確呈現必填狀態。三個選項是 Indoors / Outdoors / Both，正常字級下可直接呈現，讓人少打開一次選單；大字級則改用能完整顯示文字的排列。保留名稱與位置描述相鄰，不為了突出必填而拆散相關資訊。適合使用 impeccable clarify 與 layout。

**2. [P2] 選填欄位的說明與留白過多。**

「How to find this spot」的例子已經示範樓層與位置，下面再說 Add the floor, entrance or nearest landmark，資訊重複。它和 Place name 的例子又都出現 Library，削弱兩個欄位的分工。

畫面裡那塊空白也有具體原因：程式使用 lineLimit(2...4)，一開始就保留至少兩行。建議改成從一行開始、隨輸入長大；保留持續可見的欄位標題，用互補的例子說清楚：

| 欄位 | 例子／呈現 |
|---|---|
| Place name · Optional | e.g. Riverside Library |
| How to find this spot · Optional | e.g. Fourth floor, by the windows |
| Indoors or outdoors? · Required | Indoors / Outdoors / Both |
| Place type · Optional | Not sure |

刪去重複的找路說明。「使用既有名稱」確實能避免使用者誤以為要替地點取新名字，這層意思可以留下精簡提示；不必再重複 Optional 已表達的「可以不填」。適合使用 impeccable distill 與 polish。

**值得保留的部分**：名稱與精確位置是不同資訊，應分開；Optional 已清楚標示；欄位標題在輸入後仍會保留。現有分隔線位於不同欄位之間，並沒有把同一欄位的說明切開。About the place 本身可以保留，不是這次最需要改的文案。

**使用者影響**：第一次填寫的人需要先解讀 Setting；要回報圖書館某個角落的人，可能被兩個 Library 例子弄混；趕時間的使用者則要先掃過較長的選填說明。這是對閱讀與操作負擔的判斷，尚不能據此宣稱會造成棄填。四個欄位的數量本身並不多，真正需要減少的是重複閱讀。

**區塊評分：17/28，需改善。** 這是依截圖與程式做的啟發式評估，不是使用者測試結果。

| 評估面向 | 分數 | 依據 |
|---|---:|---|
| 狀態回饋 | 不評 | 儲存與進度不在截圖內 |
| 貼近日常語言 | 2/4 | Setting 不夠直接 |
| 操作自由 | 不評 | 返回、取消不在此範圍 |
| 一致性 | 3/4 | 原生模式合理，層級不均 |
| 預防錯誤 | 2/4 | 必填項提示不足 |
| 易於辨認 | 3/4 | 有固定標題與例子 |
| 操作效率 | 2/4 | 簡單選項藏在選單內 |
| 精簡呈現 | 2/4 | 說明重複、預留空白 |
| 錯誤復原 | 不評 | 尚未觀察錯誤狀態 |
| 輔助說明 | 3/4 | 有幫助，但可更精簡 |

工具檢查：針對 ContributionView.swift 執行一次 CLI，回傳 []、退出碼 0。它將單一 Swift 檔案作為文字掃描，沒有 SwiftUI 專用檢查能力，因此零發現不能解讀為介面通過。此為原生 iOS 截圖，沒有網頁 DOM，瀏覽器疊圖不適用。判斷主要來自截圖與程式；未驗證此區的大字級、VoiceOver 或完整輸入旅程。

Questions skipped: 本次有 2 個優先問題，評估方向已清楚，不需要再請使用者選項。
