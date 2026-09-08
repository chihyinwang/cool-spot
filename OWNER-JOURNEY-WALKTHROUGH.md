# Cool Spot：完整點擊走查

本文件只負責測試步驟、預期結果與驗證狀態。現行功能定義見 [PRODUCT.md](PRODUCT.md)，程式版本與工作方式見 [AGENTS.md](AGENTS.md)。下面的「應看到」是待檢查的預期，不表示已通過。

## 本輪狀態與起點

**Add cooling information 的本輪修正已實作，現在從 B04 做 owner 重測。** 新位置的名稱及照片皆必填；送出前未填完會標示缺漏並定位第一項。接著再測 B05；B03、B06、B10 覆蓋 Pin、選单焦點與照片。以下 agent 證據不代表 owner 已接受版面。

| 範圍 | 最新證據 | 仍需確認 |
|---|---|---|
| 表單、名稱／照片 | 本輪 iPhone 窄螢幕原生操作：缺名字被攔下，補齊名稱及照片後到 Sent for review；首次漏填定位成功 | Owner 的理解與閱讀舒適度；B03–B05 完整分支 |
| Entry/cost 與大字體 | 一般字級 Cost／Seating／Tables 同高；iPad 最大字級深色的選項、時長及已知場所無照片送審已操作 | 全部選單取消／返回；iPad 橫向及 split view |
| 更新既有場所 | 未改資料時清楚提示、不提交；單改 Seating 即可送審 | B09 還原原值、B12 全部移除的原生分支 |
| 自動測試 | 本輪 48 passed、0 failed，包含新規則及 store 拒絕無效提案；最後 UI 建置成功 | 不代表完整 VoiceOver 或真實可用性測試 |
| A、C、D、E 其餘流程 | 先前實作／部分原生測試紀錄 | 未改動，也未宣稱此版全部 40 個案例通過 |


證據按需讀取：

- [較早 About the place 驗證與截圖](.impeccable/review/about-place-2026-09-08/VERIFICATION.md)
- [Entry/cost 排列驗證](.impeccable/review/entry-layout-2026-09-08/VERIFICATION.md)
- [先前 A–E 修正／D–E 操作紀錄](.impeccable/review/owner-feedback-2026-09-07/VERIFICATION.md)
- [留存的 48 項測試結果](.impeccable/review/entry-copy-2026-09-07/test-summary.json)

以上是各次檢查範圍的證據，不等於完整真人可用性驗證。

### 2026-09-08：整體流程與資訊層級評估

基準：`3b8bf457f39e50bdbd650efb3fd4bb2f29f71e8a`，檢查前 working tree clean。本輪只新增本節與原生截圖，未修改 Swift 或產品規則。依專案約定由單一 agent 做 Impeccable critique，設計判斷與工具檢查並非兩份獨立評估。

Debug 建置成功（`/tmp/cool-spot-critique-build.log`）。使用隔離 Cool Spot Compact QA（iPhone SE、375 pt、iOS 18.2）及 Cool Spot Tablet QA（iOS 26.4）；未替換或操作 owner 原本停在未送出表單的 iPhone。一般字級流程以正常啟動檢查；最大字級／深色以 memory-only DEBUG routes 檢查，不能證明 production persistence。未重跑單元測試、完整 VoiceOver、實機單手操作或首次使用者計時。

| 案例 | 本輪原生證據 | 仍未證明 |
|---|---|---|
| A01、A07 | Explore 地點列 → Riverside Library → Save；Saved 狀態與私人欄位出現。Directions 固定可見 | 未打開 Apple Maps 驗證導覽；未驗證首次使用者能在 30 秒內做決定 |
| D01、D05 | Share how it felt → A little cooler → Publish report → 成功畫面；返回可見本輪個人回報與 You’ve shared this visit | 入口由 agent 根據已知 accessibility tree 點擊，不能算自行找到；未覆蓋 D01/D05 所有分支或重啟保存 |
| B04、B11 | 搜尋無結果 → 地圖點選 → Use this spot → Outdoors／Tree shade；無名時提示照片，填 TEST Community Courtyard 後不用照片即能送審；實際到 Sent for review | Place type 保留 Not sure，未走 B04 的選類型分支；未完成 B11 四種來源或 You 狀態回查 |
| B06 | 名稱輸入後往下展開 Entry and seating → Cost to use → Free to use；本次未跳回名稱欄 | 僅此選單序列；其他選單、取消與自訂時長仍待完整重測 |
| iPad 大字級／深色 | 地點頁及 chooser → Riverside Café 表單可開啟、原生表單可向下捲動 | 不代表全部 iPad flow、橫向或 split view 通過 |

點擊比較以 Explore 為起點，計入入口、欄位聚焦、選項與送出，不計鍵盤字元、捲動、選填項及成功頁 Done。最短路徑的結構計數：Directions 2 次（外部 Maps 未操作）、Save 2 次、符合資格的最簡回報 4 次、附近已知場所的最簡提案 6 次（source 推算）、有名稱的新地圖位置 9 次（包含一次選點與名稱聚焦；若先搜尋再多一次聚焦）。這是最短路徑的比較，不是自然操作的總點擊數或完成時間；完整 B04 會因搜尋及選填類型增加動作。

**評估後的處理狀態：**

- **P1／A01，大字級可讀區太小：** iPhone 最大字級的固定 Directions／Save 區約佔全螢幕 42%，Directions 斷成兩行；iPad 同樣有固定按鈕壓縮閱讀區。應先測試能保留字級、縮減圖示與固定區佔用的原生排列，避免直接把字縮小。
- **A01／保留，順序取捨尚未證明有問題：** 一般窄螢幕先顯示照片、場所摘要及體感分布，AC／water 在首屏之外。先回答訪客覺得多涼有產品上的理由；沒有證據證明將設施移到體感之前較好，不列為已確認的 P2 缺陷。
- **B04–B06／地圖保留，表單另作聚焦評估：** 表單地圖用於核對填寫位置，不是要求再選一次。沒有證據證明縮圖較好。Owner 此後明確修正 name/photo 規則（見 PRODUCT Identification），並要求處理分組間距、說明位置、必填／選填層級、選單列高度及送出回饋。
- **P2／A03–A05，探索控制的預期不清：** source 確認 More 是空 action、Search this area 不取新資料；第二個 filter 取代第一個，文字搜尋另外讀全部 fixtures。這是現行 prototype 邊界，也會干擾可用性評估。提議讓未接通的控制有明確狀態，並先定義搜尋與篩選一致的預期；尚未完成這些分支的本輪原生操作。

