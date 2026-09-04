---
target: Cool Spot native place detail and report flow
total_score: 28
p0_count: 0
p1_count: 3
timestamp: 2026-09-03T19-10-46Z
slug: cool-spot-placedetailview-swift
---
Method: dual-agent (A: /root/critique_design · B: /root/critique_evidence)

# Cool Spot 原生場所頁與回報流程 critique

結論：保留目前視覺方向；下一步不是再選配色，而是讓證據更準確、前往判斷更快、操作狀態更清楚。本輪只評估，未修改 App。

範圍：以 SwiftUI 實作與 PROTOTYPE-BRIEF.md、PROTOTYPE-FINDINGS.md、CONTEXT.md、PRODUCT.md 為依據。原生檢查使用 iPhone 17 Pro Max / iOS 26.4、Light Mode，包含一般與最大輔助字級。這是專家評估，不是已完成的使用者測試。

## 設計健康度：28/40，基礎良好

每項 0–4，越高越好；分數用於追蹤同一介面的改善，不代表使用者成功率。

| # | 檢查面向 | 分數 | 主要觀察 |
|---|---|---:|---|
| 1 | 系統狀態清楚 | 3 | 新回報後 Latest 不更新；停用樣式不清楚 |
| 2 | 符合日常理解 | 3 | 體感語言清楚，但 Most 過度概括 |
| 3 | 使用者控制 | 3 | 可取消、停止分享、取消收藏 |
| 4 | 一致性與原生慣例 | 3 | 原生 sheet 良好；按鈕停用處理不一致 |
| 5 | 預防錯誤 | 2 | 有資格與發布檢查；回報頁缺少場所名稱 |
| 6 | 不依賴記憶 | 3 | 選項清楚，回報時仍須記住是哪個場所 |
| 7 | 操作效率 | 2 | Directions 固定置底有幫助，但最大字級破版、前往條件偏晚 |
| 8 | 簡潔與層級 | 3 | 整體克制，回報的選填內容過早展開 |
| 9 | 錯誤復原 | 3 | 資格過期說明具體，未發布時保留表單 |
| 10 | 說明與幫助 | 3 | How this works 可找到，證據限制離摘要較遠 |
| | **合計** | **28/40** | **Good：集中修正弱點，不需要推翻設計** |

## 反模式判斷

人工判斷：沒有明顯把 AI 網站模板套到 iPhone 的問題。照片、深青色摘要、原生表單與固定操作列有明確用途；這裡的熟悉感是優點。局部問題是選項卡再包一層表單，以及不同可用狀態仍使用同樣強烈的按鈕外觀。

自動掃描：對 `cool-spot/PlaceDetailView.swift` 實際執行 bundled detector，回傳 `[]`、exit 0。但其規則面向 HTML/CSS，**不具 SwiftUI 檢查能力，不能解讀為原生介面零缺陷**。沒有可用的規則命中或誤報；補充證據來自原生畫面、無障礙樹及程式檢查，不使用 throwaway Web CSS 或瀏覽器 overlay。

## 整體印象與值得保留的地方

目前比較能回答「為什麼可能涼」，還不夠快回答「我現在能不能去」。最大的機會是把可信證據與前往條件放在一起，互助功能仍保留，但不能搶走前往決策的空間。

- **Directions 固定置底、Save 次要**：不用滑回頂端就能開始前往。
- **在場、體感、場所資訊、收藏已分開**：兩份原生檢查都確認獨立回報不必先分享在場、不會增加人數，且需明確 Publish。
- **不用假溫度表達涼爽**：三段式體感、樣本數、具體設施與未知狀態，符合目前資料能力。

## 五項優先問題

### 1. [P1] 最醒目的證據，可能說得比資料支持的更多

已確認。公園有 14 次回報：6 次 A little cooler、5 次 Not cooler、3 次 Much cooler，卻顯示「Most visitors said」。6/14 只是最多的一類，不是多數。零回報與平手也會被硬選出一個結論。另外，新回報後總數 8→9，Latest 仍是 2 hours ago。

這會讓急著找涼爽場所的人誤判共識與新鮮度。建議用確切分子／分母，例如「6 of 14 visitors said」，平手清楚表示意見不一，零回報不下體感結論；Latest 應與統計採用同一組回報。這是正確性問題，不是文案偏好。

依據：[摘要文字](/Users/chihyinwang/Desktop/cool-spot/cool-spot/PlaceDetailView.swift:140)、[最大類別計算與實際資料](/Users/chihyinwang/Desktop/cool-spot/cool-spot/PrototypeModels.swift:405)。A/B 都獨立確認目前 6/14 與新鮮度問題；零與平手另以非修改式 Swift 診斷驗證，未注入 UI。

對應：`$impeccable clarify`，搭配摘要邏輯修正。

### 2. [P1] 最大字級下，前往按鈕與設施內容真的會破版

B 原生重現、主代理核對截圖。Directions 被拆成多行碎字，置底列占掉約三分之一畫面；部分設施標籤超出右側被裁切。這不是單純「字大所以需要多滑」，而是文字不完整。

建議大字級使用不同操作列排列、保留清楚的完整名稱；標籤依可用寬度換行，不縮小使用者要求的字級，也不刪除設施。

