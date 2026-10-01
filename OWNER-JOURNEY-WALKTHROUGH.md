# Cool Spot：完整點擊走查

本文件只負責測試步驟、預期結果與驗證狀態。現行功能定義見 [PRODUCT.md](PRODUCT.md)，程式版本與工作方式見 [AGENTS.md](AGENTS.md)。下面的「應看到」是待檢查的預期，不表示已通過。

## 本輪狀態與起點

**2026-10-01：正常 App 已接本機 v5 API；止於遠端 API 之前。** 起點 Prototyping／8f7ae05。Owner 委託完成剩餘接線、tests 與適當 commit，並同意正常 API 模式停用 Publish locally；私人提案保留，明確 QA／範例模式仍可本機發布。沒有新增 API 契約、登入、上傳、部署或資料庫變更。

| Case | 檢查重點 | 證據 |
|---|---|---|
| IOS-STORE-C01–C03 | API store 初始／合法空清單無 legacy fallback；目前值更新；歷史發布只保存不套用 | 初始 skeleton 行為 Red；完整欄位 archive 與現行名稱、重啟／原資料不改寫 assertions |
| IOS-STORE-C04 | API 清單移除／重載／重啟不丟收藏筆記、回報、草稿、確認、presence deadline 或 nearby 模擬 ID | 空清單期間另存私人 pin，再重開並載入新名稱；原身分／私人值／期限保留 |
| IOS-STORE-C05–C06 | 正常 API 模式拒絕本機發布，明確範例模式不被 API replacement 改寫 | 提案保持 In review；既有兩項 legacy publication regressions 一併通過 |
| IOS-STORE-C07 | API mode 不額外加入 fixture peer reports／presence | 單一 case verified Red；自己的回報與明確 fixture mode 不刪除 |
| IOS-LOAD-C11–C13 | 成功／空結果交給 store；失敗／取消不交付；view reappearance 不自動載入 | 補上 didLoad 與 loadIfNeeded；前十項 loading/cancellation cases 保留 |
| IOS-LOAD-C14 | 明確 retry 只重開 failed；連點不重新開放；重試後 reappearance 仍不自動 retry | 單一 case verified Red；requestRetry 改 idle，HTTP 由 view-owned task 執行 |
| IOS-API-C03 | 真正匿名 HTTP → decoder → mapper → ViewModel → Store → 收藏筆記 → 重開 → 真正 HTTP | 沿用已完成元件，首次通過，不製造 Red；253 筆、Canning 身分／來源 context 與私人資料保留 |

第一輪 Store/交付 skeleton 的 related Red：19 executed／12 passed／7 failed／0 skipped；五項 Store 與兩項交付/初始載入因目標未實作而失敗。初始提案 test 前置改成有效的 update，避免把缺少新場所必填照片當成目標 Red。Green：21 passed／0 failed／0 skipped（六項 Store、十三項 ViewModel、兩項舊發布回歸）。接上畫面後初次完整 scoped validation：40 passed／0 failed／0 skipped；十一項 program/tests/project/owner plan/scheme fingerprints 不變。

Code review 再補 retry 生命周期與 fixture peer-report 邊界；各單項 Red 的 xcresult 均為 1 executed／0 passed／1 failed／0 skipped。Final Cool Spot Contract QA／iPhone 17 Pro Max／iOS 26.4: 42 passed／0 failed／0 skipped（7 API-store, 14 ViewModel, 16 mapper, 3 actual HTTP integration, 2 legacy publication regressions）；eleven tested source/test/project/owner-plan/scheme fingerprints unchanged.。

正常 App 原生證據只在既有 Cool Spot Contract QA／iPhone 17 Pro Max／iOS 26.4：真實本機 API 的 253 places；搜尋 Canning Town Library、打開詳情與 GLA · 2025；Save，私人 editor 寫入 QA note 並保存；重啟斷線時 Saved／location／note 仍在，顯示 Cooling information is currently unavailable，無舊 cooling facts。API 恢復時 failure 仍在，手動 Try again 才回 253；You／Settings／Prototype controls 正常，沒有 Publish locally 按鈕且有說明。Loading 經 accessibility tree 觀察、合法空清單經 screenshot 觀察：使用暫時 loopback HTTP fixture（3 秒回應、200 v5 empty），未清空資料庫；fixture 停止後恢復真正 Deno reader。這些是 bounded 本機互動，不等於 A–E 全套、owner UX 接受、實體 iPhone、圖片配送、GPS、效能或雲端驗證。

QA app data 在安裝前備份至 Git 外；本輪只新增自己的 QA bookmark/note，原紀錄保留。只暫停／恢復專用 prototype API listener，未重啟容器、migration、匯入或 reset。測試、logs、results、credentials、QA backup 均不納入 commit；owner test-plan/scheme/project 格式與 staging 保留。候選 project 只含新增 Store test 的四行 membership；使用獨立 index 做精準提交，核對 secrets、文件 links 與全部 40 個 A–E IDs，不 push。

下一個界線是遠端 endpoint／設定與部署設計；本輪停在此之前。Report、Cooling here、popsicle、提案仍是既有本機 prototype 生命周期，沒有假稱寫入後端。原始 bundled JSON 未改。

### 上一批載入 ViewModel：歷史 Red／Green

**2026-10-01：API 清單載入狀態第一批已 Green，相關測試 26 passed／0 failed。** 起點 Prototyping／f7a038d。Owner 先同意 Loading／成功清單／合法空清單／失敗＋Try again、無自動重試與無 bundled fallback；公開清單由 API 提供，個人資料另行保留。收到 verified Red 與完整最小 Green 後，owner 明確委託改為 CoolSpotsCatalogueViewModel 命名並完成 Green。開始時保留 AGENTS 的 code-snapshot 回報偏好、owner project／已 staged test plan／untracked scheme。

新增 [CoolSpotsCatalogueViewModelTests.swift](cool-spotTests/CoolSpotsCatalogueViewModelTests.swift) 的十個 cases／可控制回應的 MainActor LoaderSpy；新增 [CoolSpotsCatalogueViewModel.swift](cool-spot/CoolSpotsCatalogueViewModel.swift) 的 ObservableObject、四種 State、idle 初始值、注入 loader 與空 load() 介面。Project 僅新增兩檔的八行 group／target membership；移除該八行後與 owner 原 project bytes 完全一致，test plan／scheme 內容及原 staging 保留。ViewModel、spy 與呼叫均在 MainActor；callback 傳入 load count，沒有捕捉 owning spy 的循環引用。

| Case | 預期 | 實際 Red 證據 |
|---|---|---|
| IOS-LOAD-C01 | 初始化 idle，不請求／不插 fixtures | 已通過；不製造 Red |
| IOS-LOAD-C02–C04 | 請求進行時 loading，成功用現有 mapper 保留目前事實／API context，合法空清單仍是 loaded | 三項失敗：未呼叫 loader、load-start expectation 到期，或沒有 loaded state |
| IOS-LOAD-C05–C07 | connectivity／invalidResponse 失敗不自動重試；明確重試清除 failure；in-flight 重複操作不多送請求 | 三項失敗：沒有 failed／loading state 或未送第一個請求；重複操作 assertion 會在 Green 後完整驗證 |
| IOS-LOAD-C08–C09 | loader cancellation 回 idle 且可重試；取消 Task 後晚到的 success／failure 不公開結果或錯誤 | 兩項失敗：請求數為零或 started expectation 到期；spy 故意在 cancellation 後仍完成，以驗證 model 不只相信依賴會取消 |
| IOS-LOAD-C10 | 已取消的 Task 不開始請求，也不切 loading | 已通過；不製造 Red |

只在既有 Cool Spot Contract QA／iPhone 17 Pro Max／iOS 26.4 執行十項 model 加十六項 mapper：編譯成功，xcodebuild exit 65，xcresult **26 執行／18 passed／8 failed／0 skipped**。所有 mapper regressions 通過；model 兩項已覆蓋、八項因空 load() 未實作而失敗。十個相關 source／tests／project／test-plan／scheme 檔案在測試前後 SHA-256 一致。合成資料和 controlled continuations，不做任意 sleep；pending continuations 在 teardown 取消／完成以避免掛住。1 秒 expectation 是有界等待載入開始或 duplicate return，未把它當成真實網路時間保證。Logs／xcresult／fingerprints 留在 Git 外；沒有新 HTTP、圖片下載、DB/backend 或正常 App 原生互動證據，沒有重跑歷史全套 tests。

Owner 追問 Model 的職責後，agent 判斷此物件管理公開目錄的可觀察畫面狀態與載入，因此 CoolSpotsCatalogueViewModel 比泛稱 Model 更清楚；Catalogue 對應 Explore 地圖共用整份目錄的用途。原 Red 時命名是 CoolSpotsCatalogueModel；本批同步改 source／tests 檔名、類別與 helper references、project／文件 links，case IDs／assertions 未變。這是職責命名，不是全 App 採用 MVVM 的決定。

委託 Green 後，ViewModel 保存注入的 async loader；load() 先拒絕已取消或已有 in-flight 的操作，再發布 loading，成功以既有 makeSpots() 發布 loaded。合法空清單仍是 loaded([])。取消／CancellationError 回 idle，其他錯誤只發布 failed；沒有重試循環、raw diagnostics、task 所有權或持久化。await 後再檢查 cancellation，因此不合作的依賴即使晚到成功也不能覆蓋畫面。

只在同一隔離 QA 執行相同十項 ViewModel 與十六項 mapper：xcodebuild exit 0，xcresult **26 passed／0 failed／0 skipped**；十個 program／tests／project／test-plan／scheme 檔案測試前後 SHA-256 一致。retry／duplicate／取消後晚到 success 與 failure assertions 均實際完成。注入函式已提供測試所需控制，state 只有一個真實來源，沒有為 SOLID 加無用途 protocol；目前無需再重構。沒有新 HTTP、圖片下載、DB/backend、正常 App 原生互動或效能證據。

本批提交範圍限 ViewModel／tests、project 的八行 target membership 與三份既有 active documents；使用獨立暫存 index，owner 的 test-plan reference／project 格式與其他 staging 不納入。候選 project 除 owner 的 test-plan reference 外，和實際測試 project 語意一致；原 owner 檔案內容與 staging 保留。提交前檢查測試 fingerprints、實際 patch、敏感值／本機憑證比對、local links 與 40 個 A–E IDs；logs／xcresult 留在 Git 外，不 push。

當批止點（歷史）：只完成載入 ViewModel，未修改 consumer／bundled JSON／endpoint／ATS／signing；Store 與 App 接線由 owner 本次另行委託並完成，現行證據見本節起點。

**2026-10-01：v5 → 畫面模型的第二批已 Green，相關測試 37 passed／0 failed。** 起點 Prototyping／5c895ce。Owner 先要求維持相同教學原則繼續；收到 verified Red 與完整最小 Green 後，明確委託「你幫我做吧」。開始時 project 的 owner test-plan reference／格式修改、已 staged 的 cool-spot.xctestplan 與 untracked shared scheme 均保留。Xcode 仍開啟 prototype／Cool Spot Contract QA；之前的執行已停止，loader 第 43 行的本機中斷點仍在，沒有操作 owner App 資料。

先說明影響與取捨，再於既有 [CoolSpotsAPIMapperTests.swift](cool-spotTests/CoolSpotsAPIMapperTests.swift) 寫八項 tests／合成 helpers，在 [CoolSpotsAPIMapper.swift](cool-spot/CoolSpotsAPIMapper.swift) 只加入 CoolSpotAPIRecord 的五個儲存欄位介面，並在 [PrototypeModels.swift](cool-spot/PrototypeModels.swift) 加上 optional apiRecord。Red 階段沒有實作來源關聯／map／photo Green；整批沒有改正常入口或重建 v4 DTO。完整公開 item/context 沿用 typed v5，避免鏡像全部欄位；這是 prototype 的明確型別耦合取捨，不把它宣稱為通用 domain 架構。

| Case | 預期 | 實際 Red 證據 |
|---|---|---|
| IOS-MAP-C09–C10 | accepted same_place 給身分／詳情；within_place 只讓 parent 詳情／既有 discovery 可用，不合併身分；same 優先 | 兩項失敗：Apple ID／details 為 nil；既有 store 身分與 discovery assertions 會在 Green 後完整驗證 |
| IOS-MAP-C11–C12 | 未採用／未知／空白 map 不使用但 metadata 保留；完整 public item／多來源有序去重／日期與時區保留 | 兩項失敗：apiRecord 為 nil。同 record ID 18 的不同來源仍獨立；未知方法碼不重寫；generatedAt 不替換來源或紀錄日期 |
| IOS-MAP-C13–C15 | HTTPS 照片順序與 metadata 保留，不造 reports；壞尺寸／不允許 transport 不進 display；bundle 僅例子插圖 | 三項失敗：spot.photos 為空；不下載圖片或讀 owner 檔案。原 public photo metadata 仍應完整保留在 apiRecord |
| IOS-MAP-C16 | 空來源／maps／photos 與未知日期合法，不插 fixtures／legacy record | 失敗：apiRecord 為 nil；不為 missing context 補來源或時間 |

只在既有 Cool Spot Contract QA／iPhone 17 Pro Max／iOS 26.4 執行十六項 mapper、十七項 decoder 與四項受影響 legacy map/photo regressions：編譯成功，xcodebuild exit 65，xcresult **37 執行／29 passed／8 failed／0 skipped**。八項新 cases 都因目標未實作而失敗；原有二十九項都通過。九個 program／project／test-plan／scheme 檔案測試前後 SHA-256 一致。Logs／xcresult／fingerprints 留在 Git 外；owner 的三個 project/test files 內容及正常索引 entries 均另行核對。沒有重跑 backend／SQL／完整歷史 suite，沒有 HTTP、圖片下載、正常 App 互動或性能證據。

委託 Green 後，agent 在 CoolSpotsAPIMapper.swift 完成記憶體中的 API record／有序來源去重／accepted map 選擇／photo display 投影；PrototypeModels.swift 的 detailsApplePlaceID 先讀 apiRecord，沒有 API record 時沿用原有流程。既有 source dates、provenance、hours timezone、全部公開 item 與照片 metadata 原樣保留，不讀 raw source/history，也不把 contributionID 當 reportID。same_place 優先於 within_place；parent 不成為身分 alias。照片不下載，只投影 structurally displayable HTTPS 或 primary-labelled example illustrations 的 bundle refs；prototype-photo 等不進 display assets。

第一輪 Green 在同一 QA 執行相同三十七項：35 passed／2 failed／0 skipped。兩個失敗來自測試的 test-parent／帶空白假 ID 被 MKMapItem.Identifier 拒絕，沒有走到 store 身分／discovery 比對；本機 Swift／MapKit parser probe 確認兩個假 ID 回 nil、兩個現有公開 ID 能解析。修正合成 fixtures 使用可解析的公開 ID，新增 parser 非 nil 的前置 assertion；原始不透明字串保持不變的 mapper assertion 另行保留，未放寬身分規則或改 production。重新執行同一組：xcodebuild exit 0，xcresult **37 passed／0 failed／0 skipped**；九個相關檔案測試前後 SHA-256 一致。所有 store assertions 完整執行，沒有新 HTTP、圖片下載、正常 App 原生互動或容量證據。

Green 後檢查：純轉換沒有 HTTP／儲存副作用，既有 photo structural check 可共用，來源用 dictionary/Set 查找與去重；不為 SOLID 加無用途 protocol，也無需再重構。本批提交範圍限兩個 production files、一個 test file 與三份既有 active documents；owner 的 project／test plan／scheme 不納入，檔案內容與 staging 保留。測試輸出與 fingerprints 留在 Git 外；提交前檢查實際 patch、敏感值／本機憑證比對、local links 與 40 個 A–E IDs，不 push。

其後 owner 已同意正常啟動 loading／empty／error／Try again 與 API-owned catalogue／個人資料分工；上方記錄第一批載入狀態 Red，store 邊界與 API-only 接線仍待後續整合。本批沒有改 bundled JSON、DB/backend、ATS、signing、endpoint 或正常 App 行為；未將當批代寫委託延伸到下一個 Green。Owner 新要求的回報格式已記入既有 AGENTS：列點解釋測試概念／edge cases、具體檔案與程式用途，再報實際驗證與提交狀態。

**2026-10-01：v5 → 畫面模型的第一批已 Green，相關測試 26 passed／0 failed。** 起點 Prototyping／2df5242，working tree 乾淨。先檢視 ContentView／CoolSpotsResponse 的 bundled 入口、CoolSpot／PrototypeStore 的資料與個人儲存、Explore 清單與搜尋、PrototypePublication 的舊契約耦合，再向 owner 說明檔案與影響。沒有直接替換正常 App 入口；先建立純資料轉換，再處理關聯與載入狀態，避免在接線時遺失事實、身分或誤用 containing venue。

新增 [CoolSpotsAPIMapperTests.swift](cool-spotTests/CoolSpotsAPIMapperTests.swift) 的八項合成 cases、[CoolSpotsAPIMapper.swift](cool-spot/CoolSpotsAPIMapper.swift) 的空 makeSpots() 編譯骨架，以及 CoolSpot.placeID 的 nil 預設介面。後者讓沒有 DB Place 的舊 fixtures 能繼續編譯；v5 decoder 的 placeID 仍是必填 UUID，未放寬 API。Project 只加入這兩個 source files 的 group／target membership。

| Case | 預期 | Red → Green 證據 |
|---|---|---|
| IOS-MAP-C01 | 合法空清單不插入 fixtures | 骨架已通過，不製造 Red；正式轉換後仍通過 |
| IOS-MAP-C02–C03 | 保留 item 順序、兩種獨立身分、目前名稱／分類／座標及 formatted 或組合地址 | 兩項 Red → Green；保留原有順序／文字／座標及獨立 UUID，完整或稀疏地址 assertions 都通過 |
| IOS-MAP-C04–C05 | 降溫與補充文字、known yes／no／unknown、費用／座位／資格、三種停留限制正確轉換 | 兩項 Red → Green；各種 yes／no／unknown、費用／座位／資格與三種停留狀態都實際走完 assertions |
| IOS-MAP-C06–C07 | 依第一筆有序 reference 的 sourceID 找主來源，不拿 registry 第一筆；保留 GLA 2025／例子標示；未知 provider 不變成 GLA | 兩項 Red → Green；registry 刻意與 references 不同順序，仍取得對應來源；未知與 community provider 不冒充 GLA |
| IOS-MAP-C08 | 未知值保持 unknown／nil，不造入場說明、來源、距離、回報或人數 | Red → Green；unknown／nil 與中性 visitor state 通過，不把 generatedAt 當來源或到訪時間，不重建 v4 publishedRecord |

僅在既有 Cool Spot Contract QA／iPhone 17 Pro Max／iOS 26.4 執行八項 mapper、十七項 decoder 與一項受影響 legacy source adapter regression：編譯成功，xcodebuild exit 65，xcresult **26 執行／19 passed／7 failed／0 skipped**。十七項 decoder 與既有 source adapter 都通過；mapper 七項為目標未實作的行為失敗。六個相關檔案測試前後 SHA-256 一致，沒有把 compile failure 當 Red。日志在 Git 外；沒有新 HTTP／native UI 證據，也沒有重跑 backend／SQL／歷史全套 tests。

Owner 在收到完整 Green 後明確委託「幫我做」，agent 寫入當批正式 mapper，再於同一隔離 simulator 執行同一組二十六項：xcodebuild exit 0，xcresult **26 passed／0 failed／0 skipped**。十個相關 program／project／test-plan／scheme 檔案在測試前後 SHA-256 一致。Mapper 只做記憶體中的 read-model 轉換，以 source-ID dictionary 查主來源，將 yes／no／unknown 轉成 true／false／nil；沒有 transport、儲存或 UI 副作用。共用一個 private knownBool helper 避免四處重複，沒有為 SOLID 添加無用途 protocol；目前無需再 refactor。

開始 Green 時發現 owner 新增已 staged 的 cool-spot.xctestplan、untracked shared scheme，以及 project 的 test-plan reference／格式調整；全部保留原始檔案與 staging。提交只包含當批七個檔案，project 僅本批八行 group／target membership。使用獨立暫存索引準備 patch，核對程式 fingerprints／新增個資與憑證／本機設定值／文件 links 後本機 commit；正常索引的 owner 工作保留，不納入設定／logs／裝置資料。這不是 repo-wide security audit。

第一批後續的 Apple same／within 配對、photos、完整來源／evidence context 已進入上方第二批 Red，完成前不接正常 App。之後才處理 loading／empty／failure／Try again、API-only 啟動與個人 journeys 的保護。這批沒有修改 ContentView／Explore／store 行為、bundled JSON、backend／DB、ATS、endpoint 或 signing；不 push、部署或改 sibling checkout。A–E 點擊流程保持原樣。

**2026-10-01：Swift 已真正讀取本機 API，兩項整合測試通過。** 起點 Prototyping／8d0ecb5，working tree 乾淨；owner 要求下一步。重新確認 DB／Studio／pg_meta 都 running／healthy，但 loopback API 沒有回應。只執行既有 `python3 scripts/run_backend_local.py serve` 啟動 Deno，沒有重啟容器、匯入、migration 或資料寫入。獨立免登入 GET 確認正確 route 200／v5／253 items／2 sources／473,658 bytes，未知 route 404；這是環境前置查核，不把 listener 未啟動說成行為 Red。

新增 [CoolSpotsAPILocalIntegrationTests.swift](cool-spotTests/CoolSpotsAPILocalIntegrationTests.swift)，project 只增加一個 test file 的 group／target membership，沒有 production Swift／API／DB／Info.plist／ATS／signing 更改。沿用完整 loader 與 decoder；沒有 URLProtocol、替身或 bundled catalogue 介入這兩項整合測試。真正 URLSession 使用 ephemeral session、nil credential/cookie storage、不存 cookie、不使用本機 cache、5 秒 request／10 秒 resource timeout，teardown 關閉 session。端點固定為 127.0.0.1:8000，只讀 JSON／照片 metadata，不下載圖片或操作 owner 裝置資料。

| Case | 預期 | 實際證據 |
|---|---|---|
| IOS-API-C01 | 免登入真正 GET → 現有 loader → v5 decoder，完整讀取本機初始匯入清單 | 第一輪就通過，不製造 Red。253 個獨立 Cool Spot／Place 身分、250 GLA＋3 examples、GLA 2025 label／未知來源日期、generatedAt 位於本次請求時間內；5,297 pointers／145 maps／3 bundle illustrations；Canning Town Library 的既有 ID、正式座標、GLA record 18／時區背景依據及已知 within_place 都有 assertions |
| IOS-API-C02 | 現有 loader 拒絕本機未知路徑，回傳 invalidResponse | 第一輪就通過；獨立前置 HTTP 先確認該 route 的實際 status 為 404。Swift case 驗證 loader 的錯誤映射，不依賴真正資料庫故障或修改密碼 |

在既有 Cool Spot Contract QA／iPhone 17 Pro Max／iOS 26.4，僅執行新 integration class：xcodebuild exit 0，xcresult **2 執行／2 passed／0 failed／0 skipped**；測試前後 loader／decoder／integration tests／project 四檔 SHA-256 一致。既有正式碼已具備所需行為，因此沒有新 production Green／Refactor；上輪二十九個 unit tests 是既有證據，本批不重跑。沒有重跑 SQL／Deno／舊 Swift suite 或裝置矩陣，沒有自稱 App UI／照片傳送／部署／容量驗證。

平常 unit runs 不應要求啟動 server：新 integration cases 只有 `COOL_SPOTS_LOCAL_API_TESTS=1` 才執行，否則明確 XCTSkip。實測透過已安裝 xcodebuild 的 TEST_RUNNER_ 環境傳遞規則，把一個非秘密開關傳入 test host。從 prototype 根目錄、確認本機 API 健康後重現：

```sh
TEST_RUNNER_COOL_SPOTS_LOCAL_API_TESTS=1 xcodebuild -project cool-spot.xcodeproj -scheme cool-spot -destination 'platform=iOS Simulator,id=D3C4BAE1-F7BE-4D7B-AF0C-A23744C41852' -derivedDataPath /tmp/cool-spot-v5-decoder -only-testing:cool_spotTests/CoolSpotsAPILocalIntegrationTests -parallel-testing-enabled NO -quiet test
```

App 正常啟動／Explore／PrototypeStore 尚未接 API，仍使用既有 catalogue 流程；這次只證明測試中的 Swift loader 能從真正 API 取得完整資料。下一批先說明 App 入口／domain mapping／loading、empty、error、retry 的檔案影響與測試，再按教學流程開始。提交限新測試、test target membership 與三份原有文件；安全檢查後本機 commit，不納入設定／logs／裝置資料、不 push 或部署。新 App 仍以 API-only／無 bundled fallback 為方向，不默默改個人資料或舊本機發布的生命週期。

**2026-10-01：Swift HTTP 批次已 Green，相關測試 29 passed／0 failed。** 起點 Prototyping／9ea62ce；先發現 CoolSpotsAPIResponse.swift 有未提交改動，移除了已完成的欄位／關聯解析。Agent 沒有覆蓋；owner 回報恢復後，重新核對 git working tree 乾淨、HEAD 未變。先按教學方式由 agent 寫成批 tests／驗證 Red 並提供完整 Green；owner 再明確委託「你幫我弄吧」，要求權衡 SOLID，由 agent 完成當批實作與設計 review。此委託不延伸到下一批或 App 接線。

本批新增 [CoolSpotsAPILoader.swift](cool-spot/CoolSpotsAPILoader.swift)、[CoolSpotsAPILoaderTests.swift](cool-spotTests/CoolSpotsAPILoaderTests.swift)，Xcode project 只加入兩檔的 group／target membership。入口為注入 URL 與 URLSession 的 async load，回傳完整 CoolSpotsAPIResponse；最初可編譯占位實作固定 throw invalidResponse，委託後改為 GET／HTTP 200 檢查／v5 decode／兩種錯誤映射與 CancellationError。URLProtocol 替身只套到每個測試的 ephemeral session，以各自 URL 隔離、鎖保護 registry／requests，teardown 關閉 session 並移除註冊；不使用真實網路、資料庫或裝置資料。

| Case | 預期 | Red → Green 實際證據 |
|---|---|---|
| IOS-HTTP-C01–C02 | 建立 loader 不發 request；每次 load 對指定 URL 發 GET，Accept application/json，不帶 Authorization／apikey／body | C01 已通過，不製造 Red；C02 原零次 request，Green 兩次 GET，所有指定 header／URL／method／body assertions 通過 |
| IOS-HTTP-C03–C04 | HTTP 200 解析完整 v5 envelope／facts／relations，合法空清單也成功 | 兩項 Red → Green；來源年份不替換成生成時間，兩種 ID 保持獨立；完整欄位解碼另由既有十七項驗證 |
| IOS-HTTP-C05–C07 | 非 200／非 HTTP response／空或壞 JSON／舊版本／非法正式值都回 invalidResponse | 三項在占位階段已通過，不製造 Red；Green 真正經 URLSession 的替身 response 與 decoder 後仍正確拒絕 |
| IOS-HTTP-C08–C11 | transport failures 為 connectivity；URLError.cancelled 與取消 in-flight Task 保留 CancellationError；已取消 Task 不發 request | 四項 Red → Green；包含 timeout／cannotConnectToHost／networkConnectionLost。in-flight Red 未送 request，started expectation 到期；Green 送出後取消成功，已取消 Task 不送 request |
| IOS-HTTP-C12 | 同一 loader 兩次並行 load，先完成第二次，再完成第一次，各拿自己的 response | Red → Green；實際先完成第二次，兩次拿到各自的 Cool Spot ID，不把連續 request count 當成獨立 completion 證據 |

僅在既有 Cool Spot Contract QA／iPhone 17 Pro Max／iOS 26.4 執行十二項新 loader tests 與十七項 decoder tests：編譯成功，xcodebuild exit 65，xcresult **29 執行／21 passed／8 failed／0 skipped**。十七項 decoder 全通過；loader 四項已通過、八項為目標未實作的行為失敗。沒有把編譯錯誤當作 Red，也沒有重跑舊 v4 regression／歷史 Swift suite／SQL／backend。此結果不代表 Swift 已向真實 API 送 GET。

委託 Green 後，同一隔離 simulator 執行十二項 loader 與十七項 decoder：xcodebuild exit 0，xcresult **29 執行／29 passed／0 failed／0 skipped**。正式 loader 只協調 HTTP 與既有 decoder，沒有重複欄位驗證、保存最後回應或混用兩次 load 的結果；依賴注入讓 transport 可受控測試。它仍依賴具體 URLSession，沒有把依賴注入說成完全符合 DIP；目前這是 Foundation 邊界，另建 transport protocol 尚無實際收益，未為湊齊 SOLID 加抽象。Green 後檢查發現 non-HTTP 測試的 handler closure 捕捉其 owning SessionStub；改為捕捉 URL 值以移除循環引用，再單獨執行該 case：1 passed／0 failed／0 skipped，xcodebuild exit 0。沒有變更正式行為或測試預期。

