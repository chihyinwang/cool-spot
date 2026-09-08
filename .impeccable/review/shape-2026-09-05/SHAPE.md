# Cool Spot — 第一階段待確認設計

2026-09-05 · iOS / SwiftUI · Register: product · Mode: Operate

狀態：使用者於 2026-09-05 回覆「都同意」，四稿與三項建議均已核准；第二階段實作記錄見 ../implementation-2026-09-05/。讀取 PRODUCT.md、CONTEXT.md、四份 PROTOTYPE 文件與 recognition/DESIGN-NOTES.md，並核對現有 SwiftUI。這份稿件補充本次決策，不改寫既有測試發現，也不是新的設計系統。

## 1. 目標與設計邊界

炎熱、疲倦、單手操作的人，先在 30 秒內找到、判斷並開始前往可信的降溫地點。讀取證據優先，貢獻其次。沿用原生 NavigationStack、sheet、List、系統字級與 AppStyle 的深青／薄荷色角色；不沿用 Web prototype CSS。

**已定案**：Explore / Saved / You；Saved 的 Places / Pins；Your reports；私人儲存、公開場所資訊、個人體感、十分鐘人數各自獨立。Save 不取得資格；已開始回報沒有完成期限。沒有感測器就沒有溫度。公開場所資料要審查，Visitor report 經明確 Publish 後發布。

**本次需確認**：標記與區塊的具體構圖、Required → Ready → Optional 互動，以及下列三個缺口的建議處理。所有互動稿只表示流程，不是真實發布、保存或定位。

## 2. Live Presence 標記

```text
0 人                 2 人             3 人             10 人
                     [人 2]          [人 3]          [人 10]
  (場所類型)          (場所類型)       (場所類型)       (場所類型)
```

小標記位於場所圖示正上方、水平置中。0 人時整個小標記不存在。圖示的地圖錨點不隨標記出現而移动；數字用等寬數字，依位數長寬，至少驗證 1、2、3 位數。不能把 10 顯示成三點，也不自行截為 9+。地圖密集時保留各場所的語意，叢集數量不得套同一個人數標記。

正式實作共用 `CoolSpotPin(type:count:)`，Places 地圖與 `PresenceMapExample` 都引用它；用 `person.fill` ＋數字，場所仍使用既有 `PlaceType.symbol`。來源不是這個 component 的輸入；官方來源在 Place 頁保留文字 badge。圖示與數字合成一個 VoiceOver 元素，不變成兩個按鈕。讀法例：「Riverside Library，圖書館，2 人在最近 10 分鐘分享正在這裡降溫」。0 人不能讀作場所沒有人。

```text
How this works — Illustration only

   [人 2] → [人 3] → [人 3，停留] → [人 2]
    1.5 秒   0.25 秒    2.5 秒       重播示例

   [ Pause example ]
```

**已定案**：自動循環，Pause / Resume；Reduce Motion 顯示靜態 3 和「2 → 3」文字、不自動循環。關閉 sheet／App 非活動時停止；使用者暫停不被重繪重設。輔助閱讀不逐幀廣播數字。

**提案**：不移動地圖、不彈跳 pin，只變換數字；返回 2 明示為「Example restarts」，不能看起來像十秒內過期。文字：「People who shared they’re cooling off here in the last 10 minutes. This is not a seat count, capacity or temperature reading.」示例不分享定位、不改真實人數。詳細說明保留附近檢查、匿名、十分鐘到期與 Stop sharing。

## 3. Place → Visitor reports

```text
Visitor reports                         View all

“Quiet upstairs, with tables
away from the windows.”
Example report · Visit date unavailable

How long people stayed                         ›

[ Share how it felt ]
Start while you’re here. You can finish later.
```

**提案**：只預覽一則，先標題與閱讀入口，再留言及其來源，接著可展開的停留時間分布，最後是次要的貢獻按鈕。保留現有停留分布，因為需求中簡圖省略它不代表授權刪除。View all 開同一個既有報告閱讀頁；留言可作同一閱讀連結，但不另顯示重複 CTA。Directions / Save 仍是 Place 頁底部主操作。

真實回報有 `visitedAt` 才顯示絕對日期；fixture 留言標為 Example，沒有作者、日期、答案就不補造。沒有留言但有真實報告時可預覽實際體感；沒有任何個別報告時顯示「No individual reports to read yet」，不從 aggregate totals 建造紀錄，View all 不顯示無內容入口。真實與 fixture 混合時优先有實際資料的報告，不把無日期 fixture 排成最新。

貢獻入口隨狀態：尚未開始且符合資格 → Share how it felt；已開始 → Continue report；該次已發布 → You’ve shared this visit；不符合資格 → 停用 Share how it felt，加原因和 Why can’t I share?。續填說明仍指向 You → Your reports。

## 4. Visitor report：唯一必填到立即可送

