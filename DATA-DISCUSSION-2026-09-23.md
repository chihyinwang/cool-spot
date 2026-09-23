# Cool Spot 資料結構討論紀錄

整理日期：2026-09-23。這份文件是 owner 明確要求的新 chat 背景資料，記錄目前程式、已討論的設計及未定案事項；不是新的開發計畫、資料庫 migration 或實作授權。沒有「接下來要做什麼」的結論。既有 PRODUCT、AGENTS、OWNER-JOURNEY-WALKTHROUGH 仍是原有產品與工作紀錄；本文件是此次討論的定時快照。

## 1. 使用者問題、工作範圍與現況

### 這次討論在回答什麼

Owner 想釐清一個 Cool Spot 中的使用者登記資料、GLA 資料、Apple Maps 配對資料怎麼組成；現在 mapping 檔是不是 App 讀取的檔；之後 API、資料庫與 App 是否需要相同結構；多來源名稱是否重複，以及設計有哪些 trade-offs。

最新要求是整理這些討論，包含檔名、絕對路徑、用途，讓新的 chat 能接續理解。Owner 明確要求不要代下後續工作的結論。此要求沒有指定後端供應商、核准資料庫表設計、核准名稱採用規則，也沒有要求本輪修改 App、commit、push、部署或直接建立新 chat。

### 工作位置

| 項目 | 已核對狀態 |
|---|---|
| 本次 prototype worktree | `/Users/chihyinwang/Desktop/cool-spot-prototype` |
| 分支 | `Prototyping`，保留大小寫 |
| HEAD | `ec9fbf9f23032c231a53ec9281203368be16ebb1`，訊息為 `Align Cool Spot data contracts and persist local contribution publishing` |
| HEAD 之後 | 十筆搜尋／配對抽查的程式、資料、文件仍有未提交變更；不能只讀 HEAD 推斷現況 |
| 另一份 checkout | `/Users/chihyinwang/Desktop/cool-spot`，分支 `ViewCoolSpots`，是 EssentialFeed 式 TDD 重建；與本次 prototype 分開，本次未修改 |

溝通偏好：繁體中文、先給主要答案、少切換主題；程式與識別字使用英文。Owner 已啟用 [i-have-adhd skill](/Users/chihyinwang/.codex/skills/i-have-adhd/SKILL.md)，直到明確關閉為止。Prototype 驗證只用 iPhone 17 Pro Max，必要編譯及聚焦測試，不跑 iPad／多尺寸／Dynamic Type／外觀矩陣。不得刪除裝置上的既有收藏、回報、照片或筆記。

### 現有資料與配對進度

目前 bundled GLA 清單有 **250 筆真實 GLA 2025 資料快照**；另有 **3 筆明確標示的社群示例**：Tate Modern、Example Community Room、Example Shaded Garden。Tate Modern 是真實場所，但這組 cooling info／visitor reports 是示例；另兩處是虛構示例。普通場所 British Museum 是對照用的搜尋 seed，不是第 254 筆已登記 Cool Spot。實際装置亦可能有本機已發布的使用者提案。

| GLA 配對狀態 | 數量 |
|---|---:|
| 自動接受、同一場所 | 136 |
| 查閱來源後接受、同一場所 | 7 |
| 查閱來源後接受、所屬場館 | 1 |
| 有候選、仍需核對 | 87 |
| 既有查詢未找到候選 | 19 |

因此為 **143 個同場所連結 + 1 個所屬場館連結 + 106 個未接受配對**。`reviewed` 是既有 prototype 的來源核對／模擬審核狀態，不代表 owner 已逐筆驗收，也不是已存在遠端審核團隊。250 筆都已轉成 Cool Spot，未配對的仍有降溫資料與原始座標。