提交前又發現 loader 磁碟內容回到完全相同的初始占位介面，原因未確定；沒有提交這個不一致狀態。先保存 owner-only 暫存副本，再重新套用已委託的 Green。因 source 與早先 Green 證據不一致，重新執行整批二十九項：xcodebuild exit 0、29 passed／0 failed／0 skipped；核對 loader／loader tests／decoder／decoder tests／project 五檔在測試前後 SHA-256 一致，提交時再比對。暫存副本、fingerprints 與 logs 均留在 Git 外。

下一步用真實本機 endpoint 驗證 253 筆；本批結果只包含 URLProtocol 合成回應，不代表 Swift 已向後端送 GET。Explore／App 入口與 UI error／retry 行為仍待下一批；沒有 bundled fallback、預先加入快取／retry／附近搜尋／登入，沒有修改 decoder／舊 Swift consumer／JSON／signing／DB／backend 或 sibling checkout。延續 owner 的適當本機 commit 與安全檢查授權；提交限 source／tests／target membership／三份既有文件，不提交本機設定、測試輸出或 device 資料，不 push。

**2026-10-01：Swift v5 第三批已 Green，相關測試 18 passed／0 failed。** 起點是 Prototyping／7bed3f6，working tree 乾淨；owner 同意下一步。Agent 解釋完整關聯契約與來源對應規則後，新增 IOS-V5-C13–C17 tests／合成 helpers，及 SourceReference／Provenance／MapReference types 與四個空陣列占位介面；照片沿用 PlacePhotoAsset。確認 Red 後，owner 明確委託「你幫我弄吧」，由 agent 完成當批 Green。Swift HTTP 與 Explore 尚未接線。

| Case | 預期 | 實際證據 |
|---|---|---|
| IOS-V5-C13–C14 | 保留主來源順序、來源＋record 身分、四種取得方法與 pointers、same／within 外部 ID、照片順序及 metadata；空陣列合法 | C13 Red → Green，C14 在占位階段已通過，真正讀取後仍通過，不製造 Red。合成兩個 source 共用 record ID 18，仍是不同來源紀錄；日期不替換成 generatedAt |
| IOS-V5-C15–C16 | 關聯日期／caption／contributionID 的 null 保持 nil；四個 arrays 及必要 nested 欄位必須存在且型別正確 | 兩項 Red → Green。只解析 metadata，不下載圖片；合成 HTTPS／bundle refs 與既有 optional contributionID 的讀取測試不代表 Report／媒體服務已實作 |
| IOS-V5-C17 | registry source ID 唯一且非空白，record ID 非空白；reference 必須指向 registry，provenance tuple 必須在同一 item 的 references | Red → Green；包含來源不存在、錯 record、同 record 的錯來源、重複／空白 source、空白 record，以及 record 只連到另一個 Place 的案例 |

在既有 Cool Spot Contract QA／iPhone 17 Pro Max／iOS 26.4，僅執行 CoolSpotsAPIResponseTests：編譯成功，xcodebuild exit 65，xcresult 十七項執行、十三項通過、四項失敗、零跳過。原十二項仍通過；失敗為關聯資料未讀入、nullable 有紀錄卻得到空陣列、缺欄位未拒絕與錯來源關聯未拒絕。新欄位目前只是 computed placeholders，不能把過關的空陣列 case 當成完整讀取證據。

委託 Green 後，四個占位 var 已改為儲存 let；decode 以 registry ID Set 和每個 item 的 SourceReference Set 檢查對應，拒絕錯誤署名而非改寫來源。method／provider／relationship／verification 保留原 API 字串，不在讀取時重新推斷或把 within 改成 same。於同一隔離 simulator 執行十七項 v5 tests，另加既有 v4 decoder 回歸：xcodebuild exit 0，xcresult 十八項通過、零失敗、零跳過。實作直接，沒有額外重構。全部為合成 fixture；未用真正 HTTP payload 或聲稱效能／照片下載證據。

完整 v5 read model 的三批解析已通過；下一步先解釋與測試 Swift HTTP client／loader，再以本機匿名 GET 與真實 253 筆 payload 整合驗證，最後接 App 清單入口。這批沒有修改舊 v4 DTO／bundled JSON／photos renderer／project／DB／backend，也沒有 HTTP request／UI／圖片下載或 Report schema。提交限 decoder／tests 與既有文件，通過實際 staged diff／個資與憑證／本機設定值／文件 links 檢查後才 commit；不納入本機設定、device 資料或測試輸出，不 push。

**2026-10-01：Swift v5 第二批已 Green，相關測試 13 passed／0 failed。** 第一批 checkpoint 是 Prototyping／e1633f2；開始時 working tree 乾淨。Owner 詢問 App 是否已打 API 並同意下一步；確認 Swift 仍沒有 HTTP request 後，agent 依教學流程新增 IOS-V5-C07–C12 tests、必要 nested types 和新欄位占位介面，保留前六項行為。確認 Red 後，owner 明確委託「你幫我弄吧」，由 agent 完成當批 Green。沒有將此委託延伸到下一批或 App 接線。

| Case | 預期 | 實際證據 |
|---|---|---|
| IOS-V5-C07–C08 | 保留完整地址／場所分類／降溫描述／access／hours；unknown 與 nullable 值不杜撰 | C07 Red → Green。C08 在占位階段已通過，因 default 恰為 unknown／nil／空 features；不製造 Red，真正解碼後仍通過 |
| IOS-V5-C09–C10 | 新分類碼降為 unknown，但保留認識的 features；保留三種合法停留限制 | 兩項 Red → Green；沿用已有 wire enums 的 fallback，入場資格新增同樣的 typed fallback；停留狀態沿用 CoolSpotStayLimit 的 strict Status |
| IOS-V5-C11–C12 | limited 要正數分鐘，其他狀態不能帶分鐘；缺必要 object／enum／access key 或錯誤型別要拒絕 | 兩項 Red → Green；未知停留狀態或壞 minutes 型別是 DecodingError，已知狀態的矛盾組合是 invalidItems |

在既有 Cool Spot Contract QA／iPhone 17 Pro Max／iOS 26.4，僅執行 CoolSpotsAPIResponseTests：編譯成功、xcodebuild exit 65，xcresult 為十二項執行、七項通過、五項失敗、零跳過。六個舊 cases 全通過，新增六個有五個因目標未實作而失敗。只改新 decoder／tests，並維護既有文件；沒有舊 Swift consumer／bundled JSON／project 設定／DB／backend／Explore／HTTP／UI 變更，沒有重跑其他歷史 suite。測試全部為合成內容，敏感值 pattern 檢查無發現。

Agent 受委託完成 Green 後，在 CoolSpotsAPIResponse.swift 把 Item 的占位 var 改為儲存 let，交由合成 Decodable 讀取；補 Eligibility 的未知分類解碼，在 decode guard 加上 postedStayLimit.isValid。沒有從名稱判斷分類或補倫敦時區，缺少的描述／hours 保持 nil；新 model 不含 scope／eligibilityDetails。於同一隔離 simulator 執行十二項 v5 tests，另加既有 v4 decoder 回歸：xcodebuild exit 0，xcresult 十三項通過、零失敗、零跳過。實作直接，沒有額外重構。

下一步是來源關聯、欄位依據、地圖與照片的 Swift 解析，之後才接 URLSession／App 清單入口。這批提交限 decoder／tests 與既有文件；真正 staged diff、敏感值 pattern、本機設定值與文件 links 檢查後才 commit，不納入本機設定、device 資料或測試輸出，不 push。一般更正歷史／Report／照片傳送與上傳仍未實作；沒有讓舊 catalogue 成為 fallback。

**2026-10-01：Swift v5 第一批已 Green，相關測試 7 passed／0 failed。** Owner 同意繼續下一步與適當 commit，要求提交前檢查個資／安全；在 agent 寫 tests／可編譯介面並確認六項 Red 後，owner 明確委託「你幫我弄」，由 agent 完成當批 decode Green。新增 [CoolSpotsAPIResponse.swift](cool-spot/CoolSpotsAPIResponse.swift)、[CoolSpotsAPIResponseTests.swift](cool-spotTests/CoolSpotsAPIResponseTests.swift)，Xcode project 只增加兩檔的 group／target membership，沒有 signing／帳號設定變更。這次委託不自動擴張到其他產品批次。

| Case | 預期 | 實際證據 |
|---|---|---|
| IOS-V5-C01–C02 | 保留 v5 datasetID／生成時間／來源年代與範例標示／兩種獨立身分，允許空清單 | 合成 payload，來源日期不等於 generatedAt；nullable metadata 保持 nil，Place ID 讀為 UUID；兩項 Red → Green |
| IOS-V5-C03–C04 | 拒絕 v1–v4／未知版本、malformed JSON、缺少必要封套／身分欄位、非 UUID Place ID、錯誤座標型別 | 區分 unsupportedVersion 與 DecodingError，不以任意 throw 當作正確拒絕；兩項 Red → Green |
| IOS-V5-C05–C06 | 拒絕空白 ID／名稱、重複 Cool Spot／Place 身分、越界座標；保留有效邊界與原文 | 空白包含 NBSP／zero-width space；(0,0) 和經緯度端點合法，非空白名稱不 trim；兩項 Red → Green |

第一次執行因測試檔目錄拼字不同於 Xcode group 而無法編譯，不算 behavioral Red；修正位置到 cool-spotTests 後，僅執行新 class，編譯通過。Cool Spot Contract QA 是 iPhone 17 Pro Max／iOS 26.4；xcodebuild exit 65，xcresult summary 為六項執行、六項失敗、零跳過，全部由尚未實作的 decode 骨架造成。沒有跑歷史 Swift 全套、UI 走查或 backend suite，沒有更換 owner 使用中的 simulator App。

Green 在同一隔離 simulator 執行新 class 六項，並加入既有 testCoolSpotsResponseUsesV4DatasetIDAndReadsLegacyResponseIDs 作為舊 consumer 的回歸檢查：xcodebuild exit 0，xcresult 為七項通過、零失敗、零跳過。JSONDecoder 負責型別／必要欄位，decode 再檢查版本、兩種身分各自唯一、非空白文字與有效座標；合法原文保持不變。實作已小且直接，不為儀式額外重構。

這只是第一批讀取封套、來源與 id／placeID／name／location 的 Green；尚未完成地址、降溫、access、hours、欄位依據、來源關聯、地圖和照片解析。舊 v4 consumer／bundled JSON／Explore／保存與發布流程未改，未發 HTTP／引入 fallback。下一批是其餘場所資訊與關聯的 Swift 解析，再接真正 HTTP。提交限這批 source／tests／target membership 與既有文件；不納入本機設定、測試結果或 device 資料，不 push。

**2026-10-01：真正本機免登入 v5 API 已完成，相關 Deno tests 54 passed／0 failed。** Owner 明確委託「繼續做，該 commit 就 commit」，本批由 agent 完成 Green、入口與文件；沒有把此委託延伸到 Swift、部署或其他功能。來源匯入 baseline 是 Prototyping／2907708；來源結構／唯讀登入 checkpoint 已提交為 1138d97（Clarify catalogue sources and add a read-only backend login），API 提交見 git log。十三份 migration，沒有新 migration／重啟服務／重匯資料／reset。App 仍未讀 API。

實際路徑：HTTP → server.ts 路由 → handler.ts → reader.ts → 六種 database_reader.ts 查詢 → PostgreSQL → response.ts 組 v5 → HTTP JSON。六種讀取共用 REPEATABLE READ／READ ONLY transaction，避免一份回應混用不同次資料狀態。依 Place ID 整批分組，沒有逐場所追加查詢或把多組一對多 JOIN 成倍增的結果。

| Case | 組裝預期 | 實際證據 |
|---|---|---|
| V5-C01–C04 | v5 封套、兩種身分、正式值／null／unknown、明確公開欄位 | 原 Red 0 passed／4 failed；委託最小 Green 後 4 passed。後續新增空關聯欄位並維持通過；名稱原文、(0,0)、退休欄位／synthetic raw／archive／audit 排除均有 exact assertions |
| V5-C05–C08 | 來源年代／範例、已知或未知日期、hash、多來源主次順序、Place 關聯、缺失來源拒絕、無關來源排除 | Red 5 passed／3 failed（含前四項）；C08 已通過，不製造 Red。Green 8 passed；合成已知日期轉 UTC，來源空日期沒有替換成回應時間 |
| V5-C09–C13 | 欄位取得方式組成 public pointers；地圖 same／within 與外部 ID；有序照片／credit／日期；空關聯保留場所 | 先修正 synthetic extra map evidence 的 TypeScript excess-property compile error，才觀察 Red 9 passed／4 failed；C13 已通過。Green 13 passed。未知 field key／未連結來源拒絕，沒有杜撰 report／author；合成已知照片日期與 null caption 只證明 assembler，不聲稱真實 reader 有這些資料 |

| Case | 整合／入口預期 | 實際證據 |
|---|---|---|
| DB-C77–C78 | 真正資料庫組完整 v5；每次 load 產生獨立回應時間，不更改來源時間 | 與 API-C06–C08 同批 Red 2 passed／3 failed；先排除 runner 未允許 postgres.js PGSSL 環境讀取的設定錯誤。真正 Red 是 adapter 空骨架／GET 500；Green 5 passed，full counts／固定 library 值／來源身分／公開 keys 驗證 |
| API-C06–C08 | 免登入真正 HTTP GET 200 完整 v5、錯誤 DB 密碼 500 通用訊息、四種寫入方法 405 且不呼叫 reader | 真正 loopback HTTP，回應 body 全讀完、server／connections 收尾；handler 原失敗／method 行為在 Red 已通過。Green 時真正錯誤密碼仍回通用 500，沒有印診斷／URL／密碼 |
| API-C09–C11 | 非 function 路徑 404、正確路由傳回 v5、設定限專用本機登入並隱藏錯誤值 | Red 1 passed／2 failed；Green 3 passed。既有 route／setting 合法值不為製造 Red 而破壞 |

最終同批執行：7 handler＋13 assembler＋26 TCP/projection＋5 adapter/HTTP＋3 route/config = **54 passed／0 failed，Deno exit 0**。Deno format／型別與 git diff 檢查通過。既有 handler unit tests 的 v4 fixture 只驗證通用 JSON 傳輸；production 不 import 舊 catalogue JSON。沒有重跑 634 歷史 SQL 全套、舊 schema 演練、Swift 或 mapping；先前 migration／importer 的驗證仍為下方 dated evidence。

另外啟動真正的 standalone 本機程序：`python3 scripts/run_backend_local.py serve`，維持 `http://127.0.0.1:8000/functions/v1/cool-spots`。獨立 HTTP client 未附 Authorization，GET 200：253 items／2 sources／250 GLA＋3 examples／5,297 pointers／145 maps／3 photos；當次 body **473,658 bytes**。POST 405、其他路徑 404。這是本機整合證據，不是 Edge Functions／Kong／雲端部署或容量測試；`functions/v1` 是沿用 function 路由前綴，payload schemaVersion 是 5。

安全 runner 只讀 ignored／regular／owner-owned／0600 的 .env.backend.local，拒絕非 loopback／非專用角色或 Docker 遠端 override，檢查本機 DB healthy；只把設定透過 child environment 傳入，不放 command arguments，捕捉並遮蔽輸出。執行 `python3 scripts/run_backend_local.py test` 可重現上述 suites。停止 serve 用 Ctrl-C，關閉 listener／連線，不 stop/reset Supabase。最後唯讀確認 DB／Studio／pg_meta 都 healthy，migration 13 份；九張表筆數與既有 253／253／2／253／253／5,297／145／3／253 一致。這次沒有重啟容器。

**API 完成時停點：App 尚未改讀 API。** 後續 owner 同意先開始上方 Swift decoder 批次；HTTP client 與清單入口仍未修改。照片仍為既有 bundle:// illustration 參照，沒有圖片 HTTP／上傳服務；未建立 Report／作者／登入／附近查詢／分頁／Cooling here。photo contribution_id 去留與其餘尚未核准命名維持待議。

**2026-10-01：照片 reader DB-C73–C76 已 Green。** Owner 明確委託「好喔你幫我做」後，agent 補上完整唯讀 SELECT／JOIN／ORDER BY；同一受限本機 integration suite 為 **26 passed／0 failed，Deno exit 0**，包括原二十二個 TCP／reader cases。原 Red 是 23 passed／3 failed；DB-C76 空骨架時已通過，不製造 Red。這次委託限於 photo Green；下一批恢復 owner 輸入核心 Green 的教學方式。分支仍 Prototyping／2907708，保留 working changes，未 commit／push；十三份 migration，無新 schema／服務／Swift／bundled JSON／handler 變更，尚無 v5 HTTP／App 接線。

**2026-10-01 照片用途討論：** Owner 確認未來 Report 需要附圖，Place 頁也需要照片總覽；同一張 Report 照片在總覽保留原 Report／公開作者脈絡。推薦共用照片資源，不複製圖片檔、不把造訪照片當成已確認場所事實。已記入 PRODUCT；完整 schema、攝影者／提交者署名與總覽／上傳／可見性流程留待 Report 批次。現有 Swift VisitReport 沒有照片欄位；place_photos 是既有場所資訊照片，三張插圖沒有真實 Report 或作者。討論階段只記錄決定並提供 owner Green，未因討論重跑 Red；之後委託的 reader Green 見下方證據。沒有新增 Report／photo 關聯、刪 contribution_id 或修改 Swift。

