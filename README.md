# PromptVault: Relational Database for Cross-Model AI Prompt Management

A relational database design for saving, tagging, rating, versioning, and comparing prompts across multiple AI models (Claude, GPT-4, Gemini, etc.).

Built for CS669 (Database Design & Implementation), Boston University.

## Overview

Most knowledge workers use AI assistants daily but have no structured way to track which prompts work best, on which models, for which tasks. PromptVault addresses this with a relational schema that treats **prompts, model runs, and ratings as first-class entities**, enabling evidence-based comparison of AI model effectiveness — a feature no commercial prompt tool currently offers as a primary design concern.

## Key design decisions

- **User specialization** — `FreeUser` and `PaidUser` subtype `User_Account`, enforcing a 50-prompt cap for free-tier users at the schema level
- **Prompt versioning** — `PromptVersion` preserves every edit to a prompt over time, distinct from `PromptRun` (an actual execution against a model)
- **Cross-model comparison** — `AIModel` and `PromptRun` are modeled as independent entities specifically so the same prompt can be run and rated across multiple models
- **Team sharing with approval** — `PromptShare` supports curated, permissioned sharing of prompts to team workspaces
- **Historical tracking via trigger** — a `BEFORE UPDATE` trigger on `PaidUser.subscription_tier` automatically logs every tier change to `SubscriptionTierChange`, enabling churn and upgrade-pattern analysis without any application-layer logic

## Repository structure

```
├── sql/
│   └── promptvault_schema.sql        # Complete schema: tables, sequences, indexes,
│                                      # stored procedures, trigger, queries, view
├── diagrams/
│   ├── conceptual_erd.png            # High-level entity-relationship diagram
│   └── physical_erd.png              # Full attribute-level ERD (PK/FK detail)
└── docs/
    └── CS669_Iteration6_Report.docx  # Full written project report
```

## Schema at a glance

**14 tables:** `User_Account`, `FreeUser`, `PaidUser`, `Prompt`, `PromptVersion`, `Tag`, `PromptTag`, `AIModel`, `PromptRun`, `Rating`, `Team`, `TeamMembership`, `PromptShare`, `SubscriptionTierChange`

**2 stored procedures:** `AddFreeUser`, `AddPromptShare`

**1 trigger + function:** `SubscriptionTierChangeTrigger` / `SubscriptionTierChangeFunction`

**1 view:** `ModelEffectiveness`

## Sample query — best-performing AI model by rating

```sql
CREATE OR REPLACE VIEW ModelEffectiveness AS
SELECT
    am.ModelID, am.model_name, am.provider,
    pr.RunID, r.rating_value
FROM AIModel   am
JOIN PromptRun pr ON pr.ModelID = am.ModelID
JOIN Rating    r  ON r.RunID    = pr.RunID
WHERE pr.status = 'completed';

SELECT
    model_name, provider,
    COUNT(RunID) AS total_runs,
    ROUND(AVG(rating_value), 2) AS avg_rating
FROM ModelEffectiveness
GROUP BY ModelID, model_name, provider
HAVING COUNT(RunID) >= 2
ORDER BY avg_rating DESC, total_runs DESC;
```

This is the core query behind PromptVault's distinguishing feature: telling a user which AI model performs best for their specific type of prompt, backed by their own rating history.

## Tech stack

`PostgreSQL` · `SQL (stored procedures, triggers, views)` · Entity-relationship modeling (conceptual + physical)

## Author

Sharmila Gopal — MS Applied Data Analytics, Boston University