```text
                      Your report              Finish later
                      Riverside Library

Required              How did it feel compared with outside?
                      ○ Not cooler
                      ○ A little cooler
                      ○ Much cooler
                            ↓ 點選後進 Ready，不發布

‹ Back                Your report              Finish later
Ready                 Your report is ready
                      You can publish now, or add more details.

                      How it felt
                      Much cooler than outside       Change
                      Visit time
                      [保留該次實際時間]               Change

                      Add more details · Optional
                      What helped                          ›
                      How long you stayed                  ›
                      Add a comment                        ›

                      [ Publish report ]

Optional row → 單項編輯頁 → Back → Ready，顯示答案摘要
Publish → Report published → Done → 原場所或 Your reports
```

體感選擇是唯一必填；一選就建立可發布狀態。原生返回保留答案，Change 返回同一選項頁。Finish later、sheet dismiss、重新啟動均保存既有草稿，不設截止日、不啟動 Live Presence。已選體感的舊稿直接進 Ready；沒選體感進 Required。從 presence shortcut 帶入的答案同樣進 Ready，只有明確 Publish 才送出。

What helped 可以不填，即使選 Not cooler 也不禁用：某個因素有幫助，不代表整體比外面涼。它只屬於該次体验；不改公開 cooling features。How long you stayed 不變成正式停留限制。Optional 頁 Back 保存目前編輯；可清除自己的答案恢復未填，不需完成其餘項目。發布失敗保留草稿、顯示原因與 Retry，避免重複新增；成功才從 Unfinished 移到 Published。

**待確認 1 — 保留 Visit time 確認列（建議）**：你提供的 Ready 圖省略了它，但產品已依造訪時間判斷新鮮度，延後回報不能變成剛剛造訪。保留原始時間的唯讀摘要＋Change，不新增必填步驟；沿用既有可編輯時間範圍。不可把原始時間缺失的歷史資料補成今天。

## 5. Add cooling information：同一表單、不同初始內容

```text
A Recognised Place ─────────── 已選場所 ─┐
B Explore ＋ ── 地點選擇 ────────────────┤
C Saved Pin → Add cooling information ──┤→ 同一公開場所草稿
D Existing Cool Spot ──────── 更新模式 ─┘

地點選擇
 ├ Nearby suggestions → 明確選擇場所
 ├ Search all recognised places → 搜尋結果 → 明確選擇
 ├ Add a missing named place → 名稱＋地圖位置
 └ Use this exact unnamed spot → 確認精確位置

每次選擇 → 檢查是否已有 Cool Spot
 ├ 已有 → 更新同一場所，不建立副本
 └ 未有 → 依身分類型收最低必要資料
          ↓
      Ready to send for review ⇄ 自選 Optional
          ↓ Send for review
      Sent for review（尚未公開）
```

### 地點選擇 wireframe

```text
‹ Back           Choose a place                 Close

[地圖：saved coordinate＋實際精度（若有）]
Your saved pin（C）；Current location（B，定位可用時）

Search all recognised places                       ›

Nearby suggestions
Riverside Café · [地址]                             ›
Riverside Library · Already a Cool Spot             ›

Add a missing named place                          ›
Use this exact unnamed spot                        ›
```

C 的座標、建議距離與地圖中心來自保存當時的位置；不要以目前位置覆盖，也不要硬寫 accuracy 25 m。B 無定位時仍可搜尋／手選位置；定位失敗不等於沒有場所。搜尋可檢索全部 recognized sources，nearby 只排名、不自動選擇。空結果可重試或改走 missing / exact。若搜尋結果或送出前發現已有 Cool Spot，提示已切換更新，保留新輸入供使用者比對；衝突值不默默覆寫。

### 最低資料與 Ready 條件

| 路徑 | 必須具備 | 不能默認／額外強迫 |
|---|---|---|
| Recognised place | 場所 identity；Setting；至少一項 Cooling feature；可信 Type，若無則使用者選擇 | 未知 Setting 不能當 Indoors；地圖名稱是確認資訊 |
| Missing named place | 名稱、地圖位置、Type、Setting、至少一項 Cooling feature | 不把私人 Pin 名称預填成公開名稱 |
| Exact unnamed spot | 精確位置、Outdoors、至少一項 Cooling feature、公眾可合法進入確認、可辨認照片 | 不強迫命名或選 Park；不新增 Type 問題 |
| Existing Cool Spot update | 至少一項實際修改及該修改本身有效 | 見下方待確認 2；不要求補齊未碰觸的歷史缺項 |

```text
‹ Back           Add cooling information         Close
Minimum details

Recognised               Missing named             Exact unnamed
Place [source name]      Name [input]               Location [map] Change
Setting [Choose…]        Location [map] Change      Setting Outdoors
Type [source / Choose]   Type [Choose…]             Cooling features ›
Cooling features ›       Setting [Choose…]          □ Public can legally enter
                         Cooling features ›        Identifying photo › Required

             [ Continue ]（最低資料完整才可用）
```

Known-place photo optional；exact photo required 且放在 Required 摘要，不能在 Optional 重複列出。照片缺失／權限拒絕／無法辨認時不假裝成功，有重試或重新選圖入口；現有 prototype 未接照片管線，第二階段必須明示模擬，不得將任意布林值視為正式有效照片。