Owner 同意的讀取方向見 [PRODUCT 的 connected slice](PRODUCT.md#agreed-connected-prototype-slice--app-integration-pending)：v5 移除 scope／eligibilityDetails，不建相容 view；新 App 只從 API 讀場所，不需舊版解碼／bundled fallback／舊本機場所發布還原。原始 v4 輸入與資料庫快照仍保留作來源證據。尚未實作新 App；不把這個方向當成刪除或上傳裝置資料的授權。

**照片 reader DB-C73–C76：Green。** 先查核 place_photos schema、公開照片與其獨立上傳／審核生命週期、initial importer、現有 Swift consumer／兩份 inputs 和本機正式值。唯讀確認 DB healthy、migration 13、places／cool_spots 253、photos 3、只有一個已收錄 Place 有照片，沒有 ordinary-Place photo fixture；API login 有 SELECT。三張只屬 Example Community Room，皆為 illustration，position 0／1／2；caption 非 null、captured_at／published_at／contribution_id 全為 null，URL 參照均 bundle://，不是已提供 HTTPS 圖片服務。

本批明確讀取現有十三欄 id／place_id／thumbnail_ref／image_ref／width／height／caption／captured_at／published_at／attribution／source_kind／contribution_id／position。型別日期為 Date | null，其他選填為 string | null。這些是 internal metadata rows，不是新 wire 契約；未將位置／圖片參照當成照片 ID。position 是既有展示順序，query 排序採 place_id／position；JOIN cool_spots 限定現行 list 關聯。保留既有 contribution_id placeholder（目前全 null），先前移除推薦未套用；不在 reader 批次默默刪欄。無 upload、bytes／EXIF、私人 uploader 或待審照片加入清單。

| Case | 預期行為 | 本次證據 |
|---|---|---|
| DB-C73 | 三張穩定資源 ID 連到 Example Community Room，position 0–2 排序且回傳指定十三欄 | Green：三張 identity／position 與十三欄 shape 通過；原 Red 是 [] 對三張 |
| DB-C74 | 第二張 Indoor seating 的圖片／縮圖 refs、尺寸 1448×1086、caption／attribution／source／其他 metadata 原樣保存 | Green：精確十三欄通過；原 Red 是 undefined。未證明圖片 bytes 已可下載 |
| DB-C75 | 三張皆 illustration，拍攝／發布時間及未指定 contribution ID 保留 null，不補生成時間 | Green：三張指定 metadata／null assertions 通過；原 Red 是 []，非空預期避免真空通過 |
| DB-C76 | 沒照片的 Canning Town Library 仍在 253 筆 list，不製造照片 | Green：完整照片結果下該圖書館仍無照片；原空骨架即通過，沒有人工 Red |

Agent 只新增 PlacePhotoRow／Promise.resolve([]) loader 和四個 tests；以同一 credentials-safe runner 執行，型別檢查通過，**23 passed／3 failed，Deno exit 1**。失敗都是目標 metadata 未實作，不是連線／permission／SQL 錯誤；stub 階段不發 photo SQL。原二十二項全通過，未重跑來源 SQL／importer／Swift／handler suites，無資料寫入或新 migration。

Owner 委託本批 Green 後，agent 確認磁碟仍是空骨架，再補上先前提供的完整 async 查詢。沿用 capture／filter runner 與 ignored owner-only settings，以 --frozen lock、受限 env／127.0.0.1:54322 network permissions 執行，DB healthy；**26 passed／0 failed，Deno exit 0**。此前未到達的 identity／shape／精確 metadata／null assertions 全部通過；原二十二個 cases 保持 Green。deno fmt --check 與 git diff --check 通過，查詢無需 refactor。只讀既有資料，沒有新增 fixture 或資料寫入；沒有重跑來源 SQL／importer／Swift／handler suites，沒有 migration、restart、cloud SQL、commit／push 或部署。

**本批下一步：** 對齊 v5 assembler cases，寫 tests／驗證 Red，再提供 owner 輸入的完整最小 Green；之後才接本機 HTTP。三張目前都在同 Place、null 日期、nonnull caption、illustration／bundle refs，因此 known dates、null caption、其他 source_kind／HTTPS／跨 Place 排序、全空表與排除 ordinary-Place photos 尚未覆蓋，不宣稱圖片下載、Report 附圖／總覽、發布／上傳或 iOS 接線已完成。


**地圖 reader DB-C68–C72：Green。** 先查核現有 place_map_links schema／欄位權限、PRODUCT 的兩種關係、bundled accepted identity ledger、匯入程式與 owner reader。唯讀確認 DB healthy、places／cool_spots 253、migration 13、accepted links 145／distinct Place 145；144 same_place／1 within_place、136 automatic／9 reviewed、1 null checked_at。沒有 ordinary Place 的 map fixture；API login 可 SELECT external_place_id，不能讀 evidence。沒有重新搜尋 Apple、重新配對或 migration。

這批沿用目前六個公開欄位 place_id／provider／external_place_id／relationship／verification／checked_at；後兩個 physical names 的 review 推薦尚未套用。checked_at 型別 Date | null，保留原始配對時點；reviewed 是既有來源覆核／範例標記，不宣稱 owner 或實地確認。內部排序採 place_id／provider／external_place_id，只使輸出穩定，不新增配對可信度或 primary 排序規則。JOIN cool_spots 限定這份 Cool Spot list 的關聯，不定案新的 Place-first API。

| Case | 預期行為 | 本次證據 |
|---|---|---|
| DB-C68 | 145 accepted identities 完整、連到原 Place、排序穩定且只有六欄；automatic／reviewed 數量保留 | Green：全部 identities／排序／六欄 shape／方法 counts 通過；原 Red 為 0 對 145 |
| DB-C69 | Canning Town Library same_place → I7E8561E6022ED614，reviewed／2026-09-18T14:33:54Z 保留 | Green：精確六欄與原時間通過；原 Red 為 []，不解讀為今日場所有效 |
| DB-C70 | Streatham lobby within_place → I469799177B7DF2F3；保留原時間、大廳 ID／名稱／座標 | Green：六欄、within_place 與大廳自己的 facts 通過；原 Red 為 [] |
| DB-C71 | 無 accepted match 的藥學博物館留在 Cool Spot list，配對清單為空 | Green：完整 145 筆結果下仍沒有 museum link；空骨架原已通過，未製造 Red |
| DB-C72 | Tate example 的同場所配對保留 checked_at=null，不用現在時間補值 | Green：精確六欄與 checked_at=null 通過；原 Red 為 [] |

Red 階段，agent 只新增 PlaceMapLinkRow／Promise.resolve([]) 骨架與五個 tests，同 suite 跑真實後端連線：型別檢查通過，**18 passed／4 failed，Deno exit 1**，四項皆為預期空資料 assertions，不是連線／SQL／permission 錯誤。當時未寫 SELECT Green。既有十七項全部通過，不重跑來源 SQL／importer／Swift 或 handler。測試僅讀取／既有 WHERE false 拒絕檢查，沒有 fixtures 寫入；migration 仍十三份。

2026-10-01 owner 委託 Green 後，agent 重新確認 Prototyping／2907708、working changes 與磁碟上的空骨架，再補上完整 async SELECT／JOIN／ORDER BY。型別檢查與實際 tests 結果為 **22 passed／0 failed，Deno exit 0**；先前未到達的完整 accepted identity ledger／shape／兩種關係／原配對時間／own-place facts／null assertions 全部通過。deno fmt --check／git diff --check 通過，查詢簡單清楚，無需 refactor。只讀既有資料，不重新搜尋 Apple；沒有 migration、DB reset、服務 restart、cloud SQL、commit／push、部署或 sibling checkout 改動。

**本批下一步：** 照片 reader，接著 v5 assembler 與本機 HTTP；本次代寫授權限於地圖 Green。初始每 Place 0／1 map 的 fixture 尚未驗證多配對排序、全部沒有配對的 database、或 JOIN 排除 ordinary-place links；不將這些推論當測試證據。


**來源整理 DB-C63–C67：完成。** 使用一個 agent，只操作 prototype checkout 與指定本機 DB。Owner 指定 `place_field_inference_records`；表內仍包括直接讀取／格式轉換，並非每筆都是推定。`catalogue_import_history` 保留名稱與完整首次快照，不宣稱更正歷史服務。data_sources metadata 改為指定型別欄位（含明確 is_example）；source_records 保留原始紀錄與 import_audit，刪除 mapped_data 副本；source_record_id 在相關表／reader 一致。history 指紋欄改為 import_payload_sha256，原始 canonical input／快照 keys 與 hash 保留。正式場所／降溫欄位、地圖／照片欄位與廁所語意尚未套用其餘 review 建議；不把設計推薦當成全部完成。

| Case | 整理後的行為 | 實際證據 |
|---|---|---|
| DB-C63 | 來源標頭使用明確欄位；時間為 timestamptz／可未知；GLA false／範例 true | 結構、型別與真實 reader 精確公開欄位通過 |
| DB-C64 | 來源紀錄保留 raw_record／import_audit；mapped_data 已有完整不可變 item 快照後才刪除 | 五個 migration rehearsal tests 與全 253 筆原始／audit／archive 比對通過 |
| DB-C65 | 採 owner 表名、清楚區分直接 mapping／兩種推定／範例；原來源關聯／欄位鍵限制及日期保留 | 新結構與四種碼、FK／retired field 拒絕、全量比對／DB-C60–C62 通過 |
| DB-C66 | 改名後仍保持 RLS／唯讀；原始資料、audit、本機 raw_file_path 及歷史私有 | 來源與登入權限 assertions、真實 TCP 的 42501 checks 通過 |
| DB-C67 | 同一原始輸入整理後重試完全不變；新匯入仍原子、來源變動須停止 | 十三個 importer tests：九表完整 retry 比對、253 筆 namespaced 匯入、更正後重試、來源標頭變動、失敗 rollback 通過 |

先新增 [source_structure.test.sql](supabase/tests/database/source_structure.test.sql) 與原始清單重試 test：SQL 結構 Red **9 failed／10 skipped**，psql 本身 exit 0 但 TAP 有 failures；原始 retry test 因新表不存在失敗（42P01）。依賴新結構的行為當時未執行。先核對 owner 存好的舊版取得方式 SELECT，DB-C46–C62 **17 passed／0 failed**；不把尚未跑過的 owner Green 當成歷史結果。

新增第十三份 [migration](supabase/migrations/20260930220000_clarify_catalogue_sources.sql)，不修改前十二份。先在 populated 舊 schema 以 BEGIN／ROLLBACK 執行 [test_source_structure_migration.py](scripts/test_source_structure_migration.py)：**5 passed**，包括九表逐列保留、缺少 item archive／來源 header archive／hash 衝突／非範例 review 時拒絕。source_structure 在 migration 同一 rollback 演練亦通過。此 rehearsal 只適用套用前 schema；永久套用後不要重跑或 reset。

以 capture/filter 輸出的 `supabase migration up --local --workdir .` 套用，exit 0；沒有 start／status 憑證輸出或服務重啟。Green：**19 structure＋134 source storage＋24 login = 177 SQL assertions，0 failed／0 skipped；13 importer tests；17 Deno TCP／reader tests，exit 0**。DB-C48 新增 raw_record／import_audit／raw_file_path 的真實登入拒絕檢查；沒有打印 URL、密碼、原始 driver errors。未重跑無關 handler／mapping／Swift suites 或 634 項歷史全套。

最後唯讀計數仍為 253 places／253 cool_spots／2 sources／253 source records／links／5297 acquisition records／145 maps／3 photos／253 histories，migration 十三份。全部 253 的原始內容、配對 audit、initial item／document metadata／fields／fingerprint 與原輸入相同；正式 Place／Cool Spot 與原快照差異為 0。方法分布改為 mapped_from_source 4000、inferred_from_context 1000、inferred_from_name 250、example_data 47；原記錄時間保留。postgres 的臨時 SET reader/api 與 reader/api 的 extensions USAGE 都 false，所有測試 fixtures／暫時授權 rollback。

**下一步：** 接續 maps／photos reader，再組 v5 與本機免登入 HTTP。尚無產品 API／App 接線；不在本批開始其餘 schema 重命名、新查詢／回報／登入或部署。


接手完整讀取三份 active documents、i-have-adhd／essential-tdd，檢查 handler／Swift／v4 schema／兩份 fixtures／migrations／importer 與權限 tests。唯讀確認三個本機容器（db、pg_meta、Studio）healthy、Studio HTTP 200；沒有 Auth／PostgREST／Kong／Edge Runtime 容器。253 Places／253 Cool Spots、2 sources、253 source records／links、5,297 evidence、145 map links、3 photos、253 initial histories 與十一份 migration 均吻合。2026-09-29 再確認角色測試前兩表筆數仍 253，reader 為 NOLOGIN，cool_spots_api 尚不存在；未重啟服務或重跑 634／11 歷史結果。

| Case | 第一批預期行為 | 實際狀態 |
|---|---|---|
| DB-C43 | 專用後端角色存在、具 LOGIN 屬性且沒有管理／bypass RLS 特權；既有 reader 保持 NOLOGIN | Green；角色／屬性 assertions 通過。真實密碼登入尚未驗證 |
| DB-C44 | 以後端角色讀回指定測試 Place／Cool Spot 的正式值；兩表的新增、修改、刪除及清空均拒絕 | Green；SET LOCAL ROLE 後身分與讀回值正確，八種寫入均回 42501；Red 時角色缺失而跳過 |
| DB-C45 | client／authenticator 不可取得後端角色；後端不能取得管理員、在 application schema 建物件，或讀 raw／舊 v4／私有配對證據／匯入歷史 | Green；角色／schema 權限檢查與五種受限資料 SELECT 拒絕均通過；Red 時跳過 |

新增 [backend_login.test.sql](supabase/tests/database/backend_login.test.sql)，plan 23，使用獨立 fixtures 與 BEGIN／ROLLBACK；測試只給 pgTAP schema usage 和執行者的臨時 SET membership，不替受測角色補 domain-table 權限。執行 `SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local --workdir . supabase/tests/database/backend_login.test.sql`：**1 passed／1 failed／21 skipped，runner exit 1／Result FAIL**。唯一失敗是 DB-C43 角色不存在，無語法或 runner 錯誤；這是結構 Red，不是實際連線拒絕或讀寫權限的行為 Red。測試後唯讀確認兩表各 253 筆、十一份 migration、測試 Place 為零、backend role 不存在、pgTAP 未保留、postgres 對 reader 的臨時 SET 權限為 false。

Agent 以 CLI 建立 [20260929055551_add_backend_read_login.sql](supabase/migrations/20260929055551_add_backend_read_login.sql)，Red 當時為 0 bytes、未套用。Owner 隨後親手輸入並回覆「存了」；agent 讀取確認僅 CREATE ROLE（LOGIN、無管理／bypass RLS 屬性）及 GRANT reader（INHERIT true、SET false），沒有密碼或資料寫入。先核對本機只有這份 pending、history 十一份與兩表各 253 筆，再執行 `SUPABASE_TELEMETRY_DISABLED=1 supabase migration up --local --workdir .`，exit 0，只套用第十二份，owner SQL 未修改。

第一次執行本批與既有 cool_spots_permissions.test.sql：新 suite 前 9 項通過，第 10 項中斷，錯誤為 could not determine which collation to use for string comparison；既有 **47 項全部通過**。新 suite 當時 plan 23 但只執行 9 項，整次 FAIL，沒有將未執行項算通過。唯讀定位 current_user::text 的 collation 為 C、期望字串為 default；pgTAP 整列比對遇到衝突。Agent 只將角色身分改成獨立布林 assertion，JOIN 仍比對原 Cool Spot ID、名稱、經緯度，plan 改為 24；未放寬權限或修改 production SQL。

只重跑受影響的 backend_login.test.sql：**24 passed／0 failed／0 skipped，exit 0／Result PASS**。既有 47 項的程式與 SQL 未再變動，沒有重跑。沒有 production refactor；未跑 634 整套、importer、Deno 或 Swift。

Green 後唯讀確認：history 十二份、最新 20260929055551；cool_spots_api LOGIN=true 且 superuser／createdb／createrole／replication／bypassrls 皆 false；reader 保持 NOLOGIN；membership 為 ADMIN=false／INHERIT=true／SET=false。九表筆數仍為 253／253／2／253／253／5297／145／3／253，兩套測試的五個 fixture Places 都不存在，pgTAP 未保留，postgres 對 api／reader 的臨時 SET 與 api 的 extensions USAGE 均 false。沒有留下測試資料或臨時授權。

**2026-09-30 憑證準備：** Owner 在 Terminal 執行 psql 的隱藏密碼提示，回報已完成。其 Terminal 的 docker 不在 PATH，改用已確認存在的 /Applications/Docker.app/Contents/Resources/bin/docker；未修改 shell 設定。Agent 唯讀查詢 cool_spots_api 的 rolpassword IS NOT NULL，結果 true，未讀出密碼或 hash。Owner 隨後以隱藏輸入保存 .env.backend.local，使用 COOL_SPOTS_DATABASE_URL 並對密碼做 URL 編碼，不在指令文字中填入密碼。Agent 確認檔案存在、0600、owner 為目前 macOS 使用者、被 Git 忽略，URL 為預期的 127.0.0.1:54322／postgres／cool_spots_api 且密碼非空；未輸出檔案內容或 credentials。這只確認設定已保存，尚未證明實際登入。

**DB-C46–C48 連線批次：Green。** 新增 [database_integration_test.ts](supabase/functions/cool-spots/database_integration_test.ts)、[database.ts](supabase/functions/cool-spots/database.ts) 與 [deno.lock](supabase/functions/cool-spots/deno.lock)，固定 Postgres.js 3.4.9。此批只建立連線，尚不組合 v5 JSON。

| Case | 預期行為 | 本次證據 |
|---|---|---|
| DB-C46 | TCP 登入的 session_user／current_user 皆為 cool_spots_api，JOIN 正式兩表讀回 Canning Town Library 的舊 ID、名稱與座標 | Green：真實 TCP、登入身分與讀回值 assertions 全通過；原 Red 停在 client 骨架 |
| DB-C47 | 改用刻意錯誤的密碼，PostgreSQL 拒絕並回 28P01 | Green：真正查詢收到 28P01；原 Red 停在 client 骨架 |
| DB-C48 | 真正登入後，場所 UPDATE、raw_data 與匯入歷史 SELECT 均回 42501 | Green：先確認登入角色，三種禁止操作皆收到 42501；原 Red 停在 client 骨架 |

測試 URL 守衛限定本機主機／port／資料庫／角色，拒絕額外 query parameters；UPDATE 使用 WHERE false，即使權限倒退也不改任何列，受限資料 SELECT 使用 LIMIT 0，不取回原始值。Helpers 只顯示安全錯誤代碼，且在 finally 關閉連線。正式資料的預期值由本次唯讀管理查詢核對；它不是後端登入成功證據，migration 仍十二份。

執行前以 runner 清除繼承的 PG*／同名 URL 環境值，載入 owner 的本機設定；stdout／stderr 捕捉後先遮蔽連線字串及密碼再輸出。實際指令為：

```sh
/opt/homebrew/bin/deno test --no-prompt --lock=supabase/functions/cool-spots/deno.lock --env-file=.env.backend.local --allow-env='COOL_SPOTS_DATABASE_URL,PG*' --allow-net=127.0.0.1:54322 supabase/functions/cool-spots/database_integration_test.ts
```

初次型別檢查通過，三個 test body 均執行，**0 passed／3 failed，Deno exit 1**；共同失敗訊息為 Database connection is not implemented。這是 client 尚未實作的 Red，不是 SQL／認證失敗。Agent 當時只保留拋錯骨架，完整最小 Green 交由 owner 輸入。

Owner 存好 database.ts 後，agent 確認實際內容為 postgres(databaseURL, { max: 1, connect_timeout: 5 })，以同一指令重跑：**3 passed／0 failed，Deno exit 0**。資料庫容器 running／healthy，設定檔仍是 0600、目前使用者持有且 Git 忽略；沒有改寫 owner client 或做 refactor。deno fmt --check 僅指出 owner 檔尾缺最後換行，原樣保留；它不影響型別／行為結果。未重跑既有 SQL／handler／importer／Swift tests。

**DB-C49–C50 第一個 reader JOIN 批次：Green。** 新增 [database_reader.ts](supabase/functions/cool-spots/database_reader.ts)，CoolSpotRow 首步含 id／place_id／name／latitude／longitude，loadCoolSpotRows 接收已建立的 client。最初為空清單骨架，後由 owner 輸入 SELECT／JOIN。這是逐步組裝完整回應的內部資料，不是新增或縮減 API 契約；地址／降溫內容／來源與 v5 尚待後續批次。

| Case | 預期行為 | 本次證據 |
|---|---|---|
| DB-C49 | Reader 依舊 Cool Spot ID 排序，讀回完整 253 個原 ID 與 253 個唯一 Place ID | Green：數量、完整原 ID 清單／順序與 Place 唯一性通過；原 Red 為 0 對 253。兩份既有 JSON 僅提供測試的原 ID 對照 |
| DB-C50 | Reader 讀回圖書館的舊 ID、名稱、經緯度及不同的新 Place UUID | Green：圖書館各欄、Place UUID 格式與兩種 ID 不同皆通過；原 Red 在空清單中找不到場所 |

在同一 integration suite 初次加上兩個 tests 後重跑：型別檢查通過，**3 passed／2 failed，Deno exit 1**；原 DB-C46–C48 保持 Green，兩個新 case 在預期 assertions 失敗。當時 reader 未查詢或寫入資料。Agent 未代寫 JOIN Green，完整當步程式碼交由 owner 輸入。當時唯讀計數仍為 253 places／253 cool_spots／2 sources／253 source_records／253 links／5297 evidence／145 map links／3 photos／253 histories，migration 十二份。

Owner 隨後存好 database_reader.ts；agent 讀取確認 SELECT c.id／c.place_id／p.name／座標函式，JOIN places，ORDER BY c.id，最後回傳展開的 rows。以同一受限／遮蔽輸出 runner 執行：**5 passed／0 failed，Deno exit 0**；型別檢查與全部當批 assertions 通過。沒有代改 owner query 或 refactor，沒有重跑 SQL／handler／importer／Swift 歷史 suites。

**DB-C51–C52 地址／場所類型批次：Green。** 本批沿用 places 已有的七個地址欄與 place_type，不新增 migration。Agent 先唯讀核對 Canning Town Library 與 Tate Modern 範例的正式值，再新增 tests，並僅補 CoolSpotRow 的必要型別宣告（七個 string | null、一個 string），原 SQL 當時完全不動。TypeScript 宣告不會自行選取 SQL 欄位；擴充 SELECT 由 owner 隨後輸入。

| Case | 預期行為 | 本次證據 |
|---|---|---|
| DB-C51 | Library 的街道／locality／borough／country code 原樣讀回；formatted／line2／postal code 保留 null，類型為 library | Green：八欄與已核對正式值相符；原 Red 全為 undefined |
| DB-C52 | Tate Modern 範例保留完整地址與 culture 類型；未知地址組件維持 null，不從格式化文字猜拆郵遞區號 | Green：八欄原值／null 均保留；原 Red 全為 undefined。這不驗證範例場所的目前狀況 |

Red 時重跑同一 integration suite：型別檢查通過，**5 passed／2 failed，Deno exit 1**。舊五個 cases 保持 Green；新增兩個都在預期資料比較失敗，原因是 SELECT 尚未包含地址／類型，不是資料庫缺欄或連線失敗。Agent 沒有代寫擴充 SELECT，完整函式 Green 提供 owner 輸入；本批只查詢正式資料，未更新場所或重新匯入。兩個 fixtures 驗證現有部分地址／formatted 與 null，未宣稱覆蓋所有可能地址組合。

Owner 回報完成後，agent 確認檔案的 SELECT 已包含七個 p.address_* 與 p.place_type，以同一受限、遮蔽 credentials 的 runner 重跑：**7 passed／0 failed，Deno exit 0**，型別與當批行為全部通過。未改寫 owner Green、未 refactor、未新增 migration 或重跑其他歷史 suites。Owner 同時詢問 JOIN 是否建立一張大表；已說明它只產生這次查詢的組合結果，原 places／cool_spots 保持分開，後端再把結果整理成 JSON；沒有另存表或 view。

**DB-C53–C55 降溫／使用欄位批次：Green。** Owner 要求 next 後，agent 查核第九份 migration、PRODUCT 與本機正式 Cool Spot 欄位；沿用既有的 17 欄，不新增 domain 欄位或 migration。最初只在 CoolSpotRow 補上讓測試可編譯的欄位型別，未擴充 owner SELECT；測試 helper coolingValues 只抽取這一批公開欄位。SELECT 由 owner 隨後完成。

| Case | 預期行為 | 本次證據 |
|---|---|---|
| DB-C53 | Canning Town Library 的室內、冷氣、使用條件與營業時間原文／時區完整讀回；unknown 與 null 保留 | Green：17 欄比對通過；原 Red 皆為 undefined |
| DB-C54 | Community Room／Shaded Garden 範例保留 no／none／unknown／limited、單一／多個設施、未公告限制與未知限制及空 hours | Green：room 與 garden 兩筆的 17 欄均通過；原 Red 停在 room 比較，未執行 garden 內容 assertion |
| DB-C55 | St John's Hyde Park 的空設施清單 [] 與既有降溫描述原文一起保留，不從文字推論設施碼 | Green：17 欄、空清單與原文皆通過；原 Red 皆為 undefined。歷史描述不是今日降溫證明 |

唯讀檢查確認全 253 筆的 area_description／additional_information／posted_stay_limit_minutes 皆為 null；本批只能覆蓋這三欄空值，非空文字／正整數的 reader 路徑尚未驗證。不為測試改寫正式資料；既有 SQL 儲存驗證不代替 reader 非空值測試。來源年份／依據需在後續來源批次補齊，尚無 v5 HTTP 回應。

Red 時用同一受限本機／遮蔽 credentials 的 runner 跑 integration suite：型別檢查通過，**7 passed／3 failed，Deno exit 1**。DB-C46–C52 保持 Green；DB-C53–C55 都因 SQL 未選取新欄位而出現預期資料比較失敗，沒有 SQL 語法或連線錯誤。Agent 只新增 tests／helper／型別宣告，完整 SELECT 補充交由 owner 輸入。

Owner 回報完成後，agent 確認 SELECT 已含 17 個指定 c. 欄位，重跑同一 runner：**10 passed／0 failed，Deno exit 0**。型別與所有當批 assertions 通過，包括先前 Red 未到達的 garden assertions。未代改 owner Green、refactor、更新場所、重新匯入或重跑其他歷史 suites。

**DB-C56–C57 公開來源 metadata 批次：Green。** 先查核第十份 migration、既有兩份 catalogue 的 sources、importer 與本機 data_sources；只保留既有公開 metadata 的指定欄位，不把整包 metadata 或本機 raw_file_path 帶回 source row。新增 DataSourceRow 型別與空 loadDataSourceRows 骨架，tests 加在同一 integration suite；owner 隨後完成查詢。本批尚未讀 place_source_links 或組 v5 JSON。

| Case | 預期行為 | 本次證據 |
|---|---|---|
| DB-C56 | 兩個來源依 ID 排序，GLA 公開資料保持 2025 標籤／dataset／網址／下載網址／checksum，未知原始時間維持 null；只回指定公開欄位 | Green：完整來源順序／精確公開欄位與 null 通過；原 Red 在來源數量 0 對 2 失敗 |
| DB-C57 | 社群來源保持 Example cooling info 與 is_example=true；缺少的網址／dataset／原始時間／公開 checksum 為 null | Green：完整範例來源欄位與 null 通過；原 Red 在空清單中找不到範例來源 |

同一受限／遮蔽 credentials 的 runner 執行：型別檢查通過，**10 passed／2 failed，Deno exit 1**。舊十個 tests 保持 Green；兩個新 case 都因 loader 尚未查詢而回空清單，在預期 assertions 失敗。GLA metadata 未含 isExample，內部 row 採 null 表示未提供；wire 欄位仍待 assembler 按既有公開語意處理。原始 metadata 的未知下載／更新時間不能填成 API 回應時間；生成時間是另一項資訊。

Agent 已解釋 metadata 是 JSON，SQL ->> 取指定欄位，並提供完整 loadDataSourceRows 最小 Green 由 owner 輸入。未代寫核心 Green、改權限、建立 view／migration、修改 Swift／bundled JSON 或重跑其他歷史 suites。

Owner 存好來源 loader 後，agent 確認明確 SELECT 十一個公開欄位、用 ->> 取指定 metadata 值並依 id 排序；重跑同一 runner：**12 passed／0 failed，Deno exit 0**。GLA／範例的所有欄位 assertions 通過，未改 owner Green、權限或正式資料。

**DB-C58–C59 場所來源關聯批次：Green。** Agent 新增 PlaceSourceLinkRow（place_id／source_id／record_id／position）、空 loadPlaceSourceLinks 骨架及兩個 tests，owner 隨後完成查詢。關聯分批讀取，後續用 Place ID 組裝，沒有把原始紀錄或歷史帶入公開 reader。

| Case | 預期行為 | 本次證據 |
|---|---|---|
| DB-C58 | 初始 253 個 Place 的來源關聯完整、依 Place ID 排序；250 筆 GLA、3 筆範例且 position=0 | Green：數量、覆蓋／排序／來源分布與 position 通過；原 Red 為 0 對 253 |
| DB-C59 | 圖書館連到 GLA record_id="18"；Tate 範例連到原範例 ID，只回四個關聯欄位 | Green：圖書館與 Tate 精確四欄關聯通過；原 Red 停在圖書館 [] 比較 |

同一受限／遮蔽 credentials 的 runner 執行：型別檢查通過，**12 passed／2 failed，Deno exit 1**。前十二個 cases 保持 Green；新 cases 在預期 assertions 失敗，不是連線或 SQL 錯誤。Agent 未代寫核心 Green，完整四欄 SELECT／JOIN 交由 owner 輸入。這批測試只覆蓋初始每 Place 一個來源；不代表限制未來來源數量，也不宣稱已驗證多來源排序或排除沒有 Cool Spot 的 Place。

Owner 回覆「好了」並詢問三個函式的責任後，agent 重新讀取 prototype 磁碟檔案：loadPlaceSourceLinks 仍為 Promise.resolve([]) 骨架，未見提供的 SELECT／JOIN。重跑同一 runner，仍為 **12 passed／2 failed，Deno exit 1**；沒有將 owner 回覆當成 Green 證據，沒有代寫查詢。已說明三個 reader 分別讀正式場所事實、來源介紹及場所與來源紀錄的關聯；完整 API 組裝仍待後續實作。

Owner 理解查詢後要求下一步，agent 再讀磁碟確認 loadPlaceSourceLinks 已含四欄 SELECT、JOIN cool_spots 與 ORDER BY place_id／position。以同一 runner 執行：**14 passed／0 failed，Deno exit 0**；先前未到達的 Tate 與所有來源分布 assertions 都通過。未代改 owner Green 或 refactor。

**DB-C60–C62 欄位取得方式批次：Green。** 先查核 migration 十／十一、importer 的欄位鍵映射及既有 v4 provenance 定義，再以專用後端連線唯讀核對正式 place_field_evidence。新增 FieldEvidenceRow（place_id／field_key／source_id／record_id／method／recorded_at）、空 loadFieldEvidenceRows 與同 suite 的三個 tests。內部 recorded_at 為 Date | null，後續 wire 時間序列化仍屬 assembler 工作。

| Case | 預期行為 | 本次證據 |
|---|---|---|
| DB-C60 | 5,297 筆目前欄位依據覆蓋全部 253 個 Place，place_id／field_key 不重複，每筆連到同 Place 的來源紀錄，沒有 retired fields | Green：數量、關聯／覆蓋與欄位鍵通過；初始 Red 為 0 對 5297 |
| DB-C61 | 圖書館的 cooling_features／hours_time_zone／place_type 改用 mapped_from_source／inferred_from_context／inferred_from_name；GLA record 18 與原時間保留，只回六欄 | Green：三種取得方式與精確六欄皆通過；初始 Red 第一筆為 undefined |
| DB-C62 | Tate 範例 cooling_features 使用 example_data 方法碼、範例 source／record 與原 2026-09-18T22:32:22Z | Green：精確六欄／範例標記通過；初始 Red 為 undefined，不代表有真實審核服務 |

唯讀核對方法分布為 imported 4000、dataset_context 1000、name_rule 250、reviewed_contribution 47，合計 5297，且全部 recorded_at 非 null。本批 fixtures 只覆蓋已知時間；null 時間的 reader 路徑仍需另驗證。GLA 現有依據記錄時間為 2026-09-19T00:16:05Z，來源仍標 GLA 2025，不解讀成今日降溫確認，也不以 API generatedAt 覆寫。

同一受限本機／遮蔽 credentials 的 runner 執行：型別檢查通過，**14 passed／3 failed，Deno exit 1**。舊十四個 cases 保持 Green；三個新 case 在預期 assertions 因空 loader 失敗。Agent 只寫 tests／必要型別／空骨架，六欄 SELECT／JOIN Green 交由 owner 輸入；未建立 migration、改正式資料或重跑歷史 suites。

Owner 存好的 SELECT 已在本次整理前驗證 17 passed／0 failed；整理後使用新表／欄名與方法碼的十七個測試亦全通過。**下一步：** 做地圖／照片與 v5／HTTP。Credentials 不寫入 migration／Git／App，也不要求 owner 貼到對話。API-C05 持續待整合，版本目標為 v5；未 commit／push、部署、操作雲端、重設資料庫或修改另一 checkout。

**2026-09-28 資料準備批次的完成證據：** 先後提交 c69b3fd（地址／確認結論）、b47bd4f（降溫欄位）、9e8a04b（來源／權限）；本機 importer 與收尾紀錄提交於 2907708。沒有 push。十一份 migration 已套用，最新為 20260928224500。

| Case | 行為 | 本次實際證據 |
|---|---|---|
| DB-C39 | 原始座標在 geography 轉型前拒絕越界、NaN／Infinity、字串／bool／NULL；保留合法邊界、零與經緯順序 | importer tests 通過；首輪骨架未拒絕十個無效輸入，實際失敗 |
| DB-C40 | 初始 253 筆的名稱／地址／降溫欄位、來源、完整 v4 item 與文件 metadata、原 ID／Apple 配對／照片保留 | 交易內全量比對、永久匯入後唯讀逐筆比對均通過；初輪缺少 records，後續另抓到 document_metadata 缺失並補存 |
| DB-C41 | 同一輸入重試不新增、不換 Place ID、不覆寫後來的本機值；來源內容改變時拒絕 | namespaced 253 筆可重複演練，原資料不動；更正拒絕分支實際拋出預期錯誤。這不是更正發布 API |
| DB-C42 | 資料／來源／首次快照一起提交；中途失敗全部 rollback；引號、反斜線、換行與類 SQL 文字維持資料；只可寫本機 | 故意在寫入後造成 division by zero，確認沒有殘留；remote Docker host/context 拒絕、local context 固定；11 個 importer tests 最終全部通過 |

[import_catalogue.py](scripts/cool_spots/import_catalogue.py) 的起始骨架跑 7 個 tests：19 個 assertion/subtest failures，包含 10 個座標拒絕、6 個內容拒絕、空 catalogue 與兩個缺少匯入資料的案例；接受合法座標／回滾骨架原已通過，不製造 Red。後續合法 address_line1 evidence 在第十份 schema 被拒，新增 SQL cases 後以第十一份修正，見下一段。後加來源變動、引用文字和本機目標守衛的回歸案例直接通過，沒有回溯宣稱 Red。metadata 新 assertion 曾因缺少 key 中斷，補存原文件 schemaVersion／datasetID／generatedAt／sources 後通過。

永久寫入前先以 BEGIN／ROLLBACK、db-import-test- 命名空間跑完整 253 筆演練，確認正式表仍 0 筆。然後執行：

```sh
python3 scripts/cool_spots/import_catalogue.py --apply-local
python3 -m unittest discover -s scripts/cool_spots -p test_import_catalogue.py
SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local --workdir . supabase/tests/database
```

本機永久 transaction 成功；有真實資料後再確認 **11 importer tests passed**、**634 SQL assertions passed／0 failed／0 skipped**。SQL 四個 NaN NOTICE 是既有刻意無效輸入。測試 fixtures 與臨時 role grants 已 rollback，沒有 reset；未重跑拆分前 migration rehearsal、mapping tests、API／Swift 或 JSON Schema 工具（先前環境缺 jsonschema）。本批用 import validation、SQL tests 與全量資料比對驗證，不把它們稱為 HTTP／App 驗收。

最後資料：253 places、253 cool_spots、2 sources、253 source_records／links、5,297 field_evidence、145 accepted map links、3 photo references、253 initial history。GLA 與三個範例標示、raw hash、原始／對照／mapping 快照、全部採用欄位及 metadata 均比對一致。Reader 的 LOGIN／superuser／BYPASSRLS 為 false；postgres 對 reader 的臨時 SET／USAGE 為 false；沒有 location_scope／eligibility_details domain columns。現有 Swift／JSON／handler 檔未變，沒有 API/Auth/Studio 啟動、雲端 SQL、部署或 ViewCoolSpots 編輯。

**該批當時的停止點：** 接通 API 之前；2026-09-29 已由 owner 新指示續接，當前進度與 v5 決策見本節開頭。以下保留各批當時的實際證據。

**2026-09-28 來源儲存 DB-C34–C38：134 assertions Green。** 降溫內容已提交 b47bd4f。第十份 preserve_catalogue_sources 新增七表、關聯、same_place 唯一索引及 RLS／限縮欄位 SELECT，沒有後端登入或 API reader。新表缺失時 Red 為 7 failed／1 skipped。首次 Green 檢查中三個 permission tests 誤用 generated identity 的 UPDATE，先遇到 428C9；改成合法 UPDATE 後各角色實際回 42501，未放寬權限斷言。補上 INSERT 拒絕後 132 項通過。

匯入演練發現 field_key 的初始正規表示式不接受 address_line1。新增兩個獨立 cases，實際 Red 為合法地址鍵被拒、虛構欄位被接受（132 passed／2 failed）；不修改已套用 migration，新增第十一份 validate_evidence_field_keys 改成明確支援清單。最終 **134 passed／0 failed／0 skipped**。正式資料仍由 places／cool_spots 保存；欄位 evidence 不重複保存正式值，catalogue_import_history 只保留首次事件，未宣稱通用更正／審核歷史已完成。

**2026-09-28 降溫內容 DB-C30–C33：Green。** 地址與已確認設計已提交 c69b3fd。新增 cooling_content.test.sql；結構 Red 為 18 failed／2 passed／1 skipped，沒有把缺欄位時未執行的行為算通過。第九份 migration 20260928220000_add_cooling_content.sql 加 places.place_type 與 17 個降溫／使用資訊欄位，不含 location_scope／eligibility_details。沿用 v4 固定代碼、unknown、空設施清單、選填非空白文字、正整數公告分鐘及成對 hours/time zone，不推論營業中。

套用後本批 107 assertions 通過，連同既有四份 suite 共 **500 passed／0 failed／0 skipped**。測試涵蓋合法／非法代碼、NULL 與未知、七種設施及飲水分開、不可巢狀／含 NULL 的設施清單、可清空區域說明／補充、文字原樣保存、停留限制與時間成對；場所與 Cool Spot 身分保持。這是本機 schema Green，沒有 reader／HTTP／iOS 變更或效能宣稱。

**2026-09-28 本輪委託：接 API 前的資料準備。** Owner 同意更新 PRODUCT 的完整結論並要求繼續本機實作與適當 commits。新 storage/API 不採用 location_scope／eligibility_details；保留選填 area_description、帶來源年代的 cooling_details；正式值以 places／cool_spots 為準，來源與歷史須一起保存。field_adoptions／14 表草案不是整體批准，Cooling here 身分及回報資格留待對應批次。原 v4／Swift 相容處理仍待後續，今天不刪 fixture 欄位。

執行順序：先提交已 Green 的地址與設計 checkpoint，再分批完成降溫欄位、來源／配對保存、可重複且不覆寫更正的本機初始匯入。每批保留實際 Red／Green 與資料／權限證據。**在後端登入／唯讀連線、reader、v4 HTTP 回應／免登入 HTTP 實測之前停止**；同樣不開始 iOS 改讀 API。未授權 push、部署、雲端 SQL、reset 或另一 checkout 變更。

以下地址與 Places 記錄是各批次當時證據；393 項是前一輪結果，本輪未為接手／commit 重跑。

**2026-09-28 地址基本驗證：DB-C26–C29 已本機 Green，393 項全通過。** Owner 明確要求「1 你直接幫我做完；2 跟我討論」，因此本批包含 agent 寫 tests、驗證 Red、寫 Green 並套用本機 migration；當時第 2 步的其他欄位／來源／Apple 關係只討論；後來 owner 已委託本文件開頭的 pre-API 批次。起點仍為 Prototyping／edbcd5a 加第七份地址批次的未提交變更。先唯讀確認 history 七份、兩表均 0 筆；未 reset，未重跑歷史測試。

執行前已說明本批規則：未知維持 NULL，六個一般地址欄位拒絕空字串／純空白但保留有內容原文；國家代碼沿用 v4 的兩位 ASCII 大寫字母格式；沒有需求依據的地址長度上限不另外加入。唯讀掃描 250 GLA＋3 社群 JSON，違規地址值為 0；沒有重建 fixture 或 seed。

| Case | 可觀察行為 | 證據 |
|---|---|---|
| DB-C26 | 六個一般地址欄位的 INSERT 各自拒絕空字串、26 種單一空白、混合空白 | 168 項 Green；Red 時全部被接受 |
| DB-C27 | 六欄 UPDATE 各拒絕空字串／混合空白，原地址保持 | 13 項 Green；Red 時 12 次修改被接受，讀回原值也失敗 |
| DB-C28 | 有內容地址保留 Unicode／標點／空白／換行；一字可接受，不套用名稱 300 字上限或截斷 | 5 項在 Red 階段已通過，Green 保持；沒有製造失敗 |
| DB-C29 | country code 拒絕 16 種無效格式的新增／修改，失敗不改原值；合法多國格式可保存及更正 | 37 項 Green；Red 時 33 failed／4 passed。只驗格式，不驗國家名單 |

新增 [place_address_constraints.test.sql](supabase/tests/database/place_address_constraints.test.sql)，共 223 項，以 BEGIN／ROLLBACK 保護本機資料。先執行 `SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local --workdir . supabase/tests/database/place_address_constraints.test.sql`：**9 passed／214 failed，無跳過，exit 1**。失敗 1–181、187–219 為未拋出 23514 或不合格 UPDATE 覆寫原值；這是真正的行為 Red，沒有語法／runner 錯誤。

Agent 用 CLI 建立並填入 [20260928204716_validate_place_addresses.sql](supabase/migrations/20260928204716_validate_place_addresses.sql)，只加六個非空白 CHECK 與 country code 格式 CHECK。執行 `SUPABASE_TELEMETRY_DISABLED=1 supabase migration up --local --workdir .`，exit 0，只套用第八份；先前七份不改寫、不重跑。

Green 指令：

```sh
SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local --workdir . supabase/tests/database/place_address_constraints.test.sql supabase/tests/database/places.test.sql supabase/tests/database/cool_spots.test.sql supabase/tests/database/cool_spots_permissions.test.sql
```

**393 passed／0 failed，無跳過，exit 0**（223＋72＋51＋47）。原地址的 NULL／清空、部分／完整地址、關聯與權限回歸也通過。既有四次 NaN NOTICE 仍屬刻意座標案例。沒有為通過而更動 assertions，無需 refactor；沒有重跑 API／Python／Swift 或拆分前的 migration rehearsal。

最後唯讀核對 history 八份、最新 20260928204716；七個新增 CHECK 的 validated=true，七個地址欄仍 nullable。places／cool_spots 都 0 筆、pgTAP 未保留；postgres 對 reader 的 SET／INHERIT 與 reader 的 extensions USAGE 均 false。資料／暫時授權已 rollback。當時尚未 commit／push；其後地址批次提交於 c69b3fd。未部署、操作雲端或更改 iOS／JSON／ViewCoolSpots。地址格式組合與更正一致性屬後續寫入流程，並未因基本驗證 Green 而完成。

**該批後續：** owner 隨後確認欄位邊界並委託接 API 前的本機工作，見本節開頭。

**2026-09-28 地址批次：DB-C21–C25 已本機 Green，170 項全通過。** 起點為 Prototyping／`edbcd5a`（`Separate Places from Cool Spot records`），working tree clean，相對本機記錄的 origin/Prototyping 領先三個 commits；未 fetch／push。Owner 同意 [PRODUCT 的七個可空地址欄位](PRODUCT.md#2-名稱地址與座標以誰為準)，起初沿用 agent 寫 tests／驗證 Red、owner 輸入核心 SQL；Red 後 owner 明確要求「你直接幫我做吧 給我看結果」，委託 agent 代寫及完成本批 Green。先唯讀確認 Docker database healthy、history 六份、places 仍三欄且兩表皆 0 筆，沒有重設或啟動 API/Auth/Studio。

| Case | 地址批次預期行為 | 本次證據 |
|---|---|---|
| DB-C21 | 七個指定地址欄位使用 text | Green：七項型別通過；先前七項皆因 column does not exist 失敗，為結構 Red |
| DB-C22 | 省略全部地址時可保存，七欄均讀回 NULL，沒有猜測預設值 | Green：兩項通過；Red 時明確跳過 |
| DB-C23 | 部分地址、只有完整文字、全部地址組件含 Unicode 均保存並讀回 | Green：六項通過；Red 時明確跳過 |
| DB-C24 | 更正地址並由呼叫端清除舊完整文字；可全部清回 NULL；Place 事實與 Cool Spot 關聯保留 | Green：四項通過；Red 時明確跳過。不測或宣稱自動清除 formatted |
| DB-C25 | reader 可讀兩種公開 Place 的地址但不能改；anon／authenticated 不能直接讀或改；拒絕後地址不變 | Green：七項通過；Red 時明確跳過 |

在既有 [places.test.sql](supabase/tests/database/places.test.sql) 新增 19 項（原 53 → 72），在 [cool_spots_permissions.test.sql](supabase/tests/database/cool_spots_permissions.test.sql) 新增 7 項（原 40 → 47）。每個新寫入情境使用指定假場所；測試用 BEGIN／ROLLBACK，不匯入真實目錄。執行：

```sh
SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local --workdir . supabase/tests/database/places.test.sql supabase/tests/database/cool_spots_permissions.test.sql
```

**Red 結果：119 項計畫，93 passed／7 failed／19 skipped，exit 1。**原 Places 53 與權限 40 通過；七個失敗皆為缺地址欄位，沒有語法或 harness 錯誤。當時 19 個依賴新欄位的行為尚未驗證，未算 Green。原有四次 NaN NOTICE 屬刻意輸入的座標案例。未重跑未變動的 Cool Spot 51、API／Python／Swift suites，也未重跑只適用拆分前 schema 的 migration rehearsal。

Agent 用 CLI 建立 [20260928201025_add_place_addresses.sql](supabase/migrations/20260928201025_add_place_addresses.sql)，當時為 **0 bytes**、未套用，沒有代寫 Green。Red 後唯讀核對 history 仍六份、address 欄位 0 個、places／cool_spots 都 0 筆、pgTAP 未保留；postgres 對 reader 的 SET／INHERIT 與 reader 的 extensions USAGE 均 false，測試資料與臨時授權已撤回。

**本批 Green（owner 明確委託代寫）：** agent 再次確認第七份仍為空白、本機 history 六份、places 三欄且兩表 0 筆，接著填入完整最小 ALTER TABLE：新增七個 text 欄位，不加 NOT NULL 或預設值。執行 `SUPABASE_TELEMETRY_DISABLED=1 supabase migration up --local --workdir .`，exit 0，只套用 20260928201025_add_place_addresses.sql。沒有改動既有 migration、tests 或 assertions 來取得 Green。

再執行：

```sh
SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local --workdir . supabase/tests/database/places.test.sql supabase/tests/database/cool_spots.test.sql supabase/tests/database/cool_spots_permissions.test.sql
```

**170 passed／0 failed，無跳過，exit 0**：Places 72、Cool Spot 身分／關係 51、permissions 47。四次 NaN NOTICE 為既有刻意無效座標案例。沒有需要的 refactor；未重跑 API／Python／Swift 或舊 schema 的 migration rehearsal。

最後唯讀查核：history 七份、最新 20260928201025；places 十欄，新增七欄皆 text／nullable／無預設值，原 id/name/location 保持。兩表 RLS=true，各保留 reader SELECT policy；PUBLIC／anon／authenticated 無兩表 grants，reader 只有 SELECT。兩表均 0 筆，pgTAP 未保留，postgres 對 reader 的 SET／INHERIT 與 reader 的 extensions USAGE 均 false。

**本批後續：** 基本地址驗證後來由 owner 委託完成，見本文件開頭 DB-C26–C29。格式組合／更正一致性與來源保存仍待後續；本批不是 v4 reader Green。當時尚未 commit；其後地址批次提交於 c69b3fd。未部署、操作雲端、重設資料庫或更改 iOS／JSON／ViewCoolSpots。這次代寫 Green 授權只涵蓋本批，後續仍沿用既有教學約定。

**2026-09-28 後端教學接手核對：** 在 prototype 的 `Prototyping` 確認 HEAD 為 `8a0bae0`，訊息 `Add local Cool Spot database foundation and design notes`；讀取前 working tree clean，相對本機記錄的 origin/Prototyping 領先兩個 commits，未 fetch／push。完整讀取三份 active documents 與 owner 指定的 i-have-adhd／essential-tdd，沿用批次說明、agent 寫 tests／驗證 Red、owner 輸入核心 Green 的覆寫。

Docker 查核只有 `supabase_db_cool-spot-prototype` 運行且 healthy。以 READ ONLY transaction 查得五份 migration history、cool_spots 的 id text／name text／location geography(Point,4326) 三欄皆 NOT NULL、既有主鍵與五個 CHECK、RLS 與 reader SELECT policy／grant；reader 仍為 NOLOGIN、非 superuser、無 BYPASSRLS。cool_spots 為 0 筆，places 不存在。這是本次唯讀狀態證據，沒有重跑歷史 78＋24 或七個 handler tests，也沒有啟動其他服務、套用 migration 或重設資料庫。

接手時程式與 fixture 核對：當時只有五份 migrations，handler 仍使用注入的 load，沒有真實 reader／HTTP 入口；Canning Town Library 的既有 ID、GLA 18、Apple 配對與座標均保留。其後 owner 回覆「1–4 都同意」，最小拆分規則已記入 PRODUCT，下節記錄本批 tests 與 Red。沒有修改 Swift、TypeScript、JSON 或 ViewCoolSpots。

**2026-09-28 Places 拆分批次：owner Green 已儲存，agent 依明確委託在本機套用，驗證通過。** 承接原 DB-C01–C15，依新資料責任調整兩份既有 tests，新增 [places.test.sql](supabase/tests/database/places.test.sql) 與 [migration rehearsal](supabase/tests/migrations/split_places_from_cool_spots.test.sql)。原名稱／座標限制搬到 places 的測試；舊 Cool Spot text ID／原文保存／JOIN 讀回留在 cool_spots；權限測試改用兩表的有效 fixture。既有 C01–C15 的下方 Green 紀錄保留為舊 schema 證據；新版 tests 的通過結果如下。

| Case | 本批可觀察行為 | 本次證據 |
|---|---|---|
| DB-C16 | Place 獨立存在；預設產生不同 UUID v4；拒絕重複／無效／NULL ID，名稱或位置更改不換 ID；名稱與位置沿用原限制 | Green：places suite 53 項全部通過、無跳過；Red 曾為 2 結構失敗／51 跳過 |
| DB-C17 | 舊 Cool Spot ID 經 JOIN 讀回；place_id 必填、唯一且指向存在的 Place，INSERT／UPDATE 均限制；名稱／位置只有 places 一份 | Green：cool_spots suite（含 C18 及舊 ID 回歸）51 項全部通過、無跳過；Red 曾為 4 結構失敗／47 跳過 |
| DB-C18 | 有 Cool Spot 引用時拒絕刪 Place；刪 Cool Spot 保留 Place；修改 Place 事實時兩種 ID 不變 | Green：實際 FK 拒絕刪除、移除 Cool Spot 後 Place 保留及兩種 ID 不變均通過；不回溯宣稱曾有行為 Red |
| DB-C19 | 真正 migration 搬移三筆假資料，保留 UUID 形狀／legacy／帶空白的 Cool Spot ID、名稱、座標和筆數；同名同座標不合併 | Green：永久套用前執行實際 owner SQL，11 項全部通過並 rollback；Red 曾為 2 通過／4 結構失敗／5 跳過 |
| DB-C20 | places 啟用 RLS；anon／authenticated 不能直接存取兩表；reader 可讀有／無 Cool Spot 的 Place 與 JOIN，但不能寫入／清空 | Green：permissions suite 40 項全部通過、無跳過；Red 曾為 2 通過／1 結構失敗／37 跳過 |

第一輪測試有兩個 harness 問題：places 的 schema_ready 別名放錯位置而中斷；Supabase pgTAP runner 只複製測試檔，無法以相對 include 讀取 migration。這些不算產品 Red。Agent 修正 SQL 別名，新增 [test_place_migration.py](scripts/test_place_migration.py) 作為測試執行器：讀取實際 migration（不複製實作），內嵌到既有 BEGIN／ROLLBACK suite，透過指定 Docker database 的 psql 輸出 TAP，由本機 prove 判讀。沒有增加 production SQL 或安裝工具。

修正後執行：

```sh
SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local --workdir . supabase/tests/database/places.test.sql supabase/tests/database/cool_spots.test.sql supabase/tests/database/cool_spots_permissions.test.sql
prove --exec python3 scripts/test_place_migration.py
```

日常 schema tests 共 144 項：2 passed／7 failed／135 skipped，exit 1；migration rehearsal 共 11 項：2 passed／4 failed／5 skipped，exit 1。合計 **4 passed／11 結構失敗／140 skipped**；修正後沒有語法或執行器錯誤，不把缺少 schema 的跳過項目記為已驗證行為。原 78＋24 項沒有另為接手重跑；此次是因 schema 職責改變而執行更新的 tests。

[20260928145903_split_places_from_cool_spots.sql](supabase/migrations/20260928145903_split_places_from_cool_spots.sql) 在 Red 階段由 CLI 建立，當時為 **0 bytes** 且未套用。該次測試後唯讀確認 history 仍為原五份、places 不存在、cool_spots 0 筆、pgTAP 未保留；postgres 對 reader 的 INHERIT／SET 與 reader 的測試 extensions USAGE 均為 false。假資料與暫時設定已 rollback。未重設資料庫、啟動 API/Auth/Studio、執行雲端 SQL、改 iOS／JSON、部署、commit 或 push。

**本批 Green：** owner 儲存 SQL 後明確要求「你幫我 apply」。Agent 讀取實際檔案，確認完整最小拆分、資料搬移與權限內容，不代改 SQL。先執行 `prove --verbose --exec python3 scripts/test_place_migration.py`：**11 passed／0 failed，無跳過，exit 0**。唯讀核對演練後 history 仍五份、places 不存在、cool_spots 0 筆，確認 rollback。再在 prototype 執行 `SUPABASE_TELEMETRY_DISABLED=1 supabase migration up --local --workdir .`，exit 0，僅套用 `20260928145903_split_places_from_cool_spots.sql`。

套用後執行上述三份 database tests：**144 passed／0 failed，無跳過，exit 0**，分別為 places 53、cool_spots 51、permissions 40。四次 Invalid Coordinate NOTICE 對應刻意輸入 NaN 的案例，不是測試失敗。SQL／assertions 無需修正，無需 refactor；沒有重跑未受影響的 API／Python／Swift tests。

最後唯讀核對：history 六份；places 為 id uuid（default gen_random_uuid()）／name text／location geography(Point,4326)，cool_spots 為 id text／place_id uuid，皆 NOT NULL；主鍵／CHECK／UNIQUE／FK 均 validated=true，FK 為 ON DELETE RESTRICT。兩表 RLS=true，各有 reader SELECT policy；PUBLIC／anon／authenticated 無兩表 grants，reader 僅 SELECT。兩表皆 **0 筆**，pgTAP 未保留，postgres 對 reader 的測試 INHERIT／SET 與 reader 的 extensions USAGE 均 false。未改 owner SQL、重設資料庫、操作雲端、啟動 API/Auth/Studio、改 iOS／JSON、部署、commit 或 push。

**本批收尾：** owner 已在本機 psql 用 `\d public.cool_spots`／`\d public.places` 查看兩表，並要求先檢查隱私再提交一個 local commit。pre-application rehearsal 只適用舊 schema，永久套用後不重跑，也不重設資料庫製造舊狀態；後續驗證使用 database 下三份 tests。地址、來源／seed／reader／API-C05 與轉型前座標檢查仍待後續批次。

**Places 拆分提交完成：** owner 授權後已提交 `edbcd5a`，訊息為 `Separate Places from Cool Spot records`，parent 為 `8a0bae0`；提交後 working tree clean，未 push。範圍共九個檔案：三份 active documents、第六份 migration、三份日常 database tests、migration rehearsal 與 Python runner。檢查這九份文字檔，未發現私鑰、憑證／密碼／token 或具名個人 home 路徑；這是本批內容檢查，不是完整安全稽核。另核對 Git 作者／提交者 email，owner 明確接受沿用現有設定；不把實際地址寫入文件，不修改 Git 身分設定或重寫歷史。SQL／tests 未變，沿用上述 144＋11 項實際 Green；未為 commit 重跑，未 push。

**2026-09-28 提交 checkpoint：** owner 要求先整理安全檢查提出的本機路徑與排除規則，再 commit。本批訊息為 `Add local Cool Spot database foundation and design notes`，parent 為 `4ad70e3`；範圍是五份既有 migration、兩份 database tests、Supabase 設定／排除檔、三份 active documents 與 root .gitignore。移除 active documents 中具名 home／本機暫存目錄路徑，補排除私鑰、簽署憑證、資料庫檔與壓縮備份；SQL migrations／tests 與 .env.example 仍可追蹤。沿用 2026-09-27 的 78＋24 項 Green，SQL／API／Swift 未變，不為提交重跑。未 push、部署、操作 Docker／雲端或重寫 Git 歷史；舊快照中的路徑不屬於這次 active-document 清理。

本輪提交前的檢查涵蓋原 12 個待提交檔、Git index、目前追蹤內容及 HEAD 可追溯的 17 個 commits，未確認到真實憑證外洩；這不是完整執行期安全審計，也未逐張檢查歷史截圖／影片。檢查紀錄保存在 repository 外。以下歷史指令的專案絕對路徑改寫為 `.`，表示在 `cool-spot-prototype` 根目錄執行；不代表另一次執行或新測試結果。

**2026-09-28：owner 要求更新整輪討論結論；完整設計集中在 [PRODUCT：場所後端設計結論](PRODUCT.md#場所後端設計結論)。** 核心方向是 places 保存地點、各地點可有 0／1 份目前的 Cool Spot 資訊、多則回報另存，父子關係只屬於 Places。來源／欄位來歷／地圖身分仍分開保留。當時的下一步是確認最小拆分；owner 隨後已同意，DB-C16–C20 已本機 Green、六份 migration 已套用；地址批次 DB-C21–C25 隨後已 Green，第七份套用與 170 項結果見本文件開頭。

目前回報／旅程建議見 [PRODUCT：園內點位與地圖收合](PRODUCT.md#園內點位與地圖收合)：回報歸屬一個 Place，公園頁可彙整本身與子點回報、保留原歸屬；不強迫先選子 Cool Spot。普通公共 Place 的回報資格、選填公開座標、私人 Pin 入口、父子到訪資格及相容遷移仍需確認，不當成已完成或已批准的 UI。Owner 暫定同意地圖先收合細部點位；園內點數與 Cooling here 人數分開，22 個點只是示例。程式查核確認 VisitReport 仍連 spotID、沒有作者／自己的座標；handler tests 使用替身 reader，真實 reader 未實作；within_place 不等於一般父子表。原 A–E click paths 與 dated Green 證據保留，不改成未實作的流程。

JOIN／附近查詢評估已記入 PRODUCT：核心拆表合理，但空間索引、配對唯一性、回報分頁、避免 N+1 與多組一對多 JOIN、查詢計畫及並發測量仍待實作。此次只讀 Mac 專案檔案、參照 PostgreSQL／PostGIS 官方資料並更新三份文件；沒有新的 SQL／效能／API 測試或原生互動證據。SQL／API／iOS／JSON 沒有變更，未操作 Docker 或雲端、未部署、commit 或 push。替換過時的建表／回報提案，保留以下 migration、測試及來源查核的實際證據。

接手前的本機驗證為 2026-09-27：當時五份 owner-written migration 已套用，資料限制 DB-C01–C12 共 78 項、權限 DB-C13–C15 共 24 項均 Green。權限測試的 SET ROLE 前置設定已修正，owner SQL 未改。這批教學於 2026-09-26 起點為 `Prototyping`／`4ad70e3`，當時 working tree clean；2026-09-28 重新核對 HEAD 未變，三份 active documents 已修改，Supabase 設定／migrations／tests 尚未追蹤，比已記錄的 `origin/Prototyping` 多一個 commit，未 fetch 或 push。Owner 要求先教基本概念，已討論 App／API／資料庫分工、表／列／欄、主鍵／外鍵、一對多、SELECT／WHERE／JOIN，以及型別／NULL／限制。對話中的 P1／P2、R1–R3 與訪客留言只是教學假資料，沒有寫入正式資料或代表回報 API 已定案。Canning Town Library 的內部 UUID 在初始 prototype 已存在並由 identity registry 保留；GLA 的 `18` 來自原始 `cs_indoor_site_id`，不是 objectid 或本機列號。

Owner 確認附近／範圍搜尋是確定需求，並接受第一版資料庫採 PostGIS 的方向，具體邊界見 PRODUCT。先前分開 latitude／longitude 的型別示例不是已批准的儲存實作；places／cool_spots 的完整欄位、來源／身分關係、constraints、seed 與 reader 仍需逐批設計。「場所＋降溫資訊＋來源」是三類責任，不是已定案的三張 SQL 表。沿用由 agent 批次寫 tests／驗證 Red、owner 輸入核心 SQL／TypeScript Green 的方式；不逐小測試要求「懂了嗎」。已解釋 migration（記錄資料庫結構變更的 SQL 檔）與 seed（初始資料）的區別，以及 CLI／容器／psql／PostgreSQL 的連線路徑。Owner 回報已完成本機 psql 與 SELECT current_database(), current_user 的練習；此回報不代表 App 已連線。Owner 要求操作前說明目的與影響，操作後解釋結果，維持可理解的邏輯脈絡。

2026-09-27／28 設計查核證據：250 筆 GLA ID 中有 10 個 UUID v4、240 個 UUID v5；3 筆社群範例均為 UUID v4。adapter 使用 registry 保留既有 ID，缺少時以固定 GLA 2025 來源輸入產生 UUID v5，沒有執行會改寫資料的 build 程式。唯讀檢視本機索引時只有 cool_spots_pkey、0 筆場所；未做容量測試。程式確認 Search this area 只收起按鈕，附近查詢仍使用手機已載入的資料。這些查核不代表 places 拆分、索引、來源追蹤或後端搜尋已完成；本次文件整理沒有重跑未修改的測試。

準備階段確認 Deno 2.9.7／TypeScript 6.0.3、Homebrew 7.0.6 可用；當時在 PATH 和常見安裝位置未找到 Supabase CLI、容器環境或 PostgreSQL 工具。Owner 隨後自行安裝並啟動 Docker Desktop。Agent 確認 Docker client／engine 29.8.0 正常，初始沒有容器；以 Homebrew 安裝 Supabase CLI 2.118.0（只新增該 formula，沒有按安裝訊息升級 Xcode 或處理其他 taps）。在本 worktree 執行 `supabase init`，新增 [config.toml](supabase/config.toml) 與 [Supabase local exclusions](supabase/.gitignore)；project_id 為 cool-spot-prototype，保留既有 handler/tests，沒有啟用 IDE 或 plugin hooks。

以 `SUPABASE_TELEMETRY_DISABLED=1 supabase db start --workdir .` 啟動專用本機 PostgreSQL，CLI exit 0，容器 `supabase_db_cool-spot-prototype` healthy。啟動 log 留在系統暫存的受限檔案，不輸出 credentials 到對話或 Git。首次初始化下載資料庫及內部初始化需要的映像；最後只有 database 容器運行，未啟動 API／Auth／Studio 服務。尚無 seed.sql 的 warning 符合未建立初始資料的狀態，不是測試失敗。

在資料庫 tests 前，透過該容器內的 psql 執行唯讀 SQL：PostgreSQL **17.6**；`pg_available_extensions` 顯示 PostGIS **3.3.7**、pgTAP **1.3.3** 可用，兩者當時 installed_version 都是 NULL；public table count 為 **0**。這只證明環境可查詢。雲端資料庫版本未查核，雲端兩個帳戶與 rls_demo_notes 沒有複製到本機。

第一批測試見 [cool_spots.test.sql](supabase/tests/database/cool_spots.test.sql)。先從 id／name／location 三欄開始，完整場所內容與來源關係仍未定案。

| Case | 要驗證的行為 | 目前證據 |
|---|---|---|
| DB-C01 | 存入 UUID 形狀與舊式文字 ID 的兩筆測試場所；讀回相同 ID、名稱、經度與緯度 | Green：寫入與讀回兩個 assertions 都通過；Red 時寫入因缺表失敗、讀回跳過 |
| DB-C02 | 相同 ID 的第二筆資料被拒絕（23505 unique_violation） | Green：確實得到 23505；Red 時是缺表 42P01 |
| DB-C03 | NULL id／name／location 各自被拒絕（23502 not_null_violation） | Green：三項各自得到 23502；Red 時都是缺表 42P01 |
| DB-C04 | 拒絕空字串 ID／名稱（23514 check_violation） | Green：兩項皆取得 23514；Red 時不合格 INSERT 被接受 |
| DB-C05 | 接受 1 字元 ID／名稱、300 字元中文名稱；拒絕 301 字元名稱 | Green：三項通過；Red 時前兩項已通過，301 字元 INSERT 被接受。計算字元，不是 UTF-8 bytes |
| DB-C06 | 修改既有名稱為空字串時也被拒絕 | Green：UPDATE 取得 23514；Red 時空字串更新成功 |
| DB-C07 | PRODUCT 定義的 26 種空白字元，各自及混合成字串作為 ID／名稱時均拒絕 | Green：54 項 INSERT 皆取得 23514；Red 時全部被接受 |
| DB-C08 | 既有 ID／名稱改為純空白時也被拒絕 | Green：兩項 UPDATE 皆取得 23514；各自安排有效初始資料。Red 時更新被接受 |
| DB-C09 | 有內容的 ID／名稱保留周圍空白；帶空白與不帶空白的 ID 不合併 | Green：成功寫入並讀回相同原文；這兩項在 Red 階段也已通過 |
| DB-C10 | 經度 ±180／緯度 ±90 四個組合及 (0, 0) 可存入並原樣讀回 | Green：兩項通過；既有型別已接受合法邊界，沒有為此製造 Red |
| DB-C11 | 空地理點的新增與修改均拒絕 | Green：兩項皆取得 23514；Red 時被接受。POINT EMPTY 不是 NULL |
| DB-C12 | 經度或緯度為 NaN 的新增與修改均拒絕 | Green：四項皆取得 23514；Red 時被接受。每個 UPDATE 自行安排有效初始資料 |
| DB-C13 | 存在 API 專用 reader 角色，場所表啟用 RLS | Green：兩項通過；Red 時角色不存在、RLS 未啟用 |
| DB-C14 | anon／authenticated 均不能直接 SELECT／INSERT／UPDATE／DELETE／TRUNCATE 場所表 | Green：兩項角色身分及十項 42501 拒絕均通過；Red 時十種操作未拋錯 |
| DB-C15 | reader 以無管理特權的 NOLOGIN 角色讀回場所及座標，不能寫入或清空；client／authenticator 不能取得此角色 | Green：十項均通過；修正 transaction 內測試執行者的 SET membership 後完成，沒有跳過 |

Red 階段執行 `SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local supabase/tests/database/cool_spots.test.sql`：**六個 assertions，5 failed／1 skipped，exit 1，Result: FAIL**。失敗皆為 `relation public.cool_spots does not exist`，不是連線或 SQL 語法錯誤；這是缺少資料結構的 **結構 Red**，不能宣稱當時已觀察到錯誤的唯一性／必填限制行為。測試用獨立 ID 與明確的座標期望值，不匯入或更動 bundled JSON；DB-C02 自行安排重複資料，不依賴 C01 成功。測試檔以 BEGIN／ROLLBACK 撤回測試資料。CLI 下載 pg_prove:3.36 執行器並在測試時準備 pgTAP；檔案內的 create extension 回報 already exists。Red 結束後以唯讀 SQL 查核：pgTAP／PostGIS 的 installed_version 皆為 NULL，public table count 為 0；當時沒有留下啟用的 pgTAP、PostGIS 或場所表。

Agent 先以 `supabase migration new create_cool_spots` 建立空白 [20260926221052_create_cool_spots.sql](supabase/migrations/20260926221052_create_cool_spots.sql)。Owner 隨後親手填入並儲存 Green：gis 分組／PostGIS extension，以及 public.cool_spots 的 text primary key、name text not null、location gis.geography(Point, 4326) not null。Agent 讀取確認內容，檢查只有這一份 migration，先解釋存檔與套用的差別，再執行 `SUPABASE_TELEMETRY_DISABLED=1 supabase migration up --local --workdir .`：exit 0，回報該 migration 已套用。Agent 沒有代寫或修改 owner 的核心 SQL。

Green 驗證：執行同一個 `supabase test db --local supabase/tests/database/cool_spots.test.sql` 指令，**Tests=6，全部通過，無跳過，exit 0，Result: PASS**。再以唯讀 SQL 確認 `supabase_migrations.schema_migrations` 記錄版本 20260926221052、PostGIS installed_version 為 3.3.7、pgTAP 為 NULL；cool_spots 三欄的型別與 NOT NULL 符合 migration，表內 **0 筆**，測試資料已 rollback。沒有需要的 refactor，agent 未修改測試或 production Green 來取得通過。

Owner 隨後詢問 migration 與 Git 的關係、同日多份檔案的順序；已說明 migration 是可執行變更腳本，Git 管檔案歷史，資料庫另記已套用版本，Supabase 按檔名時間戳排序。切換 Git commit 不會自動還原資料庫；這輪保留第一份已套用 migration，新增下一份。

文字長度批次：以現有 v4 讀取契約的 id minLength 1、name minLength 1／maxLength 300 作為本批規則，沒有把整包 JSON 當成已批准的資料表設計。唯讀掃描 250 GLA 與三筆社群範例，沒有空白 ID／名稱；最長名稱分別 51／22 字元，沒有改動資料。Agent 說明案例後在同一測試檔新增六個 assertions，再執行 `SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local supabase/tests/database/cool_spots.test.sql`：**12 assertions，8 passed／4 failed，exit 1，Result: FAIL**。原六項與兩個有效邊界案例通過；DB-C04 的兩項、DB-C05 的 301 字元、DB-C06 的空字串更新，皆 caught: no exception／wanted: 23514。這次確實觀察到目前資料庫接受不合格內容，是 **行為 Red**。

Agent 在 Mac prototype 目錄執行 `supabase migration new add_cool_spot_text_constraints`，先建立空白 [20260926225900_add_cool_spot_text_constraints.sql](supabase/migrations/20260926225900_add_cool_spot_text_constraints.sql)，沒有修改第一份 SQL。Red 後的唯讀檢查顯示 migration history 當時只有 20260926221052，表內 0 筆，pg_constraint 只有 cool_spots_pkey，尚無新 CHECK。

文字批次 Green（2026-09-27）：owner 親手填入並回報存好第二份 migration。Agent 讀取確認 ALTER TABLE 只加兩個 CHECK：char_length(id) > 0，以及 char_length(name) BETWEEN 1 AND 300；同時核對 migrations 目錄只有預期兩份，資料庫尚未套用第二份。先向 owner 說明 Mac CLI → Docker 本機 PostgreSQL 的操作位置與影響，再執行 `SUPABASE_TELEMETRY_DISABLED=1 supabase migration up --local --workdir .`：exit 0，log 只套用第二份，第一份沒有重跑。隨後用原本 `supabase test db --local supabase/tests/database/cool_spots.test.sql` 驗證：**Tests=12，全部通過、無跳過，exit 0，Result: PASS**。沒有改寫測試或 owner 的 SQL，沒有需要的 refactor。

Green 後再透過 docker exec／psql 唯讀查核：history 依序有 20260926221052、20260926225900；cool_spots_id_not_empty／cool_spots_name_length 的 CHECK 定義正確且 validated=true，原主鍵保留；表內 **0 筆**，測試資料已撤回。這是資料庫限制的本機驗證，不代表 API 已連線或有正式場所資料。

第二份 migration 只檢查長度；空格本身也是字元。Owner 已同意 PRODUCT 的純空白拒絕／有內容原樣保存規則，第三批已完成下述 Red → Green。座標及場所權限批次也已完成下方 Green；原始輸入範圍／順序、其他場所欄位／來源、seed 與 reader 仍未實作或驗證。三欄及 SQL 權限 Green 不代表完整場所 schema 或 API 可公開使用；真實連線與免登入 HTTP 讀取仍待驗證。

Owner 於 2026-09-27 要求親手操作一次套用 migration，已在第三份完成：agent 說明並寫 tests／驗證 Red，owner 輸入 SQL，再依提供的 Mac Terminal／--local／prototype workdir 指令自行套用。Agent 沒有代為執行 migration up 或 reset，收到回報後才唯讀核對 history 並驗證 tests。

純空白批次 Red（2026-09-27）：唯讀查看 [CoolSpotsResponse.decode](cool-spot/CoolSpotsResponse.swift)，確認先用 whitespacesAndNewlines 驗證、再回傳原 response。另以本機 `xcrun swift -e` 列舉 Foundation 字元集，取得 PRODUCT 記錄的 26 個 code points；這不是 iOS build 或新 Swift suite 證據。PostgreSQL 的 POSIX 空白分類會受 locale 影響，因此預計以明確字元集和 C collation 判斷。唯讀 SELECT 探查確認該表示式拒絕這 26 個單字元及空字串，接受 Library／含中文且有周圍空白的文字；沒有 ALTER TABLE 或套用 production Green。

Agent 在 [cool_spots.test.sql](supabase/tests/database/cool_spots.test.sql) 加入 DB-C07–C09，共新增 58 個 assertions。空白樣本以獨立、明確的整數 code points 建立 transaction 內的暫存表，逐筆測實際 INSERT；另測混合字元、兩個 UPDATE 及原文讀回。執行 `SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local supabase/tests/database/cool_spots.test.sql`：**Tests=70，14 passed／56 failed，無跳過，exit 1，Result: FAIL**。失敗為第 13–68 項，全部 caught: no exception／wanted: 23514，是實際接受純空白值的行為 Red；原 12 項及兩項原文保留測試通過。

隨後在 Mac prototype 目錄執行 `supabase migration new reject_blank_cool_spot_text`，建立當時 **0 bytes** 的 [20260927101339_reject_blank_cool_spot_text.sql](supabase/migrations/20260927101339_reject_blank_cool_spot_text.sql)。當時 owner 尚未輸入或套用，agent 沒有執行 migration up／reset。Red 後唯讀查核：history 只有前兩份、原主鍵及兩個 CHECK 保留、cool_spots 為 **0 筆**。測試資料已 rollback。

純空白批次 Green（2026-09-27）：owner 親手填入 SQL 並執行套用，回報 `Applying migration 20260927101339_reject_blank_cool_spot_text.sql... Local database is up to date.`。Agent 讀取檔案，確認只新增 id／name 的非空白 CHECK；透過本機 docker exec／psql 唯讀確認三個 history 版本均存在，兩個新 CHECK 的 validated=true，原限制保留。執行未改動的 `SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local supabase/tests/database/cool_spots.test.sql`：**Tests=70，70 passed／0 failed，無跳過，exit 0，Result: PASS**。測試後再唯讀查核 cool_spots 為 0 筆，測試資料已 rollback。沒有代寫或修改 owner SQL、沒有修改 tests 來取得通過，無需 refactor。Owner 另詢問是否要指定 migration；已說明 CLI 比對檔名版本與資料庫的已套用紀錄，按順序執行 pending 檔案，先前成功版本會跳過。

座標批次 Red（2026-09-27）：owner 要求下一步後，agent 先讀現有 v4 schema 與 Swift 的 CLLocationCoordinate2DIsValid，再於 Docker PostgreSQL 執行唯讀 SELECT。PostGIS 3.3.7 的 POINT EMPTY 非 NULL 且 ST_IsValid=true；單一座標 NaN 的 ST_IsValid=false。有限越界輸入會在轉 geography 時被調整：POINT(181 51) → POINT(-179 51)、POINT(0 91) → POINT(0 89)；倫敦座標交換前後仍是可表示的點。這些是函式探查，不是匯入/API 驗收；Infinity 文字的初次探查被解析器拒絕，未列入本批 coverage。已先向 owner 說明儲存值檢查與轉型前輸入檢查的差別，再寫 tests。

Agent 在同一 [cool_spots.test.sql](supabase/tests/database/cool_spots.test.sql) 加入 DB-C10–C12 共八項 assertions：有效邊界寫入／讀回兩項，空點及兩個 NaN 軸的 INSERT／UPDATE 共六項。執行 `SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local supabase/tests/database/cool_spots.test.sql`：**Tests=78，72 passed／6 failed，無跳過，exit 1，Result: FAIL**。第 73–78 項全是 caught: no exception／wanted: 23514，確認目前表接受不合格值；原 70 項與有效座標的兩項皆通過。測試仍以獨立 fixture 與 BEGIN／ROLLBACK 保護資料。

Agent 執行 `supabase migration new validate_cool_spot_locations` 建立空白 [20260927104448_validate_cool_spot_locations.sql](supabase/migrations/20260927104448_validate_cool_spot_locations.sql)，準備在對話提供最小 CHECK，讓 owner 輸入；沒有代寫 Green 或套用第四份。Red 後唯讀查核：history 仍只有前三份，主鍵與四個文字 CHECK 保留，cool_spots 為 **0 筆**。轉換前範圍／有限數字檢查與經緯度映射留在未來匯入／寫入入口，不以本批儲存測試宣稱完成。

座標批次 Green（2026-09-27）：owner 回報已輸入並套用第四份 migration，並要求持續說明每個步驟，尤其要指出需由 owner 決定的事項。Agent 讀取實際檔案，確認 CHECK 同時要求 not ST_IsEmpty 與 ST_IsValid，未代改 SQL。以 docker exec／psql 唯讀查核：history 有 20260926221052、20260926225900、20260927101339、20260927104448，cool_spots_location_valid 的 convalidated=true，原限制保留。執行未改動的 `SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local supabase/tests/database/cool_spots.test.sql`：**Tests=78，78 passed／0 failed，無跳過，exit 0，Result: PASS**。四次 Invalid Coordinate NOTICE 對應刻意安排的 NaN INSERT／UPDATE，不是失敗。測試後唯讀確認 cool_spots 為 **0 筆**；沒有重跑 migration、改寫 tests 或需要的 refactor。

權限批次 Red（2026-09-27）：owner 選擇 A，架構規則見 PRODUCT。先前唯讀查核顯示 RLS 關閉、無 policies、anon／authenticated 有表格讀寫權限；cool_spots_reader 角色不存在。Agent 先說明操作位置與 cases，再新增 [cool_spots_permissions.test.sql](supabase/tests/database/cool_spots_permissions.test.sql)。以管理員準備有效且獨立的假場所，SET LOCAL ROLE 實際切換成 anon／authenticated，再執行讀、增、改、刪、清空表；測試最後 ROLLBACK。reader 分支只為 pgTAP 工具授予 transaction 內的 extensions schema usage，不替受測角色補場所或 gis 權限；角色不存在時明確跳過。client 是否能取得 reader 使用 pg_has_role 查核具名角色，避免把測試連線本身的管理員 SET ROLE 權力誤認為 client 權力。

在 Mac prototype 目錄執行 `SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local supabase/tests/database/cool_spots_permissions.test.sql`，由 CLI 連到 Docker 本機 PostgreSQL：**Tests=24，2 passed／12 failed／10 skipped，exit 1，Result: FAIL**。兩個 current_user assertions 通過；角色不存在／RLS 關閉為兩個結構失敗，anon／authenticated 的五種操作各自未拋錯，造成十個 caught: no exception／wanted: 42501 行為失敗。reader 的十個 assertions 尚未執行，不宣稱讀取／唯讀權限已驗證。

Red 後唯讀確認 cool_spots 為 **0 筆**、history 仍為原四個版本，reader 仍不存在。Agent 用 `supabase migration new restrict_cool_spot_access` 建立 [20260927151756_restrict_cool_spot_access.sql](supabase/migrations/20260927151756_restrict_cool_spot_access.sql)，檔案空白且未套用。Agent 已在對話提供完整 Green，但 owner 隨後詢問 reader 是哪種 App 使用者，要求先按 use cases 討論權限，再處理第五份。唯讀確認該檔仍為 0 bytes；本次不修改 tests／migration，不操作 Docker 或雲端資料庫。先說明免登入公開讀取、後端服務角色與 App 帳號的區別，以及回報／私人資料／審核的不同權限需求，再由 owner 恢復實作。先前禁止 client 直接 SELECT 的 Red 是 A 方案的架構邊界，不能當成公開讀取本身是漏洞的證據。Agent 未代寫核心 Green 或更動永久權限。這是本機資料庫 Red，未啟動 Data API、未驗證 HTTP，也未決定真正 reader 的連線憑證設定。

權限討論後 owner 回覆「ok 下一步」，恢復第五份 Green。Agent 先說明目的，再以 Mac 檔案讀取及 Docker psql 唯讀核對：第五份仍為 0 bytes，history 四份、reader 不存在、RLS=false、場所 0 筆。沿用既有 Red，未重跑未改動 tests；再次提供完整 SQL 與 --local 套用指令，由 owner 親手輸入及操作。此時尚未新增權限或取得 Green。未登入的公開 HTTP 讀取留待 API-C05 真實連線驗證。

權限批次 Green（2026-09-27）：owner 回報完成第五份並要求下一步。Agent 讀取 SQL 並以 Docker psql 唯讀確認 history 含 20260927151756、reader 為 NOLOGIN／非 superuser／不 bypass RLS、場所 RLS=true、SELECT policy 只給 reader。未改 owner SQL、未重新套用 migration。執行 `SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local supabase/tests/database/cool_spots.test.sql supabase/tests/database/cool_spots_permissions.test.sql`：原 **78 項通過**；權限前 **15 項通過** 後因 `permission denied to set role "cool_spots_reader"` 中斷，計畫 24 項只執行 15，整次 exit 1／Result: FAIL，不能記為權限 Green。

唯讀診斷定位為測試前置條件：本機 postgres 的 rolsuper=false、rolcreaterole=true；對 reader 的 membership 為 ADMIN=true、INHERIT=false、SET=false，createrole_self_grant 為空。角色能被管理不代表測試連線可以直接 SET ROLE。用 BEGIN／GRANT／SET LOCAL ROLE／ROLLBACK 的最小探查確認，只在 transaction 內授予 current_user SET 權限即可成功切換，回滾後 SET 仍為 false。已有明確 catalog 與失敗訊號，因此沒有擴大成多個無關假設或額外環境重建。Agent 在 permission test 加入必要 helper：`grant cool_spots_reader to current_user with inherit false, set true;`，不給 reader 額外場所權限、不修改任何 assertions 或 migration。

只重跑受影響的 `SUPABASE_TELEMETRY_DISABLED=1 supabase test db --local supabase/tests/database/cool_spots_permissions.test.sql`：**Tests=24，24 passed／0 failed，無跳過，exit 0，Result: PASS**。先前 78 項的程式與資料庫限制未再更動，沒有重複跑。測試後唯讀確認場所 **0 筆**、history 五份、postgres 的測試 SET 權限=false、reader 的測試 extensions schema USAGE=false；臨時權限已撤回。無需 production refactor，沒有宣稱 API 已連線。

來源與 Apple mapping 設計查核（2026-09-27）：owner 已同意來源另建表，但尚未同意其完整欄位、關聯／原始紀錄／Apple 表或第六份 SQL。Owner 接著要求看完整 GLA 原始紀錄，再要求釐清轉換涵蓋範圍、Cool Spot 結構、建表取捨與搜尋重複問題。Agent 使用 domain-modeling 的概念區分方法，沿用現有三份文件，沒有新增 CONTEXT／ADR 或平行進度檔。以下是 source inspection，沒有重跑 tests、匯入資料或操作資料庫。

現況共有三層：GLA Feature 是外部原始格式；[CoolSpotsResponse.Item](cool-spot/CoolSpotsResponse.swift) 是 v4 場所讀取格式；Swift CoolSpot 加入畫面／本機 journey 所需值。當次查核的 SQL public.cool_spots 只有 id/name/location；2026-09-28 拆分後的結構見本文件開頭。不能將 Swift 的 distance、presenceCount、isNearby 或報告彙整當成 GLA 場所欄位照抄入資料庫。

查閱 [adapter](scripts/cool_spots/build_cool_spots.py)、[原始 GeoJSON](data/cool-spots/gla-cool-spaces-2025.geojson)、[v4 fixture](cool-spot/Resources/CoolSpots.prototype.json) 與 schema，並唯讀掃描 250 筆 properties：全部具有相同的 26 個原始欄位，其中 15 個映射到 v4（包含 sourceReferences 的紀錄 ID），11 個沒有獨立 v4 欄位。geometry 另映射為經緯度。下表涵蓋全部 26 個 properties 及 geometry：

| GLA 原始欄位 | 現行 v4 目標／處理 |
|---|---|
| geometry.coordinates | location.longitude = 第一個數值；location.latitude = 第二個數值；不使用 properties.x/y |
| cs_indoor_site_id | sourceReferences.recordID（文字）；透過既有 identity-registry 對回內部 id，不把 GLA 編號當成全域 Cool Spot ID |
| cs_name | name；整理空白；placeType 另外由名稱規則推定並記錄 name_rule |
| cs_address_one / cs_address_two | address.line1 / line2；整理空白，缺少 line1 目前輸出空字串 |
| cs_borough / cs_postcode | address.borough / postalCode；未知保持 null |
| cs_cooling_facilities | coolingFeatures；已知文字轉 code、去重；未識別值記在 mapping dataWarnings，不臆測能力 |
| cs_cooling_facilities_other | coolingDetails；整理空白 |
| cs_opening_hours | hours.text；來源有文字才有 hours，搭配 Europe/London；不計算 Open now，目前場所卡不顯示這段時間 |
| cs_toilets_available | access.toilets：on_site / none / nearby / unknown |
| cs_wheelchair_access | access.wheelchairAccess：yes / no / unknown |
| has_drinking_water / has_seating | access.drinkingWater / seating：yes / no / unknown；不含座位數量或即時空位 |
| is_free_of_charge | access.cost：yes → free，其餘目前 unknown，不推論為付費 |
| is_staffed_when_open | access.staffedWhenOpen：yes / no / unknown |
| cs_max_seating | 只留原始來源；Canning Town 為 20，目前沒有容量欄位 |
| indoor_cooling_temp | 只留原始來源；Canning Town 為 Indoor temperature of 26C or less，不是現在溫度 |
| cs_heat_vulnerable / cs_heat_vulnerable_other | 只留原始來源，不轉成誰才有資格進入；access.eligibility 仍 unknown |
| objectid / Approve / org_name / runtime / Tier | 只留原始來源；Approve 不代表我們後端的審核狀態，runtime 不代表現況已查證時間。Swift 中舊 SourceRecord 型別仍有兼容欄位，但目前 v4 producer 不輸出該 legacy 物件 |
| x / y | 只留原始來源；本輪未確認其座標系統，不拿來取代 geometry |

v4 額外衍生／非 GLA 原欄位：setting=indoors、London/GB、hours.timeZone 來自資料集 context；location.scope、eligibility 與未提供的設施維持 unknown；photos、mapReferences 與 provenance 來自獨立流程。GLA 250 筆 photos 皆空，社群三筆中有一筆非空，不能在 reader 重建時一律丟成空陣列。datasetID 是整包回應識別，與 sourceID／個別場所 id 都不同。

Canning Town 的現行資料串接：Cool Spot id 5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab；GLA sourceID gla-cool-spaces-2025、recordID "18"；Apple Place ID I7E8561E6022ED614，relationship=same_place、verification=reviewed。這來自保留的 2026-09-18 source-reviewed decision，不是本輪重新線上或原生確認。Apple 候選地址為 18 Barking Road，GLA 為 18 Rathbone Market；不能只因地址文字不相同就否定既有有證據的對應。

搜尋程式查核：[PlaceSearch.swift](cool-spot/PlaceSearch.swift) 保留 primary/alternate Apple IDs；PrototypeStore.existingSpot(for:) 只接受現有 Cool Spot ID 或已接受 same_place Apple ID；Explore.searchedPlaces 排除已對應 Cool Spot 的普通 Apple 結果。searchCoolSpots 可用 within_place 找到建物內的降溫區，但 existingSpot 不合併它與整棟建物。無 accepted ID 時不做名稱／距離模糊合併，普通 Apple 結果仍可能與 GLA 條目並列。來源碼中有 alias 去重與 containing-venue 分離的既有測試，這次沒有執行。現存 mapping summary 為 136 auto_matched、7 reviewed_matched、1 reviewed_related、87 needs_review、19 no_candidate；不能宣稱 250 筆都已對上或同名結果永遠不重複。

以上保留的是現有資料轉換與搜尋身分的查核證據。後續資料庫分工及未決項目統一見 [PRODUCT：場所後端設計結論](PRODUCT.md#場所後端設計結論)；不在走查文件另外維護一套表格設計。


2026-09-27 資料庫批次結束時，變更為三份 active documents、兩個 CLI 設定／排除檔、兩份 database tests，以及 owner 輸入並套用的五份 migration；其後已於 2026-09-28 納入 `8a0bae0`。API／Python／Swift tests 未因這次資料庫批次而重跑。當時沒有 seed／iOS／JSON 改動，沒有 Supabase login/link、操作雲端 SQL、部署、commit、push 或修改 ViewCoolSpots。API-C05 真實 reader／回應整合仍待實作。

**2026-09-26：Owner 要求提交目前批次。** Commit 訊息為 `Add local Cool Spots API handler and replace catalogue naming`，parent 為 `4b8f828`。範圍包含本機 handler／七個 tests、Swift／JSON／工具改名與舊資料相容、環境檔保護及現行文件。沿用下方 2026-09-25 的測試證據；程式未再改動，不為 commit 重跑測試。沒有部署、push 或修改 ViewCoolSpots；API-C05 仍未開始。

**2026-09-25：Owner 委託全面命名調整，已實作與驗證。** 公開降溫場所資源稱為 Cool Spot；一般 Apple Maps 結果、私人 Pin、待審核提案仍是不同概念。API 清單 handler 改為 `createListCoolSpotsHandler`，完整讀取回應改為 `CoolSpotsResponse`／`coolSpotsResponse`，資料集識別欄位改為 `datasetID`，每個場所原本的 `id` 不變。Swift、TypeScript、fixture、schema、資料處理腳本、Xcode references 及現行文件路徑已同步更新；相關路徑見 AGENTS code map。新 JSON producer 為 v4；Swift 保留 v1–v3 讀取，舊本機發布欄位也能遷移為 `publishedCoolSpotRecords`，journey 儲存位置不變。舊 literal 只留在相容處理、回歸測試及原有 QA 啟動參數 alias；Xcode 系統設定名稱、歷史 snapshot 與歷史 log 路徑保留原文。未把資料來源的歷史上架紀錄解釋為目前仍涼爽的保證；三筆社群範例標示不變。

驗證：Deno **7 passed／0 failed**；Python 配對規則 **11 passed**；v4 JSON Schema、250 GLA＋3 社群、來源／ID／配對／照片不變量通過。預設與 bundled Python 均缺少 jsonschema，改用 `/tmp/cool-spot-naming-validation` 獨立環境（jsonschema 4.26.0）完成 schema 驗證，未改全域 Python。與改名前逐值比較，兩份 app fixture 及完整 mapping 僅變更頂層版本／識別 key；raw GLA SHA-256 及其餘 11 個來源／registry／audit 檔 bytes 不變。

在新建 **Cool Spot Naming QA**（iPhone 17 Pro Max／iOS 26.4，`A70648F1-74A6-4E5E-9CE3-D4323754D0CB`）執行必要的 app/test 編譯與模型測試：**88 passed／0 failed**，log `/tmp/cool-spot-naming-tests.log`。兩個新增回歸測試涵蓋 v4 輸出與 v1–v3 舊 key 讀取、舊本機發布資料載入／存新 key／重開保留。此次是明確委託的相容性 refactor，不宣稱新增功能的 Red → Green 證據。只使用隔離測試資料；沒有替換 owner 的 app、執行原生互動走查或裝置矩陣。API-C05、部署與登入接線仍未開始；未修改 ViewCoolSpots，未 commit／push。

**2026-09-25：API 錯誤／方法限制批次 Red → Green，以及本機設定保護。** 已加入 API-C04 的 POST／PUT／PATCH／DELETE 四個參數化測試，和既有 API-C03 一起驗證。執行 `deno test --no-lock supabase/functions/cool-spots/handler_test.ts`：**2 passed／5 failed**。C01／C02 通過；C03 因 reader 的錯誤直接傳出而失敗；四個 C04 都回傳 200、預期 405。Red 階段尚未到達 Allow header、JSON body 與 reader 呼叫數 assertions。隨後 owner 親手輸入並儲存完整 Green，回報七個測試通過；agent 讀取實際 handler.ts，確認先以 method guard 拒絕非 GET，再以 try/catch 處理讀取，並用相同指令獨立驗證 **7 passed／0 failed**。所有 assertions 已到達並通過。無需重構，agent 未修改 production Green。下一步 API-C05 真實資料庫／Swift 整合尚未開始。

設定保護：`.gitignore` 新增 `.env`／`.env.*`，保留 `!.env.example`；排除 `supabase/.temp/` 與 `supabase/.branches/`。新增 [.env.example](.env.example)，只含假 project URL 與 publishable key placeholder，標明目前單元測試不讀取此檔。以 `git check-ignore --no-index` 驗證 root／nested env 被排除，兩層 `.env.example` 和 handler.ts 仍可追蹤，CLI local state 被排除；目前沒有已追蹤的非範本 env 檔。這不是完整 Git 歷史 secret scan，沒有填入真實 key、建立實際 .env、連線、部署、commit 或 push。測試格式與 diff whitespace 檢查通過。

**2026-09-24：Owner 完成 Supabase Auth／SQL／RLS 入門實驗。** Owner 已建立 Supabase 雲端專案，並在 Authentication → Users 手動建立兩個 email／password 測試帳號 A、B。建立畫面使用 Free organization、London region；指引為開啟 Data API、關閉自動暴露新表、開啟自動 RLS，agent 沒有讀取雲端設定確認最終 toggle 狀態。帳號、密碼、project keys 與 session tokens 不記入本文件。這是獨立練習，未開始實作 Cool Spot 資料表或接上 iOS。

| 實驗 | 實際證據與結果 |
|---|---|
| 建立帳號與 SQL 查詢 | Owner 回報 SQL Editor 查到剛建立的 `auth.users` 紀錄。A 的 Terminal 截圖顯示 `Signed in` 與 user ID；之後 owner 回報 B 也能登入。 |
| 錯誤密碼 | Owner 依指引重跑登入，確認錯誤密碼被拒絕。不是自動化測試結果。 |
| 練習資料存在 | Owner 在 SQL Editor 執行建表／seed 指引，回報看到 A、B 各一筆筆記。表為 `public.rls_demo_notes`，欄位為 `id`、`owner_id`、`body`；`owner_id` references `auth.users(id)` with `on delete cascade`。 |
| 未有 SELECT policy | 指引明確啟用 RLS、撤銷 PUBLIC／anon／authenticated 既有 table grants，只授予 authenticated SELECT。Owner 用 A 的真實登入 token 呼叫未加 owner filter 的 Data API GET，確認回傳 `[]` 與 HTTP 200。SQL Editor 的管理者查詢仍可見兩筆，不以管理者查詢驗證 RLS。 |
| 只讀取自己的資料 | Owner 執行 policy `Users can read their own demo notes`：`FOR SELECT TO authenticated USING ((select auth.uid()) = owner_id)`。隨後用同一段登入＋GET 指令分別以 A／B 重跑；owner 回報兩者均符合只看到本人那筆筆記的預期。 |

指令呼叫 `/auth/v1/token?grant_type=password` 登入，再以 publishable key 與該使用者的 Bearer token 呼叫 `/rest/v1/rls_demo_notes?select=owner_id,body&order=body`。密碼隱藏輸入，登入 JSON 留在 subshell 記憶體；token 經 stdin headers 傳入 curl，畫面只顯示 user ID、查詢資料與 HTTP status。Agent 的本機語法檢查和成功／失敗模擬 HTTP 檢查通過；**實際雲端結果依據 owner 操作回報**，agent 未以 credentials 連線重驗。未測匿名讀取、INSERT／UPDATE／DELETE、token lifecycle 或效能；不把此練習列為完整安全驗證。

SQL 目前由 owner 在雲端 SQL Editor 執行，尚未存為 repository migration，也未建立正式 Cool Spot schema／seed 或 iOS Auth 接線。Owner 隨後安裝 Deno，並確認理解 API-C01「查詢成功但沒有場所」的情境；agent 補上 TypeScript handler 最小骨架並驗證行為 Red，owner 親手輸入並儲存 Green 後，agent 驗證 **1 passed／0 failed**，詳見下方。尚未連接資料庫或部署 API。這輪沒有修改 Swift、owner 模擬器資料或 ViewCoolSpots，沒有執行 app build／tests、commit 或 push。

**2026-09-23：連線 prototype 範圍確認與第一個 API test 準備。** Owner 已完成 grilling 共識確認並要求繼續。在 Prototyping 接入 Supabase PostgreSQL/Auth、自寫 TypeScript Edge Functions API；場所與回報皆由 API 讀取。先以兩個預建帳戶及服務端測試到訪資格驗證 Report，之後接場所提案／審核／發布。免費方案優先，月費上限 GBP 25；具體產品規則見 PRODUCT 的 Agreed connected prototype slice。這不是 ViewCoolSpots 的重建進度。

本輪起點 HEAD `4b8f828`、tracked working tree clean。唯讀核對發現現有 VisitReport 沒有作者 ID，所有本機回報均視為自己的，私人資料使用全裝置 snapshot；登入接線必須同時隔離帳戶資料，既有本機紀錄不自動上傳或歸戶。既有 questionnaire、草稿、期限及排序規則沿用；未修改 Swift 或 owner 裝置資料。

第一組 API cases（2026-09-25 起依相近概念分批處理，保留各 case ID）：

| ID | 可觀察行為 | 狀態 |
|---|---|---|
| API-C01 | 公開 GET 成功但無場所時，回傳 HTTP 200、JSON content type 與 v4 空 items 清單回應 | 2026-09-24 Red：實際 501／預期 200；owner 輸入並儲存 Green 後，1 passed／0 failed；無需重構；僅本機替身資料驗證 |
| API-C02 | 成功讀取時，保留 Cool Spot list metadata、場所 ID、items 內容及來源資訊 | Owner 確認通過；2026-09-25 新批次執行時 agent 亦驗證通過，未改 production 或製造 Red |
| API-C03 | Reader 失敗時，回傳可辨識的服務失敗，不冒充成功空結果或洩露內部錯誤 | 2026-09-25 行為 Red：reader 錯誤直接傳出，未產生預期 500 JSON；Owner 輸入 Green 後 agent 驗證通過；全批 7 passed／0 failed |
| API-C04 | 不支援的 HTTP method 被拒絕，且不觸發 Cool Spot list 載入 | 2026-09-25 POST／PUT／PATCH／DELETE 四個案例 Red：實際 200／預期 405；預期另含 Allow: GET、固定 JSON 錯誤與零次 load；Owner 輸入 Green 後 agent 驗證通過；全批 7 passed／0 failed |
| API-C05 | 真實 PostgreSQL reader、免登入 HTTP 與新版 Swift decoder 的 v5 讀取契約相容 | 2026-10-01 跨層讀取已驗證：DB-C77–C78／API-C06–C11 的後端 reader／HTTP，加上 IOS-API-C01–C02 的真正 Swift URLSession／v5 decoder，兩項本機整合通過；App UI／store 接線仍是下一批，未宣稱畫面或部署完成 |

以下使用目前命名描述 API-C01–C04；最初 Red／Green 的 fixture 為 v3，2026-09-25 改名時升為 v4。測試介面為 `createListCoolSpotsHandler(reader)` 產生 Request → Response handler，reader 提供非同步 `load()`；API-C01 使用可控制的空 Cool Spot list 替身，不存取 Supabase、網路或使用者資料。測試檔為 [handler_test.ts](supabase/functions/cool-spots/handler_test.ts)。2026-09-24 已核對 Deno 2.9.7／TypeScript 6.0.3。第一次執行 `deno test --no-lock supabase/functions/cool-spots/handler_test.ts` 因缺少 handler.ts 而 TS2307 型別檢查失敗，未執行 test body，不算行為 Red。Owner 隨後表示理解；agent 新增 [handler.ts](supabase/functions/cool-spots/handler.ts) 最小骨架，接收 reader／Request 但僅回傳 HTTP 501。以相同指令重跑，型別檢查通過並執行一個測試，在 status assertion 失敗：`501 !== 200`，結果 **0 passed／1 failed，行為 Red 已驗證**。該次尚未到達 JSON content type／body assertions。

Owner 親手輸入 Green，完成儲存後 agent 重新讀取檔案確認：`await reader.load()` 取得 Cool Spot list，`Response.json(coolSpotsResponse, { status: 200 })` 回傳資料。同一測試指令結果 **1 passed／0 failed**，HTTP status、JSON content type 與完整空 Cool Spot list body 三個 assertions 均通過。先前一次 owner 回報完成後，磁碟仍為 501 骨架，重跑仍失敗；僅在讀到實際儲存的 Green 並執行成功後才記錄通過。程式目前簡短清楚，無需重構，agent 未代寫 Green 或做 refactor。`Promise<unknown>` 只描述資料來源可非同步回傳值，尚未定義或驗證完整 v3 TypeScript schema。API-C02 隨後已寫入，owner 執行回報見下一段；資料來源失敗與 method 限制的批次 Red → Green 見本輪起點；未連線或部署。2026-09-23 準備當日未建立雲端資源、commit 或 push。

API-C02：在同一個 handler_test.ts 加入 「成功時保留完整清單回應」測試（當時為 v3）。透過 JSON import 沿用 [CommunityCoolSpots.prototype.json](cool-spot/Resources/CommunityCoolSpots.prototype.json) 的三筆範例，未另定縮減場所 schema。測試先確認 fixture 非空；reader 回傳 `structuredClone(coolSpotsResponse)`，避免 handler 若修改輸入時同時改動預期值。Assertions 檢查 HTTP 200、JSON content type，以及完整 Cool Spot list 深度相等，包含 metadata、場所內容、來源、照片與 map references。這是回應資料保留測試，不驗證 schema 正確性、照片網址可連線或真實場所現況。2026-09-25 owner 明確確認兩個測試已通過；最初依 owner 本機執行回報記錄；在隨後新增 C03／C04 的七個測試批次中，agent 也實際確認 C02 通過。現有 handler 已涵蓋此 case，本步沒有新增 Red、修改 production code 或做 refactor。不要再將此 case 說成尚未執行，或要求 owner 重複回報同一階段。

API-C03（2026-09-25）：新增 「讀取失敗回傳通用 JSON 錯誤」測試。假的 reader.load 拋出 `Database connection failed: internal diagnostic`，模擬資料來源讀取失敗；本步提出的具體回應預期為 HTTP 500、application/json，以及完整 body `{"error":{"code":"cool_spots_load_failed"}}`。完整 body 比較也防止把內部錯誤細節加進回應。這是本機替身，不曾中斷真實資料庫。已與 C04 一起執行，觀察到錯誤直接傳出，行為 Red 確認；其後 owner 已加入 catch／Green，agent 獨立確認七個測試通過。Owner 要求相關案例一批說明、測試，不再逐個等待「懂了」。C04 以同一段測試對 POST／PUT／PATCH／DELETE 分別建立 Request；預期 405、Allow: GET、application/json、完整 body {"error":{"code":"method_not_allowed"}}，並確認 reader.load 呼叫數為零。Red 時皆先在 status assertion 失敗；owner 輸入 Green 後，包含零次 load 在內的 assertions 全部通過。這批只驗證所列四種 method；HEAD／OPTIONS 或瀏覽器 CORS 不在這次測試證據內。

Owner 選擇的合作方式（2026-09-25 更新）：同一概念的 cases 一批說明、由 agent 寫 tests 並一起驗證 Red，再提供一份完整的最小 Green，仍由 owner 親手輸入 SQL／API 核心實作。取消逐 test 的理解確認停頓；遇到實質未定決策或 owner 要求解釋時才停下釐清。這次速度調整本身沒有授權 agent 代寫 Green 或 refactor；隨後 owner 明確委託的全面命名 refactor 是獨立授權，新功能仍沿用教學協作方式。2026-09-25 也研究選型與地圖 API 邊界，當日 PostGIS／bbox／radius 尚屬候選；沒有地理查詢實作或效能測量。

目前 app 程式基準：`42c0905` — `Improve GLA-to-Apple place matching and Cool Spot discovery`（2026-09-23，owner 委託提交）。16 個檔案包含搜尋排序／場館內降溫區發現、保守配對規則、已核對連結、查詢／抽查資料、測試、互動報表工具、PRODUCT 與 owner 要求的資料討論快照。未 push，未為 commit 重跑測試；staged diff 檢查通過。ViewCoolSpots 未改；此程式基準不代表後續文件 commit 的 HEAD。

**2026-09-23：文件校正。** 依目前程式與目錄更新下方 A–E 現行步驟：改用正常啟動可找到的地點、明確區分持久化與預覽模式、修正審核控制及跨案例前提。40 個案例編號與以下有日期的歷史紀錄保留。本次只核對文件／程式、連結與編號，沒有執行 App、重跑測試或新增 owner 通過紀錄。這兩份文件在 Prototyping 已受 Git 追蹤，依 owner 要求一起提交。

**2026-09-19：十筆真實搜尋／地點配對抽查（ec9fbf9 之上的變更，2026-09-23 提交為 42c0905）。** Owner 授權挑十筆代表案例，確認搜尋 → 正確地點 → 降溫卡／Place details。新增只讀、序列查詢的 `AuditDiscovery.swift`；真實名稱搜尋與必要的地址補查存於 `data/cool-spots/apple-discovery-sample.json`，不把 API 回傳視為原生 UI 驗證。十筆案例及逐筆結果見 `data/cool-spots/discovery-cases.json`、`data/cool-spots/discovery-audit.json`。

修正：地址限定的 Street/St 正規化、門牌在第二行仍參與衝突檢查、公共交通／停車場／廁所候選不可自動當場所。原生 Beckton 搜尋重現兩筆相同圖書館，查 Newham 官方同址別名後接受連結。Green Street 新名稱查詢找到 337–341 Green Street 的正確 ID，拒絕 1.1 km 外的 7 Green Street；Willesden Green 採用官方 95 High Road 的 The Library，保留公車站、Library of Things、牙醫為不同身份；Harold Hill 以地址找到正確 Salvation Army 分點，系統卡電話／網站亦與官方相同，Apple 的 Thrift Store 分類未覆寫 GLA。Ham Library 的縮寫解決；同規則另外改善 Hampton Hill。Streatham 大廳只建立 within_place → 場館詳情，搜尋場館能列出大廳，場所身份不合併。實際搜尋 Ham Library 發現完整名稱埋在其他結果後，已改完整名稱優先。來源事實、250 UUID／座標皆未更動。

限定原生證據：只用 **Cool Spot Contract QA / iPhone 17 Pro Max / iOS 26.4**（D3C4BAE1-F7BE-4D7B-AF0C-A23744C41852），正常持久化 store。十筆均由 Explore 輸入搜尋 → 點 GLA 結果 → 地圖移到來源座標 → 半卡；八笔有已核准連結的 Place details 均實際開卡並讀名稱／地址。Canning Town、Custom House、Beckton、Ham、Green Street、Willesden Green、Harold Hill 為同場所，Streatham 為所屬場館；後者在搜尋場館時可找到大廳。最終排序版本已原生看到 Ham Library 第一筆。Horniman 原生仍有 GLA／Apple 兩筆，未核准身份仍是限制；藥學博物館查無 Apple 場所，GLA 卡可開、没有 Place details，另查 66–68 East Smithfield 地址距 GLA 57 m，沒有擅改來源座標。七個同場所並不代表即時條件或入口位置已實地查證。完整250結果為 143 同場所＋1 所屬場館、87 待判定、19 查無候選；不是144筆皆同一身份。

驗證：Python 三個新增案例先失敗再修正，最終 **11 passed**；最終相關 Swift **7 passed, 0 failures**，含三個新增案例，log `/tmp/coolspot-discovery-final-tests.log`。初次 test 編譯因 optional sourceReferences 缺少 `?` 失敗，修正後相關六項通過；後續排序修正再跑七項，不把初次失敗算通過。v3 schema、250 GLA＋3 社群、穩定 ID、來源 facts 不變與來源保留檢查通過。安裝前 `/tmp/coolspot-discovery-backup` 備份本機資料，最終既有 preferences 原鍵值及 Documents／Application Support 檔案逐值／逐檔一致。未送出提案、未改收藏、未操作 owner 其他模擬器。結果總覽支援本輪10筆、完整250筆與待處理篩選，關係與原生限制分開呈現。未跑完整 suite／裝置矩陣；未修改 ViewCoolSpots。當日未 commit/push；2026-09-23 按 owner 要求提交為 42c0905，未 push。

**2026-09-18：欄位契約修正與本機發布（已納入 ec9fbf9）。** Owner 授權修正逐欄稽核缺口。schema v3 保留 Water nearby、Limited seating、附近／不在現場／沒有廁所，以及 no_stated_limit／unknown／正整數分鐘；Other 與未知類型分開。公開補充使用 additionalInformation，特定區域使用 areaDescription；舊 instructions／postedStayLimitMinutes 可讀不再輸出。GLA 未逐筆提供的 scope／eligibility 保留 unknown，下載時間不再取 filesystem mtime，改為 hash-bound manifest（舊下載時間為 null）。三個社群範例移至 CommunityCoolSpots.prototype.json，與 250 GLA 共用 decoder；既有 UUID 與 133 自動／4 覆核／94 待覆核／19 無候選配對結果不變。

送審提案／狀態、已發布場所與照片均在正常啟動重開後保留。圖片原檔／縮圖放獨立 device-local 檔案，JSON/preferences 不塞圖片 bytes。You → Settings → Prototype controls → Publish locally 僅模擬本機審核決策；更新只套用 changed fields，保留其他 GLA 事實、身份、visitor evidence、presence 與私人資料；衝突為 Action needed，重複 Publish 不建立重複紀錄／照片。GLA 有本機修改會標 Local edits，欄位 evidence 保留 source record ID 和 recording time。移除僅改標籤、沒有資料套用的 Merge 控制，重複地點保留原 Review update 路徑。可填選項沒有增加新問題，只將 Toilets 原本 Yes/No 改為清楚的地點／可用性選項。未發布或拒絕的提案不進入公开卡；修改理由不公開，public note 在 More information 收合區。Optional area text 不會把已選場所拆成另一筆；只有明確 specific_area + within_place 的資料才引用父場所詳情而不合併身份。

驗證：`/tmp/cool-spot-contract-final-tests.log` **83 passed, 0 failed**（8 個新增測試涵蓋發布／重開／照片／欄位保留／衝突／來源／地址未知／區域身份／舊欄位相容等）；最後 Local edits 文案另以兩個相關模型測試驗證，`/tmp/cool-spot-contract-attribution-tests.log` **2 passed**。GLA 配對規則 8 passed；v3 Schema 驗证 250 GLA + 3 社群例子及 Swift 實際產生、原生提交流程保存的 JSON 皆通過。初次完整測試有一個案例使用了 MapKit 不接受的假 identifier，修正成合法格式後再跑全套；不將初次失敗算作通過。必要的 app/test 編譯成功，未跑裝置／字級／外觀矩陣。

原生：僅新建 **Cool Spot Contract QA**（iPhone 17 Pro Max / iOS 26.4，UDID D3C4BAE1-F7BE-4D7B-AF0C-A23744C41852）。正常持久化 store 的 Example Community Room → Suggest an edit：選 Water nearby、Limited seating、Toilets nearby、輸入 TEST PUBLIC NOTE、從系統 picker 選事先加入該 QA 相簿的示意照片 → Send for review。重開後 In review 保留；Prototype controls → Publish locally → 再重開：同一 ID 的卡顯示 Limited seating、Water nearby、Toilets nearby、More information 下的 TEST PUBLIC NOTE；原兩則 visitor reports／兩人基準保留，Photos 從 3 變 4，See all → 第四張可正常打開並標 Community photo · Local demo。圖片 `/tmp/cool-spot-contract-evidence/published-photo.png`，原生實際發布 JSON `/tmp/cool-spot-contract-evidence/native-published-item.json`。最終版 Canning Town Library 卡的名稱／地址／GLA 2025、AC／水／免費座位及既有 Place details 等入口仍在；沒有無依據的 Open to everyone 或已移除的 hours。填寫時工具小寫輸入出現鍵盤轉碼異常，改用全大寫測試文字後確認 Your changes 有正確內容，不將 AX setValue 的暫時畫面文字當成已保存答案。

未修改 owner 既有模擬器資料、ViewCoolSpots；2026-09-19 依 owner 要求 commit 為 ec9fbf9，未 push。這是有實際資料套用的本機 prototype，沒有伺服器審核、遠端照片上傳或跨裝置同步；不是 250 地點現況逐筆驗證。A–E 40 個編號保留，B06/B11/E01 路徑與 PRODUCT 已更新。

**2026-09-15 owner 指示：** Prototype 只在 iPhone 17 Pro Max 做簡短互動與必要編譯確認；不跑 iPad、多尺寸、Dynamic Type／外觀矩陣。下方歷史裝置證據不代表需要重跑。

**2026-09-18：Photos B、完整 GLA 目錄與配對。** Owner 指定先研究 API 設計，再實作 B，將所有 Cool Spaces 轉為 Cool Spot 並交付完整 JSON／可查看的配對結果。正常啟動已有 250 個 GLA 2025 場所加 3 個既有社群範例。新 producer schema v2／adapter 支援來源參照、欄位 provenance、結構地址、explicit unknown、photos 與已接受 mapReferences；原十筆 UUID 保留。原始 snapshot／校驗碼、兩輪名稱搜尋及舊 ID 的重新解析均保留。結果為 133 自動接受、4 筆 Codex 另查官方來源後接受、94 筆候選待核對、19 筆查無候選，沒有尚未查詢或服務失敗的紀錄。四筆覆核有來源 fingerprint／candidate snapshot；不是 owner 人工驗收。完整輸出為 `data/cool-spots/cool-spots-mapping.json`，app response 不帶候選稽核資料。76 筆有分類／未辨識降溫方式的轉換提醒，保留原資料而非補猜。

B 的操作：搜尋 **Example Community Room → 照片縮圖 → 全螢幕照片 → Next／Previous → Done**；**See all → Photos 相簿 → 選照片 → Done → Back**。照片在 cooling/access 摘要後、Facilities & accessibility 前，最多三張 108 pt 縮圖；GLA 無圖不放空殼。三張圖均為產生的示意素材，caption/attribution 標明 illustration，沒有捏造拍攝時間。相簿兩欄初次檢查發現圖片壓縮欄距，已以明確欄寬修正後原生重看。使用者表單 photo 仍是本機待審提案，沒有新增上傳、自動發佈或遠端媒體服務。

限定證據：iPhone 17 Pro Max／Cool Spot Layout QA 正常持久化啟動，縮圖開對應照片、Next 更新照片與說明、See all 開相簿、第三張圖為 3 of 3 且 Next disabled、相簿 Back 返回相同場所卡均已原生確認。滑動手勢工具未可靠改頁，不將其列為通過證據；原生 TabView 支援分頁，Next/Previous 的實際操作已確認。`/tmp/coolspot-photos-catalogue-final-tests.log` 56 項 CoolSpotTests 通過；最後來源適配改動另以三項相關測試檢查（來源 community/unknown、照片 decoder、A/B/C 搜尋），三項均通過，結果見 `/tmp/coolspot-catalogue-source-adapter-tests.log`。配對規則 8 測試通過；JSON Schema、250 個唯一 ID/來源覆蓋、十個既有 UUID、accepted links 無重複、來源欄位指標及圖片 JSON 驗證通過。建置 `/tmp/coolspot-photos-catalogue-final-build.log` 成功；最終 source-adapter 測試也會編譯 app。這不是遠端服務整合、所有 250 個場所原生逐點檢查或完整 journey 驗收。

更新前備份 `/tmp/coolspot-photos-catalogue-backup-20260918-152356`。正常安裝後 app 既有 preference（journey JSON）與 Documents 逐值／逐檔核對保留，沒有新增收藏、回報、presence 或改私人筆記。結果總覽已在瀏覽器檢查狀態篩選、Canning 搜尋及清除後 250 筆清單；顯示候選差異、來源、查詢與 review 原因，完整候選仍在 JSON。沒有跑 iPad／多尺寸／字級矩陣。

**2026-09-18：淡分隔線與第一區入口（已納入 8674c98）。** Owner 比較互動稿後授權實作：場所資訊、Visitor reports、目前人數／分享操作之間均使用 native Divider，線上下各 16 pt；照片與私人筆記有內容才產生下一區及分隔線。Place details／View nearby streets 同在第一區，街景加入 binoculars；較輕、無右箭頭的 Suggest an edit 位於第一區末端。人數及分享操作共用白底，移除內層藍底及已分享狀態內的額外分隔線。普通場所採同一組 Place details／街景，再以淡線分開 Add cooling information 與有內容的私人筆記。Report a problem 原本僅顯示服務不可用，已移除。未變更 MapKit 請求、收藏、回報／presence 資格或資料。

限定驗證：建置成功 `/tmp/cool-spot-section-layout-build.log`。僅在 Cool Spot Layout QA／iPhone 17 Pro Max 正常啟動：Tate Modern 第一區入口順序／圖示／淡線可見，街景展開取得 Look Around 後可收合；Suggest an edit 開到既有 Update place details，未修改／送出，關閉返回。John Harvard Library 展開卡同時確認 1–2、2–3 的淡線，以及白底人數／Here to cool down?。截圖 `/tmp/cool-spot-section-layout-evidence/tate-first-section.png` 與 `gla-section-dividers.png`。Tate 下方的原生 scroll/drag 工具未可靠移動，改以同一實作的較短 GLA 卡確認第三區，沒有因此調整 app 的捲動程式。沒有宣稱已重測所有分支、ordinary 卡或私人筆記的原生畫面；條件渲染已 source review。純 UI 調整未新增／重跑模型測試，也未跑裝置矩陣。安裝前備份 系統暫存目錄中的 `cool-spot-section-layout-backup-*`（本機路徑已隱去）；安裝／操作後既有 preferences 的 journey JSON 與 3 個 Documents／Application Support 檔案比對一致。A01／B09／E05 現行步驟已更新，40 個 A–E 編號保留。ViewCoolSpots 未改；後續依 owner 要求提交為 `8674c98`，未 push。

**2026-09-18：場所資訊入口圖示。** Owner 確認後，Facilities & accessibility 加 list.bullet、Read all reports 加 text.bubble；與 Place details 共用可縮放 20 pt 圖示欄及 8 pt 文字間距，保留文字／原有箭頭，區塊標題不加圖示。建置成功 `/tmp/cool-spot-detail-icons-build.log`；只在 iPhone 17 Pro Max 的 Tate Modern 展開卡確認兩個新圖示、三個入口文字對齊及 AX 名稱仍清楚，截圖 `/tmp/cool-spot-detail-icons.png`。純呈現改動未新增／重跑模型測試。安裝前備份 `/tmp/cool-spot-detail-icons-backup`，安裝後既有偏好／journey／Documents 比對保留；未 commit/push，ViewCoolSpots 未改。

**2026-09-18：設施／訪客回報範例與人數確認（已納入 e90bfb4）。** Owner 要求移除 Cooling space hours，UI 已移除，GLA 原始時間資料保留。正常目錄為十筆 GLA＋三個社群範例：Tate Modern（四種設施，三則回報）；Example Community Room（無廁所、輪椅不通行、有值守／桌子，兩則回報）；Example Shaded Garden（輪椅可通行、無值守，廁所／桌子未知，兩則回報）。後兩者是虛構場所，沒有假 Apple Place ID。來源及每則回報均標 Example，固定 UUID／日期，彙總與七則個別回報一致，不注入個人已發佈報告或確認。票數相同時改為「2 reports · Mixed experiences」，避免原來拼接成重複句子。

人數原因：新 GLA／Tate 初始 presenceCount 為 0，CoolSpotPin 只在 >0 顯示數字；所有新地點附近狀態預設 false，How this works 的 2→3 是獨立示範。未找到標記更新缺陷、沒有改動人數行為。兩個明確虛構範例新增固定示範底數 2／1，並非即時遠端人數。QA 以 Prototype controls 模擬 John Harvard Library 附近，I’m cooling off here 後卡片 0→1，半卡上方真實地圖標記顯示 1；Stop sharing 後卡片歸零。未發佈訪客回報。測試後只移除此輪產生的 nearby／presence／John Harvard 到訪確認，回復測試前的 journey snapshot，先檢查其餘資料及既有確認未變，正常啟動。

限定驗證：四項測試通過（GLA 不製造證據、三類搜尋／身分、社群設施與七則回報一致且不污染私人資料、人數附近條件／加一／600 秒到期），`/tmp/cool-spot-community-examples-tests.log`。最終混合體感文案修正後建置成功，`/tmp/cool-spot-community-examples-final-build.log`。只用 iPhone 17 Pro Max；三個社群範例均展開設施確認，Tate 的 Read all reports 可讀三則標記範例的評論，地圖 0→1 已原生確認。Simulator AX 在測試後只有外框，改用原生截圖／座標完成操作，未因此調整 app 行為。截圖 `/tmp/cool-spot-community-examples-evidence/`；更新前備份 `/tmp/cool-spot-community-examples-backup`，原有偏好／文件已核對保留；defaults CLI 無法覆寫 app container 的快取資料，因此關閉此 QA 裝置後只還原此輪修改的 journey key，再正常啟動比對。最終 Community Room 原生截圖確認 Mixed experiences 文案。沒有裝置矩陣或完整 suite，ViewCoolSpots 未改，未 commit/push。

**2026-09-18：時間／設施漸進展開（先前版本的限定驗證）。** Owner 確認後實作：摘要保留費用、座位與入場條件；Cooling space hours 及 Facilities & accessibility 依資料存在才顯示，預設收起、原地展開。設施集中廁所、輪椅通行、人員值守及桌子；已知「沒有」仍可顯示，未知不補值，只有輪椅資料也能顯示此列。飲水／座位不在設施中重複；Place details 固定接在這組補充資訊之後，Visitor reports 的條狀圖與評論保持原有行為。沒有變更 Cool Spot list、表單、保存或回報規則。

限定驗證：iPhone 17 Pro Max／Cool Spot Layout QA 正常持久化啟動，John Harvard Library 初始兩列收起，分別展開看到正確時間與廁所／輪椅／值守，再收合成功；Place details 開到同名圖書館系統卡，關閉回原降溫卡。Tate Modern 與 British Museum 均沒有空時間／設施列，保留相同 Place details。只做這一台的 A/B/C 原生畫面與互動確認；建置成功 `/tmp/cool-spot-disclosures-build.log`，UI-only 調整沒有新增或重跑模型測試。截圖在 `/tmp/cool-spot-disclosures-evidence/`。更新前 `/tmp/cool-spot-disclosures-backup` 備份的 12 個 preferences plist 既有鍵值及 Documents 檔案均保留。`git diff --check` 通過，40 個 A–E 編號與本機文件連結有效；ViewCoolSpots 仍乾淨，未 commit/push。這不是完整 journey 或真人 usability 驗收。

**2026-09-18：來源整合版地點頁與表單（先前版本的限定驗證）。** Owner 授權最新版。A/B/C 共用名稱→地址→分類的 identity header；GLA 或社群來源不決定欄位位置。降溫特色後直接顯示已知費用／座位／資格／輪椅通行／來源時間／特定區域／停留上限，不再有 Hours & access 折疊。來源在分類旁出現一次。Visitor reports 包含統計、日期、展開的條狀圖、停留體驗、個別評論、唯一 Read all reports 和回報入口。Facilities 位於其後，按資料顯示廁所、值守、桌子。十筆 staffedWhenOpen 已按 GLA objectID 對回原始 is_staffed_when_open，未更新 2025 快照年代。表單移除 Wi-Fi／Power outlets／Laptop use allowed；輪椅通行加入 Entry and seating，廁所／值守／桌子置於 Facilities。Specific area · Optional 改為描述特定房間／角落，普通場所預設收起。修正仍送審，不直接改公開事實，也不自動產生體感回報；本輪沒有做真正審核／發佈後端。

限定驗證：編譯成功，9 項相關測試通過：5 項目錄／來源／修正測試與 4 項原有表單提交／重複場所／選填行為。紀錄 `/tmp/cool-spot-unified-details-tests.log`、`/tmp/cool-spot-unified-details-contribution-tests.log`；初次 selector 指向錯誤 class 的 4 項未執行，已改用 ApprovedContributionTests 執行通過，沒有把未執行算通過。沒有重跑全 suite。iPhone 17 Pro Max／Cool Spot Layout QA 正常啟動確認 John Harvard Library 半卡／展開卡的入口資訊與較下方 Facilities；Suggest an edit 可見預填輪椅、廁所、值守及未填的桌子，Specific area 預設收起，沒有三個已移除問題，未送出提案。Tate Modern 保留 Example cooling info，缺少時間／設施時不留空區；British Museum 保留附近探索、Place details、Directions／Save，無 Call／Website。隔離 memory-only place preview 顯示有資料的 Visitor reports，統計與評論集中，隨後已恢復正常持久化啟動。原生手勢／AX 連線在測試後失效，重開 Simulator 並重選原 QA 裝置後恢復；沒有因此更改 app 互動實作。

更新前備份 `/tmp/cool-spot-unified-details-backup`，安裝後既有偏好值一致；圖片在 `/tmp/cool-spot-unified-details-evidence/`（a-gla、b-community、c-ordinary、visitor-reports-example）。沒有裝置矩陣，沒有寫入 ViewCoolSpots，未 commit/push。保留 40 個 A–E 編號；A01/A05/B05/B06 的現行點擊路徑已更新。這些是限定原生與模型證據，不是完整 journey 驗收或真人 usability 結果。

**2026-09-18：縮減場所卡操作（先前限定驗證）。** Owner 指定移除地點頁的 Call／Website，聯絡資訊留在 Place details 系統卡。已刪除普通場所卡的兩個按鈕，保留相容的資料欄位；A/B 原本沒有獨立聯絡按鈕。Tate Modern 移除沒有依據的 ground-floor seating 示範說明，沒有補充資訊就不顯示 Hours & access；GLA 原始欄位不變。Visiting information 的欄位範圍及 How to find this spot 表單是否保留仍在討論，本輪沒有擴改表單。編譯及調整後的單一三狀態測試通過（`/tmp/cool-spot-contact-removal-tests.log`）；只在 iPhone 17 Pro Max 的正常持久化啟動確認：Tate Modern 無空的 Hours & access，British Museum 無 Call／Website 且保留 Place details、Find nearby Cool Spots、Directions、Save。更新前已備份 `/tmp/cool-spot-contact-removal-backup`，安裝後既有偏好值一致。未重跑完整 suite、未跑裝置矩陣，未 commit/push。A05 預期已更新，40 個 A–E 編號不變。

**2026-09-18：A／B／C 正常啟動比較初次驗證（下文記錄當時畫面）。** Owner 要求三種頁面可直接看，並拒絕在 app 按鈕中使用 Apple Maps 品牌。正常 Explore 現有十筆 GLA 加 Tate Modern（Example cooling info），另有可搜尋的 British Museum 普通場所。Tate Modern 的 Apple Place ID 已用 MapKit 查核，降溫／進入內容為明確標示的非 GLA 示範，不填假開放時間或訪客回報。`PlaceInformation` 將可顯示事實與來源分開；Hours & access 依資料存在與否呈現，B 缺 hours 仍可讀 instructions。三種詳情按鈕都叫 Place details；A/B 放在 access 資訊旁、訪客回報之前，街景仍在下方。C 保留 No cooling information yet／附近探索與原本操作。新 MapKit 搜尋結果優先於本機種子資料，保留電話／網站等資料。

限定驗證：五項 Cool Spot list 測試通過（含新增三種狀態、B 精確身分合併，以及原本四項相容檢查），`/tmp/cool-spot-three-states-tests.log`；沒有重跑全 suite。最終 UI 建置成功 `/tmp/cool-spot-three-states-final-build.log`。只用 Cool Spot Layout QA／iPhone 17 Pro Max／iOS 26.4：正常啟動顯示 11 Cool Spots；搜尋 Tate Modern 只有一筆該場所，半卡／展開卡標 Example cooling info，Hours & access 顯示 ground-floor seating 示範說明；Place details 開到真實 Tate Modern 並可關閉返回。Canning Town Library 顯示來源時間、廁所、無障礙與相鄰 Place details，原 Saved 狀態保留。搜尋 British Museum 開普通場所卡，有 Call／Website／Place details／Find nearby Cool Spots，沒有空的 Hours & access。未再逐一開 A/C 系統卡、未重做收藏／回報完整旅程，也未跑任何裝置矩陣。QA 更新前備份 `/tmp/cool-spot-three-states-backup`，安裝後持久化鍵值比對一致。沒有改 owner 其他模擬器或 ViewCoolSpots，未 commit/push。

畫面：`/tmp/cool-spot-three-states-evidence/a-gla.png`、`b-community.png`、`c-ordinary.png`。A05 已加入三種直接搜尋路徑，A–E 40 個固定編號不變。這些是 agent 的限定原生證據；owner 尚待判斷呈現感覺。

**2026-09-18：十筆 GLA JSON 初次整合。** 正常啟動使用自己的 API-shaped JSON，取自 GLA 2025 的十筆真實場所；原始資料共 250 筆。本輪十筆名稱／來源 ID／座標／開放時間已與原始檔核對。每筆另有固定內部 UUID 與人工檢查的 Apple Place ID，搜尋以已知 primary/alternate ID 合併，不靠距離或名稱猜測。沒有新增伺服器、沒有為新場所填入示範回報或人數。舊收藏與筆記保留，來源標成 GLA · 2025；Hours & access 顯示來源開放時間／廁所／無障礙資訊。這是來源快照，不代表 2026 現況已重新查證。

驗證：`/tmp/cool-spot-catalog-build.log` 建置成功；`/tmp/cool-spot-catalog-tests.log` **67 passed、0 failed**，含四項新檢查：十筆資料與無虛構訪客證據、Apple 別名去重與拒絕近距離誤合併、未知代碼／版本處理、既有 Apple 收藏與內部 ID 回報保存。只在 Cool Spot Layout QA（iPhone 17 Pro Max／iOS 26.4）正常持久化啟動：Explore 顯示十筆；搜尋 Canning Town Library 只有一筆該場所，開卡後地圖移到 Canning Town；Hours & access 顯示週一至六 9–20／週日及假日休息、廁所與無障礙；Apple Maps place details 顯示相同圖書館和 Rathbone Market／Barking Road 地址；關閉回原卡。Save → 重啟 → Saved → Canning Town Library 仍為同一降溫卡與 Saved 狀態。既有 Riverside Library 收藏仍在。QA 安裝前資料備份 `/tmp/cool-spot-catalog-backup`；安裝／測試後、建立新測試收藏前既有偏好鍵值一致。截圖 `/tmp/cool-spot-catalog-evidence/canning-hours-saved.png`。未操作 owner 模擬器、未跑裝置矩陣，未 commit/push，未修改 ViewCoolSpots。

本輪只證明十筆整合路線與上述互動；未聲稱已批次配對全 250 筆、完成全部 A–E 或完成真人可用性驗收。回報資格仍是模擬 nearby／先前確認，新的十筆預設不在附近；需試填時在 QA 的 You → Settings → Prototype controls 選該場所。以下舊版驗證有日期，不能當作新目錄逐項重測結果。

**2026-09-17 文案、間距與收藏編輯：** Owner 要求刪除 Across recorded visits／not a guarantee 類旁白、體感條狀圖直接顯示，並重看所有 view 的分組。單人檢視 Explore、兩種場所卡、Saved／Pins、You／報告／貢獻／帳戶／設定／Cool Hunt、表單／說明頁及共用 label/button/image/icon；原生 Form/List 保留平台分組，未為重排而改動資料資格與提交流程。

| View 範圍 | 這次決定與實作 |
|---|---|
| Explore／搜尋／附近面板 | 標題與地點／距離靠近；列與列有清楚分隔；移除 Reviewed places only 等重複說明；清除搜尋與篩選保留 44 pt 點擊區 |
| Cool Spot／一般場所 | 名稱地址為一組、設施與進入條件一組；體感摘要、日期與常駐條狀圖放 How it felt；Visitor reports 集中個別評論預覽、Read all reports 與分享入口；主區塊 32 pt、內部 4–16 pt；一般場所的缺資料狀態與附近按鈕靠近，聯絡／Apple 資訊另成組 |
| 照片／街景／共用圖示 | 沒有實際照片時不顯示大型裝飾圖；有照片保留；街景維持按需；共用 icon-label 採一致間距與文字基線 |
| Saved／Pin | Save 一次即完成；Saved → Edit saved place → Save changes；沒有筆記不插入空表單，有筆記才顯示 Your note 摘要；Pin 使用左上 Edit 進同一編輯器，不重複提供兩個 Edit；Cancel 保護修改，移除有筆記的收藏需確認 |
| Visitor reports／You | 個別回報取消重複上下 padding；作者日期靠近；縮短 demo、保存、感謝、review/account 等旁白，保留精簡狀態與必要 Example 標記 |
| Contribution／Visit report | Native Form 24 pt 分節、問題與欄位 8 pt；刪除重複 chooser／分類解釋；Posted time limit 直接表達意思；Comment 有固定標籤；必填提示與錯誤保留 |
| 說明／設定／狀態頁 | 刪除重複動畫／appearance 解說；較長資格解釋留在主動開啟的 help；模擬控制仍有操作說明，避免誤動測試紀錄 |

實際證據：只用 **Cool Spot Layout QA（iPhone 17 Pro Max／iOS 26.4，ADD1EA21-7D94-4DC3-BAF8-87BEAD36DDD6）**，正常持久化啟動。Riverside Library 半卡／完整卡可直接讀圖表，沒有兩句刪除文案或 Reported experiences 按鈕；Save 後不出現空編輯表單。Saved 選單 → 編輯測試筆記 → Save changes → Your note 顯示；再改 → Cancel → Discard changes 保留原筆記；重啟以 Saved 開啟仍有筆記、資訊順序一致。Suggest an edit 的 native Form 分組已查看，未送出。Pin 首輪發現筆記 Edit 與 Edit saved pin 重複，已收斂為左上單一 Edit，最終原生畫面及開啟 Edit saved pin 已確認。建置 `/tmp/cool-spot-layout-build.log`、`/tmp/cool-spot-layout-build-final.log` 成功；未重跑歷史單元測試、iPad／多尺寸／Dynamic Type 矩陣，未修改 owner 模擬器資料。截圖 `/tmp/cool-spot-layout-evidence/place-expanded.png`。這是 source review 與限定原生操作，不是每個狀態的完整可用性驗證。

**2026-09-17 評論入口修正：** Owner 指出統計旁的 View all 與下方可點評論重複且分散。How it felt 現在只放統計／停留時間；Visitor reports 將最新評論、Read all reports 與分享入口放在同一組，預覽文字不可導航。只在同一台 iPhone 17 Pro Max QA 原生確認：點預覽留在原卡、Read all reports 開啟完整回報、Back 回到原卡與原捲動位置；既有 Saved／測試筆記仍在。建置 `/tmp/cool-spot-report-grouping-build.log` 成功，`git diff --check` 通過；截圖 `/tmp/cool-spot-layout-evidence/report-grouping.png`。沒有重跑裝置矩陣或單元測試，回報資料／排序／資格未改。

**2026-09-16 owner 同意並委託實作旅程調整：** 已統一 Explore／Saved 場所卡順序；cooling features 保留單一區塊、先顯示兩項再原地展開；體感摘要縮短，分布改為展開查看；Seating provided 已改顯示文字且保留舊儲存值。一般場所提供 Find nearby Cool Spots，以所選地點為中心找已有 Cool Spot 資料；可擴大範圍、返回原卡，沒有把 Apple 結果當成已確認 Cool Spot。Opening hours & place details 與按需 View nearby streets 為次要資訊。沒有更改 Report／Cooling here 資格或審核流程。資料仍是三個示範 Cool Spot，這次未接入真實降溫目錄。以下原生證據是 agent 操作，不是 owner 驗收。

本輪僅 iPhone 17 Pro Max、iOS 26.4 正常啟動與建置（`/tmp/cool-spot-journey-card-build.log`）；未跑其他裝置或重跑歷史 63 項測試。原生確認 British Museum → Find nearby Cool Spots：1 km 空結果 → 3 km 出现 City Gallery Foyer 2.4 km／Shade beside the playground 2.7 km → 開卡 → 關閉回同一範圍 → Back to The British Museum 回原場所 → 關閉後 British Museum 搜尋字仍保留。結果卡的距離也已核對為 2.4 km from The British Museum (straight-line)，不再顯示 fixture 的 14 min walk。系統卡顯示 Museum 營業時間並返回；展開街景才載入，仍是 Apple 的黑門視角。Riverside Library 的設施可在原區塊展開／收合，半卡顯示 Seating provided。Saved 使用相同 view 與轉 Explore 的程式路徑已檢視；原生分頁座標操作受工具視窗定位問題阻擋，未宣稱這段已完成原生驗證。重裝前備份 `/tmp/cool-spot-journey-backup-20260916-104223`，更新後原有兩個持久化鍵值完全一致。截圖 `/tmp/cool-spot-journey-evidence/cooling-card.png`、`/tmp/cool-spot-journey-evidence/nearby-results.png`。

**2026-09-15：選點會移動地圖，場所卡先顯示半張、可展開；correction 提供名稱與類型選項。Owner 可從 A01/A05/B12 看操作感覺。** 搜尋仍沿用原本的場所頁、Save 與提案表單；本輪沒有改寫 Report／Cooling here／冰棒流程。先前表單的 B04 owner 重測仍待進行，接續 B03/B05/B06/B10。以下 agent 證據不代表 owner 驗收。

| 範圍 | 最新證據 | 仍需確認 |
|---|---|---|
| 表單、名稱／照片 | 本輪 iPhone 窄螢幕原生操作：缺名字被攔下，補齊名稱及照片後到 Sent for review；首次漏填定位成功 | Owner 的理解與閱讀舒適度；B03–B05 完整分支 |
| Entry/cost 與大字體 | 一般字級 Cost／Seating／Tables 同高；iPad 最大字級深色的選項、時長及已知場所無照片送審已操作 | 全部選單取消／返回；iPad 橫向及 split view |
| 更新既有場所 | 未改資料時清楚提示、不提交；單改 Seating 即可送審 | B09 還原原值、B12 全部移除的原生分支 |
| 自動測試 | 2026-09-15：63 passed、0 failed（原有 61 ＋ 聯絡資料相容／更正送審 2）；最後 UI 建置成功 | 不代表完整 VoiceOver 或真實可用性測試 |
| 其餘流程 | C/D/E 原實作與 48 項既有測試仍通過；本輪 A05／B01/B02 有新增搜尋證據 | 未宣稱此版全部 40 個案例或完整 VoiceOver 通過 |


2026-09-15 Look Around／Apple 詳情延伸：僅在 iPhone 17 Pro Max 確認 Tesco Extra（Grand Depot Road）的街景預覽、Apple Maps place details → 系統卡的 Tesco 品牌圖／營業時間／電話／網站 → 關閉返回同一 cooling 卡，沒有改變 Save 狀態。無覆蓋與載入失敗有提示／重試程式分支，本次未另找地點重現。建置成功（`/tmp/cool-spot-look-around-build.log`）；本次只增加原生 UI 串接，沒有重跑先前 63 項測試或裝置矩陣。截圖：`/tmp/cool-spot-look-around/cooling-card.png`、`/tmp/cool-spot-look-around/apple-place-card.png`。重裝前備份 `/tmp/cool-spot-look-around-backup-20260915-111313`，既有持久化鍵值比對一致。

2026-09-15 A05 街景入口回饋：修正前 British Museum 預覽為黑色住宅門、British Library 為 Midland Road 側面。將有效 Place ID 的請求從 coordinate 改為完整 MKMapItem，與系統卡共用身分；British Museum 仍為同一黑門，Library 仍為側面（視角改成面向紅色外牆），不能宣稱入口問題已修好。附近街景提示已說明可能看不到入口或室內情況。Museum 系統卡顯示正確館名／博物館圖示，關閉可回同一 cooling 卡。本輪僅 iPhone 17 Pro Max 正常啟動與建置成功，未重跑單元測試；紀錄 `/tmp/cool-spot-look-around-location-build.log`，修正前後截圖 `/tmp/cool-spot-look-around-location/`。重裝前備份 `/tmp/cool-spot-look-around-location-backup-20260915-115204`，既有持久化鍵值比對一致。

2026-09-15 簡短原生確認（iPhone 17 Pro Max，iOS 26.4）：Tesco Extra／Grand Depot Road 選點前地圖仍在 London Bridge；修正後定位 Woolwich 並顯示標記與 Half screen 卡。原生 Sheet Grabber 可展開為 Expanded；座標拖曳工具沒有可靠完成上滑，實際手勢感覺留給 owner。此結果顯示 Food market、Call、Website；Add cooling information → correction 可見預填名稱及 12 個既有類型選項，未送出提案。Riverside Library 半張卡仍顯示降溫、費用、體感與導航。沒有重跑 iPad 或其他顯示矩陣。

建置：`/tmp/cool-spot-place-card-build.log`；測試：`/tmp/cool-spot-place-card-tests.xcresult`。重裝前備份在 `/tmp/cool-spot-place-card-backup-20260915-103349`，原有持久化鍵值比較一致。地圖修正以選點前後的原生畫面確認，沒有額外新增只測座標 helper 的測試。這些是 agent 確認，尚未代表 owner 驗收。

證據按需讀取：

- [較早 About the place 驗證與截圖](.impeccable/review/about-place-2026-09-08/VERIFICATION.md)
- [Entry/cost 排列驗證](.impeccable/review/entry-layout-2026-09-08/VERIFICATION.md)
- [先前 A–E 修正／D–E 操作紀錄](.impeccable/review/owner-feedback-2026-09-07/VERIFICATION.md)
- [留存的 48 項測試結果](.impeccable/review/entry-copy-2026-09-07/test-summary.json)

以上是各次檢查範圍的證據，不等於完整真人可用性驗證。

### 2026-09-14：真實地點搜尋與相容保存

基準：`Prototyping` 的 `7c0a756` 加本輪未提交變更；owner 明確要求 agent 直接實作，保留現有 user flow。另一 worktree 的 `ViewCoolSpots` 仍為 `425e138`，未修改其 Swift、測試或 Xcode 設定，本輪不計入重建 S03。

- 實作：Explore 與 Choose a place 共用 MapKit 搜尋，350 ms debounce、Search 立即送出、清空／離頁取消、忽略舊結果、loading／empty／failure／Try again。保留 fixtures；選到一般場所沿用原頁／原表單，不新增 cooling 證據。Save 保存基本地點資料，舊 snapshot 相容。MapKit 沒提供照片，新結果用 Place illustration。
- Red → Green 實際驗證：新場所收藏後重新建立 store 找不到詳細資料；搜尋未送 request；舊請求未取消／最新結果未顯示；清空仍發送空查詢。四輪失敗及修正結果保留於 `/tmp/cool-spot-search-{save,request,latest,clear}-{red,green}.xcresult`。其餘搜尋與回歸檢查共 61 passed、0 failed，結果 `/tmp/cool-spot-search-suite.xcresult`。最後 UI 建置紀錄 `/tmp/cool-spot-search-build-final.log`。
- 原生環境：Cool Spot Compact QA（iPhone SE，375 pt，iOS 18.2）與 Cool Spot Form Tablet QA 18（iPad Air 11-inch M2，iOS 18.2，既有最大 Dynamic Type，Light／Dark）。正常啟動，沒有使用 memory-only preview，也沒有替換 owner 的模擬器或操作其未送出表單。

| 案例 | 實際原生證據 | 範圍限制 |
|---|---|---|
| A05 | iPhone 搜尋 British Library，地址為 96 Euston Road, London, NW1 2DB；開原本地點頁 → Save；重開 App → Saved → 同一地點、地址及 Saved 狀態 | 私人備註／舊回報相容有單元測試；未在原生畫面編輯私人備註 |
| B01/B02 | British Library → Add cooling information；名稱／來源類型帶入、Indoors/Outdoors 沒預選；Change place → 搜尋 Tate Modern → 原表單。iPad 再驗證 British Library 地址保留 | 未實際送出真實場所提案；審核仍為 session-only prototype |
| A01/A05 | 搜尋 Riverside Library 仍顯示原 Cool Spot，點選開原完整降溫資訊頁；原收藏與 Pin 仍可見 | 未重做 C/D/E 完整原生旅程 |
| A05／E05 | iPad 搜尋 SW1A 1AA 與 British Library；最大字體／深色的名稱、地址、未有降溫資訊可讀；觀察到 Searching places…。iPhone 軟體鍵盤開啟時可讀完整結果並點入；按 Search 後 Nearby strip 恢復 | 未完成全部 VoiceOver、橫向／split view，iPhone accessibility tree 未穩定提供內容，以原生截圖操作 |
| A09 | 清空回到原 Explore；失敗、重試及真正空結果有受控測試 | Apple 對亂字仍回傳近似場所，本輪未宣称自然重現原生無結果／網路失敗 |

原生檢查發現並修正：搜尋列的次要文字在 material 背景不可見，改用明確文字色；表單地址改由已選場所解析，避免清空結果後消失；距離標示區分 selected place、Pin 與 example location。窄螢幕軟體鍵盤曾把結果壓到半列，已將非空搜尋聚焦時的 Nearby strip 暫時收起，完成輸入／清空後恢復；這些修正保留導航與表單步驟。

歷史搜尋截圖當時存於 `/tmp/cool-spot-search-evidence/`（iPhone 搜尋、鍵盤、iPad 大字體深色、重啟後 Saved）；2026-09-17 檢查時暫存檔已不在，不再提供失效連結。QA iPad 的外觀已還原為原本的 Light，保留原最大字體；B04 既有 owner 反饋仍未驗收。

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

以上 DEBUG flows 使用 memory-only store，不是正式保存／上傳／審核服務證據，也不是首次使用者的完成時間或點擊數測量。

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
4. 除非寫「接上一項」，開始前退出目前表單／地點。公開測試表單用 Close → Discard and close；個人回報用 Finish later。分清兩種草稿的保存範圍，見 PRODUCT。
5. 每次修正後只重測受影響編號；記錄版本、日期與結果。沒有實際測試就填「待測」，不要沿用舊版的通過狀態。

`→` 是下一個點擊或動作；「返回」是左上角返回；「關閉地點」是 ×。Explore／Saved／You 是底部分頁，Places／Pins 是 Saved 內的分類。GPS 與審核仍為 prototype，限制見 PRODUCT。

**現行 A–E 使用正常本機 API 啟動，先確認 `python3 scripts/run_backend_local.py serve` 的本機服務可用。** 明確例外為 E01 的舊發布模擬，只能使用隔離 memory-only fixture mode；不能拿它證明 API 或重啟保存。正常清單為 API 的 250 筆 GLA＋3 labelled examples；British Museum 必須由 live MapKit search 或既有私人收藏取得。正常模式不重播本機發布、不補 fixture visitor reports 或 peer presence；其餘個人回報流程仍是本機 prototype。

| 用途 | 可搜尋的地點 | 前提 |
|---|---|---|
| GLA 資訊／修正 | John Harvard Library、Canning Town Library | 初始沒有 visitor reports 或示範人數；沒有填的資格／設施不應推測。 |
| 非 GLA 降溫資訊 | Tate Modern | API mode 初始無訪客回報／示範人數，可開真實場所的 Place details。 |
| 個人回報／人數／草稿 | Example Community Room、Example Shaded Garden | API mode 初始無 fixture 回報／示範人數；QA 附近模擬和個人回報仍可使用。 |
| 普通場所／新增提案 | British Museum | 應顯示 No cooling information yet。British Library 已在 GLA 目錄，不能用來測這個分支。 |

既有本機回報／發布可能改變上述狀態，先確認前提再測。B11／E01 會持久化測試提案，C03／D04 的日期模擬會修改所有「已確認、尚未開始回報」的造訪；需要這些情境時使用隔離 QA iPhone 17 Pro Max，只建立本輪資料，不重置 owner 裝置。若 British Museum 已在該 QA 本機發布成 Cool Spot，改用另一個明確顯示 No cooling information yet 的普通場所，整組相關步驟使用同一個名稱。

## A：找地點、閱讀、私人儲存

### A01｜很熱，想判斷去哪裡

1. Explore → 搜尋 `John Harvard Library` → 點同名 Cool Spot；也可從底部 **Cool Spots** 或地圖標記開啟。
2. 確認地圖移到場所、半卡上方仍看得見標記。讀名稱、GLA · 2025、降溫設施與費用／座位；上滑展開。
3. 降溫特色下方讀有資料的費用、座位與使用資格；未知資格不應顯示 Open to everyone。不再顯示 Cooling space hours；**Facilities & accessibility** 預設收起，點開讀廁所／輪椅通行／人員值守。再次點擊可收合，座位／飲水不重複。來源在分類旁；同組的 **Place details** 開同一場所的補充資訊，關閉回原降溫卡；**View nearby streets** 緊接其後，第一區末端是較輕的 **Suggest an edit**。
4. 場所資訊、Visitor reports、目前人數／分享操作三區之間均有淡分隔線；人數與 Here to cool down? 共用白底，沒有內層藍色卡片。新場所 **Visitor reports → No reports yet**；沒有捏造體感條狀圖。有自己的已發布回報才顯示相應分布；正常 API mode 不額外加入 fixture 訪客證據。

**觀察：** 是否足以決定去不去、還缺什麼？GLA 時間仍留在資料中但不在 app 卡顯示；要看場所時間可開 Place details，資料依系統卡提供。座位表示設有座位，並非現在有空位。

### A02｜比較兩個地點

1. 關閉地點 → Explore 搜尋 **Example Shaded Garden** → 開啟同名 Cool Spot。
2. 比較降溫特色、入場／座位資訊與 Visitor reports；初始無回報時顯示 No reports yet，有自己回報時才有分布。
3. 關閉 → 搜尋 **Example Community Room** → 開啟並讀 Visitor reports 與目前人數。

**觀察：** 哪些是場所資訊、哪些是一次造訪的經驗？正常 API mode 的兩個虛構場所只有 labelled place facts，初始沒有 fixture 訪客回報／示範人數。個人已發布回報加入後，統計應與同一批實際本機回報相符；這不是遠端同步。

### A03｜用篩選縮小範圍

1. 關閉地點 → Explore → **Indoor** → 看地圖及底部結果 → 再點 Indoor 取消。
2. 依序試 **Outdoor shade**、**AC**、**Free**、**Water**，每次看結果再取消；橫向滑動篩選列可找後方選項。
3. 點 **Indoor**，接著點 **Water**，觀察是否符合預期。

**目前行為：** 一次只保留一個篩選，第二個會取代第一個，不能組合條件。**More** 尚未接通，點一次確認後即可停下，不必找隱藏頁面。

### A04｜定位、暫不提供定位、移動地圖

1. Explore → **Nearby**。若出現 **Use your current location?**，先選 **Not now** → 搜尋框輸入 `John Harvard Library`，確認仍可搜尋。
2. 清空搜尋框 → Nearby → 若再次出現說明，選 **Continue**。
3. 拖動地圖 → **Search this area**。

**目前行為：** 說明是 App 內的模擬流程，不是 iOS 真正的定位授權。已按過 Continue 時不一定再問。Search this area 目前只收起按鈕，不會重新取得該區資料；地圖移動也不會改變模擬的所在地。

### A05｜搜尋已知 Cool Space 與尚無降溫資料的場所

在同一次正常啟動中比較三種狀態，不需 Run Arguments：

- **A：Canning Town Library** → GLA · 2025；摘要後為預設收起的 Facilities & accessibility，以及 Place details；展開有廁所／輪椅／值守，沒有 Cooling space hours；Place details 開同一圖書館。
- **B：Tate Modern** → Example cooling info；降溫、費用、座位與使用資格仍可見；Facilities & accessibility 顯示範例的廁所／輪椅／值守／桌子，Visitor reports 有三則標 Example 的回報，統計與列表一致。Place details 開真實 Tate Modern 卡。另搜 Example Community Room（含沒有廁所／輪椅不通行）及 Example Shaded Garden（部分未知、沒有工作人員），各有兩則回報；兩者為虛構場所，沒有捏造 Apple 場所卡連結。這是非 GLA 的示範降溫資訊，不是實際社群回報或重新查證的場所承諾。
- **C：British Museum** → No cooling information yet／Find nearby Cool Spots；沒有空的 Cooling space hours 或 Facilities & accessibility 區；詳情按鈕同樣叫 Place details，名稱／地址／分類順序與 A/B 一致。

本輪 A05 抽查可搜尋 Canning Town Library、Custom House Library、Beckton Library、Ham Library、Green Street Library、Library at Willesden Green、Streatham Ice and Leisure Centre、Salvation Army Centre (Harold Hill)、Horniman Museum、Museum of the Royal Pharmaceutical Society。完整名稱相符的 Cool Spot 應先顯示；Streatham 場館與大廳保持不同身份；Horniman 仍有待核對重複結果。

A/B/C 的搜尋結果可能另有 MapKit 近似場所。B 同一場所不應同時出現一筆普通場所與一筆 Cool Spot。接著可用以下普通場所分支檢查收藏／返回。

1. Explore → 搜尋框輸入 `British Museum`（確認仍是 No cooling information yet 的普通場所）→ 核對地址 → 點選該場所。
2. 確認地圖移到該場所、出現標記及半張卡；讀 **No cooling information yet**，有來源資料時可見分類；地點頁不提供 Call／Website，聯絡方式留在 Place details。上滑展開；點 **View nearby streets** 才載入附近街景，標示為附近街景。有 Place ID 時可點 **Place details** → 關閉應回同一 cooling 卡。點 **Save**；若本來已 Saved，不用取消舊收藏。
3. 關閉地點 → Saved → **Places** → 剛收藏的場所；重新啟動 App 後再開一次，名稱、地址與 Saved 應仍正確。
4. **Saved → Edit saved place**；只對本輪測試資料修改 Name in Saved／Your note → **Save changes** → 回原場所，Your note 應顯示摘要；關閉／重啟後仍保留。再修改 → Cancel → Discard changes 應保留之前內容。
5. 同一普通場所 → **Find nearby Cool Spots**：地圖以這個場所為中心，顯示 1 km 內已有資料的結果。空結果可 **Search a wider area**。點結果開降溫卡 → 關閉應回原範圍；**Back to [原場所]** → 關閉原卡後，Explore 搜尋字應保留。從 Saved 進入時會切至 Explore，使用該收藏場所名稱作搜尋上下文。距離是從該場所起算的直線距離，不是步行時間。

**觀察：** 收藏是否被誤認為公開新增 Cool Spot？私人名字是否和場所原名分得清？普通場所現在也有 Directions；已收藏時用 Saved 選單編輯或 Remove from Saved；不再突然出現第二個儲存表單。

### A06｜收藏／取消收藏已存在的 Cool Spot

1. Explore → **John Harvard Library** → **Save**（若原本已 Saved，直接下一步）。
2. 關閉 → Saved → Places → John Harvard Library，應開相同資訊順序的地點頁，不會換成照片優先。
3. 只有在這是本輪新收藏時，點 **Saved → Remove from Saved** 取消；有筆記時須再確認 → 關閉 → 確認 Places 已移除；再從 Explore 收藏回來。

**觀察：** 已有 Cool Spot 與普通場所的 Saved 入口是否都合理？取消收藏不應刪除你的回報。

### A07｜從 Explore 快速存一個私人 Pin

1. Explore → 右下 **＋** → **Save a pin here** → 如出現定位說明，選 Continue。
2. 在 **Save a pin here?** 先選 **Cancel**，確認未新增。
3. 再開同一路徑 → **Save pin** → 提示出現時點 **View pin**。
4. 若提示已消失：Saved → Pins → 最新的 **Dropped pin**。

**觀察：** 你是否知道保存的是目前模擬所在地，而非地圖畫面中心？是否清楚它是私人、沒有開始回報？

### A08｜從 Saved 存 Pin、命名並找回

1. Saved → 右上 Pin 按鈕（**Save a pin here**）→ **Save pin** → **View pin**；也可從 Pins 開最新 Dropped pin。
2. 左上 **Edit** → Name in Saved 填 `TEST 河邊樹蔭` → Your note 填 `TEST 靠牆的長椅` → **Save changes**。
3. **Done** → 再從 Pins 開剛存的項目 → 核對名稱、備註、位置。

**保留給 B03：** 使用這個測試 Pin，確認公開提案不會自動帶入私人文字。目前沒有刪除 Pin 的使用者入口；不必連續建立很多個。

### A09｜離開 App 去導航／搜尋不到

1. Explore → John Harvard Library → **Directions** → 檢查交給 Apple Maps 的步行目的地 → 返回 Cool Spot；不用真的出發。
2. 關閉地點 → Explore 搜尋 `TEST nowhere 999` → 觀察結果 → 清空搜尋。

**目前行為：** 兩種場所的 Directions 都是外部地圖連結。無結果時顯示 **No places found**，可改搜尋字詞，或點 **Add cooling information at a location** 進入新增流程；沒有直接把搜尋字詞當成新場所。搜尋包括 Apple Maps 真實結果與目前目錄；Apple 可能回傳近似結果，不能把隨意字串當成一定無結果。若失敗應顯示 Couldn’t search places 與 Try again，清空後不保留舊結果。

## B：新增／修正公開場所資訊

這一輪不需要開始 Visit Report 或分享人數。公開提案的 **Send for review** 與個人回報的 **Publish report** 是兩條不同流程。

### B01｜從普通場所直接補降溫資訊

1. Explore → 搜尋 `British Museum` → 核對 Great Russell Street 的場所 → 確認 **No cooling information yet** → **Add cooling information**。
2. 核對表單帶入同一場所名稱／地址；**Indoors or outdoors?** → **Indoors**。
3. 在 **What helps people cool down?** 選 **Air conditioning**，只作隔離 QA 表單輸入，不代表已查證該場所冷氣。
4. 先不送，直接接 B06 檢查選填。按鈕可點不代表資料完整；未填完整時應顯示驗證提示。

**觀察：** 是否不用再選一次場所？Place type 已知時應顯示來源值，不要求重填；其他選填項目可略過。

**也測收藏入口：** Saved → Places → A05 收藏的 British Museum → **Add cooling information**。應直接開同一場所的表單，名稱／地址正確；未由 MapKit 提供的場所類型仍為選填，環境不得推測。若已本機發布成 Cool Spot，這會成為更新分支，需另備普通場所。

### B02｜Explore ＋ 的統一選擇頁

1. 關閉目前公開表單（測試答案可選 **Discard and close**）→ 關閉地點 → Explore → ＋ → **Add cooling information**。
2. 在選擇頁搜尋 `British Museum` → 選尚無降溫資訊的同名場所 → 核對新增表單 → 返回。
3. 搜尋 `Tate Modern` → 核對 Bankside, London 地址及 **Already on Cool Spot · Update information** → 選結果 → 應開 **Update place details**，帶入既有示例資料 → 返回。
4. 改搜 `John Harvard Library` → 選既有 Cool Spot → 同樣開更新表單，不建立第二個 Library。

**觀察：** Nearby places 會包含目前目錄，不保證目標在第一屏；可直接搜尋。選項下的 Add cooling information／Already on Cool Spot · Update information 是否足以預告接下來做什麼？

### B03｜把私人 Pin 的位置提供給別人

**狀態：規則已實作；agent 限定檢查見上方，完整 owner 走查待測。**

1. 關閉公開表單 → Saved → Pins → A08 的 **TEST 河邊樹蔭** → **Add cooling information**。
2. **Confirm the spot**：確認原本 Pin 的位置 → **Use this spot**。
3. 核對公開名稱與備註為空，不應出現私人 `TEST` 文字；自行填公開名稱 `TEST Playground shade` → Indoors or outdoors? → **Outdoors** → **Tree shade**。
4. **Add photo** → 選一張測試照片；名稱及照片皆提供後，不用回答進入資格也可以送審。Required 應使用同樣樣式，跟隨名稱及照片問題。
5. 確認照片顯示且必要答案已填；先不送，可接 B10。Send for review 可點本身不代表驗證已通過。

**觀察：** 先回答室內／室外，再填相鄰的名稱與特定區域描述是否順暢？名稱提示是否清楚歸屬輸入欄？位置只留一個 Change location，進入資格與必填照片是否分得清？

**也測 Pin 對應到已知場所：** 完成本項與 B10 後，Close → Discard and close → 從同一 Pin 再進 Add cooling information → Confirm the spot → **Search nearby places** → 搜尋並選 **British Museum**（仍無降溫資訊時）。應改為該場所填資料；退出後，原私人 Pin 的名稱、備註和位置都應保留。

### B04｜搜尋不到，但知道有名稱的場所

**狀態：規則已實作；agent 限定檢查見上方，完整 owner 走查待測。**

1. Explore → ＋ → Add cooling information → 搜尋 `TEST courtyard`。
2. 無結果，或 Apple Maps 的近似結果不是目標場所 → **Choose a spot on the map** → 在地圖點選位置 → **Use this spot**。
3. **Indoors or outdoors?** 直接選 **Outdoors** → **Place name** 填 `TEST Community Courtyard`，兩題皆應標明必填 → Place type · Optional → **Square, plaza or courtyard**。
4. 選 Tree shade → 未加照片按 Send，應定位 Photo 並要求照片、不得實際送審；Add photo → 選測試照片 → 確認符合送審條件；先不送。

**觀察：** 三個室內／室外選項是否可直接選，未選時有沒有誤導性預設？是否分得清場所名稱與特定區域描述？名稱應鼓勵容易辨認的描述，不必假造正式場所名稱；描述欄位不應預留多餘空白。有名稱時照片仍必填。

### B05｜室內角落、無名位置與改位置

**狀態：規則已實作；agent 限定檢查見上方，完整 owner 走查待測。**

1. 接 B04 表單：清空名稱 → Indoors or outdoors? 選 **Indoors**；將之前選的 Place type 改回 **Not sure**。即使已有照片，缺名稱也不得實際送審。
2. **Specific area · Optional** 填 `TEST Fourth floor, corner by the windows`；加長到多行，確認欄位隨內容增高。
3. 自訂容易理解的公開名稱 `TEST Fourth-floor window seating` → 選至少一個降溫設施，確認有一張照片 → 確認符合送審條件；切換 Outdoors／Both 也使用相同規則。
4. 回表單上方 **Change location** → 調整地圖位置 → **Use this spot** → 答案保留。
5. 關閉本次測試表單。若從 Saved Pin 進入，核對原 Pin 的位置與私人文字沒被改動。

**檢查：** 沒有正式名稱的位置也需要自訂易懂名稱及照片。場所分類和進入資格可以留 Not sure；照片不能替代名稱，名稱也不能免除照片。

### B06｜選填資料在同頁完成

1. 在 B01 或其他公開表單 → 展開 **Entry and seating**。
2. **Who can use this spot?** → **Limited access**，確認不會出現額外填寫區塊；**Cost to use** 選 Free to use，確認免費與 Limited access 可以並存；目前沒有填具體限制對象的欄位。
3. **Time limit** → Other duration… → Hours 選 1、Minutes 選 30。
4. 試 **Seating／Wheelchair accessible**，以及 Facilities 的 **Toilets／Staff on site when open／Tables**；再收合兩組。確認沒有 Wi-Fi／Power outlets／Laptop use allowed。
5. **Anything else people should know?** 填 `TEST public note`；重新展開原分組，確認答案保留。

**重點回饋：** Who can use this spot? 有 Everyone／Limited access／Not sure，皆不擋送審。Cost to use 有 Free to use／Purchase required／Entry fee／Not sure。沒有 Who is it limited to? 或 Tickets and booking 填寫區塊。Time limit 是場所公告限制，不是這次造訪待了多久。

**重測錄影中的跳位：** 點一下上方 Place name → 往下滑 → Entry and seating → Cost to use／Seating／Posted time limit，分別開啟、取消及選值。開選單時背景應停在原位，不跳回名稱區；這項測試不需要送審。

### B07｜返回與改選場所

1. Explore → ＋ → Add cooling information → 搜尋並選尚無降溫資訊的 British Museum → Indoors or outdoors? 選 Indoors → Air conditioning。
2. 左上返回 → 再搜尋並選同一場所 → 確認答案保留。
3. **Change place** → 搜尋並選 **Tate Modern** → 讀 **Change to a different place?** → **Keep current place**，或點彈出框外取消 → 返回原表單。
4. 再 Change place → Tate Modern → 確認 **Change place** → 應開 Update place details，帶入 Tate 的既有資料，不保留剛才為另一場所選的 Air conditioning。

**觀察：** 是否分清返回、取消換場所、確定更換？同一份尚未關閉的公開表單在記憶體保留答案；它不是永久草稿。從已知場所直接進表單時可能沒有第一層返回鍵，用 Change place 進選擇頁即可。

### B08｜離開公開表單而不誤送

1. 在公開表單改一項答案 → **Close** → 讀 **Discard this place contribution?**。
2. **Keep editing**，或點彈出框外取消 → 確認答案仍在。
3. 試向下滑關閉 sheet，觀察是否保護未送出的答案；若沒有預期反應，截圖／記錄，不必反覆滑。
4. 最後 Close → **Discard and close** → 重新進同一入口，確認本次未送出的公開答案不會當成已送審資料。

**目前邊界：** 公開場所表單沒有 Finish later／跨重啟續填。向下滑的完整行為尚未完成原生驗證；Close 是明確可用的出口。iOS 彈出框不一定顯示文字取消鈕，點框外也可取消。

### B09｜只修正既有 Cool Spot 的一項資料

1. Explore → John Harvard Library → 第一區末端 **Suggest an edit** → 確認標題 Update place details、既有設施已選好。
2. 先不修改 → 按 Send for review；應顯示 Change at least one detail before sending an update，不建立提案。
3. Entry and seating → Seating → 選與原值不同的項目 → 讀 **Your changes**。
4. 改回原值 → 再按 Send，若無其他改動應提示需修改一項、不提交；再改一次，留給 B11 送審。

**其他入口：** Saved → Places → 已收藏的 John Harvard Library → Suggest an edit；或 Explore → ＋ → Add cooling information → John Harvard Library。都應開既有資料的修正表單。

### B10｜照片：選取、取消、更換、移除

**狀態：新位置一律需要照片已實作；完整系統照片分支待 owner 重測。**

1. 在 B03 自訂名稱戶外表單 → Add photo → 先取消系統選擇器；其他答案應保留。
2. 再 Add photo → 選一張測試照片 → 等待載入 → 確認無須另勾「能辨識地點」開關。
3. **Replace photo** → 選另一張 → **Remove photo**。
4. 新地圖位置即使有名稱，移除照片後也不得實際送審；再加入照片。另在 B01 已由搜尋選到的 British Museum 表單，試一次移除選填照片，確認此分支沒有新增照片要求。

**若自然遇到錯誤：** Photo couldn’t be loaded → **OK** → 重新 Add photo。不要刻意找壞檔案或清空相簿；這項不是每次都能重現。照片不會真的上傳。

### B11｜送審與找回結果

**需要覆蓋四種來源時：** 分別用 B01 的普通場所、B03 的自訂名稱戶外位置、B04 的有名新場所、B09 的既有 Cool Spot 修正。每次重新準備一份表單，完成 B11 → E01 後再送下一筆；控制器只處理最新一筆場所提案，不能指定較早的待審案。其他案例可能已要求丟棄表單，不要假定四份未送出答案會同時保留。送出前完成要保留的返回／照片測試。

1. 在一份已填好的測試提案／修正中 → **Send for review**。
2. **Sent for review** → 讀說明 → **Done**；若回到 Saved／地點的父頁，先按 Done／× 回主畫面。
3. You → **Places you’ve added or updated** → **In progress** → 找剛才的地點與 **In review**。
4. 重啟 App 後確認提案仍在 In review，再接 E01。送審資料與照片會保存，但此時不得出現在公開地點頁。

**目前止點：** 這些紀錄是狀態展示，不能點進去編輯、補件或開提案詳情。送審不會立即改掉地圖上的場所資訊。

### B12｜來源不正確／移除全部降溫設施

1. John Harvard Library → Suggest an edit → **Name or place type is incorrect** → Suggested name 改為 `TEST Updated Library`；Suggested place type 可從既有分類選擇；Additional details 可略過 → 核對 Your changes 的名稱／類型前後值。
2. 在同一修正表單，取消全部原有降溫設施。
3. 應出現 Required 的原因欄位；先按 Send，應定位原因欄並提示、不能實際提交 → 填 `TEST the cooling facilities are no longer available` → 核對可送審及 Your changes。
4. 這是驗證分支，最後 Close → Discard and close 即可。

**目前行為：** 更正欄位預填原始名稱／類型；只修改有誤的項目即可。送出的是等待審核的建議，保留原始值，不會改動 Apple Maps 或已發布場所。

## C：分享人數、到訪資格、離開

**準備 C 與 D：** 使用 John Harvard Library、Example Community Room、Example Shaded Garden 尚無自己當次已發布回報／既有草稿的狀態；不修改原有紀錄。館方／社群範例回報不影響此資格。若前提不足，標記「C/D 前置資料不足」或使用隔離 QA，不刪舊回報、不改系統時間。下列 Garden／Room 簡稱分別指這兩個 Example 場所。

**切換模擬所在地的完整路徑：** You → Settings → Prototype controls → **Nearby place** → 選地點或 **Away from all Cool Spots** → 返回 Settings → 返回 You → Explore。它只改測試資格，不會真的追蹤位置，也不會把地圖的固定示範座標搬到該場所。

### C01｜理解人數動畫

1. Explore → 任一 Cool Spot → **How this works**（在 Here to cool down? 區塊下方）。
2. 讀說明、看地圖上 **2 → 3** → **Pause example** → **Resume example**。
3. **Done** → 回地點頁，比較卡片顯示的人數；其中可能包含固定示範基準。

**觀察：** 你是否理解動畫只是示例？是否誤以為人數等於空位、溫度或全部在場人數？若目前已分享，先 Stop sharing 才會重新看到此入口。

### C02｜只分享人數，不寫回報

1. 用上述設定把 Nearby place 設為 John Harvard Library → Explore → John Harvard Library（正常目錄即可）。
2. 記下人數 → **I’m cooling off here**。
3. 確認人數加一、出現結束時間 → 收成半卡確認地圖標記顯示 1 → 再展開，先不要選下方體感 → **Stop sharing**，卡片歸零。
4. 關閉地點 → You → Your reports → 查看 **Visits you can report**。

**應理解：** Stop sharing 停止人數分享，但已建立的私人開始回報資格仍在；沒有選寫回報前，不應當成你填到一半的報告。

### C03｜離開七天後才開始回報

1. 接 C02，用設定選 Away from all Cool Spots → You → Your reports → Visits you can report。
2. 確認 John Harvard Library 還有 Share how it felt，先不要點。
3. You → Settings → Prototype controls → **Simulate a visit 7 days ago** → 返回 Your reports。
4. 日期應變成七天前，**Share how it felt 仍可用**。點進去應保留該造訪日期；Finish later 可留下草稿。

**檢查：** 確認過的到訪沒有開始／完成期限。此控制會將所有已確認但尚未開始回報的造訪移到七天前，並設為 Away；只在隔離 QA 的本輪資料操作。這不是實際等待七天的測試，也不改既有草稿與已發布回報。

### C04｜離開前什麼都沒做／只有收藏

1. 先在 You → Your reports 確認另一地點（優先 Example Shaded Garden）沒有未完成回報；不刪除舊資料。
2. Nearby place 選 Away → Explore → 該地點 → **Save**（若已收藏略過）→ 查看 Share how it felt 是否仍不可用。
3. **Why can’t I share?** → 讀說明 → Done；同時查看 I’m cooling off here 在不附近時是否不可用。

**前提：** 該地點不能已有確認過的到訪。若有，標為不適用；沒有提供刪除舊到訪紀錄來製造這個狀態的入口。收藏本身不會提供資格。

### C05｜分享人數後，走體感捷徑

1. Nearby place 改 Example Community Room → Explore → Example Community Room → I’m cooling off here。
2. 分享成功區塊下方 → **A little cooler** → 進 Your report。
3. 確認體感已預選；改選 **Not cooler** → **Finish later**。
4. 回地點頁 → Stop sharing；保留這份草稿，D 輪會繼續使用。

**觀察：** 是否清楚分享人數與發布體感是兩件事？先選捷徑也應能修改答案。

### C06｜切換分享地點、重新啟動及十分鐘到期

1. 在附近的 Example Community Room → I’m cooling off here → 記下結束時間。
2. 關閉地點 → Nearby place 改 Example Shaded Garden → Explore → 該地點 → I’m cooling off here。
3. 回前一地點確認只有新地點仍有自己的分享；回新地點記下結束時間。
4. 關閉並重新開啟 App，在結束時間前查看分享仍在；不用重按分享。等待到顯示的結束時間後再看人數。

**觀察：** 自己只同時分享一個地點；重啟不延長這次的十分鐘，到期移除的是自己的那一人，不會讓其他示範人數全部歸零。這項不會自動發布回報。

## D：開始、續填、發布與閱讀回報

這輪若選到已發布本次造訪的地點，請更換；目前沒有編輯／刪除已發布回報的入口。**先做續填與丟棄，再做 D07 的發布**，避免提早關閉這次造訪的測試入口。

### D01｜不分享人數，也能開始回報

1. Nearby place 選 Example Shaded Garden → Explore → 該地點 → Visitor reports 下方 **Share how it felt**。如果已有草稿，按 Continue report 即可，但略過「預設未選」觀察。
2. 初次進入時先不選體感，確認 Publish report 不可用；記錄原 Visit time。
3. 選 **Not cooler**，確認 Publish 可用；不必填原因、停留或留言。
4. 先按 **Finish later**，不要發布 → 查看地點頁出現 Continue report。

**觀察：** 這條獨立路徑不應新增人數；「沒有變涼」也能回報。若 C06 的人數仍在，先 Stop sharing 再比對。

### D02｜選填、改時間與返回

1. You → Your reports → Unfinished → Example Shaded Garden 的 **Continue report**。
2. **What helped** 展開 → 選 Tree shade、再取消一次；選好測試答案後收合。
3. **Time here** → 選一個時長；再試 **Prefer not to say** 或 **Not added**，最後留自己想測的答案。
4. 留言框填 `TEST D02 這裡有樹蔭` → **Visit time** 改為稍早的時間 → Finish later。

**觀察：** 訊息是否好找、會否誤會每一題都必填？Visit time 是造訪時間，不是現在按發布的時間；不能選未來時間。

### D03｜離開、重啟，再續填

1. Nearby place → Away from all Cool Spots → 返回主頁 → 關閉並重新開啟 App。
2. You → Your reports → Unfinished → Example Shaded Garden 的 Continue report。
3. 核對 D02 的體感、設施、停留答案、留言及 Visit time → Finish later。

**觀察：** 從 You 能否直接找到草稿？不應要求重新到場、重新分享人數或先收藏。

### D04｜已開始的草稿不受時間限制

1. You → Settings → Prototype controls → **Simulate a visit 7 days ago**。
2. 返回 You → Your reports → Unfinished → Example Shaded Garden 的 Continue report。
3. 確認答案仍可修改、Publish 可用 → Finish later。

**注意：** 控制器只調整未開始回報的造訪日期，所有確認過的到訪都繼續可回報；已開始草稿保留原答案及日期。

### D05｜同時有兩份草稿，從不同入口找回

1. You → Your reports → 檢查 C05 的 Example Community Room 與 D01 的 Garden 草稿都在 Unfinished。
2. 打開 Room 的 Continue report → Finish later → 再打開 Garden 的，確認兩份答案沒有混在一起。
3. Explore → Garden → Continue report → Finish later。
4. 若 Garden 已收藏，關閉地點 → Saved → Places → Garden → Continue report → Finish later。

**觀察：** You、地點頁和已收藏地點是否回到同一份草稿？Saved 沒有收藏該地點時不會憑空出現這條路徑。

### D06｜丟棄測試草稿與重新開始

1. You → Your reports → Example Community Room 的 Continue report → 頁面下方 **Discard answers**。
2. 先點彈出框外取消 → 確認答案仍在。
3. 再 Discard answers → 確認丟棄 → 檢查該草稿消失；Away 時仍可在 Visits you can report 重新開始。
4. You → Your reports → Visits you can report → Example Community Room 的 Share how it felt → 應為新的空白表單 → 選一項 → Finish later。

**只丟棄 C05 測試草稿。** 這只清除答案，保留已確認到訪；不刪除 Saved 或以前已發布回報。

### D07｜發布回報與防止同次重複發布

1. You → Your reports → Garden 的 Continue report → 檢查內容／Visit time → **Publish report**。
2. 完成頁 → **Done** → You → Your reports → **Published** → 打開這一則。
3. 核對 Visit、Published、體感與選填答案；Unfinished 應少一份，Room 的測試草稿仍在。
4. 返回 Explore → Garden → 應看到 **You’ve shared this visit**；檢查人數沒有因發布回報而增加。

**也測另一次到訪：** 模擬在 Garden 附近 → 該場所頁 → **Share a new visit** → 選體感 → Finish later。確認舊回報仍在 Published、新草稿單獨存在，人數沒有增加。Published 沒有編輯／刪除入口。

### D08｜最新預覽、全部回報、自己的與範例格式

1. Explore → **Example Shaded Garden** → **Visitor reports**：同區讀體感統計、分布、最新預覽，再點 **Read all reports**。
2. 核對 D07 本機新回報的 Visit time／答案／文字；有填的資料才出現，正常 API mode 不補 Example visitor report。
3. 返回地點頁 → 直接點預覽文字應留在原卡；只有 **Read all reports** 開啟回報清單，統計標題旁沒有另一個 View all。
4. 返回 You → Your reports → Published 查看 D07 自己的版本；若要比較 Example visitor report，另用明確 fixture preview，不把它視為正常 API 回報。

**排序：** 依 Visit time，最新在前，不分作者；不是依按下發布的時間。造訪時間填得較早的新回報不一定占預覽。範例有固定日期和 Example 標示；未填的選填欄位可略過，不應改成另一套格式。

**補充觀察：** You 裡自己的已發布詳情共用 Visitor reports 的閱讀格式，另在下方補充 Published 時間與收到的感謝。

## E：審核狀態、感謝、帳戶與設定

### E01｜提案保存與 API 發布界線

1. 先在隔離 QA 依 B11 送出一筆本輪 TEST 場所提案；核對 You → Places you’ve added or updated 中最新提案為 **In review**。
2. You → Settings → Prototype controls：正常 API 模式不應有 **Publish locally**，應有 Public place publishing requires the backend 的說明。
3. 返回提案詳情，原答案／照片仍保留，狀態仍為 In review；Explore 的 API 清單不應因提案而新增／覆蓋場所。
4. 關閉表單後正常重啟，再確認私人提案仍在；只有正常 API 清單從服務重新載入。

**界線：** Needs clarification／Do not publish 仍是本機狀態模擬，沒有遠端送審／上傳或真正發布。舊 Publish locally 只在明確 memory-only 範例模式保留；其 idempotence／identity／photos／archive 行為由本輪兩項 legacy regressions 驗證，不把它們說成正常 API UI 或跨裝置服務。原提案／私人照片不刪除，歷史公開快照保存但不重播。

### E02｜對別人的範例回報送感謝、取消

1. Explore → Example Community Room → Visitor reports → Read all reports → **Example visitor report** → **Send a popsicle**。
2. 如果第一次出現 **Send a little thank-you?**，先 Cancel；再點 Send a popsicle → 確認送出。已看過說明時可能直接切換為已送。
3. 確認 **Popsicle sent · Demo** → **Undo** → 再送一次，最後可 Undo。
4. 查看自己的回報，確認沒有對自己送感謝的按鈕。

**觀察：** 是否清楚這是感謝作者，不是涼度投票？本地示範不通知真人，也不改變回報排序或人數。

### E03｜收到感謝後找回對應回報

1. You → Settings → **Popsicle thank-you example**，先讀 **For your report at…** 指定的是哪一筆。
2. **Simulate receiving a popsicle** → 返回 You → Your reports → Published → 開對應地點的最新指定報告。
3. 查看收到感謝的 Example 說明；可重啟後檢查紀錄仍在。

**前提：** 這個按鈕就在 Settings，不是在 Prototype controls 裡。尚未發布任何回報時，只會看到先發布的提示。

### E04｜帳戶、Cool Hunt 與回到任務

1. You → **Sign in** → Your account → 讀說明 → 若要試模擬登入，再點頁內 **Preview account**。
2. 返回 You → **Your account**，查看登入後樣子 → 返回。
3. **Cool Hunt** → 讀 Shade finder、Place types discovered → 橫向滑動類型列 → 讀 Your help → 返回 You。

**目前止點：** Preview account 只是本次使用的帳戶示範，沒有 Apple／Email 驗證、跨裝置同步或 Sign out。Cool Hunt 的類型解鎖會對本次人數分享反應，但 Shade finder 1 of 2 與部分貢獻數是固定示例；方塊不可點進。也沒有獨立 All contributions 的目前導覽入口。

### E05｜外觀、大字、減少動態與輔助入口

**選做，不列入目前預設驗證。** 只有 owner 指定相關問題時，才在 iPhone 17 Pro Max 檢查對應一項並還原設定；不跑 iPad、尺寸／字級／外觀矩陣。下列保留各設定的查找路徑，不是要求逐項執行。

1. You → Settings → Appearance → **Dark** → 返回 Explore → 打開一個地點及其回報；再試 **Light**／**Match System**，最後恢復你原來的設定。
2. 若使用 iPhone／Simulator 的系統 Settings：Accessibility → Display & Text Size → Larger Text → 放大文字 → 回 Cool Spot 看表單、回報、送出鈕；之後恢復原值。
3. 系統 Settings → Accessibility → Motion → **Reduce Motion** → 回地點 → How this works，查看靜態完成狀態；之後恢復原值。系統語言不同時按相應中文名稱找設定。
4. 回地點頁確認沒有不可用的 **Report a problem** 入口；要修正場所資料，使用第一區末端 **Suggest an edit**。

**觀察：** 大字是否擠壓、遮住操作？深色是否難讀？Suggest an edit 是否和「分享這次體感」分得清？不要為此更改自己的資料或開啟不需要的系統權限。

## 無法靠一般點擊完整重現的分支

下面也是產品流程範圍，但現在不要求你靠猜測把它們叫出來。

| 分支 | 若自然出現的點擊順序 | 目前限制／測試方式 |
|---|---|---|
| 新提案與既有地點重複 | This place is already on Cool Spot → **Review update** → 核對 Your changes → Send for review；或 **Keep editing** 取消 | 已知 Cool Spot／Apple 場所身份可直接對應既有資料；無來源身份的新位置需座標幾乎完全相同，且符合特定點位或名稱條件。手指點地圖不易觸發，不是模糊近距離去重。需要另備測試資料，模型證據另記。 |
| 照片讀取失敗 | Photo couldn’t be loaded → OK → Add／Replace photo | 本輪不要求刻意損壞圖片；如遇到，確認其他答案留著。 |
| 場所提案送出失敗 | Not sent → Keep editing → 補正後再 Send for review | 沒有「模擬失敗」按鈕，也沒有真實網路上傳；正常按鈕驗證可能讓你遇不到。 |
| 個人回報發布失敗 | Report wasn’t published → Keep editing → 確認 Visit time 再 Publish report | 沒有固定 UI 開關可觸發；不可把沒有遇到寫成已通過失敗復原。 |
| 完全空白資料狀態 | Saved 的 Nothing saved yet／You 的 No reports yet／無場所提案 | 全新隔離 QA 的正常啟動沒有私人收藏、Pin、提案或自己的回報，但目錄與三個社群示例仍在。已有裝置須保留原有資料，不使用 memory-only 舊 fixture 或清空 owner 裝置來製造此狀態。 |

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
| 返回／滑動與選單焦點是否穩定；外觀／輔助設定只依 owner 指定選做 | B05、B06、B08、E05 |

### 本輪結果紀錄

目前只有上方列出的歷次證據與 owner「可用、仍需驗證」的總評；2026-09-23 文件校正沒有新增逐項通過紀錄。下表是尚未取得的 owner 回饋，不表示目前已授權開始跑完整走查。收到實際回饋後在此記錄，不新增另一份 findings 文件。

| 日期／版本 | 編號 | 觀察與完成方式 | 決定／修正 | 復測結果 |
|---|---|---|---|---|
| 待本輪回饋 | B04 | 尚未記錄 | — | 待測 |
