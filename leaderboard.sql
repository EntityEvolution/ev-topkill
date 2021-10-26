CREATE TABLE `ev_leaderboard` (
    `license`   VARCHAR(255) NOT NULL,
    `discord`    VARCHAR(255) NOT NULL,
    `kills`     INTEGER(7) NOT NULL DEFAULT 0,
    `deaths`    INTEGER(7) NOT NULL DEFAULT 0,
    PRIMARY KEY (`license`)
);