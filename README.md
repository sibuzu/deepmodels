# RTX WSL: TW / TWN monthly model update (2026-10-19)

This workflow downloads directly from Google Drive and runs independently of
China, Windows G: and Windows Conda. The upstream data producer must continue
uploading complete monthly ZIPs to Google Drive before this procedure starts.

Current restored state (2026-10-19): all 28 October TW/TWN MDL/PT files have been
restored byte-for-byte to china-20261019. The September TW/TWN parquet files were
freshly copied from China and overwritten; all 546 historical parquet SHA values
match the original China inventory. predicts/ has been added to the Git index,
not committed or pushed. Stale RTX provenance sidecars for the two overwritten
September files were removed; originals and model backups are under
/dvol/modeltrain-work/rollback-china-20261019-111858.

Manual month-end entry point (written but NOT executed):
  cd ~/git/ModelTrain
  ./TW/monthly_update.sh
It prompts for the target model month, defaulting to the next calendar month in
Asia/Taipei. For October month-end, or when running late in November, specify:
  ./TW/monthly_update.sh 202611
This trains 202611 MDL/PT using October data, and creates October parquet using
the existing 202610 models. It runs 14 models concurrently for 50 epochs, converts
PT under Python 3.6 / Torch 1.0.1 CPU, validates parquet, commits with message
"202611", pushes the CURRENT Git branch to origin, then uploads only those 14 PT
and two parquet files (plus provenance JSON) to the existing ts2013 Drive paths.
The actual repository is /dvol/deepmodels (plural). Git identity and remote push
access are checked before downloading/training. No branch checkout, force-push,
JP/CN update, Docker restart or scheduling is performed by this entry point.

Date completeness is checked against CSV contents, not Google Drive upload time.
Expected weekdays exclude Saturday/Sunday only; holidays/typhoon closures are
deliberately presented to the operator. Missing weekdays, missing representative
stocks on the final weekday, stale ZIPs or a >10% final-day coverage drop prompt
"c = continue / q = quit", with quit as default. No model training occurs until
this check is accepted. Both TW_STK_DAILY.zip and StockDataN.zip remain required.

Each monthly run keeps immutable input snapshots under its run directory. If the
download already includes dates after the input month, only the snapshots are
trimmed at that month-end. Thus later dates do not influence the original trainer's
pre-split weight normalization; the downloaded cache and native formulas remain
unchanged. This month-bounded wrapper has only synthetic-data/mock-command tests
so far; it has not trained/pushed/uploaded production artifacts.

Commit scope is only target-month MDL/PT plus ALL predicts/ changes, including the
staged original China history. Other staged paths cause preflight to stop, and
other unstaged model months/SOP/code are not automatically committed. Google Drive
uploads use checksum/size verification and never sync/delete other months.
Keep run.json and commands.log under /dvol/modeltrain-work/monthly/<run>/.
After interruption, continue the same frozen inputs and completed stages with:
  ./TW/monthly_update.sh --resume /dvol/modeltrain-work/monthly/<run>
Completed file hashes are verified before skipping a step. Training retries always
start from the previous month, rather than appending another 50 epochs. Existing
target-month MDL/PT files block a new run unless explicitly forced:
  ./TW/monthly_update.sh 202611 --force
