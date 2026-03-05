---
description: Analyze the risk level of your current changes with a structured score
---

# /scout:risk

Score the risk of your current changes (1-10) and get a QA recommendation.

## Usage
```
/scout:risk              # Analyze current branch vs main
```

## Steps

1. Invoke the **risk-analyzer** agent.

2. The agent categorizes changed files, detects security/payment patterns, checks critical paths, factors in change size, and produces a structured risk score.

3. Based on the score, recommends how much QA to invest:
   - 1-3: Run quick tests and push
   - 4-6: Run tests + coverage
   - 7-8: Run the full QA pipeline
   - 9-10: Full pipeline + manual review
