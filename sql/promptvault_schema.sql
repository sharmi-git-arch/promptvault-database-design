--TABLES
CREATE TABLE User_Account (
    UserID DECIMAL(12) NOT NULL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    account_tier VARCHAR(50) NOT NULL,
    created_at DATE NOT NULL
);

CREATE TABLE FreeUser (
    UserID DECIMAL(12) NOT NULL PRIMARY KEY,
    prompt_limit DECIMAL(12) NOT NULL,
    FOREIGN KEY (UserID) REFERENCES User_Account(UserID)
);

CREATE TABLE PaidUser (
    UserID DECIMAL(12) NOT NULL PRIMARY KEY,
    billing_date DATE NOT NULL,
    payment_method VARCHAR(255) NOT NULL,
    subscription_tier VARCHAR(255) NOT NULL,
    FOREIGN KEY (UserID) REFERENCES User_Account(UserID)
);

CREATE TABLE Prompt (
    PromptID DECIMAL(12) NOT NULL PRIMARY KEY,
    UserID DECIMAL(12) NOT NULL,
    title VARCHAR(255) NOT NULL,
    prompt_text VARCHAR(255) NOT NULL,
    created_at DATE NOT NULL,
    is_archived VARCHAR(10) NOT NULL,
    FOREIGN KEY (UserID) REFERENCES User_Account(UserID)
);

CREATE TABLE PromptVersion (
    VersionID DECIMAL(12) NOT NULL PRIMARY KEY,
    PromptID DECIMAL(12) NOT NULL,
    prompt_text VARCHAR(255) NOT NULL,
    version_number DECIMAL(12) NOT NULL,
    edited_at DATE NOT NULL,
    is_current VARCHAR(10) NOT NULL,
    FOREIGN KEY (PromptID) REFERENCES Prompt(PromptID)
);

CREATE TABLE Tag (
    TagID DECIMAL(12) NOT NULL PRIMARY KEY,
    tag_name VARCHAR(255) NOT NULL
);

CREATE TABLE PromptTag (
    PromptID DECIMAL(12) NOT NULL,
    TagID DECIMAL(12) NOT NULL,
    tagged_at DATE NOT NULL,
    PRIMARY KEY (PromptID, TagID),
    FOREIGN KEY (PromptID) REFERENCES Prompt(PromptID),
    FOREIGN KEY (TagID) REFERENCES Tag(TagID)
);

CREATE TABLE AIModel (
    ModelID DECIMAL(12) NOT NULL PRIMARY KEY,
    model_name VARCHAR(255) NOT NULL,
    provider VARCHAR(255) NOT NULL,
    context_window DECIMAL(12) NOT NULL,
    input_price DECIMAL(12) NOT NULL,
    output_price DECIMAL(12) NOT NULL
);

CREATE TABLE PromptRun (
    RunID DECIMAL(12) NOT NULL PRIMARY KEY,
    PromptID DECIMAL(12) NOT NULL,
    ModelID DECIMAL(12) NOT NULL,
    UserID DECIMAL(12) NOT NULL,
    run_timestamp DATE NOT NULL,
    total_cost DECIMAL(12) NOT NULL,
    status VARCHAR(50) NOT NULL,
    FOREIGN KEY (PromptID) REFERENCES Prompt(PromptID),
    FOREIGN KEY (ModelID) REFERENCES AIModel(ModelID),
    FOREIGN KEY (UserID) REFERENCES User_Account(UserID)
);

CREATE TABLE Rating (
    RatingID DECIMAL(12) NOT NULL PRIMARY KEY,
    RunID DECIMAL(12) NOT NULL,
    UserID DECIMAL(12) NOT NULL,
    rating_value DECIMAL(12) NOT NULL,
    notes VARCHAR(255),
    FOREIGN KEY (RunID) REFERENCES PromptRun(RunID),
    FOREIGN KEY (UserID) REFERENCES User_Account(UserID)
);

CREATE TABLE Team (
    TeamID DECIMAL(12) NOT NULL PRIMARY KEY,
    team_name VARCHAR(255) NOT NULL,
    owner_user_id DECIMAL(12) NOT NULL,
    created_at DATE NOT NULL,
    FOREIGN KEY (owner_user_id) REFERENCES User_Account(UserID)
);