2026-09-19 曾在 iPhone 17 Pro Max 實際走完十筆搜尋 → 點選 → 地圖定位 → 降溫卡；其中八筆有接受的連結，亦開過系統 Place details。Horniman Museum 仍有兩個 Apple 候選，原生搜尋仍可能顯示兩筆；藥學博物館未找到可確認的 Apple 場所 ID，僅有地址結果，未強行配對。這是十筆抽查，不是 250 筆全量實機驗收，也不證明 2026 的現場降溫條件。

最新相關驗證紀錄為 **7 項 Swift 測試、11 項 Python 配對測試、schema／來源／穩定 ID 檢查通過**；不是新跑完整 suite。更早的 83 項全套結果屬於上一輪契約與發布改動。完整證據在 walkthrough；本次整理文件未重跑 App 測試。

## 2. 資料長怎樣：目前已實作

### 三種角色，不是三份獨立的公開場所

**Cool Spot 是我們管理的場所實體；GLA 和使用者登記是它的內容來源；Apple mapping 是外部場所的對應關係。**

GLA 與使用者都可能提供名稱、設施等重疊欄位。公開讀取資料保留目前採用的值，再記錄來源；不是要求 UI 並排顯示兩套完整欄位。並非每筆都要同時有 GLA、使用者登記與 Apple 配對。缺少 Apple 對應不會讓 Cool Spot 消失。

### App response 與 mapping 工作檔

```text
App response
  schemaVersion, catalogID, generatedAt, sources
  items[]
    id, name, location, address, placeType, setting
    coolingFeatures, coolingDetails, additionalInformation
    access, hours, photos
    sourceReferences, provenance, mapReferences

Mapping audit export
  上面同一份 response 與 items[]
  mapping
    algorithm, summary, automaticRule
    results[]
      coolSpotID, sourceRecordID, status, reason
      selectedPlaceID, relationship, query, attempts
      candidates, review, dataWarnings, error
```

已在 2026-09-23 直接比對：`CoolSpotCatalog.prototype.json` 與 `coolspot-catalogue-mapping.json` 的 **`items` 完全相同**。前者是 App 讀取用；後者多帶開發／配對稽核資訊，App 不載入 `mapping`。`mapping.results[].coolSpotID` 指回 `items[].id`。

兩份 GLA／社群 bundled response 都是 **schemaVersion 3**，使用同一個 decoder 與 `PrototypeCatalog.Item`。reader 保留 v1/v2 相容；不能因為 Swift 尚有 legacy `sourceRecord`、`appleMatch` 等欄位，就把它們當作 v3 建議輸出。

### 一筆現有 Cool Spot 的完整內容

以下直接取自 bundled JSON 的 Canning Town Library，未手寫補值。GLA facts 是來源快照，`recordedAt` 是轉換記錄時間，不是現場查證時間。`hours` 仍存於資料，但 App 自訂地點卡已依 owner 要求不顯示 Cooling space hours。