The --force flag directly authorizes overwrite without another prompt or old-model
backups (including the parallel trainer's target-model backup). Missing-data prompts
remain active. Use --resume for interrupted work, or --force for an entirely new run;
these two options cannot be combined.

After the workflow, verify the latest run for the target month independently:
  ./TW/check_monthly_update.sh 202611
The check reads completion state, local artifact/snapshot SHA-256, committed file
contents, remote Git branch ancestry, and sizes/MD5 of all 18 Google Drive files.
It exits nonzero on any failure and writes check-result.json in that run directory.
It does not train, commit, push or upload. To check a particular run instead:
  ./TW/check_monthly_update.sh --run /dvol/modeltrain-work/monthly/<run>

Recurring update scope (operator instruction, 2026-10-19): TW/TWN only.
Skip JP and CN downloads/training in the regular update. The Windows SOP at the
bottom is historical reference; its JP/CN checks are not part of this workflow.
The active update scripts already download only these two Taiwan input files:
  00David/TW_STK_DAILY.zip
  TW/TSE/day/StockDataN.zip
StockDataN.zip remains an actual dependency, not just a legacy filename check:
both trainers read and concatenate it after TW_STK_DAILY.zip before preprocessing,
and TW/TWN parquet preparation reads both ZIPs too. After candidate filtering,
duplicate training keys retain the first source (TW_STK_DAILY). Weight normalization
is computed BEFORE this cross-source deduplication, so duplicate supplement rows
can still affect training weights. Removing the supplement is a data/algorithm
change and has not been done as part of this dependency inspection.
Local ZIP inspection on 2026-10-19: StockDataN has 632 symbols in RuleTable.xml,
627 also present in TW_STK_DAILY and 5 absent there (00718B, 00784B, 00790B,
00794B, 00925). At least the 00718B / 2019-12-20 sample is present in both
families' 202610 training sets and can only come from StockDataN. This example
is not a count of all supplement contributions; overlapping symbols may also
supply historical dates absent from the first ZIP.

Code: /home/jack/git/ModelTrain
TW MDL models: /dvol/deepmodels/pytorch/tw
TWN MDL models: /dvol/deepmodels/pytorch/twn-30
TWN runtime alias: /dvol/deepmodels/pytorch/twn -> twn-30
Local PT models: /dvol/deepmodels/ptmodel/{tw,twn}
Input ZIPs: /dvol/modeltrain-data
Training and prediction caches: /dvol/modeltrain-work/cache
TW parquet: /dvol/deepmodels/predicts/tw/YYYY/pred_tw_YYYY_MM.parquet
TWN parquet: /dvol/deepmodels/predicts/twn/YYYY/pred_twn_YYYY_MM.parquet
Logs: /dvol/log/modeltrain
Rollback baseline: Git tag china-20261019 in both repositories

Training-data audit finding (2026-10-19; resolve before claiming exact China parity):
The original trainers calculate weight normalization over all prepared dates BEFORE
splitData applies the model-month cutoff. China caches end 2026-09-30, while the
current RTX input ZIPs/caches extend through 2026-10-16. Thus October data influences
the September-ending training weights even though October rows are not trained.
For 202610, the full training keys/order, float32 X and targets match China exactly,
but RTX weights are scaled by TW 0.9969425721 and TWN 0.9942567514 relative to China.
The early production migration test MDL/PT files used these RTX weights; they have
since been restored to china-20261019 as recorded above. Diagnostic outputs remain
outside this repository, and the reports below describe those historical tests.
Use an identical immutable source snapshot to reproduce a historical run. A future
change to compute normalization only before the model-month cutoff must preserve
the original pre-dedup normalization semantics and be validated separately. The
standalone trainers keep their original behavior; the new monthly wrapper bounds
its private input snapshots by month instead. A newer live ZIP alone does not ensure identical
historical training weights, even when all selected X/target values are unchanged.

1. One-time Python environments (uv):
   cd ~/git/ModelTrain
   ./TW/setup_uv.sh
   ./TW/setup_pt_uv.sh

   .venv: Python 3.10.20 / PyTorch 2.0.1+cu118 for training and prediction.
   .venv-pt: Python 3.6.13 / PyTorch 1.0.1 CPU for legacy local PT export.
   PT setup uses project-pinned uv 0.13.1 and independently verified Python
   archives. It does not require China or a Conda installation.

2. Google Drive authorization (remote ts2013 already configured on RTX):
   ts2013 points to My Drive root for 2013turbostar@gmail.com.
   Current RTX remote uses the operator's own Desktop OAuth client.
   Account and both input ZIPs were verified after authorization.
   Publishing status: In production (confirmed by operator).
   Use your own Google Desktop OAuth client for long-term operation; rclone's
   shared client_id will stop working during 2026.
   https://rclone.org/drive/#making-your-own-client-id

   Create/choose a Google Cloud project, enable Google Drive API, configure
   External audience and drive scope, create a Desktop app client and download
   its JSON. Publish the app to In production; Testing grants expire in 7 days.
   Import downloaded credentials and reauthorize without printing secrets:
   /usr/bin/python3 TW/setup_drive_client.py /mnt/c/Users/jack/Downloads/CLIENT_FILE.json
   Select 2013turbostar@gmail.com in the browser. The helper verifies account
   identity and both input ZIPs before replacing ts2013; it saves a private
   backup of the old configuration. No credentials belong in Git or chat.

3. Monthly sequence: when September 2026 source data is complete:
   cd ~/git/ModelTrain

   (1) Train the NEXT month's model, 202610:
       Parallel option: train TW A-G and TWN A-G together (14 CUDA processes):
       ./TW/update_parallel.sh 202610 -n 50 --seed 202610 --dry-run
       ./TW/update_parallel.sh 202610 -n 50 --seed 202610

       update_parallel.sh checks/downloads the input ZIPs once. train_parallel.sh
       has the same interface but uses existing local ZIPs. Verified TW/TWN
       caches are each prepared once; workers share per-run float32 NumPy maps.
       The default is 14 concurrent models; --jobs 1..14 changes concurrency.
       Each family/submodel has a stable derived seed, so changing --jobs does
       not change its RNG stream. Seed/TF32/deterministic settings differ from
       the old shared RNG stream; do not expect old MDL hashes to match.

       As in the original trainer, an existing target-month MDL is continued.
       To retrain 202610 from 202609 without deleting current MDL files first:
       ./TW/train_parallel.sh 202610 -n 10 --seed 202610 --from-previous --dry-run
       ./TW/train_parallel.sh 202610 -n 10 --seed 202610 --from-previous

       All results first go to /dvol/modeltrain-work/parallel/<run>/jobs/<id>/.
       The controller publishes the 14 target MDL files only after all workers
       and finite-weight/CPU-inference validations succeed. Replaced originals
       are backed up under <run>/backups; a publication error attempts rollback
       of the files already replaced. Publication is atomic per file, not one
       filesystem transaction for all 14; restart consumers after completion.
       Logs, initial snapshots, source/input hashes, seeds and results are in
       <run>/run.json and jobs/{tw,twn}-{A..G}/console.log. The shell entry points
       share family locks with the sequential update/train scripts. Do not run
       raw trainer Python commands concurrently against the same model files.

       Small diagnostic run without publishing any MDL files:
       ./TW/train_parallel.sh 202610 -n 10 --from-previous --no-publish --sample-rows 1024
       --sample-rows is rejected unless --no-publish is present. --run-dir can
       select a new directory for the run. Omit --sample-rows for real training.
       This entry point trains MDL only; run the PT conversion steps below later.
       The normalization/cutoff finding at the top of this SOP remains unchanged.

       Sequential alternatives remain available:
       ./TW/update_tw.sh 202610 -c -n 50 --seed 202610
       ./TW/update_twn.sh 202610 -c -n 50 --seed 202610

       Each update script checks/downloads both ZIPs, trains its model family,
       and validates all seven checkpoints. train_tw.sh / train_twn.sh only
       train using existing local ZIPs. TWN has 20 inputs; TW has 17 inputs.
       The default is 50 epochs when -n is omitted.
       The 202610 training target dates end on 2026-09-30.
       Existing target-month checkpoints are continued by the original trainer.
       For a fresh retrain, preserve a Git baseline then remove only the seven
       target-month MDL files. Do not rerun this command merely to convert PT
       or create parquet; it would train the target month again.

   (2) Convert that same 202610 month for local consumers:
       ./TW/convert_pt_tw.sh 202610 --dry-run
       ./TW/convert_pt_tw.sh 202610 --report /dvol/modeltrain-work/pt-tw-202610.json
       ./TW/convert_pt_twn.sh 202610 --dry-run
       ./TW/convert_pt_twn.sh 202610 --report /dvol/modeltrain-work/pt-twn-202610.json

       Each command converts only A-G for its model family and exact month.
       Existing PT files cause
       an error; pass --overwrite explicitly when replacing them is intended.
       Export uses PyTorch 1.0.1 CPU, preserves the original warm-up and trace,
       reloads each temporary PT and compares inference at batch sizes 1/16/100
       before atomically replacing the output file.

   (3) Optional parquet generation for the completed September inputs:
       Skip this step when only training/PT output is requested.
       ./TW/predict_tw.sh 202609
       ./TW/predict_twn.sh 202609

       TW_Predict.py uses the SAME month's A-G MDL models: September parquet
       uses ModelT{A..G}202609.mdl, not the newly trained 202610 model.
       The 202610 model has already seen September during training; using it
       for September would change the original historical prediction semantics.
       Prediction reads MDL directly; it does not require PT conversion output.
       TW parquet date/month follows T1date (prediction/trade date). A row
       based on the last August trading day can therefore appear in September.
       Output: /dvol/deepmodels/predicts/tw/2026/pred_tw_2026_09.parquet
       TWN output: /dvol/deepmodels/predicts/twn/2026/pred_twn_2026_09.parquet
       TWN uses the September ModelN{A..G}202609.mdl files. Its month follows
       input date (T0/date), whereas TW follows T1date. TWN preserves the
       existing close25/vol25 preprocessing and 20-feature input contract.
       Columns: date, stock_id, A0..G0, A1..G1; sorted by date and stock_id.
       Inputs retain C#-compatible four-decimal midpoint-to-even rounding.
       Non-finite feature rows are excluded and listed in the prediction-cache
       JSON's data_quality field. Prediction outputs must all be finite.
       --force rewrites the parquet. Changed inputs or model hashes also cause
       regeneration automatically; a verified unchanged output is skipped.

   For complete October data, the sequence becomes:
       ./TW/update_tw.sh 202611 -c -n 50 --seed 202611
       ./TW/update_twn.sh 202611 -c -n 50 --seed 202611
       ./TW/convert_pt_tw.sh 202611 --report /dvol/modeltrain-work/pt-tw-202611.json
       ./TW/convert_pt_twn.sh 202611 --report /dvol/modeltrain-work/pt-twn-202611.json
       ./TW/predict_tw.sh 202610
       ./TW/predict_twn.sh 202610

4. Data/cache behavior:
   ZIPs are reused only after matching cloud size and MD5. To force downloading:
       .venv/bin/python TW/download_tw_data.py --refresh
   Feather training cache (-c) is reused only if ZIP contents, stock list,
   trainer source and data-library versions match its recorded signature.
   Explicit prediction months have a separate bounded cache, covering only the
   requested range plus preprocessing history. Input, stock-list or code changes
   rebuild it. Prediction cache and training cache are not interchangeable.
   MODELTRAIN_DATA_ROOT, MODELTRAIN_MODEL_ROOT, MODELTRAIN_CACHE_DIR,
   MODELTRAIN_PREDICT_ROOT and MODELTRAIN_LOG_DIR override the default paths.

5. Current TW compatibility test (2026-10-19):
   The old seven 202610 MDL files were removed after verifying the Git baseline.
       ./TW/update_tw.sh 202610 -c -n 10 --seed 202610
   All seven finished 10 epochs, starting from their 202609 checkpoints.
   Training data: 2018-10-01 through 2026-09-30, 908018 samples.
   Reports/logs: /dvol/modeltrain-work/tw-202610-validation
   Native legacy PT export was first validated under
   /dvol/modeltrain-work/pt-migration-evaluation. The operator then authorized
   production TW/TWN PT export. Per-family validation reports are under
   /dvol/modeltrain-work/{tw,twn}-202610-validation/production-pt-validation.json.
   202609 parquet: 41576 rows; 191 non-finite UD3 rows excluded and recorded.

   Subsequent explicit September prediction comparison requested by operator:
   TW: 41576 finite rows; China has 191 additional all-nonfinite output rows.
   TWN: 41529 finite rows; China has 193 additional all-nonfinite output rows.
   Per-row raw-data audit confirms all 191/193 exclusions originate from
   TW_STK_DAILY.zip: B3 OHLC and volume are all zero, B2close is positive,
   and UD3=(B2close/B3close-1)*10 becomes positive infinity. The migration's
   added finite-input filter removes these rows; China retains all-NaN outputs.
   The two families share 185 affected T0 rows. TW also includes 6 August-31
   inputs by T1date, while TWN includes 8 September-30 inputs by T0 date.
   Full row lists: the comparison directory's tw-missing-rows-detail.csv and
   twn-missing-rows-detail.csv. No prediction rules were changed by this audit.
   All 14 September model SHA-256 hashes and rounded float32 model inputs match.
   Common prediction values are not bitwise identical across GPU platforms:
   maximum absolute differences TW 0.000091552734375, TWN 0.0001220703125.
   All individual zero-threshold sign decisions agree on the common finite rows.
   Replaying original code on China reproduces its saved parquet values exactly.
   Follow-up isolation using only stock 2330, 20 September dates and all A-G:
   repeated same-host runs are bitwise identical after changing random seeds.
   Cross-host differences persist with batch size 1, CPU mode, deterministic
   algorithms and TF32 disabled. Model-A layer tracing locates first GPU
   differences at net.0 Linear and first CPU differences at net.2 BatchNorm1d.
   Changing batch size alone also changes float32 output values on each host.
   This run confirms numerical backend/platform effects without using threshold
   comparisons. Stock-2330 evidence: the comparison directory's
   single-stock-2330/comparison.json and *-single-row-values.csv files.
   Detailed evidence: /dvol/modeltrain-work/predict-202609-china-comparison-20261019-050025/final-report.json
   TWN run (authorized after TW): ./TW/update_twn.sh 202610 -c -n 10 --seed 202610
   Latest operator instruction: finish TWN training and TW/TWN PT only;
   do not run further parquet generation during this test.
   Completion: TWN A-G each finished 10 epochs using 914254 rows, target dates
   2018-10-01 through 2026-09-30. All seven checkpoints passed finite-weight
   and CPU inference checks. Production 202610 PT A-G for both TW and TWN
   passed legacy PyTorch 1.0.1 CPU reload checks at batch sizes 1/16/100;
   maximum trace reload error was 0 for both families.
   The seven old TWN 202610 checkpoints were verified against china-20261019,
   then removed to warm-start from September, matching the TW test procedure.
   TWN training, PT and parquet verification results are recorded under
   /dvol/modeltrain-work/twn-202610-validation.

   Follow-up isolated training audit: TW-A and TWN-A only, 1024 training rows,
   128 separate probe-evaluation rows, batch 256, 10 epochs / 40 Adam updates.
   September A checkpoints match by SHA-256. Both native Dropout and controlled
   shared-mask diagnostics were run on CPU and GPU with deterministic settings
   and an explicit identical shuffle schedule. Native trainModel/_train_data and
   Adam definitions were extracted with AST to avoid production imports/writes.
   On RTX, original China code versus migrated code is bitwise identical for
   first-step outputs/loss/gradients/Adam state, final state and probe predictions.
   Repeated same-host runs also match exactly. Cross-host shared-tensor runs do
   not match bitwise, even with identical controlled Dropout masks. After 40 GPU
   updates, probe-prediction max differences with controlled masks are TW
   0.000002920627594 and TWN 0.000047869980335; parameter differences are retained
   in the report and are not judged using a prediction threshold. This is a small
   training-path test, not a full-run quality or trading-integration approval.
   Native-cache runs also expose the normalization discrepancy noted above.
   Audit: /dvol/modeltrain-work/train-a-china-comparison-20261019-053328
   Read REPORT.txt, comparison.json, probe.py, prepare.json files and run.json files.
   All diagnostic models are under the audit directory or China's private Temp
   directory. No production checkpoints, caches or China source files were changed.
   A fresh legacy load check of all 14 production 202610 PT files also passed
   Python 3.6.13 / PyTorch 1.0.1 CPU at batch sizes 1/16/100. SHA-256 matches the
   previous export validations; see pt-legacy-load-recheck.json in the audit.

   Parallel runner verification (2026-10-19):
   train_parallel.sh / update_parallel.sh now support all 14 TW/TWN models.
   Each model completed 10 epochs on 1024 sampled rows with --no-publish,
   both at --jobs 14 and --jobs 1, starting from the September checkpoints.
   All 79 state tensors per model and final losses were exactly identical
   between the two concurrency settings; file SHA values can differ because
   Torch serialization includes storage metadata, so tensors were compared.
   GPU telemetry measured a 7344 MiB whole-card peak with 14 workers, and
   timestamps verify all 14 training intervals overlapped. All existing
   production MDL/PT hashes remained unchanged. Actual 14-checkpoint publication
   to an isolated model root also preserved original backups and permissions.
   Unit checks cover worker failure cleanup, inherited/competing family locks,
   refused external overwrites, rollback, and diagnostic no-publish enforcement.
   All 24 TW workflow tests passed, including 8 new parallel tests.
   Evidence: /dvol/modeltrain-work/parallel-14-validation-20261019/comparison.json
   Detailed report: /dvol/modeltrain-work/parallel-14-validation-20261019/REPORT.txt

6. Docker restart and DavidTrade integration are performed by the operator:
   cd ~/git/docker/deepdavid
   docker compose -f compose.yaml -f compose.gpu.yaml restart deepdavid
   Use DavidTrade with deepdavid.solarsuna.com to confirm the newly trained TW.
   Confirm local PT use separately after the PT files are deployed.

7. Publish artifacts after local/integration validation:
   Review, commit and push only the intended models in /dvol/deepmodels.
   Parquet and its provenance JSON are under deepmodels/predicts for Git review.
   Python environments and the local data cache remain outside the model repository.
   Google Drive paths matching the old Windows copy scripts:
       PT: ts2013:期貨歷史資料/00David/MODELS/{tw,twn}/
       Parquet: ts2013:期貨歷史資料/00David/TW_STK_TICK/Predicts/{tw,twn}/YYYY/
   Upload only the selected month's files after review, for example:
       rclone copy /dvol/deepmodels/ptmodel/tw 'ts2013:期貨歷史資料/00David/MODELS/tw' --include 'ModelT?202610.pt' --checksum
       rclone copy /dvol/deepmodels/ptmodel/twn 'ts2013:期貨歷史資料/00David/MODELS/twn' --include 'ModelN?202610.pt' --checksum
       rclone copyto /dvol/deepmodels/predicts/tw/2026/pred_tw_2026_09.parquet 'ts2013:期貨歷史資料/00David/TW_STK_TICK/Predicts/tw/2026/pred_tw_2026_09.parquet' --checksum
       rclone copyto /dvol/deepmodels/predicts/twn/2026/pred_twn_2026_09.parquet 'ts2013:期貨歷史資料/00David/TW_STK_TICK/Predicts/twn/2026/pred_twn_2026_09.parquet' --checksum
   These upload commands have not been run as part of the migration test.

8. Rollback the October test checkpoints (choose the affected family):
   git -C /dvol/deepmodels restore --source=china-20261019 -- 'pytorch/tw/ModelT?202610.mdl'
   git -C /dvol/deepmodels restore --source=china-20261019 -- 'pytorch/twn-30/ModelN?202610.mdl'
   If October PT files have subsequently been replaced, restore those too:
   git -C /dvol/deepmodels restore --source=china-20261019 -- 'ptmodel/tw/ModelT?202610.pt'
   git -C /dvol/deepmodels restore --source=china-20261019 -- 'ptmodel/twn/ModelN?202610.pt'
   Restart DeepDavid after restoring MDL weights. Regenerate any affected parquet
   before publishing it; its provenance detects changed same-month MDL weights.
   Code changes are on migration/wsl. Preserve desired local changes in a commit
   before switching to china-20261019 to inspect or run the original code.

--- Original China / Windows SOP retained for reference ---

# TRAIN 深度向下沖
1. RDP DellData (192.168.100.186)
d:
cd D:\git\YahooDownload\TWSE
download_tw_stock.bat

2. RDP WinChina (192.168.100.194)
dir G:\期貨歷史資料\00David\TW_STK_DAILY.zip
dir G:\期貨歷史資料\00David\CN\SH?_A_STK_DAILY.zip
dir G:\期貨歷史資料\TW\TSE\day\StockDataN.zip
dir G:\期貨歷史資料\00David\TOKYO\JP_STK_DAILY.zip

# Make sure Google Drive is ready

3. git pull D:\deepmodels
6. run update_tw.bat
7. run update_twn.bat
9. git commit && push D:\deepmodels
10. convert pt models (step 11~15)

# Convert 深度向下沖 ptmodel (pytorch version 1.0)
11. wsl
12. conda activate pytorch101
13. cd /mnt/d/git/ModelTrain/TW
14. python MakeLocalModel.py
15. exit

# Commit and Rclone to Google Cloud
16. cd D:\deepmodels
17. git add . && git commit & push
18. copy_gdrive.bat

# sync SDL
19. ssh simon@192.168.100.103 (SDL)
20. git pull /dvol/deepmodels

# check
22. Use DavidTrade.exe to verify model if working.

-- DONE.