CREATE TABLE TeamMembership (
    UserID DECIMAL(12) NOT NULL,
    TeamID DECIMAL(12) NOT NULL,
    role VARCHAR(50) NOT NULL,
    joined_at DATE NOT NULL,
    PRIMARY KEY (UserID, TeamID),
    FOREIGN KEY (UserID) REFERENCES User_Account(UserID),
    FOREIGN KEY (TeamID) REFERENCES Team(TeamID)
);

CREATE TABLE PromptShare (
    ShareID DECIMAL(12) NOT NULL PRIMARY KEY,
    PromptID DECIMAL(12) NOT NULL,
    TeamID DECIMAL(12) NOT NULL,
    shared_by_user_id DECIMAL(12) NOT NULL,
    shared_at DATE NOT NULL,
    permission_level VARCHAR(50) NOT NULL,
    FOREIGN KEY (PromptID) REFERENCES Prompt(PromptID),
    FOREIGN KEY (TeamID) REFERENCES Team(TeamID),
    FOREIGN KEY (shared_by_user_id) REFERENCES User_Account(UserID)
);

CREATE TABLE SubscriptionTierChange (
    TierChangeID DECIMAL(12) NOT NULL PRIMARY KEY,
    OldTier      VARCHAR(255) NOT NULL,
    NewTier      VARCHAR(255) NOT NULL,
    UserID       DECIMAL(12) NOT NULL,
    ChangeDate   DATE NOT NULL,
    FOREIGN KEY (UserID) REFERENCES PaidUser(UserID)
);

--SEQUENCES
CREATE SEQUENCE user_seq START WITH 1;
CREATE SEQUENCE prompt_seq START WITH 1;
CREATE SEQUENCE promptversion_seq START WITH 1;
CREATE SEQUENCE tag_seq START WITH 1;
CREATE SEQUENCE aimodel_seq START WITH 1;
CREATE SEQUENCE promptrun_seq START WITH 1;
CREATE SEQUENCE rating_seq START WITH 1;
CREATE SEQUENCE team_seq START WITH 1;
CREATE SEQUENCE promptshare_seq START WITH 1;
CREATE SEQUENCE tierchange_seq START WITH 1;

--INDEXES
CREATE INDEX PromptUserIDIdx           ON Prompt(UserID);
CREATE INDEX PromptVersionPromptIDIdx  ON PromptVersion(PromptID);
CREATE INDEX PromptTagPromptIDIdx      ON PromptTag(PromptID);
CREATE INDEX PromptTagTagIDIdx         ON PromptTag(TagID);
CREATE INDEX PromptRunPromptIDIdx      ON PromptRun(PromptID);
CREATE INDEX PromptRunModelIDIdx       ON PromptRun(ModelID);
CREATE INDEX PromptRunUserIDIdx        ON PromptRun(UserID);
CREATE INDEX RatingRunIDIdx            ON Rating(RunID);
CREATE INDEX RatingUserIDIdx           ON Rating(UserID);
CREATE INDEX TeamOwnerUserIDIdx        ON Team(owner_user_id);
CREATE INDEX TeamMembershipUserIDIdx   ON TeamMembership(UserID);
CREATE INDEX TeamMembershipTeamIDIdx   ON TeamMembership(TeamID);
CREATE INDEX PromptSharePromptIDIdx    ON PromptShare(PromptID);
CREATE INDEX PromptShareTeamIDIdx      ON PromptShare(TeamID);
CREATE INDEX PromptShareSharedByIdx    ON PromptShare(shared_by_user_id);
CREATE INDEX PromptRunStatusIdx        ON PromptRun(status);
CREATE INDEX RatingValueIdx            ON Rating(rating_value);
CREATE INDEX PromptTitleIdx            ON Prompt(title);

--STORED PROCEDURES
CREATE OR REPLACE PROCEDURE AddFreeUser(
    p_email        VARCHAR(255),
    p_display_name VARCHAR(255),
    p_created_at   DATE
)
AS $$
BEGIN
    INSERT INTO User_Account (UserID, email, display_name, account_tier, created_at)
    VALUES (nextval('user_seq'), p_email, p_display_name, 'free', p_created_at);
    INSERT INTO FreeUser (UserID, prompt_limit)
    VALUES (currval('user_seq'), 50);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE AddPromptShare(
    p_prompt_id         DECIMAL(12),
    p_team_id           DECIMAL(12),
    p_shared_by_user_id DECIMAL(12),
    p_shared_at         DATE,
    p_permission_level  VARCHAR(50)
)
AS $$
BEGIN
    INSERT INTO PromptShare (
        ShareID, PromptID, TeamID, shared_by_user_id, shared_at, permission_level
    )
    VALUES (
        nextval('promptshare_seq'),
        p_prompt_id, p_team_id, p_shared_by_user_id, p_shared_at, p_permission_level
    );