```json
{
  "id": "5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab",
  "name": "Canning Town Library",
  "location": {
    "latitude": 51.516829995,
    "longitude": 0.010439996,
    "scope": "unknown"
  },
  "address": {
    "formatted": null,
    "line1": "18 Rathbone Market",
    "line2": null,
    "locality": "London",
    "borough": "Newham",
    "postalCode": null,
    "countryCode": "GB"
  },
  "placeType": "library",
  "setting": "indoors",
  "coolingFeatures": [
    "air_conditioning"
  ],
  "coolingDetails": null,
  "additionalInformation": null,
  "access": {
    "cost": "free",
    "eligibility": "unknown",
    "eligibilityDetails": null,
    "seating": "yes",
    "drinkingWater": "yes",
    "toilets": "on_site",
    "wheelchairAccess": "yes",
    "staffedWhenOpen": "yes",
    "tables": "unknown",
    "areaDescription": null,
    "postedStayLimit": {
      "status": "unknown",
      "minutes": null
    }
  },
  "hours": {
    "text": "Monday - Saturday -9am-8pm, Sunday closed, Public Holidays - Closed",
    "timeZone": "Europe/London"
  },
  "photos": [],
  "sourceReferences": [
    {
      "sourceID": "gla-cool-spaces-2025",
      "recordID": "18"
    }
  ],
  "provenance": [
    {
      "sourceID": "gla-cool-spaces-2025",
      "method": "imported",
      "fields": [
        "/name",
        "/location/latitude",
        "/location/longitude",
        "/address/line1",
        "/address/line2",
        "/address/borough",
        "/address/postalCode",
        "/coolingFeatures",
        "/coolingDetails",
        "/access/cost",
        "/access/seating",
        "/access/drinkingWater",
        "/access/toilets",
        "/access/wheelchairAccess",
        "/access/staffedWhenOpen",
        "/hours/text"
      ],
      "recordID": "18",
      "recordedAt": "2026-09-19T00:16:05Z"
    },
    {
      "sourceID": "gla-cool-spaces-2025",
      "method": "dataset_context",
      "fields": [
        "/setting",
        "/address/locality",
        "/address/countryCode",
        "/hours/timeZone"
      ],
      "recordID": "18",
      "recordedAt": "2026-09-19T00:16:05Z"
    },
    {
      "sourceID": "gla-cool-spaces-2025",
      "method": "name_rule",
      "fields": [
        "/placeType"
      ],
      "recordID": "18",
      "recordedAt": "2026-09-19T00:16:05Z"
    }
  ],
  "mapReferences": [
    {
      "provider": "apple_maps",
      "placeID": "I7E8561E6022ED614",
      "relationship": "same_place",
      "verification": "reviewed",
      "checkedAt": "2026-09-18T14:33:54Z"
    }
  ]
}
```

### 欄位的語意

| 欄位群 | 語意 |
|---|---|
| `id`、`name` | 我們的穩定場所 ID 與目前採用的公開名稱。名稱可改、可重複；不作為主鍵 |
| `location`、`address`、`placeType`、`setting` | 數字座標、空間範圍、結構化地址、我們的分類與室內／室外等狀態；可保留 unknown |
| `coolingFeatures`、`coolingDetails`、`additionalInformation`、`access`、`hours` | 場所降溫／使用資訊；已知沒有與未知不同；來源有值不表示 UI 全部預設展開 |
| `photos` | 已發布照片資源陣列；GLA 來源未提供照片時為 `[]`；不是圖片 bytes，也不是 Apple 相片集合 |
| `sourceReferences`、`provenance`、`mapReferences` | 分別為來源紀錄連結、目前採用欄位的來源依據、已接受的外部地圖對應 |

`sourceReferences` 的 `sourceID` 連到 response 的 `sources[].id`，`recordID` 是該來源的紀錄 ID。`provenance.fields` 使用 `/access/seating` 等欄位路徑，記錄來源、採用方式和時間；它描述現行值，**不等於一份內含所有歷史值、相互衝突說法與完整審核過程的 audit log**。舊值／理由另在來源快照與本機提案紀錄中。

`mapReferences` 目前有 provider、placeID、relationship、verification、checkedAt。沒有在這裡再複製 Apple 的完整名称、地址與照片。未接受配對時是 `[]`；不會把候選 ID 當作正式連結。

| relationship | 已實作含義 |
|---|---|
| `same_place` | 對應同一場所，可用於搜尋結果辨認及收藏歸到同一 Cool Spot |
| `within_place` | Cool Spot 是所屬場館中的區域；可借場館開 Place details、由場館搜尋發現該區域，但不得合併場所身份或將區域的降溫 facts 延伸到整棟建築 |

自動接受或來源核對，只改變驗證資訊，不改變 Cool Spot 的基本資料結構。`no_candidate` 表示現有查詢沒找到可用候選，不等於 Apple 一定沒有這處場所。

### 使用者資料不只有一種生命週期

