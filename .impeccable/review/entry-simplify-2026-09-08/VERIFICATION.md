# 移除兩個填寫區塊

依使用者要求，公開新增／更新表單移除 Who is it limited to? 與 Tickets and booking；清理相應 FocusState，並同步 B06 與現行流程文件。保留資格、費用、座位與時間限制選項。資料模型保留既有資料的讀取及顯示相容性。

2026-09-08 編譯通過，紀錄：`/tmp/cool-spot-entry-simplify-20260908-build.log`。iPhone 模擬器以 Limited access 的既有場所更新表單檢查：兩個輸入區塊皆消失，費用後直接接 Seating／Tables／Time limit，見 `form.png`。本輪僅刪除 UI 與未使用焦點，未新增或重跑模型測試，未重跑 iPad 驗證。

新版安裝並啟動於原本模擬器。安裝前後 journey snapshot、感謝紀錄與外觀偏好校驗值一致。隔離測試手機已關閉。
