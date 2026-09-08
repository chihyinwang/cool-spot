# Cool Spot：以使用者心思走查回報流程

## Current owner feedback revision — 7 September 2026

This section supersedes older eligibility and form instructions below. The current owner walkthrough is [OWNER-JOURNEY-WALKTHROUGH.md](OWNER-JOURNEY-WALKTHROUGH.md).

- Confirmed visits have no deadline to start or finish a report. Discard clears answers, keeping the visit eligible. A nearby person can explicitly choose Share a new visit after publishing; retries never create duplicates.
- Saved recognised places and existing Cool Spots open their normal place pages, with Save/Saved and shared private-note controls. Private save success is acknowledged in place.
- Indoor, outdoor and mixed settings use the same location-identification rule. Public names and untrusted place types are optional. An unnamed point needs a decodable identifying photo; optional location directions can identify a floor or corner. Who can use this spot is optional for every place: Everyone, Limited access (with students, members and residents as visible examples), or Not sure. Limited access and unknown eligibility do not block review. Eligibility and cost remain separate. The MVP form omits the Who is it limited to? and Tickets and booking text fields (owner decision, 2026-09-08). Cost to use offers Free to use, Purchase required, Entry fee and Not sure; a free ticket is not an entry fee.
- The public form uses a map preview with one Change location action. Name and helper text share one row. Time limit has presets and hours/minutes controls.
- Explore explicitly shows no matches and offers an optional contribution route. Your own published report reuses the public report layout. The review/account/moderation services remain prototype boundaries.

Older sections below record prior iterations; do not use their 24-hour cutoff, forced indoor name/type, mandatory public-entry confirmation, or free-text time-limit instructions.

## Current public contribution / report journeys — 6 September 2026

Explore + → inline search / nearby / one map route → selected place → one grouped public form → Send for review. Known-place entry starts at the form. Saved-pin entry starts at its original map position; the point is confirmed before asking for a public name. An unnamed outdoor point still requires a decoded identifying photo and public-entry confirmation, without the former photo self-confirmation switch. Related optional facts expand inline; changing place protects existing answers with an explicit consequence.

Report reading uses one date-sorted list across authors, with newest preview using that same list. Own and example provenance are explicit. Your report starts with the feeling choice and keeps optional features, duration and comment on one page. Finish later remains private and preserves visit time.

The journey revisions below are historical. This current section supersedes their contribution-screen order and earlier pending-choice status; saved-data, eligibility and original-visit-time rules remain unchanged.

日期：2026-09-04；2026-09-05 更新 Your reports 與續填規則。這是設計假設、程式核對與原型操作紀錄；下面的內心話是用來檢查流程的假設，並非受測者原話。

## 這一輪的判斷

使用者先需要決定哪裡能降溫。想幫忙的人，才需要理解回報。頁面不能要求每個找地點的人先學完定位資格、匿名人數與回報期限。

回報過程要能回答四件事：我按了會公開什麼？現在沒空怎麼辦？之後去哪裡找？還能不能完成？這一輪把答案放在操作發生的位置，並補齊返回路徑。

在附近開始的回報沒有完成期限，保留該次造訪時間與答案。只分享正在降溫人數而未開始回報者，沿用 24 小時「開始」資格；這不是已開始回報的提交期限。Save 不會啟動回報，不會變成到訪證明。沒有新增背景定位或被動造訪紀錄。

## Journey 1：我很熱，只想知道值不值得去

- 心思：「能不能進去？可能多涼？有人說不涼嗎？我還缺什麼資訊？」
- 路徑：Explore／搜尋 → 場所頁 → 體感摘要與三種回報數 → cooling features／完整展開 → 入場與座位資訊 → Directions。
- 完成：讀資訊、儲存、開啟導航都不要求先回報或分享人數。也允許使用者因資訊不足而決定不去。
- 這輪修補：場所類型與來源標章對齊，空間不足時上下排；Museum or cultural venue 比 Culture 明確。
- 仍需測試：整頁仍有內容密度問題；新回報說明位在回報區，不應搶先於降溫證據。導航連結只驗證目的地 URL；沒有實際步行或外部導航完整測試。未知開放時間仍可能阻礙真正出發。

## Journey 2：我人在這裡，想說其實不涼

- 心思：「我沒有在這裡成功降溫，但仍想提醒別人。」
- 路徑：場所頁 → Visitor reports → Share how it felt → Not cooler → 確認 Visit time → Publish visit report → Done。
- 完成：體感為唯一必選答案；原因、停留時間與留言可略過。時間預填，可修正。不會增加正在降溫的人數。
- 這輪修補：人在附近時看得到可離開後繼續，表單中有 Finish later 與 You → Your reports 返回提示，不再顯示提交截止時間。
- 仍需測試：新增 Visit time 是為了避免誤解補報時間，但立即回報的人可能覺得多一項欄位；測量是否真的需要修改，不要只問喜不喜歡。現在公開後沒有修改答案入口，這是下一個功能缺口。