| 類型 | 與 Cool Spot 的關係 |
|---|---|
| 場所登記／修改提案 | 提供名稱、降溫條件、設施、公開補充與照片；採用後修改場所的公開資訊 |
| Visitor report | 某次到訪的體感、幫助降溫的條件、停留時間、評論與到訪時間；透過 `spotID` 指向場所，不等於場所登記，也不自動覆寫場所 facts |
| Cooling here／presence | 有期限的人數／在場狀態，與場所基本資料不同生命週期 |
| 收藏／私人筆記 | 使用者私人資料，不因公開登記或修改而公開 |
| 照片 | 場所資訊提案可附照片；目前 visitor experience 的 `VisitReport` 沒有 photo 欄位；未發布照片不進公開 photo 清單 |

這個區分很重要：說「使用者 report 的資料」時，應先辨識是在說場所資訊提案，還是一次到訪的體感回報。Swift 的 form model 也保留某些 legacy 欄位，不能僅因 struct 有欄位就假定目前 UI 有詢問它。

## 3. 後端要怎麼存：討論方向與實際狀態

### 現在沒有遠端後端

目前沒有已運作的 catalogue API、資料庫服務、伺服器審核、遠端照片上傳或跨裝置同步。也沒有選定後端供應商、SQL／NoSQL、最終 table schema 或正式 endpoint contract。

| 目前真正儲存的位置 | 內容 |
|---|---|
| Repository 的 `data/catalogue/` | GLA 原始 snapshot、來源 manifest、ID registry、MapKit 查詢結果、接受決定及配對稽核 |
| App bundle 的 `Resources/*.json` | 打包進 App 的 GLA 250 筆與社群 3 筆示例 response |
| 裝置內 `UserDefaults` encoded snapshots | 提案、審核模擬狀態、本機發布的 catalogue items、visitor reports、收藏／筆記、presence 等 |
| 裝置內 Application Support／`PrototypePlacePhotos` | 每張圖片的 original、公開用 image.jpg 及 thumb.jpg；JSON 只存參照 |

`You → Settings → Prototype controls → Publish locally` 是**本機審核模擬**。送出提案與照片先保留待審，明確 Publish locally 後才套用公開欄位／照片。重開 App 會還原本機資料。沒有送到任何遠端服務。

### 已討論的後端設計方向，不是已定案的資料庫表

已提出：讓 API 回傳整理好的 Cool Spot；後端分開保存來源、使用者提案、接受的場所內容與 Apple 對應。以下只是討論中需要分辨的邏輯資料，不代表一定各建一張表、也沒有核准 table 名稱。

| 邏輯資料 | 討論中的用途 |
|---|---|
| Cool Spot 與目前採用欄位 | 我們自己的穩定身份與公開名稱、降溫／設施資訊，作為 App 讀取內容 |
| 來源原始紀錄／快照 | 保留 GLA 原始值、來源 ID、版本等，支援追溯與之後比較差異 |
| 使用者提交與審核紀錄 | 保留提出什麼、修改理由、狀態與採用結果；公開讀取與寫入提案不是同一個 contract |
| 外部場所對應及配對依據 | 同一場所／所屬場館的 Apple ID；候選、判斷理由等與公開 payload 分開管理 |
| 照片、visitor reports、presence、私人資料 | 各有獨立生命週期；照片 bytes 與 JSON 分開，私人／未發布內容不混入公開 response |

**API 可以包含 `mapReferences`，資料庫仍可把外部對應分開儲存。** JSON 物件內嵌與資料庫分表並不矛盾；API 可由後端組合公開讀取資料，不要求 iOS 自行 join 多份來源。

先前提出未來由伺服器管理公開身份、審核結果、provenance 與接受的 map links；照片透過獨立上傳／媒體傳遞；使用者提交 contribution／report，而不是把整份 GET response 原樣寫回。這些是方向，**沒有遠端實作**。列表分頁、圖片載入量與 API 版本仍需按實際服務設計，不能承諾目前整包 JSON 永遠逐字不變。

