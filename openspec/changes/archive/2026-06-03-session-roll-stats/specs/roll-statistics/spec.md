# Roll Statistics Specification

## Purpose

Per-session dice and oracle statistics — breakdown by dice type (average, sum, min, max per notation) and oracle result distribution (weighted table frequencies). Data originates from in-memory per-buffer history and is exposed through the summary window.

## Requirements

### Requirement: Dice History — Per-Buffer Append

dice.lua SHALL maintain a `roll_history` table keyed by buffer number. `M.roll()` SHALL append every successful roll result to `roll_history[bufnr]` as the final step before returning.

#### Scenario: History captures roll result

- GIVEN a buffer with bufnr=X and an initialized dice module
- WHEN `M.roll("2d6")` returns `{ notation="2d6", rolls={4,3}, total=7, sides=6, count=2, ... }`
- THEN `roll_history[X]` SHALL contain that result table as its last entry

#### Scenario: History isolates per buffer

- GIVEN buffers 1 and 2 each have rolled
- WHEN both histories are inspected
- THEN `roll_history[1]` and `roll_history[2]` SHALL contain only results from their respective buffer

### Requirement: Dice History — Accessor and Clear

dice.lua SHALL expose `get_history(bufnr?)` and `clear_history(bufnr?)`. Both default to the current buffer when `bufnr` is nil.

#### Scenario: Get returns array

- GIVEN dice_history has entries
- WHEN `get_history()` is called
- THEN it SHALL return an array of result tables (empty array if none)

#### Scenario: Clear empties history

- GIVEN a buffer with roll history entries
- WHEN `clear_history(bufnr)` is called
- THEN `roll_history[bufnr]` SHALL be an empty array

### Requirement: Oracle History — Per-Buffer Append

oracle.lua SHALL maintain an `oracle_history` table keyed by buffer number. `M.roll()` SHALL append every successful oracle result to `oracle_history[bufnr]` as the final step before returning.

#### Scenario: Oracle history captures result

- GIVEN `M.roll("fate")` returns `{ table="fate", value="yes", display="Yes" }`
- THEN `oracle_history[bufnr]` SHALL contain that result table as its last entry

### Requirement: Oracle History — Accessor

oracle.lua SHALL expose `get_history(bufnr?)` defaulting to current buffer. It SHALL return the oracle_history array or empty array.

### Requirement: Capture Before Display

`M.roll_dice()` and `M.roll_oracle()` in init.lua SHALL capture the roll/oracle result to history (by calling the respective module's history append path) BEFORE showing the float window or echo.

#### Scenario: Roll captured before UI

- GIVEN `M.roll_dice("2d6")` is called
- WHEN the float window appears
- THEN dice history SHALL already contain that roll's result

#### Scenario: Oracle captured before UI

- GIVEN `M.roll_oracle("fate")` is called
- WHEN the result is displayed
- THEN oracle history SHALL already contain that oracle's result

### Requirement: Summary Integration — Dice Breakdown

`build_session_summary()` SHALL include a `rolls` field with dice statistics aggregated by notation type. Each notation entry SHALL include notation string, count, sum, min, max, and average.

#### Scenario: Breakdown by notation type

- GIVEN a session with rolls `{ "2d6", "2d6", "1d20", "4df" }`
- WHEN `summary.rolls.by_type` is inspected
- THEN it SHALL contain entries: `{ notation="2d6", count=2, sum=N, min=M, max=MX, average=A }`, `{ notation="1d20", count=1, sum=S, ... }`, `{ notation="4df", count=1, sum=S, ... }`

#### Scenario: Total counters

- GIVEN the same rolls
- THEN `rolls.total_rolls` SHALL be 4, `rolls.fate_rolls` SHALL be 1, `rolls.success_counting` SHALL be 0

### Requirement: Summary Integration — Oracle Distribution

`build_session_summary()` SHALL include an `oracle_results` array in the `rolls` field. Each entry SHALL be keyed by oracle table name with a `results` sub-table of value→count mappings.

#### Scenario: Fate oracle distribution

- GIVEN 7 fate oracle rolls: 3 yes, 1 yes_but, 2 maybe, 1 no_but
- WHEN `rolls.oracle_results` is inspected
- THEN it SHALL contain `{ table="fate", results={ exceptional_yes=0, yes=3, yes_but=1, maybe=2, no_but=1, no=0, exceptional_no=0 } }`

### Requirement: Display — Roll Statistics Section

`format.lua` SHALL render a "Roll Statistics" section showing dice breakdown by type with notation, count, average, min, max, and total. It SHALL also show totals for fate rolls and success-counting rolls.

#### Scenario: Roll statistics section rendered

- GIVEN a summary with dice breakdown data
- WHEN `format_summary()` returns lines
- THEN the output SHALL include a section listing each notation type with its aggregate stats

### Requirement: Display — Oracle Distribution Section

`format.lua` SHALL render an "Oracle Distribution" section showing per-table result frequency counts.

#### Scenario: Oracle distribution rendered

- GIVEN a summary with oracle distribution data
- WHEN `format_summary()` returns lines
- THEN the output SHALL include a section listing each oracle table and its result frequencies