END;
$$ LANGUAGE plpgsql;

--TRIGGERS
CREATE OR REPLACE FUNCTION SubscriptionTierChangeFunction()
RETURNS TRIGGER LANGUAGE plpgsql
AS $trigfunc$
BEGIN
    IF OLD.subscription_tier <> NEW.subscription_tier THEN
        INSERT INTO SubscriptionTierChange (
            TierChangeID, OldTier, NewTier, UserID, ChangeDate)
        VALUES (
            nextval('tierchange_seq'),
            OLD.subscription_tier,
            NEW.subscription_tier,
            NEW.UserID,
            current_date);
    END IF;
    RETURN NEW;
END;
$trigfunc$;

CREATE TRIGGER SubscriptionTierChangeTrigger
BEFORE UPDATE OF subscription_tier ON PaidUser
FOR EACH ROW
EXECUTE PROCEDURE SubscriptionTierChangeFunction();

--QUERIES
-- Query 1: Run History with Ratings
SELECT
    ua.display_name  AS user_name,
    p.title          AS prompt_title,
    am.model_name    AS model_used,
    am.provider      AS provider,
    pr.run_timestamp AS run_date,
    r.rating_value   AS star_rating,
    r.notes          AS rating_notes
FROM User_Account ua
JOIN PromptRun    pr ON pr.UserID  = ua.UserID
JOIN Prompt       p  ON p.PromptID = pr.PromptID
JOIN AIModel      am ON am.ModelID = pr.ModelID
JOIN Rating       r  ON r.RunID    = pr.RunID
WHERE pr.status = 'completed'
ORDER BY ua.display_name, r.rating_value DESC;

-- Query 2: User Account Details by Tier
SELECT
    ua.display_name      AS user_name,
    ua.email             AS email,
    ua.account_tier      AS tier,
    ua.created_at        AS member_since,
    fu.prompt_limit      AS free_prompt_limit,
    pu.subscription_tier AS paid_subscription,
    pu.billing_date      AS next_billing_date
FROM User_Account ua
LEFT JOIN FreeUser fu ON fu.UserID = ua.UserID
LEFT JOIN PaidUser pu ON pu.UserID = ua.UserID
ORDER BY ua.account_tier, ua.display_name;

-- Query 3: Best Performing AI Model (uses view)
CREATE OR REPLACE VIEW ModelEffectiveness AS
SELECT
    am.ModelID,
    am.model_name,
    am.provider,
    pr.RunID,
    r.rating_value
FROM AIModel   am
JOIN PromptRun pr ON pr.ModelID = am.ModelID
JOIN Rating    r  ON r.RunID    = pr.RunID
WHERE pr.status = 'completed';

SELECT
    model_name                  AS model,
    provider,
    COUNT(RunID)                AS total_runs,
    ROUND(AVG(rating_value), 2) AS avg_rating
FROM ModelEffectiveness
GROUP BY ModelID, model_name, provider
HAVING COUNT(RunID) >= 2
ORDER BY avg_rating DESC, total_runs DESC;

-- Visualization 1: Average Rating by AI Model
SELECT am.model_name, am.provider,
       ROUND(AVG(r.rating_value), 2) AS avg_rating,
       COUNT(r.RatingID) AS total_ratings
FROM AIModel am
JOIN PromptRun pr ON pr.ModelID = am.ModelID
JOIN Rating r ON r.RunID = pr.RunID
GROUP BY am.ModelID, am.model_name, am.provider
ORDER BY avg_rating DESC;

-- Visualization 2: Number of Prompts per User
SELECT ua.display_name, ua.account_tier,
       COUNT(p.PromptID) AS total_prompts
FROM User_Account ua
LEFT JOIN Prompt p ON p.UserID = ua.UserID
GROUP BY ua.UserID, ua.display_name, ua.account_tier
ORDER BY total_prompts DESC;