### 名稱與重複場所的討論

目前真實例子：GLA 為 `Beckton Library`，Apple 為 `Beckton Globe Library`，App 的 `coolspot.name` 為 `Beckton Library`。原始來源可以各自有名稱，公開 Cool Spot 使用目前採用的名稱；系統 Place details 由 Apple 顯示自身名稱，可能不同。

名稱不是唯一鍵。不同分店可同名，同一場所也可有不同名稱。UUID 唯一只表示資料 ID 不撞號，不保證現實中同一場所沒有被建立兩次。GLA source ID、Apple Place ID 與我們的 Cool Spot ID 也不是同一個東西。

先前建議新增登記先找既有場所，確認同一處則作補充／修改；名稱、地址、距離可用來找候選，不能僅憑同名就合併。目前有既有 Cool Spot／Apple ID 及有限座標與名稱查重，但不是完整的跨来源去重服務。

上一則助理提出「`coolspot.name` 是採用的公開名稱，其他來源名稱保留供核對與搜尋，來源更新不直接覆蓋」作為規則建議。**Owner 尚未確認這套名稱政策；完整別名索引／自動處理改名尚未實作。** 不可把該建議升格成已批准規格。

## 4. App 端現在做什麼；未來 API 邊界討論

### 現在的正常啟動與搜尋

```text
Bundle: CoolSpotCatalog.prototype.json + CommunityCatalog.prototype.json
  → PrototypeCatalog.bundled / decode
  → PrototypeCatalog.Item.makeSpot
  → PrototypeStore / Swift CoolSpot
  → 套用裝置內已發布資料、還原個人旅程
  → Explore 與 Place detail

使用者搜尋
  → 本機 catalogue 搜尋 + 線上 MKLocalSearch
  → 用已接受的 same_place ID 辨認相同場所
  → 顯示 Cool Spot 或尚無降溫資訊的一般場所
```

Swift 的 `CoolSpot` 不逐欄等同 JSON；`PrototypeCatalog.Item` 是讀取契約，`makeSpot` 把來源資訊、設施等轉給現有 UI model，`CoolSpot` 另有體感摘要、人數等畫面所需狀態。

`PlaceSearch.swift` 使用 `MKLocalSearch`；不是每次搜尋都把全部 GLA 重新模糊配對。當查詢到的 Apple primary／alternate ID 命中接受的同場所連結，搜尋可辨認為現有 Cool Spot。只有已知身份才合併；無配對的 GLA 仍可搜尋、顯示原始座標，可能與普通 Apple 結果並列。

`within_place` 可讓「搜尋大場館」找到其中 cooling area，但兩者仍是不同實體。原生 system Place details 使用接受的 Apple ID 解析 map item；Look Around 只代表附近街景，不保證入口或室內環境，也不是 GLA／社群照片來源。

App 自訂卡根據已知內容顯示摘要與 Facilities & accessibility，unknown 不捏造；Cooling space hours 已隱藏，Call／Website 不另放自訂卡。普通場所與 Cool Spot 都維持 Place details 的一致用詞，實際可用性依有效場所身份而定。供應商能力不等於全部應預設顯示在 UI。

### 本機提案發布的現行行為

`PlaceContributionDraft` 保存提案及更新前的值。送出與 Publish locally 都做現有去重檢查。更新只套用有改變的欄位；若同欄位自提交基準後已有另一個不同變更，會變成 Action needed，而不是直接覆寫。相同提案重複發布不再新增一筆。

公開欄位被修改後，`provenance` 會調整該欄位的當前來源；其他 GLA facts、身份、visitor reports、presence 與私人資料保留。這是有限的本機更新衝突處理，不能視為已解決所有 GLA 年度匯入、多人提交或跨裝置併發問題。

### 未來網路版本在討論中的分工

討論方向是以網路 reader 取代 bundled reader，盡量沿用 item 的公開契約及 UI adapter；並不是 UI 端從 GLA、Apple、使用者三套原始資料自行決定採信哪一份。