## Journey 3：我開始填了，現在得走

- 心思：「不要把沒填完的內容發出去，也不要讓我下次重填。」
- 路徑：Share how it felt → 選答案／填部分內容 → Finish later → 場所頁顯示 Continue report 與 You → Your reports 提示。
- 返回路徑 A：You → Your reports → Unfinished → 對應場所的 Continue report → 保留的表單 → Publish report。You 只顯示入口與未完成數量，不展示個別回報。
- 返回路徑 B：若另有收藏，Saved → 同一個 Cool Spot → Visitor reports → Continue report → 同一份表單。只有收藏、未開始回報不符合此條件。
- 返回路徑 C：Explore／搜尋 → 同一個 Cool Spot → Continue report。
- 完成：答案隨修改保存，關閉表單或重新啟動也會保留。Finish later 不公開、不增加人數、不改造訪時間；沒有提交截止時間。
- 仍需測試：You 是否是使用者自然想到的返回地點？介面已提供說明與 Saved 路徑，但不能先假定人人都會找對。

## Journey 4：我只說過正在這裡降溫，回家才想分享體感

- 心思：「我當時已經告訴 App 我在那裡，現在不應被要求再回去。」
- 路徑：場所頁 → I’m cooling off here → 成功訊息與可選體感問題 → 離開／Stop sharing → You → Your reports → Visits you can report → Share how it felt → Publish。
- 完成：第一次分享人數時保留該場所 24 小時的開始資格；即使未開始回報也有返回入口，但不計入 Unfinished。使用者不必先 Save。開始後可無截止時間續填。
- 這輪修補：人數分享成功後顯示可稍後分享體感的期限和入口。人數的本地計時在十分鐘後結束，體感資格仍保留。
- 仍需測試：成功區同時說明十分鐘人數和二十四小時回報，是否仍容易混淆？兩者的動詞、公開結果與入口已分開，但需要第一次使用者解釋給我們聽。

## Journey 5：我儲存場所，是為了之後找回來

- 心思：「我點同一個場所，就應該看到它完整的資訊和可以做的事。」
- 路徑：場所頁 → Save → 離開／重新啟動 → Saved → 場所 → 完整場所頁。
- 完成：Explore 與 Saved 的 Cool Spot 使用同一個完整頁面，不再落入只有修改場所資料的分支。
- 若曾在現場開始回報：可直接繼續，保留原答案和造訪時間。
- 若只有 Save：可以重新閱讀資訊、導航、修改場所資訊，但仍沒有離開後體感回報資格。
- 仍需測試：儲存這個動作是否讓人錯誤預期「App 已知道我去過」？必要時在相關說明解釋，不把每次 Save 都變成教學。

## Journey 6：我記下一個沒名字的位置，稍後再補資料

- 心思：「先記下來，我現在沒有時間決定要不要貢獻資料。」
- 路徑：＋ → Save current location → View saved location，或稍後 Saved → 該座標 → 私人名稱／備註；選擇分享時 → Find or add a named place／Use this exact spot → Add cooling information → 送交審查。
- 完成：私人座標和備註可以保留；公開 cooling information 仍是獨立的選擇。這條既有流程保留，新增本地持久保存。
- 限制：這條路可以補場所資訊，但不能自動轉成對某個既有 Cool Spot 的體感回報。座標也不能自行決定是相鄰哪一間場所。
- 仍需調整的產品問題：這與「先存位置就是為了之後回報體感」的初始期待有落差。若要支援，需要另行設計使用者確認場所與紀錄用途的步驟，不能暗中重定義 Save。

## Journey 7：我剛離開，現場完全沒操作

- 心思：「我真的去過，為什麼想幫忙卻被拒絕？」
- 路徑：場所頁 → 停用的 Share how it felt → Why can’t I share? → 說明缺少先前附近確認、Save 不等於開始回報，以及下次如何稍後完成。
- 結果：這次仍無法回報。找得到原因，與完成原本任務，是兩件不同的評估結果。
- 我們不應歸咎於使用者沒看教學。要支援這一類人，就得改為明確同意下的更早確認，或接受較弱證據的事後分享；目前沒有偷偷選擇任何一種。
- 優先觀察：這種情境出現頻率、失望程度，以及因此流失多少有用回報。若很常見，資格規則需要重新設計；增加說明不會消除限制。

## Journey 8：我幾天後重新啟動 App

- 心思：「我上次填的還在嗎？會不會被當成今天的體驗？」
- 路徑：重新啟動 → You → Your reports → Unfinished → Continue report → 原答案、原造訪時間 → Publish report。
- 完成：舊版因 24 小時被鎖住的已開始回報也可繼續。重開、重新走近或分享人數不會把舊答案改成新造訪；丟棄答案仍需明確確認。
- 限制：同場所同時多份未完成造訪尚未支援。保留舊稿優先，不能默默覆蓋；日後需要獨立的新造訪入口。

## Journey 9：我已經發布，想確認有沒有成功