依據：[固定雙欄操作列](/Users/chihyinwang/Desktop/cool-spot/cool-spot/PlaceDetailView.swift:107)、[未限制單項寬度的 FlowLayout](/Users/chihyinwang/Desktop/cool-spot/cool-spot/PrototypeSharedViews.swift:152)、[原生截圖](/tmp/cool-spot-b-accessibility-features.png)。

對應：`$impeccable adapt`。

### 3. [P1] 前往的必要條件，比邀請貢獻更晚出現

排序已確認，對決策速度的影響仍需測試。現在先看見照片、降溫摘要、設施和分享在場，之後才看見免費與否、座位、營業時間未核實、無障礙資訊未確認。

這裡應修正前面的安排：核心任務是先判斷值得不值得出發。即使有人在降溫，也不能代替「我能不能進去」。建議在名稱／證據附近提早呈現精簡的前往條件與關鍵未知；完整 Plan your visit 保留在下方。不是把所有資訊搬上去，也不必讓 presence 區塊隨位置跳來跳去。

依據：[目前區塊順序](/Users/chihyinwang/Desktop/cool-spot/cool-spot/PlaceDetailView.swift:45)、[前往条件](/Users/chihyinwang/Desktop/cool-spot/cool-spot/PlaceDetailView.swift:227)。

對應：`$impeccable layout`，之後做 30 秒目的地判斷測試。

### 4. [P2] 不能按的按鈕，仍然看起來可以按

已確認。沒有選體感時，Publish visit report 是停用的，卻仍呈现完整深青色主按鈕；人在遠處時，I’m cooling off here 也有相同問題。無障礙狀態有正確標示 disabled，但視覺沒有同步。

建議統一停用樣式，並把原因放在按鈕旁：例如先選體感才能發布。保留遠處按鈕是否有助於發現功能，可以繼續測試；但「保留入口」不等於「看起來可按」。

依據：[按鈕樣式只處理按下狀態](/Users/chihyinwang/Desktop/cool-spot/cool-spot/PrototypeSharedViews.swift:39)、[未選體感的實際畫面](/tmp/cool-spot-b-independent-empty.png)。

對應：`$impeccable harden`。

### 5. [P2] 輕量回報看起來仍像一份較長問卷

表單結構已確認；是否降低完成率尚未測試。三個體感選項後立刻展開七個設施選項，後面還有停留時間與留言；畫面也沒有場所名稱。選 Not cooler 後仍問 What helped，語意不完全貼合。

建議顯示場所名稱，讓「選一個體感＋Publish」清楚構成完整的最小回報，其他內容透過 Add details 展開。**全部選項仍可看見，不是只保留三種設施。**代價是細節可能較少人填，因此值得比較簡化前後的完成率與資料量，而非直接認定越短越好。

依據：[完整表單結構](/Users/chihyinwang/Desktop/cool-spot/cool-spot/PlaceDetailView.swift:638)。

對應：`$impeccable distill`。

## 認知負荷與情緒歷程

負荷主要集中在「先看哪個資訊」與「回報究竟需要做多少」。分組、獨立 sheet、設施展開、明確發布都有效；弱點是前往條件偏晚、表單缺少場所提示、選填內容一次展開。七個可見選項不自動等於記憶超載，這裡評估的是任務看起來有多費力，尚無使用者測試結果。

情緒歷程：照片帶來辨識與安心 → 降溫摘要增加信心 → 較晚看到營業／可及性未知，可能推翻剛形成的信心 → 分享在場有互助回饋 → 長表單增加表面工作量。完成頁宜以貢獻帶來的幫助收尾，不必把「其他人可檢舉你的留言」作為主要結語。

## 三種使用者的警訊

- **炎熱中單手操作的 Casey**：Directions 容易找到，但能否進入仍需往下找；停用按鈕容易被誤認為沒有反應。
- **第一次使用的 Jordan**：可能把 Most 讀成大家普遍同意；把七項選填誤認為預期要完成的工作。
- **需要大字級的 Sam**：設施內容被裁切、操作列文字破碎，是已觀察到的阻礙；本輪沒有完成實際 VoiceOver 朗讀流程。

## 較小但值得記錄的問題

- 完成頁說留言可被檢舉，但「Visitor report · Report」目前是純文字。正式做檢舉測試前須補上可操作的代表流程，不是要求本輪建置審核後端。
- Official Cool Space 與實際背書範圍的解釋相距較遠，應避免讓人以為官方保證當下體感。
- Close 的原生無障礙名稱正確。原始圖示框是 36 pt，但實際點擊區未量測，不能直接判定違規。
- 10 分鐘 expiry、真實 GPS、跨啟動保存與審核目前是原型限制；不能把這輪理解測試當成它們已可正式運作的驗證。

## 待確認的設計選擇

1. 下一輪優先驗證「更快決定是否前往」，還是「更容易理解與完成回報」？
2. 範圍先採用三項確定缺陷加一項設計驗證，還是五項一起處理？

前往條件排序與回報簡化是可測試的設計假設；摘要正確性、可讀性與可用狀態則不應依個人喜好取捨。