App 仍負責搜尋與顯示、提交使用者輸入、讀取公開結果、開啟地圖詳情，以及載入／錯誤處理。GLA 匯入、場所對應判定與公開資訊採用應在服務邊界後面管理。改接 API 並非只換檔案路徑：還有請求、錯誤、載入及資料更新等行為；目前未實作這些遠端 catalogue 行為。

## 5. 已討論的取捨、未定案事項與檔案索引

### 討論中的評價與限制

先前助理評價為：「目前作為 App 讀取格式合理，方向符合穩定身份／来源追蹤／外部連結分離的原則，但不能稱為完整 production 設計。」這不是 owner 已採納所有後端方案的聲明。

| 已指出的 trade-off | 已討論內容與現況 |
|---|---|
| 一個公開值 vs 多來源分歧 | 公開畫面簡單，但分歧會被隱藏；來源與提案紀錄要能追溯。GLA／使用者誰優先、如何判定新資訊較可靠，尚未完整定案 |
| 保守配對 vs 錯誤合併 | 保守會留下重複結果；積極合併可能把錯場所的 cooling facts／回報合在一起。目前採保守規則，仍有 106 筆未接受連結 |
| 追蹤歷史 vs 維護成本 | 保存來源、提案、審核理由增加儲存與邏輯；公開 provenance 不能代替完整歷史；正式後端 history schema 未定 |
| 來源更新 vs 已採用修改 | 新 GLA 匯入可能衝掉社群修正；年度資料 ID 也不應假設永遠穩定。目前未有完整定期更新與 reconciliation 流程 |
| 一次回傳整合資料 vs payload 大小 | App 容易使用，但不宜在每個 map result 帶入無限照片／回報／配對候選。列表／detail／歷史的網路切分尚未實作 |

尚未定案：後端供應商／實體資料表、跨來源場所去重與重複紀錄合併規則、正式名稱／別名採用政策、衝突採信與來源更新策略、遠端 moderation／media／API contract。這裡只記錄狀態，不排序、不形成後續任務。

先前查閱的官方指引：Google 將顯示名稱與識別資訊區分，顯示名稱不要求唯一；Microsoft 強調 API 不應直接暴露資料庫表結構，並提醒聚合 response 與過度取資料的取捨。這些支援原則，不代表對此專案每個欄位或 table 的背書。