其他待決策限制：公開提案沒有跨重啟草稿、私人 Pin 沒有刪除入口、審核 Action needed 無補件路徑。這些見 PRODUCT，不能因為已記錄為 prototype 限制，就視為正式產品的可用性已通過。

截圖：[Explore](.impeccable/review/flow-critique-2026-09-08/phone-explore.png)、[地點首屏](.impeccable/review/flow-critique-2026-09-08/phone-place-top.png)、[新增表單首屏](.impeccable/review/flow-critique-2026-09-08/phone-contribution-top.png)、[iPhone 最大字級深色](.impeccable/review/flow-critique-2026-09-08/phone-place-large-dark.png)、[iPad 地點最大字級深色](.impeccable/review/flow-critique-2026-09-08/tablet-place-large-dark.png)、[iPad 表單最大字級深色](.impeccable/review/flow-critique-2026-09-08/tablet-form-large-dark.png)。

Impeccable detector 對 `cool-spot` 回傳 `[]`，沒有 SwiftUI 版面驗證效力；不據此宣告無問題。全 app 根目錄未產生穩定 critique slug，因此未新增平行報告或比較歷史分數；觀察集中在本文件。本輪沒有 web overlay/server。owner 完整 B04 → B05 與 B03/B06 重測仍待進行。

### 2026-09-08：Add cooling information 聚焦研究

本次只查閱原始碼、唯讀查看 owner iPhone 的 Entry and seating 原生畫面及研究設計指南；未修改 Swift、未操作表單答案、未重建 App。上方舊名稱／照片通過紀錄及 9 次點擊計數，是 owner 新決定之前的版本證據。

確認原因：`entryQuestion` 使用自訂 HStack／ViewThatFits 包裝 Who can use this spot? 與 Cost to use，Seating／Tables 等使用直接的原生 Picker；相同單行選單列沒有產品理由刻意不同高。`Section.footer` 的存在、行數和各列自訂 padding 共同造成區塊間距觀感不同。`sendBar` 只顯示 `requiredHint` 找到的第一項缺漏，文字不是可點擊的修正入口，且在可送出時消失。

待實作方案的評估標準：section 標題與問題標籤分層；Required／Optional 跟隨對應問題，使用固定樣式；必要說明緊鄰問題，出現在作答之前；一般單行 picker 使用一致 row insets／最小觸控高度，說明或換行才增加高度；新位置的 name/photo 規則依 PRODUCT。送出回饋建議比較「停用按鈕＋明確修正入口」與「按送出後標出所有缺漏、定位第一項，全部有效才提交」，不能只刪提示而留下無法操作的灰色按鈕。這是實作前的研究紀錄；下節記錄 owner 同意下一步後的實作和限定驗證。

