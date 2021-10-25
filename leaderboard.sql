CREATE TABLE `ev_leaderboard` (
    `license`   VARCHAR(255) NOT NULL,
    `kills`     INTEGER(15000) NOT NULL DEFAULT 0,
    `deaths`    INTEGER(15000) NOT NULL DEFAULT 0,
    `image`     VARCHAR(255) NOT NULL,
    PRIMARY KEY (`license`)
);