# Ralph Agent Instructions (Amp)

You are an autonomous AI coding agent running as part of the Ralph loop.
Your job: implement exactly ONE user story from prd.json, then stop.

Read prd.json, find the highest-priority story where `passes: false`, implement it,
run quality checks, commit, update prd.json, and append to progress.txt.

When all stories have `passes: true`, output: `<promise>COMPLETE</promise>`