依據：[Apple 資料輸入](https://developer.apple.com/design/human-interface-guidelines/entering-data)、[Apple 文字欄位](https://developer.apple.com/design/human-interface-guidelines/text-fields)、[NN/g 表單鄰近性](https://www.nngroup.com/articles/form-design-white-space/)、[NN/g 必填標示](https://www.nngroup.com/articles/required-fields/)、[IBM Carbon 表單](https://carbondesignsystem.com/patterns/forms-pattern/)、[GOV.UK 說明文字](https://design-system.service.gov.uk/patterns/question-pages/)、[GOV.UK 錯誤摘要](https://design-system.service.gov.uk/components/error-summary/)。原則可以支持方案，不能保證方案在本 app 的使用者測試中最佳。

### 2026-09-08：Add cooling information 實作與限定驗證

基準為 `3b8bf457f39e50bdbd650efb3fd4bb2f29f71e8a` 加本輪 `ContributionView.swift`、`cool_spotTests.swift` 及三份 active documents 的 working changes。保留先前未提交的文件及評估截圖；未 commit，未替換 owner 的 iPhone 17 Pro Max App，未操作其未送出表單。

- 實作：未列出位置需同時有名稱與有效照片；照片位置固定。問題標籤統一 Required／Optional，移除分散 footer；必要說明緊鄰題目。Cost、Seating、Tables 共用同一 picker row；較長標籤和大字體可上下排列。Send 改為按下後標出所有缺漏、定位第一題，保留答案。一般字級仍固定在底部，大字級仍放表單末端。
- 原生環境：隔離 Cool Spot Compact QA（iPhone SE，375 pt，iOS 18.2）；Cool Spot Form Tablet QA 18（iPad Air 11-inch M2，iOS 18.2，系統與 DEBUG 最大 Dynamic Type、深色）。iOS 26.4 的既有 Tablet QA 能顯示表單首屏，但本輪工具未穩定取得其內容控制樹／捲動，因此不宣稱完成該 runtime 的全流程。
- 建置成功：`/tmp/cool-spot-form-build.log`。XCTest 48 passed、0 failed，含三種 unlisted kind × 三種 setting 的名稱／照片規則、缺漏恢復、store 邊界、原有 update／duplicate 測試；[結果摘要](.impeccable/review/form-refinement-2026-09-08/test-summary.json)。最後僅修正 UI 排版／錯誤文字對比，未重複執行未受影響的模型 suite。

| 案例 | 本輪實際操作／結果 | 未覆蓋部分 |
|---|---|---|
| B03 | DEBUG Pin 入口 → Use this spot；公開名稱為空，Required 出現在名稱與照片旁；第一次按 Send 即定位到環境題，錯誤完整可見 | 從 Saved 主頁進入／返回核對原 Pin 資料尚未原生重測；私人資料不複製有模型測試 |
| B04、B05、B11 | 搜尋 TEST Community Courtyard 無結果 → 地圖 → Use this spot；填名稱、Outdoors、Tree shade、系統照片。照片存在但清空名稱後 Send 被攔下；重新實際輸入名稱後到 Sent for review | 本次未改 Place type，也未調整既有 draft 座標；B11 未做 You 回查及四種完整來源 |
| B06 | 窄螢幕 Cost → Free to use 不跳回名稱。Cost／Seating／Tables 標準列同為約 66 pt（44 pt 內容＋原生列 inset）；Time limit 因說明而較高。iPad 展開 Entry and seating、Other duration… → 顯示 Hours 1／Minutes 30 | 未逐一操作全部選單、取消及重新開啟；單手操作尚未真人觀察 |
| B01 | iPad 選 Indoors、Air conditioning，自訂時長後不加照片，成功到 Sent for review | 無照片移除的完整 B10 分支未另測 |
| B09 | iPhone 既有 Library 未修改按 Send：出現需修改一項的提示，沒有提交；改 Seating → Limited seating 後成功送審 | 原值還原由模型測試覆盖；B12 原生移除原因分支待測 |
| B10 | QA 系統 PhotosPicker 選範例照片，圖片出現、照片缺漏消失 | 系統取消、更換、移除及讀取失敗沒有全部原生覆蓋；模型驗證包含移除與壞圖片 |
| 大字體／輔助使用 | 最大字級深色下設施圖示固定欄寬，完整單字換行；picker accessibility 提供題目、目前答案及 Optional | 未宣稱完成 VoiceOver 朗讀、焦點次序、Reduce Motion 或實機 accessibility audit |

修正過程實際發現並處理：首次顯示錯誤時要等待原生 Form 更新後再捲動；大字級原生 Label 會把設施單字切開，改為此表單專用圖示／文字排列；錯誤使用高對比正文加紅色圖示，避免小字只靠淡紅色辨認。原生檢查沒有以 web detector 代替。

截圖：[名稱及錯誤定位](.impeccable/review/form-refinement-2026-09-08/phone-required-errors.png)、[欄位標籤](.impeccable/review/form-refinement-2026-09-08/phone-fields.png)、[Entry and seating](.impeccable/review/form-refinement-2026-09-08/phone-entry.png)、[iPad 最大字級設施](.impeccable/review/form-refinement-2026-09-08/tablet-features-large-dark.png)、[新位置送審成功](.impeccable/review/form-refinement-2026-09-08/phone-submitted.png)。

以上 DEBUG flows 使用 memory-only store，不是正式保存／上傳／審核服务證據，也不是首次使用者的完成時間或點擊數測量。

## 怎麼跑

| 輪次 | 任務 | 固定編號 | 含簡短記錄的估計時間 |
|---|---|---|---|
| A | 找地點、閱讀、私人儲存 | A01–A09 | 15–20 分鐘 |
| B | 新增／修正公開場所資訊 | B01–B12 | 25–35 分鐘 |
| C | 分享人數、到訪資格、離開 | C01–C06 | 10–15 分鐘，另有到期等待 |
| D | 開始、續填、發布與閱讀回報 | D01–D08 | 15–25 分鐘 |
| E | 審核狀態、感謝、帳戶與設定 | E01–E05 | 10–15 分鐘 |

1. 一次只跑一個編號；卡住約 30 秒就截圖，記下原本預期。先查範例資料是否符合前提，找不到測試狀態不等於功能通過或失敗。
2. 這份有點擊提示的走查用於覆蓋功能。找第一次使用的人做可用性測試時，先只給標題情境與目標，隱藏點擊步驟；記錄他是否自行找到、猶豫在哪裡，以及能否解釋公開／私人結果。提示後完成要另記，不能算自行找到。
3. 輸入本輪資料時加 `TEST`。取消收藏／丟棄只處理本輪測試資料；保留原有回報、備註與 Pin。資料不足請用隔離 QA 裝置，不清空原本裝置。
4. 除非写「接上一項」，開始前退出目前表單／地點。公開測試表單用 Close → Discard and close；個人回報用 Finish later。分清兩種草稿的保存範圍，見 PRODUCT。
5. 每次修正後只重測受影響編號；記錄版本、日期與結果。沒有實際測試就填「待測」，不要沿用舊版的通過狀態。

`→` 是下一個點擊或動作；「返回」是左上角返回；「關閉地點」是 ×。Explore／Saved／You 是底部分頁，Places／Pins 是 Saved 內的分類。下面地點均為 prototype fixture；GPS、搜尋、審核等限制見 PRODUCT。

## A：找地點、閱讀、私人儲存

### A01｜很熱，想判斷去哪裡

1. Explore → 底部 **Cool Spots nearby** → **Riverside Library**。同一地點也能直接點地圖標記。
2. 往下讀：場所名稱、費用／座位、已知的進入資格、Opening hours、體感摘要與三種回報數。
3. **Show all 7 cooling features** → **Show fewer cooling features**。
4. 往下 → **How long people stayed** → 再點一次收合。

**觀察：** 你能否決定去不去、還缺什麼資訊？人數、座位、涼不涼是否被誤讀成同一件事？這裡的 opening hours 仍是未知，沒有實際時刻表。

### A02｜比較兩個地點

1. 關閉地點 → Explore 底部地點列橫向滑動 → **Shade beside the playground**。
2. 比較它的三種體感回報、樹蔭、入場、座位與即時人數。
3. 關閉 → **City Gallery Foyer** → 往下到 Visitor reports。

**觀察：** 哪些資料是場所資訊，哪些是一次造訪的經驗？如果 City Gallery Foyer 沒有個別回報，應顯示 **No individual reports to read yet**，不會有 View all；它仍可能有示範彙總數，這是目前資料不完整，請記下是否令人困惑。

### A03｜用篩選縮小範圍

1. 關閉地點 → Explore → **Indoor** → 看地圖及底部結果 → 再點 Indoor 取消。
2. 依序試 **Outdoor shade**、**AC**、**Free**、**Water**，每次看結果再取消；橫向滑動篩選列可找後方選項。
3. 點 **Indoor**，接著點 **Water**，觀察是否符合預期。

**目前行為：** 一次只保留一個篩選，第二個會取代第一個，不能組合條件。**More** 尚未接通，點一次確認後即可停下，不必找隱藏頁面。

### A04｜定位、暫不提供定位、移動地圖

1. Explore → **Nearby**。若出現 **Use your current location?**，先選 **Not now** → 搜尋框输入 `Riverside`，確認仍可搜尋。
2. 清空搜尋框 → Nearby → 若再次出現說明，選 **Continue**。
3. 拖動地圖 → **Search this area**。

**目前行為：** 說明是 App 內的模擬流程，不是 iOS 真正的定位授權。已按過 Continue 時不一定再問。Search this area 目前只收起按鈕，不會重新取得該區資料；地圖移動也不會改變模擬的所在地。

### A05｜搜尋尚無降溫資料的場所

1. Explore → 搜尋框输入 `Riverside Café` → 點 **Riverside Café**。
2. 讀 **No cooling information yet** → 點 **Save**；若本來已 Saved，不用取消舊收藏。
3. 關閉地點 → Saved → **Places** → Riverside Café。
4. 在 Private details 只對本輪測試資料填名稱／備註 → **Save private details** → 確認 Private details saved → 關閉地點 → 重開確認。

**觀察：** 收藏是否被誤認為公開新增 Cool Spot？私人名字是否和場所原名分得清？普通場所現在也有 Directions；已收藏時在同一場所頁編輯私人紀錄，也能直接點 Saved 取消收藏。

### A06｜收藏／取消收藏已存在的 Cool Spot

1. Explore → **Riverside Library** → **Save**（若原本已 Saved，直接下一步）。
2. 關閉 → Saved → Places → Riverside Library，應直接開完整地點頁。
3. 只有在這是本輪新收藏時，點 **Saved** 取消 → 關閉 → 確認 Places 已移除；再從 Explore 收藏回來。

**觀察：** 已有 Cool Spot 與普通場所的 Saved 入口是否都合理？取消收藏不應刪除你的回報。

### A07｜從 Explore 快速存一個私人 Pin

1. Explore → 右下 **＋** → **Save a pin here** → 如出現定位說明，選 Continue。
2. 在 **Save a pin here?** 先選 **Cancel**，確認未新增。
3. 再開同一路徑 → **Save pin** → 提示出現時點 **View pin**。
4. 若提示已消失：Saved → Pins → 最新的 **Dropped pin**。

**觀察：** 你是否知道保存的是目前模擬所在地，而非地圖畫面中心？是否清楚它是私人、沒有開始回報？

### A08｜從 Saved 存 Pin、命名並找回

1. Saved → 右上 Pin 按鈕（**Save a pin here**）→ **Save pin** → **View pin**；也可從 Pins 開最新 Dropped pin。
2. Private details → 名稱填 `TEST 河邊樹蔭` → 備註填 `TEST 靠牆的長椅` → **Save private details**。
3. **Done** → 再從 Pins 開剛存的項目 → 核對名稱、備註、位置。

**保留給 B03：** 使用這個測試 Pin，確認公開提案不會自動帶入私人文字。目前沒有刪除 Pin 的使用者入口；不必連續建立很多個。

### A09｜離開 App 去導航／搜尋不到

1. Explore → Riverside Library → **Directions** → 檢查交給 Apple Maps 的步行目的地 → 返回 Cool Spot；不用真的出發。
2. 關閉地點 → Explore 搜尋 `TEST nowhere 999` → 觀察結果 → 清空搜尋。

**目前行為：** 兩種場所的 Directions 都是外部地圖連結。無結果時顯示 **No places found**，可改搜尋字詞，或點 **Add cooling information at a location** 進入新增流程；沒有直接把搜尋字詞當成新場所。搜尋仍使用示範資料。

## B：新增／修正公開場所資訊

這一輪不需要開始 Visit Report 或分享人數。公開提案的 **Send for review** 與個人回報的 **Publish report** 是兩條不同流程。

### B01｜從普通場所直接補降溫資訊

1. Explore → 搜尋 `Riverside Café` → Riverside Café → **Add cooling information**。
2. 核對表單已帶入 Riverside Café；**Indoors or outdoors?** → **Indoors**。
3. 在 **What helps people cool down?** 選 **Air conditioning**。
4. 觀察 Send for review 是否可點；先不送，直接接 B06 檢查選填。

**觀察：** 是否不用再選一次場所？Place type 已知時應顯示來源值，不要求重填；其他項目應可略過。

**也測收藏入口：** Saved → Places → Riverside Café → **Add cooling information**。應直接開同一場所的表單，不需要重新搜尋。

### B02｜Explore ＋ 的統一選擇頁

1. 關閉目前公開表單（測試答案可選 **Discard and close**）→ 關閉地點 → Explore → ＋ → **Add cooling information**。
2. 在 **Nearby places** 點 Riverside Café → 看是否開相同單頁表單 → 返回。
3. 搜尋框输入 `Market` → **Market Street Supermarket** → 看場所名稱與來源內容 → 返回。
4. 清空搜尋 → **Riverside Library** → 應開 **Update place details**，不是新增另一個 Library。

**觀察：** 選項下的 Add cooling information／Already on Cool Spot · Update information 是否足以讓你知道接下來做什麼？

### B03｜把私人 Pin 的位置提供給別人

**狀態：規則已實作；agent 限定檢查見上方，完整 owner 走查待測。**

1. 關閉公開表單 → Saved → Pins → A08 的 **TEST 河邊樹蔭** → **Add cooling information**。
2. **Confirm the spot**：確認原本 Pin 的位置 → **Use this spot**。
3. 核對公開名稱與備註為空，不應出現私人 `TEST` 文字；自行填公開名稱 `TEST Shade beside the playground` → Indoors or outdoors? → **Outdoors** → **Tree shade**。
4. **Add photo** → 選一張測試照片；名稱及照片皆提供後，不用回答進入資格也可以送審。Required 應使用同樣樣式，跟隨名稱及照片問題。
5. 確認照片顯示、Send for review 可點；先不送，可接 B10。

**觀察：** 先回答室內／室外，再填相鄰的名稱與找路描述是否順暢？名稱提示是否清楚歸屬輸入欄？位置只留一個 Change location，進入資格與必填照片是否分得清？

**也測 Pin 對應到已知場所：** 完成本項與 B10 後，Close → Discard and close → 從同一 Pin 再進 Add cooling information → Confirm the spot → **Search nearby places** → **Riverside Café**。應改為為 Café 填資料；退出後，原私人 Pin 的名稱、備註和位置都應保留。

### B04｜搜尋不到，但知道有名稱的場所

**狀態：規則已實作；agent 限定檢查見上方，完整 owner 走查待測。**

1. Explore → ＋ → Add cooling information → 搜尋 `TEST courtyard`。
2. 無結果 → **Choose a spot on the map** → 在地圖點選位置 → **Use this spot**。
3. **Indoors or outdoors?** 直接選 **Outdoors** → **Place name** 填 `TEST Community Courtyard`，兩題皆應標明必填 → Place type · Optional → **Square, plaza or courtyard**。
4. 選 Tree shade → 未加照片按 Send，應定位 Photo 並要求照片、不得實際送審；Add photo → 選測試照片 → 確認符合送審條件；先不送。

**觀察：** 三個室內／室外選項是否可直接選，未選時有沒有誤導性預設？是否分得清場所名稱與找路描述？名稱應鼓勵容易辨認的描述，不必假造正式場所名稱；描述欄位不應預留多餘空白。有名稱時照片仍必填。

### B05｜室內角落、無名位置與改位置

**狀態：規則已實作；agent 限定檢查見上方，完整 owner 走查待測。**

1. 接 B04 表單：清空名稱 → Indoors or outdoors? 選 **Indoors**；將之前選的 Place type 改回 **Not sure**。即使已有照片，缺名稱也不得實際送審。
2. **How to find this spot · Optional** 填 `TEST Fourth floor, corner by the windows`；加長到多行，確認欄位隨內容增高。
3. 自訂容易理解的公開名稱 `TEST Fourth-floor window seating` → 選至少一個降溫設施，確認有一張照片 → 確認符合送審條件；切換 Outdoors／Both 也使用相同規則。
4. 回表單上方 **Change location** → 調整地圖位置 → **Use this spot** → 答案保留。
5. 關閉本次測試表單。若從 Saved Pin 進入，核對原 Pin 的位置與私人文字沒被改動。

**檢查：** 沒有正式名稱的位置也需要自訂易懂名稱及照片。場所分類和進入資格可以留 Not sure；照片不能替代名稱，名稱也不能免除照片。

### B06｜選填資料在同頁完成

1. 在 B01 或其他公開表單 → 展開 **Entry and seating**。
2. **Who can use this spot?** → **Limited access**，確認不會出現額外填寫區塊；**Cost to use** 選 Free to use，確認免費與學生限定可以並存。
3. **Time limit** → Other duration… → Hours 選 1、Minutes 選 30。
4. 試 **Seating／Tables**，以及 Other facilities 的 **Toilets／Wi-Fi／Power outlets／Laptop use allowed**；再收合兩組。
5. **Anything else people should know?** 填 `TEST public note`；重新展開原分組，確認答案保留。

**重點回饋：** Who can use this spot? 有 Everyone／Limited access／Not sure，皆不擋送審。Cost to use 有 Free to use／Purchase required／Entry fee／Not sure。沒有 Who is it limited to? 或 Tickets and booking 填寫區塊。Time limit 是場所公告限制，不是這次造訪待了多久。

**重測錄影中的跳位：** 點一下上方 Place name → 往下滑 → Entry and seating → Cost to use／Seating／Time limit，分別開啟、取消及選值。開選單時背景應停在原位，不跳回名稱區；這項測試不需要送審。

### B07｜返回與改選場所

1. Explore → ＋ → Add cooling information → Riverside Café → Indoors or outdoors? 選 Indoors → Air conditioning。
2. 左上返回 → 再選同一個 Riverside Café → 確認答案保留。
3. **Change place** → Market Street Supermarket → 讀 **Change to a different place?** → **Keep current place**，或點彈出框外取消 → 返回原表單。
4. 再 Change place → Market Street Supermarket → **Change place** → 確認不再帶入前一場所的答案。

**觀察：** 是否分清返回、取消這次換場所、確定更換？同一份尚未關閉的公開表單會在記憶體保留答案，避免重填；它不是永久草稿。從已知場所直接進表單時，可能沒有第一層返回鍵，用 Change place 進選擇頁即可。

### B08｜離開公開表單而不誤送

1. 在公開表單改一項答案 → **Close** → 讀 **Discard this place contribution?**。
2. **Keep editing**，或點彈出框外取消 → 確認答案仍在。
3. 試向下滑關閉 sheet，觀察是否保護未送出的答案；若沒有預期反應，截圖／記錄，不必反覆滑。
4. 最後 Close → **Discard and close** → 重新進同一入口，確認本次未送出的公開答案不會當成已送審資料。

**目前邊界：** 公開場所表單沒有 Finish later／跨重啟續填。向下滑的完整行為尚未完成原生驗證；Close 是明確可用的出口。iOS 彈出框不一定顯示文字取消鈕，點框外也可取消。

### B09｜只修正既有 Cool Spot 的一項資料

1. Explore → Riverside Library → **Suggest an edit** → 確認標題 Update place details、既有設施已選好。
2. 先不修改 → 按 Send for review；應顯示 Change at least one detail before sending an update，不建立提案。
3. Entry and seating → Seating → 選與原值不同的項目 → 讀 **Your changes**。
4. 改回原值 → 再按 Send，若無其他改動應提示需修改一項、不提交；再改一次，留給 B11 送審。

**其他入口：** Saved → Places → 已收藏的 Riverside Library → Suggest an edit；或 Explore → ＋ → Add cooling information → Riverside Library。都應開既有資料的修正表單。

### B10｜照片：選取、取消、更換、移除

**狀態：新位置一律需要照片已實作；完整系統照片分支待 owner 重測。**

1. 在 B03 自訂名稱戶外表單 → Add photo → 先取消系統選擇器；其他答案應保留。
2. 再 Add photo → 選一張測試照片 → 等待載入 → 確認無須另勾「能辨識地點」開關。
3. **Replace photo** → 選另一張 → **Remove photo**。
4. 新地圖位置即使有名稱，移除照片後也不得實際送審；再加入照片。另在 B01 已由搜尋選到的 Riverside Café 表單，試一次移除選填照片，確認此分支沒有新增照片要求。

**若自然遇到錯誤：** Photo couldn’t be loaded → **OK** → 重新 Add photo。不要刻意找壞檔案或清空相簿；這項不是每次都能重現。照片不會真的上傳。

### B11｜送審與找回結果

**完整覆蓋時分別送四筆測試資料：** B01 的已知場所、B03 的自訂名稱戶外位置、B04 的有名新場所、B09 的既有 Cool Spot 修正。每筆都用下方同一組步驟核對。送出前完成要保留的返回／照片測試。

1. 在一份已填好的測試提案／修正中 → **Send for review**。
2. **Sent for review** → 讀說明 → **Done**；若回到 Saved／地點的父頁，先按 Done／× 回主畫面。
3. You → **Places you’ve added or updated** → **In progress** → 找剛才的地點與 **In review**。
4. 接 E01 可立刻檢查審核結果；如果先重啟 App，這份場所提案目前會重設，E01 會教你重新準備一筆。

**目前止點：** 這些紀錄是狀態展示，不能點進去編輯、補件或開提案詳情。送審不會立即改掉地圖上的場所資訊。

### B12｜來源不正確／移除全部降溫設施

1. Riverside Library → Suggest an edit → **Name or place type is incorrect** → 填 `TEST the place name has changed` → 核對 Your changes。
2. 在同一修正表單，取消全部原有降溫設施。
3. 應出現 Required 的原因欄位；先按 Send，應定位原因欄並提示、不能實際提交 → 填 `TEST the cooling facilities are no longer available` → 核對可送審及 Your changes。
4. 這是驗證分支，最後 Close → Discard and close 即可。

**目前行為：** 名稱／來源類型不是在主欄位直接覆寫，而是送出更正說明。如果這不符合你的預期，記下來討論。

## C：分享人數、到訪資格、離開

**準備 C 與 D：** 優先用還沒發布過本次造訪回報的 City Gallery Foyer 和 Shade beside the playground；不動你的舊 Riverside Library 回報。如果已顯示 You’ve shared this visit，改用另一個地點。若三個地點都已發布，標記「C/D 前置資料不足」，不要刪舊回報或改系統時間。

**切換模擬所在地的完整路徑：** You → Settings → Prototype controls → **Nearby place** → 選地點或 **Away from all Cool Spots** → 返回 Settings → 返回 You → Explore。它只改測試資格，不會真的追蹤位置，也不會把地圖的固定示範座標搬到該場所。

### C01｜理解人數動畫

1. Explore → 任一地點 → **How this works**（在 Here to cool down? 區塊下方）。
2. 讀說明、看地圖上 **2 → 3** → **Pause example** → **Resume example**。
3. **Done** → 回地點頁，比較原本真實顯示的人數。

**觀察：** 你是否理解動畫只是示例？是否誤以為人數等於空位、溫度或全部在場人數？若目前已分享，先 Stop sharing 才會重新看到此入口。

### C02｜只分享人數，不寫回報

1. 用上述設定把 Nearby place 設為 City Gallery Foyer → Explore → City Gallery Foyer。
2. 記下人數 → **I’m cooling off here**。
3. 確認人數加一、出現結束時間 → 先不要選下方體感 → **Stop sharing**。
4. 關閉地點 → You → Your reports → 查看 **Visits you can report**。

**應理解：** Stop sharing 停止人數分享，但已建立的私人開始回報資格仍在；沒有選寫回報前，不應當成你填到一半的報告。

### C03｜離開七天後才開始回報

1. 接 C02，用設定選 Away from all Cool Spots → You → Your reports → Visits you can report。
2. 確認 Gallery 還有 Share how it felt，先不要點。
3. You → Settings → Prototype controls → **Simulate a visit 7 days ago** → 返回 Your reports。
4. 日期應變成七天前，**Share how it felt 仍可用**。點進去應保留該造訪日期；Finish later 可留下草稿。

**檢查：** 確認過的到訪沒有開始／完成期限。此控制會修改本機示範日期，不是實際等待七天的測試；不改既有草稿與已發布回報。

### C04｜離開前什麼都沒做／只有收藏

1. 先在 You → Your reports 確認另一地點（優先 Shade beside the playground）沒有未完成回報；不刪除舊資料。
2. Nearby place 選 Away → Explore → 該地點 → **Save**（若已收藏略過）→ 查看 Share how it felt 是否仍不可用。
3. **Why can’t I share?** → 讀說明 → Done；同時查看 I’m cooling off here 在不附近時是否不可用。

**前提：** 該地點不能已有確認過的到訪。若有，標為不適用；沒有提供刪除舊到訪紀錄來製造這個狀態的入口。收藏本身不會提供資格。

### C05｜分享人數後，走體感捷徑

1. Nearby place 改 City Gallery Foyer → Explore → City Gallery Foyer → I’m cooling off here。
2. 分享成功區塊下方 → **A little cooler** → 進 Your report。
3. 確認體感已預選；改選 **Not cooler** → **Finish later**。
4. 回地點頁 → Stop sharing；保留這份草稿，D 輪會繼續使用。

**觀察：** 是否清楚分享人數與發布體感是兩件事？先選捷徑也應能修改答案。

### C06｜切換分享地點、重新啟動及十分鐘到期

1. 在附近的 City Gallery Foyer → I’m cooling off here → 記下結束時間。
2. 關閉地點 → Nearby place 改 Shade beside the playground → Explore → 該地點 → I’m cooling off here。
3. 回前一地點確認只有新地點仍有自己的分享；回新地點記下結束時間。
4. 關閉並重新開啟 App，在結束時間前查看分享仍在；不用重按分享。等待到顯示的結束時間後再看人數。

**觀察：** 自己只同時分享一個地點；重啟不延長這次的十分鐘，到期移除的是自己的那一人，不會讓其他示範人數全部歸零。這項不會自動發布回報。

## D：開始、續填、發布與閱讀回報

這輪若選到已發布本次造訪的地點，請更換；目前沒有編輯／刪除已發布回報的入口。**先做續填與丟棄，再做 D07 的發布**，避免提早關閉這次造訪的測試入口。

### D01｜不分享人數，也能開始回報

1. Nearby place 選 Shade beside the playground → Explore → 該地點 → Visitor reports 下方 **Share how it felt**。如果已有草稿，按 Continue report 即可，但略過「預設未選」觀察。
2. 初次進入時先不選體感，確認 Publish report 不可用；記錄原 Visit time。
3. 選 **Not cooler**，確認 Publish 可用；不必填原因、停留或留言。
4. 先按 **Finish later**，不要發布 → 查看地點頁出現 Continue report。

**觀察：** 這條獨立路徑不應新增人數；「沒有變涼」也能回報。若 C06 的人數仍在，先 Stop sharing 再比對。

### D02｜選填、改時間與返回

1. You → Your reports → Unfinished → Shade beside the playground 的 **Continue report**。
2. **What helped** 展開 → 選 Tree shade、再取消一次；選好測試答案後收合。
3. **Time here** → 選一個時長；再試 **Prefer not to say** 或 **Not added**，最後留自己想測的答案。
4. 留言框填 `TEST D02 這裡有樹蔭` → **Visit time** 改為稍早的時間 → Finish later。

**觀察：** 訊息是否好找、會否誤會每一題都必填？Visit time 是造訪時間，不是現在按發布的時間；不能選未來時間。

### D03｜離開、重啟，再續填

1. Nearby place → Away from all Cool Spots → 返回主頁 → 關閉並重新開啟 App。
2. You → Your reports → Unfinished → Continue report。
3. 核對 D02 的體感、設施、停留答案、留言及 Visit time → Finish later。

**觀察：** 從 You 能否直接找到草稿？不應要求重新到場、重新分享人數或先收藏。

### D04｜已開始的草稿不受時間限制

1. You → Settings → Prototype controls → **Simulate a visit 7 days ago**。
2. 返回 You → Your reports → Unfinished → Continue report。
3. 確認答案仍可修改、Publish 可用 → Finish later。

**注意：** 控制器只調整未開始回報的造訪日期，所有確認過的到訪都繼續可回報；已開始草稿保留原答案及日期。

### D05｜同時有兩份草稿，從不同入口找回

1. You → Your reports → 檢查 C05 的 City Gallery Foyer 與 D01 的 Shade 草稿都在 Unfinished。
2. 打開 Gallery 的 Continue report → Finish later → 再打開 Shade 的，確認兩份答案沒有混在一起。
3. Explore → Shade → Continue report → Finish later。
4. 若 Shade 已收藏，關閉地點 → Saved → Places → Shade → Continue report → Finish later。

**觀察：** You、地點頁和已收藏地點是否回到同一份草稿？Saved 沒有收藏該地點時不會憑空出現這條路徑。

### D06｜丟棄測試草稿與重新開始

1. You → Your reports → City Gallery Foyer 的 Continue report → 頁面下方 **Discard answers**。
2. 先點彈出框外取消 → 確認答案仍在。
3. 再 Discard answers → 確認丟棄 → 檢查該草稿消失；Away 時仍可在 Visits you can report 重新開始。
4. You → Your reports → Visits you can report → City Gallery Foyer 的 Share how it felt → 應為新的空白表單 → 選一項 → Finish later。

**只丟棄 C05 測試草稿。** 這只清除答案，保留已確認到訪；不刪除 Saved 或以前已發布回報。

### D07｜發布回報與防止同次重複發布

1. You → Your reports → Shade 的 Continue report → 檢查內容／Visit time → **Publish report**。
2. 完成頁 → **Done** → You → Your reports → **Published** → 打開這一則。
3. 核對 Visit、Published、体感與選填答案；Unfinished 應少一份，Gallery 的測試草稿仍在。
4. 返回 Explore → Shade → 應看到 **You’ve shared this visit**；檢查人數沒有因發布回報而增加。

**也測另一次到訪：** 模擬在 Shade 附近 → 該場所頁 → **Share a new visit** → 選體感 → Finish later。確認舊回報仍在 Published、新草稿單獨存在，人數沒有增加。Published 沒有編輯／刪除入口。

### D08｜最新預覽、全部回報、自己的與範例格式

1. Explore → Shade → 讀 Visitor reports 下方預覽 → **View all**。
2. 核對新報告與 Example visitor report 是否使用相同內容順序；有填的資料才出現。
3. 返回地點頁 → 直接點預覽文字，也應進入同一 Visitor reports 頁。
4. 再打開 Riverside Library 的 Visitor reports，比較你原有報告與範例；返回 You → Your reports → Published 查看自己的版本。

**排序：** 依 Visit time，最新在前，不分作者；不是依按下發布的時間。故把造訪時間填得更早的新發布回報，不一定占預覽。範例有固定示範日期和 Example 標示；未填的選填欄位可略過，但不應改成另一套格式。

**補充觀察：** You 裡自己的已發布詳情也共用 Visitor reports 的閱讀格式，另在下方補充 Published 時間與收到的感謝。

## E：審核狀態、感謝、帳戶與設定

### E01｜場所提案的全部審核狀態

1. 若 B11 後曾重啟 App，先用 **Explore → Riverside Library → Suggest an edit → Entry and seating → Seating** 改一项 → **Send for review → Done**，準備一筆本輪測試提案。
2. You → Places you’ve added or updated → 確認 **In progress／In review**。
3. 返回 You → Settings → Prototype controls → 按下方表格中的一項 → 返回 Settings → 返回 You → Places you’ve added or updated。
4. 記錄結果；回到同一控制頁，依序試完四個按鈕。它們會覆寫最新那筆場所提案的狀態，不是新增四筆。

| 點擊的測試按鈕 | 回到紀錄頁應看到 | 這一版能做到哪裡 |
|---|---|---|
| Needs clarification | Needs your attention → Action needed 與原因 | 只能讀原因，沒有補件／重送入口 |
| Publish | Outcomes → Published | 只模擬狀態，不會建立地圖上的新地點／更新設施 |
| Merge with an existing place | Outcomes → Added to an existing Cool Spot | 只有說明，沒有可點進目的地的入口 |
| Do not publish | Outcomes → Not published 與原因 | 沒有重送、申訴入口 |

**這不是使用者自己審核自己的內容：** Prototype controls 只是在測試不同結果畫面；真正審核服務尚未接上。狀態卡是閱讀內容，不是按鈕。

### E02｜對別人的範例回報送感謝、取消

1. Explore → Riverside Library → Visitor reports → View all → **Example visitor report** → **Send a popsicle**。
2. 如果第一次出現 **Send a little thank-you?**，先 Cancel；再點 Send a popsicle → 確認送出。已看過說明時可能直接切換為已送。
3. 確認 **Popsicle sent · Demo** → **Undo** → 再送一次，最後可 Undo。
4. 查看自己的回報，確認沒有對自己送感謝的按鈕。

**觀察：** 是否清楚這是感謝作者，不是涼度投票？本地示範不通知真人，也不改變回報排序或人數。

### E03｜收到感謝後找回对应回報

1. You → Settings → **Popsicle thank-you example**，先讀 **For your report at…** 指定的是哪一筆。
2. **Simulate receiving a popsicle** → 返回 You → Your reports → Published → 開對應地點的最新指定報告。
3. 查看收到感謝的 Example 說明；可重啟後檢查紀錄仍在。

**前提：** 這個按鈕就在 Settings，不是在 Prototype controls 裡。尚未發布任何回報時，只會看到先發布的提示。

### E04｜帳戶、Cool Hunt 與回到任務

1. You → **Sign in** → Your account → 讀說明 → 若要試模擬登入，再點頁內 **Preview account**。
2. 返回 You → **Your account**，查看登入後樣子 → 返回。
3. **Cool Hunt** → 讀 Shade finder、Place types discovered → 橫向滑動類型列 → 讀 Your help → 返回 You。

**目前止點：** Preview account 只是本次使用的帳戶示範，沒有 Apple／Email 驗證、跨裝置同步或 Sign out。Cool Hunt 的類型解鎖會對本次人數分享反應，但 Shade finder 1 of 2 與部分貢獻數是固定示例；方塊不可點進。也沒有獨立 All contributions 的目前導覽入口。

### E05｜外觀、大字、減少動態與問題回報

1. You → Settings → Appearance → **Dark** → 返回 Explore → 打開一個地點及其回報；再試 **Light**／**Match System**，最後恢復你原來的設定。
2. 若使用 iPhone／Simulator 的系統 Settings：Accessibility → Display & Text Size → Larger Text → 放大文字 → 回 Cool Spot 看表單、回報、送出鈕；之後恢復原值。
3. 系統 Settings → Accessibility → Motion → **Reduce Motion** → 回地點 → How this works，查看靜態完成狀態；之後恢復原值。系統語言不同時按相應中文名稱找設定。
4. 回地點頁 → **Report a problem** → 讀尚未接通的說明 → **Done**。目前沒有假送出的 Send report 按鈕。

**觀察：** 大字是否擠壓、遮住操作？深色是否難讀？問題回報是否和「這次不涼」混淆？不要為此更改自己的資料或開啟不需要的系統權限。

## 無法靠一般點擊完整重現的分支

下面也是產品流程範圍，但現在不要求你靠猜測把它們叫出來。

| 分支 | 若自然出現的點擊順序 | 目前限制／測試方式 |
|---|---|---|
| 新提案與既有地点重複 | This place is already on Cool Spot → **Review update** → 核對 Your changes → Send for review；或 **Keep editing** 取消 | 目前比對需座標幾乎完全相同，且有名稱時名稱相同；手指點地圖不易精確觸發，不是模糊近距離去重。需要另備測試資料，已有模型測試。 |
| 照片讀取失敗 | Photo couldn’t be loaded → OK → Add／Replace photo | 本輪不要求刻意損壞圖片；如遇到，確認其他答案留著。 |
| 場所提案送出失敗 | Not sent → Keep editing → 補正後再 Send for review | 沒有「模擬失敗」按鈕，也沒有真實網路上傳；正常按鈕驗證可能讓你遇不到。 |
| 個人回報發布失敗 | Report wasn’t published → Keep editing → 確認 Visit time 再 Publish report | 沒有固定 UI 開關可觸發；不可把沒有遇到寫成已通過失敗復原。 |
| 完全空白資料狀態 | Saved 的 Nothing saved yet／You 的 No reports yet／無場所提案 | 目前有預設 Pin 與提案，沒有安全的一鍵清空測試控制；保留真實舊資料，若需要再另備隔離測試環境。 |

## 記錄回饋

本輪先檢查入口、用詞、資訊分組、成功回饋與中斷／接續；影響理解的間距也算流程問題。純視覺偏好另外記，先不推導成已核准的改版。

```text
編號／版本／日期：
結果：通過／卡住／找不到／不適用／待測
完成方式：自行找到／看步驟或提示後完成
我想做／我原本以為：
實際發生／截圖：
```

| 尚待驗證的重點 | 相關編號 |
|---|---|
| 能否快速決定去不去，區分涼度證據、人數與座位；也允許因資訊不足而不去 | A01–A04、C01 |
| 收藏是否清楚私人；公開表單、名稱／角落／照片與選填分類是否直覺 | A05–A09、B01–B10 |
| 保存後是否找到返回入口；真的去過但缺乏確認時是否失望 | C02–C05、D01–D07 |
| 最新回報預覽、範例格式、審核結果與感謝是否被正確理解 | D08、E01–E04 |
| 大字、深色、減少動態、返回／滑動與選單焦點是否穩定 | B05、B06、B08、E05 |

### 本輪結果紀錄

目前只有上方列出的歷次證據與 owner「可用、仍需驗證」的總評，沒有新增逐項通過紀錄。收到實際回饋後在此記錄，不新增另一份 findings 文件。

| 日期／版本 | 編號 | 觀察與完成方式 | 決定／修正 | 復測結果 |
|---|---|---|---|---|
| 待本輪回饋 | B04 | 尚未記錄 | — | 待測 |