```text
‹ Back            Add cooling information        Close
Ready to send for review
You can send now, or add more details.

Place                                          Change
Name           Riverside Café（地圖來源，非輸入框）
Setting        Indoors                         Change
Type           Café, restaurant or food hall（來源）
Report incorrect place details                       ›

Cooling features                               Change
Tree shade（僅展示使用者確實選的資料）

Add more details · Optional
Entry and access                                     ›
Seating and stay                                     ›
Other facilities                                     ›
Photo                                                ›
Note                                                 ›

[ Send for review ]
Public only after review.
```

Ready 的 Name / Setting / Type 各占一列；使用者輸入者可 Change，可信來源者展示其 provenance 而不假裝可編輯。來源更正開獨立的 Report incorrect place details 子流程並返回原草稿，不直接改地圖來源身份。更新模式顯示修改前後，未修改資訊保持上下文而不偽裝成此次提交。

**待確認 2 — 更新模式只驗證實際更動（建議）**：新場所的必填不應強加到只改座位的使用者。所有入口共用 identity、欄位、Ready、Optional 與審查規則；新增／更新用不同驗證条件。更新至少一項 changed field，否則顯示「Choose a detail to update」，不能無變更送出；需要撤除最後一個 cooling feature 時走明確撤除／審查意圖，不強迫選一個不真實的替代。

### Optional 欄位分類

| 唯一歸屬 | 可填資料 |
|---|---|
| Cooling features | Air conditioning；Cooler indoor space；Tree shade；Structural shade；Drinking water；Water nearby；Natural ventilation |
| Entry and access | Free to enter / Purchase expected / Ticket required（有條件差異可說明）；Accessibility information |
| Seating and stay | Seating availability；Tables available；正式停留限制（僅知道時填，例：現場告示，不從訪客時長推論） |
| Other facilities | Toilets；Wi-Fi；Power outlets；Laptop use welcome / allowed |
| Photo / Note | Known-place optional photo；額外公開 note |

Cooling features 不收 Laptop friendly。Power outlets 不推論為允許筆電。公眾可合法進入不代表 Free to enter。空白是未知，不是 No；布林問題採未填／Yes／No，不默認沒有。若其他 access 條件都不適用，不迫使選錯誤費用類型。

## 6. Back、Close、Change 與私人 Pin

Back 在 flow 的 navigation stack 回上一步，保留所有目前答案；Optional 編輯返回 Ready。Close 位在右上角，離開整個場所貢獻流程。沒有使用者輸入可直接關閉，有未送出內容則確認，不用含糊 Cancel 同時代表返回與放棄。

**待確認 3 — 本輪場所草稿不新增跨啟動保存（建議）**：Close 顯示「Discard this place contribution?」／「Keep editing」／「Discard and close」。理由：目前只有 Visitor report 已具备持久續填；若加 Save draft，必須同時設計返回入口、儲存及遷移。Visitor report 繼續用已定案的 Finish later，不能套這個丟棄流程。若希望場所資訊也可續填，需在核准時指出，補 Places you’ve added or updated 中的草稿入口。

更換場所先進挑選，原稿暫存；取消選擇原封返回。選到同一 identity 不清除；選到新 identity，顯示「Start details for [new place]?」明列 cooling、access、seating、photo、note 都需重填或重新確認。確認才切換，新草稿不攜帶舊場所的專屬資料。名稱／type／setting 依新來源重新建立；不把舊答案暗套到新場所。

```text
‹ Saved                   Saved pin
Shade near the river
[saved coordinate map]

Private details
Name        Shade near the river                  ›
Note        [使用者私人備註]                       ›

Cooling information
No cooling information yet
[ Add cooling information ]
```

Pin 不顯示私人 tags 或匹配問卷；按 Add cooling information 才進場所選擇。公開流程採獨立草稿，不帶入私人名稱／備註／照片。送審、合併、發布均不移除、更名或擅自公開 Pin。若已知公共場所關聯可提供 View cooling information，但不以附近推論相同場所；Pin 仍在 Pins。

## 7. 第二階段驗證條件（本輪未執行）

1. 先保存既有 Saved、unfinished/published reports、appearance 等資料，驗證遷移不重置；新來源可信度與選填未知狀態不可用舊預設假造。
2. 對四個入口、三類新增與更新、重複場所、改場所、Back / Close、無定位／無照片／送出失敗作行為檢查；一個體感即可 Publish；沒填 Optional 可直接 Send。
3. iPhone / iPad，Light / Dark，最大 Dynamic Type、Reduce Motion 和 VoiceOver：44pt 目標，橫列必要時上下堆疊；Ready 送出固定在可達底部，大字可隨內容滾動，不能遮蓋欄位。
4. 原生 Simulator 截圖與 bounded Impeccable review 才能作 SwiftUI 實作證據。本輪動態 wireframe 僅供決策，不作 native QA；最多一次批次檢查與一次修正確認。
5. 核准後更新相關 PROTOTYPE 文件；只有領域詞義實際改變才更新 CONTEXT。先以首次使用者核對 0 vs 10、讀取 vs 貢獻、只答一項能送出、saved coordinate 與私人資料邊界。

請確認四個 wireframe，並選擇是否接受待確認 1–3 的建議。未確認前不進第二階段。
