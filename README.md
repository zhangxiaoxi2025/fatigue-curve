# 疲劳曲线 · Fatigue Curve

> 下夜班后，你还剩几成反应？ / How much reaction is left after a night shift?

**Live:** https://zhangxiaoxi2025.github.io/fatigue-curve/

A single-page, bilingual (中文 / English) vigilance test that uses the **Psychomotor Vigilance Task (PVT)**, the standard behavioural test in sleep-deprivation research, plus a Go/No-Go level. Tag each test as *rested daytime*, *post night shift* or *short on sleep*, and watch your own fatigue curve grow.

![Home](screenshots/desktop-home.png)

| Result | My curve | Mobile |
|---|---|---|
| ![Result](screenshots/desktop-result.png) | ![History](screenshots/desktop-history.png) | ![Mobile](screenshots/mobile-result.png) |

<sub>Screenshots come from an automated simulated run, not real measurements.</sub>

## How it works

The whole test takes about 1.5 minutes by default.

1. **Pick your state:** 白天清醒 rested daytime · 下夜班 post night shift · 熬夜/睡眠不足 short on sleep.
2. **Level 1, PVT:** a running millisecond counter appears at a random moment. Respond with **Space** or a **tap**.
   - **Quick (default):** 10 trials with random 2–5 s waits, about 50 s.
   - **Standard:** 3 minutes with random 2–10 s waits.
   - *Lapse*: RT ≥ 500 ms (30 s timeout). *False start*: a press before the stimulus, or an RT under 100 ms.
3. **Level 2, Go/No-Go:** 20 trials (30 in standard mode), about 30 s. Green circle = press, red square = hold back (20% No-Go). The page records commission errors, omissions and Go RT.
4. **Result:**
   - An **A–D reference grade** based on published data (see below).
   - Median and mean RT, lapses and lapse rate, false starts, slowest 10% mean, No-Go errors.
   - An **RT histogram** that shows the slow tail.
5. **My curve:** history lives in `localStorage` and is shown as a curve over time plus a comparison of the three states. You can export, import or clear it as **CSV**.
6. **Optional, opt-in anonymous submission** to Supabase. The community comparison shows **only real aggregates** from the database. Any state with fewer than 20 samples shows “样本不足 / Not enough data”.

### Why 10 trials?

The quick mode is a usability trade-off. With 5 trials a single slow response would already be a 20% lapse rate, so lapses would be close to meaningless. Ten trials give 10% resolution and still finish in under a minute.

Shorter tests are less sensitive. The validated 3-minute PVT-B cut duration by 70% and lost about 23% of effect size on average (Basner, Mollicone & Dinges 2011). This quick mode is shorter still and has **not** been validated, so the 3-minute mode is there for more careful comparisons.

The lapse threshold stays at the standard 500 ms so lapse rates are comparable with the reference data below. PVT-B itself recommends 355 ms for its 3-minute format.

## Reference grade (A–D)

The grade is the **worse** of two sub-grades. The band edges are this page's own choice, derived from the mean ± SD reported by Sun et al. 2020: rested median RT 326.7 ± 33.3 ms and lapse ratio 2.5% ± 3.6%; after 24 h awake, 369.7 ± 55.7 ms and 17.4% ± 15.0% (7-min PVT, lapse > 500 ms).

| Grade | Median RT | Lapse rate | Meaning |
|---|---|---|---|
| A | ≤ 293 ms (rested mean − 1 SD) | 0% | Faster than well-rested adults in the source |
| B | ≤ 360 ms (rested mean + 1 SD) | ≤ 6.1% (rested mean + 1 SD) | Typical well-rested range |
| C | ≤ 425 ms (24 h awake mean + 1 SD) | ≤ 17.4% (24 h awake mean) | Slower than rested, near the 24 h-awake average |
| D | > 425 ms | > 17.4% | Beyond the typical 24 h-awake range |