| 參考 | 用途 |
|---|---|
| [Google AIP-148](https://google.aip.dev/148) | 顯示名稱與 ID 的區別 |
| [Google AIP-122](https://google.aip.dev/122) | 資源身份原則，不是要求照搬 Google 欄位命名 |
| [Microsoft Web API design](https://learn.microsoft.com/en-us/azure/architecture/best-practices/api-design) | API representation 與內部儲存解耦、回應聚合的取捨 |

### 文件與供 App 讀取的資料

| 檔案（絕對路徑） | 用途 |
|---|---|
| [AGENTS.md](/Users/chihyinwang/Desktop/cool-spot-prototype/AGENTS.md) | Prototype 操作規則、工作狀態、保護裝置資料；須讀 worktree 內現有版本 |
| [PRODUCT.md](/Users/chihyinwang/Desktop/cool-spot-prototype/PRODUCT.md) | 現行產品契約、schema／來源／照片、已實作與未實作邊界 |
| [OWNER-JOURNEY-WALKTHROUGH.md](/Users/chihyinwang/Desktop/cool-spot-prototype/OWNER-JOURNEY-WALKTHROUGH.md) | A–E 點擊案例、日期化驗證、未解限制；不能把歷史測試當新結果 |
| [CoolSpotCatalog.prototype.json](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/Resources/CoolSpotCatalog.prototype.json) | App bundled 的 250 筆 GLA Cool Spot v3 response，含已接受 mapReferences |
| [CommunityCatalog.prototype.json](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/Resources/CommunityCatalog.prototype.json) | 3 筆社群示例，同一 v3 契約；不是三筆真實使用者提交 |

### 來源、身份與契約

| 檔案（絕對路徑） | 用途 |
|---|---|
| [gla-cool-spaces-2025.geojson](/Users/chihyinwang/Desktop/cool-spot-prototype/data/catalogue/gla-cool-spaces-2025.geojson) | GLA 原始 snapshot，250 筆；不是 App 直接讀取契約 |
| [source-manifest.json](/Users/chihyinwang/Desktop/cool-spot-prototype/data/catalogue/source-manifest.json) | 來源 URL、SHA-256、歷史下載時間未知；不把檔案 mtime 當來源查證時間 |
| [identity-registry.json](/Users/chihyinwang/Desktop/cool-spot-prototype/data/catalogue/identity-registry.json) | 本批 GLA record ID → 自己的固定 Cool Spot UUID |
| [coolspot-catalogue.schema.json](/Users/chihyinwang/Desktop/cool-spot-prototype/data/catalogue/coolspot-catalogue.schema.json) | v3 producer JSON Schema；精確必填、型別、enum、photo 定義 |
| [review-decisions.json](/Users/chihyinwang/Desktop/cool-spot-prototype/data/catalogue/review-decisions.json) | 接受配對的來源核對理由、證據 URL、來源 fingerprint／candidate snapshot |

### 配對輸出與查詢證據

| 檔案（絕對路徑） | 用途 |
|---|---|
| [coolspot-catalogue-mapping.json](/Users/chihyinwang/Desktop/cool-spot-prototype/data/catalogue/coolspot-catalogue-mapping.json) | 完整 250 筆 items + mapping 結果／候選／原因；與 app items 一致，App 不讀其 mapping |
| [apple-candidates.json](/Users/chihyinwang/Desktop/cool-spot-prototype/data/catalogue/apple-candidates.json)、[apple-address-candidates.json](/Users/chihyinwang/Desktop/cool-spot-prototype/data/catalogue/apple-address-candidates.json) | 名稱與地址查詢的候選 checkpoint |
| [apple-identifier-candidates.json](/Users/chihyinwang/Desktop/cool-spot-prototype/data/catalogue/apple-identifier-candidates.json)、[previous-apple-identities.json](/Users/chihyinwang/Desktop/cool-spot-prototype/data/catalogue/previous-apple-identities.json) | 已知 Apple ID 的解析結果與先前對應參考 |
| [apple-discovery-sample.json](/Users/chihyinwang/Desktop/cool-spot-prototype/data/catalogue/apple-discovery-sample.json) | 最近十筆抽查及必要補查的真實 MapKit 回應，不等於已接受映射 |
| [discovery-cases.json](/Users/chihyinwang/Desktop/cool-spot-prototype/data/catalogue/discovery-cases.json)、[discovery-audit.json](/Users/chihyinwang/Desktop/cool-spot-prototype/data/catalogue/discovery-audit.json) | 十筆抽查輸入／逐筆發現、原生 evidence 與仍未解項目 |

### App 模型與資料生命週期

| 檔案（絕對路徑） | 用途 |
|---|---|
| [PrototypeCatalog.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/PrototypeCatalog.swift) | `PrototypeCatalog.Item`、JSON decode／bundled、`makeSpot`、store 組裝、社群／ordinary 示例 |
| [CatalogFacts.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/CatalogFacts.swift)、[CatalogEncoding.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/CatalogEncoding.swift) | Facts／停留上限的型別與相容處理、v3 編碼輸出 |
| [PrototypeModels.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/PrototypeModels.swift) | Swift `CoolSpot`、store、identity 辨認、搜尋、visitor reports、個人持久化、本機 publication 入口 |
| [ContributionView.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/ContributionView.swift) | 場所登記／修改 UI、`PlaceContributionValues`／draft、表單驗證與選圖 |
| [PrototypePublication.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/PrototypePublication.swift) | 提案 → 公開 Item、changed-fields 更新、基準衝突及 provenance 處理 |

### App 搜尋、畫面與照片

| 檔案（絕對路徑） | 用途 |
|---|---|
| [PlaceSearch.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/PlaceSearch.swift)、[ExploreView.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/ExploreView.swift) | MapKit 搜尋、debounce／取消、結果與既有場所結合、地圖 |
| [PlaceDetailView.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/PlaceDetailView.swift)、[VisitorReportsView.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/VisitorReportsView.swift) | 降溫卡／普通卡、Place details、Look Around、體感回報與評論 |
| [PrototypePhotoStorage.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/PrototypePhotoStorage.swift)、[PlacePhotos.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/PlacePhotos.swift) | 裝置內照片原檔／縮圖與參照、photo model、縮圖列／gallery／viewer |
| [SavedYouViews.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/SavedYouViews.swift)、[ContentView.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/ContentView.swift) | 收藏／私人筆記／提案狀態／Prototype controls，以及 store／頁面進入點 |
| [ExamplePlacePhotos.json](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spot/Resources/ExamplePlacePhotos.json) | 示例 photo metadata；不代表 GLA／Apple 提供了場所照片 |

### 轉換、驗證與視覺化工具

| 檔案（絕對路徑） | 用途 |
|---|---|
| [build_catalogue.py](/Users/chihyinwang/Desktop/cool-spot-prototype/scripts/catalogue/build_catalogue.py) | 原始 GLA → Cool Spot、穩定 ID、來源轉換、保守配對、產生 app／audit JSON |
| [MatchApplePlaces.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/scripts/catalogue/MatchApplePlaces.swift)、[ResolveKnownApplePlaces.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/scripts/catalogue/ResolveKnownApplePlaces.swift)、[AuditDiscovery.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/scripts/catalogue/AuditDiscovery.swift) | 開發用 serial MapKit 候選收集、已知 ID 解析、抽查工具；不在 App 執行全量 mapping |
| [validate_catalogue.py](/Users/chihyinwang/Desktop/cool-spot-prototype/scripts/catalogue/validate_catalogue.py)、[test_mapping.py](/Users/chihyinwang/Desktop/cool-spot-prototype/scripts/catalogue/test_mapping.py)、[write_schema.py](/Users/chihyinwang/Desktop/cool-spot-prototype/scripts/catalogue/write_schema.py) | 結構／身份／來源驗證、配對規則測試、schema 產生器 |
| [cool_spotTests.swift](/Users/chihyinwang/Desktop/cool-spot-prototype/cool-spotTests/cool_spotTests.swift) | Swift model、decode、搜尋、發布與持久化測試；歷史通過數以 walkthrough 的日期／範圍為準 |
| [render_mapping_report.py](/Users/chihyinwang/Desktop/cool-spot-prototype/scripts/catalogue/render_mapping_report.py)、[mapping-report.fragment.html](/Users/chihyinwang/Desktop/cool-spot-prototype/scripts/catalogue/mapping-report.fragment.html) | 根據 mapping／抽查資料產生互動結果總覽 |

互動總覽實體檔案：`/Users/chihyinwang/.codex/visualizations/2026/09/14/01a0a1c5-a1cd-71f3-861d-37caecc4a52d/coolspot-catalogue-mapping.html`。可查看全部 250 筆、待處理與十筆抽查的候選／依據。原 chat 的 widget 選取狀態不保證自動帶到新 chat；重要數據均在上述 JSON，HTML 是呈現層。

本文件及其他絕對路徑指向同一台電腦的本機檔案；新的本機 chat 可以依路径讀取。新 chat 不會僅因為被建立就自動繼承原 chat 的完整對話或暫存附件；若改用另一台電腦或無本機存取的環境，仍需提供文件及相關檔案內容。