- 心思：「有沒有重複送出？會不會把我當成現在還在那裡？」
- 路徑：Publish → Thanks for the update → Done → 場所頁顯示 You’ve shared this visit → 更新對應體感數量。
- 完成：同一確認不可重複新增回報；Your reports 中只有該份回報從 Unfinished 移到 Published，You 的未完成數量同步減一。Published 可打開唯讀的實際答案。提交不會啟動人數分享，重新啟動仍保留提交結果。
- 時間：Visit time 表達使用者描述的體驗時間，提交時間另存。公開 Latest reported visit 依體驗時間計算；延後提交不會自動變成剛剛的體驗。
- 限制：沒有公開後改答案／刪除回報的流程。同一天不同造訪目前共用一個有效確認，不能假定已能區分每次出入；正式反濫用與更新回報規則尚待設計。

## 真實定位接入前還缺什麼

| 使用者處境 | 正式流程需要的下一步 | 本次狀態 |
| --- | --- | --- |
| 尚未同意定位 | 在首次需要檢查附近位置的動作上解釋用途，再請求授權 | 未接真實權限 |
| 拒絕定位 | 仍能讀資訊與儲存；說明無法確認附近位置，提供設定入口 | 未接真實權限 |
| 訊號不準、室內收不到 | 顯示取得位置／重試；不能直接說人不在附近 | 未接 GPS |
| 已確認真的太遠 | 解釋這次不能建立資格，已有有效紀錄者仍可完成 | 模擬流程已支援 |
| App 沒開／現場無任何主動操作 | 決定是否接受另一種證據規則 | 保留現行限制 |

## 驗證與測試方法

- SwiftUI 和本地模型是實作基準，未使用 throwaway Web CSS。
- 自動測試涵蓋跨重啟恢復、私密儲存不授予資格、過期不發布、原期限不延長、跨場所隔離、體驗／提交時間、重複提交與十分鐘人數到期；最終結果見同目錄的驗證紀錄。
- 原生操作已走通「選答案 → Finish later → 重新啟動 → 模擬離開 → 再重新啟動 → Saved → 完整場所頁 → 恢復答案 → Publish」。Not cooler 與 Drinking water 的選擇保留，人數仍為原來的 2。
- 原生操作另檢查無資格說明、You 的返回入口、過期答案與大字／深色呈現。截圖和最終檢查紀錄位於 `.impeccable/review/journeys/`。
- 本地模擬沒有向外部服務發布；其他人的人數、場所資訊與舊回報均為 fixtures。自動測試和代理操作不能證明第一次使用者一定理解。
- 下一輪使用者測試問題、主持人設定與觀察方法見 `PROTOTYPE-TEST-GUIDE.md` 的 Return-to-report test。

## 2026-09-05：核准後的最短回報與場所資訊路徑

本節取代前文的舊表單順序，保留所有資格、私人保存與原造訪時間規則。

1. **只分享體感**：Share how it felt → 三選一 → Your report is ready → Publish report。What helped、How long you stayed、Comment 可以各自進入再 Back，沒有必須經過的選填頁。Ready 的 Visit time 可修正，Finish later 保留同一份原始造訪。
2. **從 Saved Pin 提供公開資料**：Pin 顯示私人 Name／Note 與 No cooling information yet → Add cooling information → 以保存座標為中心的選擇頁 → named／missing／exact → minimum → Ready。任何公開操作都不更名、刪除或搬移私人 Pin。
3. **確切無名位置**：確認地圖位置 → 固定 Outdoors → 至少一項 cooling feature → 公眾可合法進入 → 選實際照片並確認能辨認位置 → Ready → Send for review。未選照片或缺少識別確認都不能送出；不要求名稱／Park 類型。
4. **只修正座位**：Existing Cool Spot → Add or correct place details → Seating and stay → 修改 → Back → Ready → Send for review。保持既有降溫資料，不要求重答未修改欄位。正式停留限制和自己的停留時間始終不同。
5. **改地點／離開**：更換 identity 先確認，場所專屬資料重新填；同一 identity 保留原值。Close 的 Keep editing 留在當前頁，Discard and close 放棄本次公開草稿。Visitor report 仍使用 Finish later，不能套用場所的丟棄規則。

Native photo selection is now real, local and session-only. Search and location fixtures remain simulated. Submission records public answers for in-session prototype review; no real server, image moderation or persistent public-contribution draft was added.

## 6 September feedback revision

- Read visitor reports: each individual uses the same factual reading order; actual answers remain visible and missing fixture fields stay absent. Provenance is subordinate to content.
- Enter a public-form child: the title names the edited topic. Back returns to the main form with answers retained; it does not close the sheet. Main Close offers discard confirmation for changed answers. Native attempted dismissal remains guarded against losing a proposal.
- View presence explanation: the same badge used on the map shows a restrained 2→3 arrival over MapKit, with paused and Reduce Motion equivalents. No location share is made by the explanation.

The selection and optional-field architecture is unchanged pending the owner’s choices; see `.impeccable/review/feedback-2026-09-06/DECISIONS.md`.