Other context shown on the page:
- Mah et al. 2011: college basketball players' PVT median RT went from 287.6 ± 65.9 ms at baseline to 261.4 ± 35.8 ms after weeks of sleep extension (weekly PVT, Table 3).
- Human Benchmark: across about 81 million web clicks, the median click reaction time is 273 ms (a simple click task, not a PVT). The site estimates about 30 ms of typical desktop display and input lag and notes that mobile taps tend to be slower.

**Caveats:** this is a rough reference, not a diagnosis. The norms come from lab or computer PVTs with different durations, hardware and populations. Browsers, screens and touchscreens add latency, so phone results usually run slower. Compare yourself on the same device.

## Privacy

Nothing leaves your device unless you click **匿名提交 / Submit anonymously**. A submission contains only the test summary (state, test length, RT stats, lapses, false starts, No-Go errors, n, RT histogram, app version). The table has no columns for names, emails, accounts, device IDs or IPs.

Database design ([`supabase/schema.sql`](supabase/schema.sql)):
- RLS is on, and the anonymous role only gets column-level `INSERT`. CHECK constraints validate value ranges and limit sizes.
- There is no `SELECT`, `UPDATE` or `DELETE` access to raw rows.
- Community stats come from the `SECURITY DEFINER` function `pvt_aggregate()`, which returns only per-state counts and percentiles, and only when a state has n ≥ 20.
- A simple global rate-limit trigger blocks floods.

## Science

- The PVT is a simple reaction-time task that is very sensitive to sleep loss and has minimal learning effects. Fatigue shows up less as a uniformly slower RT and more as **lapses** and a longer **slow tail**.
- Basner & Dinges 2011 found that lapse- and response-speed metrics are the most sensitive PVT outcomes. Mean and median RT were less sensitive, and the page shows both kinds of metric.

References (all checked against Crossref or Europe PMC):
1. Dinges DF, Powell JW. Microcomputer analyses of performance on a portable, simple visual RT task during sustained operations. *Behavior Research Methods, Instruments, & Computers*. 1985;17:652–655. doi:[10.3758/BF03200977](https://doi.org/10.3758/BF03200977)
2. Basner M, Dinges DF. Maximizing sensitivity of the Psychomotor Vigilance Test (PVT) to sleep loss. *Sleep*. 2011;34(5):581–591. doi:[10.1093/sleep/34.5.581](https://doi.org/10.1093/sleep/34.5.581)
3. Basner M, Mollicone D, Dinges DF. Validity and sensitivity of a brief psychomotor vigilance test (PVT-B) to total and partial sleep deprivation. *Acta Astronautica*. 2011;69:949–959. doi:[10.1016/j.actaastro.2011.07.015](https://doi.org/10.1016/j.actaastro.2011.07.015)
4. Sun J, Zhao R, Yang X, Deng H, Zhu Y, Chen Y, et al. Alteration of brain gray matter density after 24 h of sleep deprivation in healthy adults. *Frontiers in Neuroscience*. 2020;14:754. doi:[10.3389/fnins.2020.00754](https://doi.org/10.3389/fnins.2020.00754) (Table 1)
5. Mah CD, Mah KE, Kezirian EJ, Dement WC. The effects of sleep extension on the athletic performance of collegiate basketball players. *Sleep*. 2011;34(7):943–950. doi:[10.5665/SLEEP.1132](https://doi.org/10.5665/SLEEP.1132) (Table 3)
6. Human Benchmark. Reaction Time Statistics. https://humanbenchmark.com/tests/reactiontime/statistics (accessed 2026-11-22)

> **Disclaimer:** this is for entertainment and education only and is not a medical diagnosis. Browser timing varies across devices (display refresh, input latency), so compare results on the same device. If you feel seriously tired, rest, and don't drive.

## Self-hosting

1. Create a Supabase project and run `supabase/schema.sql` in its SQL editor.
2. In `index.html`, set `SUPABASE_URL` and `SUPABASE_KEY` (the anon/publishable key, which is designed to be public because RLS protects the data).
3. Serve the folder with any static host, such as GitHub Pages.

If you leave the config empty, the app works fully offline and hides the submit button.

## License

MIT © 2026 Xiaoxi Zhang
